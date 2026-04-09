import { useState, useEffect, useCallback } from "react";

const WIKI_API = "https://satisfactory.wiki.gg/api.php";
const WIKI_BASE = "https://satisfactory.wiki.gg/wiki";

const defaultData = { session: [], factories: [], needs: [], scratch: "" };
const STATUS_CYCLE = ["wip", "minimal", "optimized"];
const STATUS_STYLE = {
  wip:       { bg: "#E6F1FB", color: "#185FA5" },
  minimal:   { bg: "#FAEEDA", color: "#633806" },
  optimized: { bg: "#EAF3DE", color: "#27500A" },
};
const AMBER = "#BA7517";
const MONO = "'Share Tech Mono', 'Courier New', monospace";

// ----------------------------------------------------------
// WIKI PARSING
// Parses rendered HTML from the Satisfactory MediaWiki API.
// Uses action=parse&prop=text which returns fully expanded
// HTML with structured CSS classes (recipetable, recipe-item,
// item-amount, item-name, item-minute, etc.)
// ----------------------------------------------------------

function parseRenderedHTML(title, html, wikiUrl) {
  const doc = new DOMParser().parseFromString(html, "text/html");

  // Summary: first <p> with real content
  let summary = "";
  for (const p of doc.querySelectorAll(".mw-parser-output > p")) {
    const text = p.textContent.trim();
    if (text.length > 30) {
      summary = text.split(". ").slice(0, 2).join(". ");
      if (!summary.endsWith(".")) summary += ".";
      break;
    }
  }

  // Infobox stats
  let power = null;
  for (const label of doc.querySelectorAll(".pi-data-label")) {
    const key = label.textContent.trim().toLowerCase();
    const val = label.nextElementSibling?.textContent?.trim();
    if (!val) continue;
    if (key.includes("power")) power = val.includes("MW") ? val : `${val} MW`;
  }

  // Recipes from rendered tables
  const recipes = [];
  for (const table of doc.querySelectorAll("table.recipetable")) {
    for (const row of table.querySelectorAll("tbody > tr")) {
      if (row.querySelector("th")) continue;
      const cells = row.querySelectorAll("td");
      if (cells.length < 4) continue;

      const recipeName = cells[0]?.textContent?.trim() || "";

      const parseItems = (cell) => {
        const items = [];
        for (const el of cell.querySelectorAll(".recipe-item")) {
          const amount = (el.querySelector(".item-amount")?.textContent || "").replace(/×/g, "").trim();
          const name = el.querySelector(".item-name")?.textContent?.trim();
          const perMin = el.querySelector(".item-minute")?.textContent?.trim() || "";
          if (name) items.push({ item: name, amount, perMin });
        }
        return items;
      };

      const inputs = parseItems(cells[1]);
      const outputs = parseItems(cells[3]);

      const buildingLink = cells[2]?.querySelector("a");
      const building = buildingLink?.textContent?.trim() || null;
      const timeMatch = cells[2]?.textContent?.match(/(\d+(?:\.\d+)?)\s*sec/);
      const time = timeMatch ? `${timeMatch[1]}s` : null;

      if (inputs.length || outputs.length) {
        recipes.push({ name: recipeName, isAlternate: /alternate/i.test(recipeName), inputs, outputs, building, time });
      }
    }
  }

  const defaultRecipe = recipes.find(r => !r.isAlternate) || null;
  const alternates = recipes.filter(r => r.isAlternate);

  return {
    item: title,
    summary,
    recipe: defaultRecipe,
    alternates,
    power,
    wikiUrl,
  };
}

export default function App() {
  const [tab, setTab] = useState("wiki");
  const [data, setData] = useState(defaultData);
  const [loaded, setLoaded] = useState(false);

  const [sessionInput, setSessionInput]   = useState("");
  const [needInput, setNeedInput]         = useState("");
  const [factoryName, setFactoryName]     = useState("");
  const [factoryProduces, setFactoryProduces] = useState("");
  const [factoryStatus, setFactoryStatus] = useState("wip");
  const [showFactoryForm, setShowFactoryForm] = useState(false);

  const [wikiQuery,   setWikiQuery]   = useState("");
  const [wikiResult,  setWikiResult]  = useState(null);
  const [wikiLoading, setWikiLoading] = useState(false);
  const [wikiError,   setWikiError]   = useState(null);

  useEffect(() => {
    fetch("/api/notes")
      .then(r => r.json())
      .then(d => { if (d) setData(d); })
      .catch(() => {})
      .finally(() => setLoaded(true));
  }, []);

  const save = useCallback((next) => {
    setData(next);
    fetch("/api/notes", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(next),
    }).catch(() => {});
  }, []);

  function addSession() {
    const t = sessionInput.trim();
    if (!t) return;
    save({ ...data, session: [...data.session, { id: Date.now(), text: t, done: false }] });
    setSessionInput("");
  }
  function toggleSession(id) {
    save({ ...data, session: data.session.map(x => x.id === id ? { ...x, done: !x.done } : x) });
  }
  function deleteSession(id) {
    save({ ...data, session: data.session.filter(x => x.id !== id) });
  }
  function addNeed() {
    const t = needInput.trim();
    if (!t) return;
    save({ ...data, needs: [...data.needs, { id: Date.now(), text: t }] });
    setNeedInput("");
  }
  function deleteNeed(id) {
    save({ ...data, needs: data.needs.filter(x => x.id !== id) });
  }
  function addFactory() {
    const n = factoryName.trim();
    if (!n) return;
    save({ ...data, factories: [...data.factories, { id: Date.now(), name: n, produces: factoryProduces.trim(), status: factoryStatus }] });
    setFactoryName(""); setFactoryProduces(""); setFactoryStatus("wip");
    setShowFactoryForm(false);
  }
  function cycleStatus(id) {
    save({ ...data, factories: data.factories.map(f => f.id === id ? { ...f, status: STATUS_CYCLE[(STATUS_CYCLE.indexOf(f.status) + 1) % 3] } : f) });
  }
  function deleteFactory(id) {
    save({ ...data, factories: data.factories.filter(f => f.id !== id) });
  }
  function updateScratch(val) { setData(d => ({ ...d, scratch: val })); }
  function saveScratch() { save({ ...data, scratch: data.scratch }); }

  // ----------------------------------------------------------
  // WIKI LOOKUP — hits the public Satisfactory MediaWiki API.
  //
  // Two-step process:
  //   1. action=opensearch → fuzzy search for canonical page title
  //   2. action=parse&prop=text → rendered HTML with recipes, stats
  //
  // No API key. No proxy. Works anywhere — origin=* for CORS.
  // ----------------------------------------------------------
  async function lookupWiki() {
    const q = wikiQuery.trim();
    if (!q || wikiLoading) return;
    setWikiLoading(true); setWikiResult(null); setWikiError(null);

    try {
      // Step 1: fuzzy search for the canonical page title
      const searchRes = await fetch(
        `${WIKI_API}?action=opensearch&search=${encodeURIComponent(q)}&limit=5&format=json&origin=*`
      );
      if (!searchRes.ok) throw new Error(`Search HTTP ${searchRes.status}`);
      const [, titles] = await searchRes.json();

      if (!titles.length) {
        setWikiError(`No results for "${q}". Try the exact item name.`);
        setWikiLoading(false);
        return;
      }
      const title = titles[0];
      const wikiUrl = `${WIKI_BASE}/${encodeURIComponent(title.replace(/ /g, "_"))}`;

      // Step 2: rendered HTML (follows redirects, expands all templates)
      const parseRes = await fetch(
        `${WIKI_API}?action=parse&page=${encodeURIComponent(title)}&prop=text&format=json&origin=*`
      );
      if (!parseRes.ok) throw new Error(`Parse HTTP ${parseRes.status}`);
      const parseData = await parseRes.json();
      const html = parseData?.parse?.text?.["*"] || "";

      if (!html) {
        setWikiError("Page found but no content returned.");
        setWikiLoading(false);
        return;
      }

      setWikiResult(parseRenderedHTML(title, html, wikiUrl));
    } catch (e) {
      setWikiError(`Lookup failed: ${e.message}`);
    }
    setWikiLoading(false);
  }

  const TABS = [
    { id: "wiki",      icon: WikiIcon,    label: "Wiki" },
    { id: "session",   icon: ListIcon,    label: "Session" },
    { id: "needs",     icon: AlertIcon,   label: "Needs" },
    { id: "factories", icon: FactoryIcon, label: "Factories" },
    { id: "scratch",   icon: NoteIcon,    label: "Scratch" },
  ];

  if (!loaded) return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", fontFamily: MONO, fontSize: 13, color: "var(--color-text-secondary)" }}>
      loading...
    </div>
  );

  return (
    <div style={{ fontFamily: MONO, maxWidth: 480, margin: "0 auto", display: "flex", flexDirection: "column", minHeight: "100vh" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&display=swap');
        * { box-sizing: border-box; }
        .m-input { width: 100%; font-family: ${MONO}; font-size: 16px; background: var(--color-background-secondary); border: 0.5px solid var(--color-border-tertiary); border-radius: 8px; padding: 14px 16px; color: var(--color-text-primary); -webkit-appearance: none; appearance: none; }
        .m-input:focus { outline: none; border-color: ${AMBER}; }
        .m-btn { font-family: ${MONO}; font-size: 14px; cursor: pointer; padding: 14px 20px; border-radius: 8px; border: 0.5px solid var(--color-border-secondary); background: none; color: var(--color-text-primary); -webkit-tap-highlight-color: transparent; white-space: nowrap; }
        .m-btn:active { opacity: 0.7; }
        .m-btn-primary { background: ${AMBER}; border-color: ${AMBER}; color: #fff; font-size: 15px; width: 100%; padding: 16px; }
        .m-btn-primary:active { opacity: 0.85; }
        .m-select { font-family: ${MONO}; font-size: 15px; background: var(--color-background-secondary); border: 0.5px solid var(--color-border-tertiary); border-radius: 8px; padding: 14px 16px; color: var(--color-text-primary); width: 100%; -webkit-appearance: none; appearance: none; }
        .m-row { display: flex; align-items: center; gap: 12px; padding: 14px 0; border-bottom: 0.5px solid var(--color-border-tertiary); }
        .m-del { background: none; border: none; cursor: pointer; color: var(--color-text-tertiary); font-size: 20px; padding: 4px 8px; line-height: 1; -webkit-tap-highlight-color: transparent; flex-shrink: 0; }
        .m-del:active { color: #A32D2D; }
        .m-pill { font-size: 12px; padding: 4px 10px; border-radius: 20px; cursor: pointer; letter-spacing: 0.5px; flex-shrink: 0; -webkit-tap-highlight-color: transparent; }
        .m-pill:active { opacity: 0.75; }
        .m-nav-btn { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 3px; background: none; border: none; cursor: pointer; padding: 10px 4px; -webkit-tap-highlight-color: transparent; font-family: ${MONO}; }
        .m-nav-btn:active { opacity: 0.6; }
        .m-section-label { font-size: 11px; color: var(--color-text-tertiary); letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 12px; }
        .m-empty { font-size: 13px; color: var(--color-text-tertiary); padding: 24px 0; text-align: center; }
        .m-wiki-link { display: block; text-align: center; font-size: 13px; color: var(--color-text-secondary); text-decoration: none; padding: 14px; border: 0.5px solid var(--color-border-tertiary); border-radius: 8px; margin-top: 8px; }
        .m-wiki-link:active { background: var(--color-background-secondary); }
      `}</style>

      <div style={{ flex: 1, padding: "16px 16px 80px" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 8, marginBottom: 20 }}>
          <span style={{ fontSize: 10, color: AMBER, letterSpacing: 3 }}>FICSIT</span>
          <span style={{ fontSize: 17, fontWeight: 500, color: "var(--color-text-primary)" }}>Field Notes</span>
        </div>

        {tab === "wiki" && (
          <div>
            <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
              <input className="m-input" value={wikiQuery} onChange={e => setWikiQuery(e.target.value)}
                onKeyDown={e => e.key === "Enter" && lookupWiki()}
                placeholder="item, building, or recipe..." />
              <button className="m-btn" onClick={lookupWiki} disabled={wikiLoading} style={{ opacity: wikiLoading ? 0.5 : 1 }}>
                {wikiLoading ? "..." : "Go"}
              </button>
            </div>

            {wikiLoading && (
              <div style={{ textAlign: "center", padding: "40px 0", color: "var(--color-text-secondary)", fontSize: 13 }}>
                searching wiki...
              </div>
            )}
            {wikiError && <div style={{ fontSize: 13, color: "#A32D2D", padding: "8px 0" }}>{wikiError}</div>}

            {!wikiResult && !wikiLoading && !wikiError && (
              <div style={{ paddingTop: 16 }}>
                <p className="m-empty">Look up any item, building, or recipe.</p>
                {["reinforced iron plate", "coal generator", "assembler", "fuel generator"].map(ex => (
                  <button key={ex} onClick={() => setWikiQuery(ex)}
                    style={{ display: "block", width: "100%", textAlign: "left", background: "none", border: "0.5px solid var(--color-border-tertiary)", borderRadius: 8, padding: "12px 14px", marginBottom: 8, fontFamily: MONO, fontSize: 13, color: "var(--color-text-secondary)", cursor: "pointer" }}>
                    {ex}
                  </button>
                ))}
              </div>
            )}

            {wikiResult && !wikiLoading && (
              <div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
                  <span style={{ fontSize: 18, fontWeight: 500, color: "var(--color-text-primary)" }}>{wikiResult.item}</span>
                  {wikiResult.power && <span style={{ fontSize: 13, color: AMBER, paddingTop: 4 }}>{wikiResult.power}</span>}
                </div>
                {wikiResult.summary && (
                  <p style={{ fontSize: 14, color: "var(--color-text-secondary)", marginBottom: 20, lineHeight: 1.5 }}>{wikiResult.summary}</p>
                )}

                {wikiResult.recipe && (
                  <div style={{ background: "var(--color-background-secondary)", borderRadius: 10, padding: "14px 16px", marginBottom: 14 }}>
                    <div className="m-section-label">Recipe{wikiResult.recipe.building ? ` — ${wikiResult.recipe.building}` : ""}{wikiResult.recipe.time ? ` · ${wikiResult.recipe.time}` : ""}</div>
                    {wikiResult.recipe.inputs.length > 0 && (
                      <div style={{ marginBottom: 10 }}>
                        <div style={{ fontSize: 11, color: "var(--color-text-tertiary)", marginBottom: 6 }}>INPUTS</div>
                        {wikiResult.recipe.inputs.map((inp, i) => (
                          <div key={i} style={{ display: "flex", justifyContent: "space-between", fontSize: 14, padding: "5px 0", borderBottom: "0.5px solid var(--color-border-tertiary)" }}>
                            <span style={{ color: "var(--color-text-primary)" }}>{inp.amount} × {inp.item}</span>
                            {inp.perMin && <span style={{ fontSize: 12, color: "var(--color-text-tertiary)" }}>{inp.perMin}</span>}
                          </div>
                        ))}
                      </div>
                    )}
                    {wikiResult.recipe.outputs.length > 0 && (
                      <div>
                        <div style={{ fontSize: 11, color: "var(--color-text-tertiary)", marginBottom: 6 }}>OUTPUTS</div>
                        {wikiResult.recipe.outputs.map((out, i) => (
                          <div key={i} style={{ display: "flex", justifyContent: "space-between", fontSize: 14, padding: "5px 0", borderBottom: "0.5px solid var(--color-border-tertiary)" }}>
                            <span style={{ color: AMBER }}>{out.amount} × {out.item}</span>
                            {out.perMin && <span style={{ fontSize: 12, color: "var(--color-text-tertiary)" }}>{out.perMin}</span>}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}

                {wikiResult.alternates.length > 0 && (
                  <div style={{ background: "var(--color-background-secondary)", borderRadius: 10, padding: "14px 16px", marginBottom: 14 }}>
                    <div className="m-section-label">Alternate recipes</div>
                    {wikiResult.alternates.map((alt, i) => (
                      <div key={i} style={{ padding: "8px 0", borderBottom: i < wikiResult.alternates.length - 1 ? "0.5px solid var(--color-border-tertiary)" : "none" }}>
                        <div style={{ fontSize: 13, color: "var(--color-text-primary)", marginBottom: 4 }}>{alt.name || "Alternate"}</div>
                        {alt.inputs.length > 0 && <div style={{ fontSize: 12, color: "var(--color-text-secondary)" }}>
                          {alt.inputs.map(inp => `${inp.amount} × ${inp.item}`).join(", ")}
                        </div>}
                        {alt.outputs.length > 0 && <div style={{ fontSize: 12, color: AMBER }}>
                          → {alt.outputs.map(out => `${out.amount} × ${out.item}`).join(", ")}
                        </div>}
                        {alt.building && <div style={{ fontSize: 11, color: "var(--color-text-tertiary)", marginTop: 2 }}>{alt.building}{alt.time ? ` · ${alt.time}` : ""}</div>}
                      </div>
                    ))}
                  </div>
                )}

                <a href={wikiResult.wikiUrl} target="_blank" rel="noreferrer" className="m-wiki-link">
                  View full page on wiki →
                </a>

                <button className="m-btn" onClick={() => { setWikiResult(null); setWikiQuery(""); }}
                  style={{ width: "100%", marginTop: 8, fontSize: 13, color: "var(--color-text-secondary)" }}>
                  Clear
                </button>
              </div>
            )}
          </div>
        )}

        {tab === "session" && (
          <div>
            <div className="m-section-label">This session</div>
            <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
              <input className="m-input" value={sessionInput} onChange={e => setSessionInput(e.target.value)}
                onKeyDown={e => e.key === "Enter" && addSession()}
                placeholder="What's the next small step?" />
              <button className="m-btn" onClick={addSession}>Add</button>
            </div>
            {data.session.length === 0 && <p className="m-empty">No tasks yet. Keep them small and specific.</p>}
            {data.session.map(item => (
              <div key={item.id} className="m-row">
                <input type="checkbox" checked={item.done} onChange={() => toggleSession(item.id)}
                  style={{ accentColor: AMBER, width: 20, height: 20, cursor: "pointer", flexShrink: 0 }} />
                <span style={{ flex: 1, fontSize: 15, color: item.done ? "var(--color-text-tertiary)" : "var(--color-text-primary)", textDecoration: item.done ? "line-through" : "none", lineHeight: 1.4 }}>
                  {item.text}
                </span>
                <button className="m-del" onClick={() => deleteSession(item.id)}>×</button>
              </div>
            ))}
            {data.session.some(x => x.done) && (
              <button className="m-btn" onClick={() => save({ ...data, session: data.session.filter(x => !x.done) })}
                style={{ marginTop: 16, width: "100%", fontSize: 13, color: "var(--color-text-secondary)" }}>
                Clear completed
              </button>
            )}
          </div>
        )}

        {tab === "needs" && (
          <div>
            <div className="m-section-label">Stuff you still need</div>
            <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
              <input className="m-input" value={needInput} onChange={e => setNeedInput(e.target.value)}
                onKeyDown={e => e.key === "Enter" && addNeed()}
                placeholder="e.g. screw sub-factory" />
              <button className="m-btn" onClick={addNeed}>Add</button>
            </div>
            {data.needs.length === 0 && <p className="m-empty">Nothing queued up.</p>}
            {data.needs.map(item => (
              <div key={item.id} className="m-row">
                <span style={{ color: AMBER, fontSize: 16, flexShrink: 0 }}>▸</span>
                <span style={{ flex: 1, fontSize: 15, color: "var(--color-text-primary)", lineHeight: 1.4 }}>{item.text}</span>
                <button className="m-del" onClick={() => deleteNeed(item.id)}>×</button>
              </div>
            ))}
          </div>
        )}

        {tab === "factories" && (
          <div>
            <div className="m-section-label">Factory registry</div>
            {data.factories.length === 0 && !showFactoryForm && <p className="m-empty">No factories logged yet.</p>}
            {data.factories.map(f => {
              const s = STATUS_STYLE[f.status] || STATUS_STYLE.wip;
              return (
                <div key={f.id} className="m-row" style={{ alignItems: "flex-start", paddingTop: 16, paddingBottom: 16 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, color: "var(--color-text-primary)", marginBottom: f.produces ? 4 : 0 }}>{f.name}</div>
                    {f.produces && <div style={{ fontSize: 13, color: "var(--color-text-secondary)" }}>{f.produces}</div>}
                  </div>
                  <span className="m-pill" style={{ background: s.bg, color: s.color }} onClick={() => cycleStatus(f.id)}>
                    {f.status}
                  </span>
                  <button className="m-del" onClick={() => deleteFactory(f.id)}>×</button>
                </div>
              );
            })}
            {showFactoryForm ? (
              <div style={{ background: "var(--color-background-secondary)", borderRadius: 10, padding: 16, marginTop: 16 }}>
                <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                  <input className="m-input" value={factoryName} onChange={e => setFactoryName(e.target.value)} placeholder="Factory name" />
                  <input className="m-input" value={factoryProduces} onChange={e => setFactoryProduces(e.target.value)} placeholder="Produces (optional)" />
                  <select className="m-select" value={factoryStatus} onChange={e => setFactoryStatus(e.target.value)}>
                    {STATUS_CYCLE.map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                  <button className="m-btn m-btn-primary" onClick={addFactory}>Add factory</button>
                  <button className="m-btn" onClick={() => setShowFactoryForm(false)} style={{ fontSize: 13, color: "var(--color-text-secondary)" }}>Cancel</button>
                </div>
              </div>
            ) : (
              <button className="m-btn m-btn-primary" onClick={() => setShowFactoryForm(true)} style={{ marginTop: 16 }}>
                + Log factory
              </button>
            )}
          </div>
        )}

        {tab === "scratch" && (
          <div>
            <div className="m-section-label">Scratch pad</div>
            <textarea className="m-input" value={data.scratch} onChange={e => updateScratch(e.target.value)}
              onBlur={saveScratch}
              style={{ minHeight: 260, resize: "none", lineHeight: 1.6, fontSize: 15 }}
              placeholder="ratios, counts, half-formed plans..." />
            <p style={{ fontSize: 11, color: "var(--color-text-tertiary)", marginTop: 8, textAlign: "right" }}>saves on blur</p>
          </div>
        )}
      </div>

      <div style={{ position: "fixed", bottom: 0, left: "50%", transform: "translateX(-50%)", width: "100%", maxWidth: 480, background: "var(--color-background-primary)", borderTop: "0.5px solid var(--color-border-tertiary)", display: "flex", zIndex: 10 }}>
        {TABS.map(t => (
          <button key={t.id} className="m-nav-btn" onClick={() => setTab(t.id)}>
            <t.icon active={tab === t.id} />
            <span style={{ fontSize: 10, color: tab === t.id ? AMBER : "var(--color-text-tertiary)", letterSpacing: 0.5 }}>
              {t.label}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}

function WikiIcon({ active }) {
  const c = active ? AMBER : "var(--color-text-tertiary)";
  return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>;
}
function ListIcon({ active }) {
  const c = active ? AMBER : "var(--color-text-tertiary)";
  return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><line x1="9" y1="6" x2="20" y2="6"/><line x1="9" y1="12" x2="20" y2="12"/><line x1="9" y1="18" x2="20" y2="18"/><polyline points="4 6 5 7 7 5"/><polyline points="4 12 5 13 7 11"/><polyline points="4 18 5 19 7 17"/></svg>;
}
function AlertIcon({ active }) {
  const c = active ? AMBER : "var(--color-text-tertiary)";
  return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 22 20 2 20"/><line x1="12" y1="10" x2="12" y2="14"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg>;
}
function FactoryIcon({ active }) {
  const c = active ? AMBER : "var(--color-text-tertiary)";
  return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M2 20h20v-8l-6-4V4l-4 4-4-4v8l-6 4z"/></svg>;
}
function NoteIcon({ active }) {
  const c = active ? AMBER : "var(--color-text-tertiary)";
  return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>;
}
