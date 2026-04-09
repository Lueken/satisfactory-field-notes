class SessionTask {
  final int id;
  final String text;
  final bool done;

  const SessionTask({required this.id, required this.text, this.done = false});

  SessionTask copyWith({String? text, bool? done}) =>
      SessionTask(id: id, text: text ?? this.text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory SessionTask.fromJson(Map<String, dynamic> json) => SessionTask(
        id: json['id'] as int,
        text: json['text'] as String,
        done: json['done'] as bool? ?? false,
      );
}

class Need {
  final int id;
  final String text;

  const Need({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory Need.fromJson(Map<String, dynamic> json) => Need(
        id: json['id'] as int,
        text: json['text'] as String,
      );
}

class Factory {
  final int id;
  final String name;
  final String produces;
  final String status; // wip, minimal, optimized
  final Map<String, dynamic>? plannerData;

  const Factory({
    required this.id,
    required this.name,
    this.produces = '',
    this.status = 'wip',
    this.plannerData,
  });

  static const statusCycle = ['wip', 'minimal', 'optimized'];

  Factory cycleStatus() {
    final next = statusCycle[(statusCycle.indexOf(status) + 1) % 3];
    return Factory(
        id: id,
        name: name,
        produces: produces,
        status: next,
        plannerData: plannerData);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': name, // keep compat with web app's field name
        'name': name,
        'produces': produces,
        'status': status,
        if (plannerData != null) 'plannerData': plannerData,
      };

  factory Factory.fromJson(Map<String, dynamic> json) => Factory(
        id: json['id'] as int,
        name: (json['name'] ?? json['text'] ?? '') as String,
        produces: json['produces'] as String? ?? '',
        status: json['status'] as String? ?? 'wip',
        plannerData: json['plannerData'] as Map<String, dynamic>?,
      );
}

class NoteData {
  final List<SessionTask> session;
  final List<Need> needs;
  final List<Factory> factories;
  final String scratch;

  const NoteData({
    this.session = const [],
    this.needs = const [],
    this.factories = const [],
    this.scratch = '',
  });

  NoteData copyWith({
    List<SessionTask>? session,
    List<Need>? needs,
    List<Factory>? factories,
    String? scratch,
  }) =>
      NoteData(
        session: session ?? this.session,
        needs: needs ?? this.needs,
        factories: factories ?? this.factories,
        scratch: scratch ?? this.scratch,
      );

  Map<String, dynamic> toJson() => {
        'session': session.map((s) => s.toJson()).toList(),
        'needs': needs.map((n) => n.toJson()).toList(),
        'factories': factories.map((f) => f.toJson()).toList(),
        'scratch': scratch,
      };

  factory NoteData.fromJson(Map<String, dynamic> json) => NoteData(
        session: (json['session'] as List?)
                ?.map((e) => SessionTask.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        needs: (json['needs'] as List?)
                ?.map((e) => Need.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        factories: (json['factories'] as List?)
                ?.map((e) => Factory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        scratch: json['scratch'] as String? ?? '',
      );
}
