import 'dart:convert';

class MyData {
  Info? info;
  List<Item>? item;
  Auth? auth;
  List<Event>? event;
  List<Variable>? variable;

  MyData({this.info, this.item, this.auth, this.event, this.variable});

  factory MyData.fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return MyData.fromJson(decoded);
      }
    } catch (_) {}
    return MyData();
  }

  MyData.fromJson(Map<String, dynamic> json) {
    info = json['info'] != null ? Info.fromJson(json['info']) : null;
    if (json['item'] != null && json['item'] is List) {
      item = (json['item'] as List)
          .map((v) => Item.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    auth = json['auth'] != null ? Auth.fromJson(json['auth']) : null;
    if (json['event'] != null && json['event'] is List) {
      event = (json['event'] as List)
          .map((v) => Event.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    if (json['variable'] != null && json['variable'] is List) {
      variable = (json['variable'] as List)
          .map((v) => Variable.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (info != null) {
      data['info'] = info!.toJson();
    }
    if (item != null) {
      data['item'] = item!.map((v) => v.toJson()).toList();
    }
    if (auth != null) {
      data['auth'] = auth!.toJson();
    }
    if (event != null) {
      data['event'] = event!.map((v) => v.toJson()).toList();
    }
    if (variable != null) {
      data['variable'] = variable!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Info {
  String? sPostmanId;
  String? name;
  String? schema;
  String? sExporterId;

  Info({this.sPostmanId, this.name, this.schema, this.sExporterId});

  Info.fromJson(Map<String, dynamic> json) {
    sPostmanId = json['_postman_id']?.toString();
    name = json['name']?.toString();
    schema = json['schema']?.toString();
    sExporterId = json['_exporter_id']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_postman_id'] = sPostmanId;
    data['name'] = name;
    data['schema'] = schema;
    data['_exporter_id'] = sExporterId;
    return data;
  }
}

class Item {
  String? name;
  List<Item>? item;
  Auth? auth;
  List<Event>? event;
  Request? request;
  List<dynamic>? response;
  ProtocolProfileBehavior? protocolProfileBehavior;

  Item({
    this.name,
    this.item,
    this.auth,
    this.event,
    this.request,
    this.response,
    this.protocolProfileBehavior,
  });

  Item.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    if (json['item'] != null && json['item'] is List) {
      item = (json['item'] as List)
          .map((v) => Item.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    auth = json['auth'] != null ? Auth.fromJson(json['auth']) : null;
    if (json['event'] != null && json['event'] is List) {
      event = (json['event'] as List)
          .map((v) => Event.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    request = json['request'] != null
        ? Request.fromJson(json['request'] as Map<String, dynamic>)
        : null;
    if (json['response'] != null && json['response'] is List) {
      response = (json['response'] as List);
    }
    protocolProfileBehavior = json['protocolProfileBehavior'] != null
        ? ProtocolProfileBehavior.fromJson(
            json['protocolProfileBehavior'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (item != null) {
      data['item'] = item!.map((v) => v.toJson()).toList();
    }
    if (auth != null) {
      data['auth'] = auth!.toJson();
    }
    if (event != null) {
      data['event'] = event!.map((v) => v.toJson()).toList();
    }
    if (request != null) {
      data['request'] = request!.toJson();
    }
    if (response != null) {
      data['response'] = response;
    }
    if (protocolProfileBehavior != null) {
      data['protocolProfileBehavior'] = protocolProfileBehavior!.toJson();
    }
    return data;
  }
}

class Request {
  Auth? auth;
  String? method;
  List<Header>? header;
  Body? body;
  Url? url;

  Request({this.auth, this.method, this.header, this.body, this.url});

  Request.fromJson(Map<String, dynamic> json) {
    auth = json['auth'] != null ? Auth.fromJson(json['auth']) : null;
    method = json['method']?.toString();
    if (json['header'] != null && json['header'] is List) {
      header = (json['header'] as List)
          .map((v) => Header.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    body = json['body'] != null ? Body.fromJson(json['body']) : null;
    url = json['url'] != null ? Url.fromJson(json['url']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (auth != null) {
      data['auth'] = auth!.toJson();
    }
    data['method'] = method;
    if (header != null) {
      data['header'] = header!.map((v) => v.toJson()).toList();
    }
    if (body != null) {
      data['body'] = body!.toJson();
    }
    if (url != null) {
      data['url'] = url!.toJson();
    }
    return data;
  }
}

class Header {
  String? key;
  String? value;
  String? type;
  String? description;
  bool? disabled;

  Header({this.key, this.value, this.type, this.description, this.disabled});

  Header.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    value = json['value']?.toString();
    type = json['type']?.toString();
    description = json['description']?.toString();
    disabled = json['disabled'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    data['type'] = type;
    data['description'] = description;
    data['disabled'] = disabled;
    return data;
  }
}

class Auth {
  String? type;
  List<Bearer>? bearer;

  Auth({this.type, this.bearer});

  Auth.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    if (json['bearer'] != null && json['bearer'] is List) {
      bearer = (json['bearer'] as List)
          .map((v) => Bearer.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    if (bearer != null) {
      data['bearer'] = bearer!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Bearer {
  String? key;
  String? value;
  String? type;

  Bearer({this.key, this.value, this.type});

  Bearer.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    value = json['value']?.toString();
    type = json['type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    data['type'] = type;
    return data;
  }
}

class Body {
  String? mode;
  List<Formdata>? formdata;
  List<Urlencoded>? urlencoded;

  Body({this.mode, this.formdata, this.urlencoded});

  Body.fromJson(Map<String, dynamic> json) {
    mode = json['mode']?.toString();
    if (json['formdata'] != null && json['formdata'] is List) {
      formdata = (json['formdata'] as List)
          .map((v) => Formdata.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    if (json['urlencoded'] != null && json['urlencoded'] is List) {
      urlencoded = (json['urlencoded'] as List)
          .map((v) => Urlencoded.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mode'] = mode;
    if (formdata != null) {
      data['formdata'] = formdata!.map((v) => v.toJson()).toList();
    }
    if (urlencoded != null) {
      data['urlencoded'] = urlencoded!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Formdata {
  String? key;
  String? value;
  String? type;
  String? description;
  String? uuid;

  Formdata({this.key, this.value, this.type, this.description, this.uuid});

  Formdata.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    value = json['value']?.toString();
    type = json['type']?.toString();
    description = json['description']?.toString();
    uuid = json['uuid']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    data['type'] = type;
    data['description'] = description;
    data['uuid'] = uuid;
    return data;
  }
}

class Urlencoded {
  String? key;
  String? value;
  String? type;
  String? description;
  String? uuid;
  bool? disabled;

  Urlencoded({
    this.key,
    this.value,
    this.type,
    this.description,
    this.uuid,
    this.disabled,
  });

  Urlencoded.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    value = json['value']?.toString();
    type = json['type']?.toString();
    description = json['description']?.toString();
    uuid = json['uuid']?.toString();
    disabled = json['disabled'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    data['type'] = type;
    data['description'] = description;
    data['uuid'] = uuid;
    data['disabled'] = disabled;
    return data;
  }
}

class Url {
  String? raw;
  List<String>? host;
  String? port;
  List<String>? path;
  List<Query>? query;

  Url({this.raw, this.host, this.port, this.path, this.query});

  Url.fromJson(Map<String, dynamic> json) {
    raw = json['raw']?.toString();
    if (json['host'] != null && json['host'] is List) {
      host = (json['host'] as List).map((e) => e.toString()).toList();
    }
    port = json['port']?.toString();
    if (json['path'] != null && json['path'] is List) {
      path = (json['path'] as List).map((e) => e.toString()).toList();
    }
    if (json['query'] != null && json['query'] is List) {
      query = (json['query'] as List)
          .map((v) => Query.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['raw'] = raw;
    data['host'] = host;
    data['port'] = port;
    data['path'] = path;
    if (query != null) {
      data['query'] = query!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Query {
  String? key;
  String? value;

  Query({this.key, this.value});

  Query.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    value = json['value']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    return data;
  }
}

class Event {
  String? listen;
  Script? script;

  Event({this.listen, this.script});

  Event.fromJson(Map<String, dynamic> json) {
    listen = json['listen']?.toString();
    script = json['script'] != null ? Script.fromJson(json['script']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['listen'] = listen;
    if (script != null) {
      data['script'] = script!.toJson();
    }
    return data;
  }
}

class Script {
  String? type;
  Packages? packages;
  Packages? requests;
  List<String>? exec;

  Script({this.type, this.packages, this.requests, this.exec});

  Script.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    packages = json['packages'] != null ? Packages.fromJson(json['packages']) : null;
    requests = json['requests'] != null ? Packages.fromJson(json['requests']) : null;
    if (json['exec'] != null && json['exec'] is List) {
      exec = (json['exec'] as List).map((e) => e.toString()).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    if (packages != null) {
      data['packages'] = packages!.toJson();
    }
    if (requests != null) {
      data['requests'] = requests!.toJson();
    }
    data['exec'] = exec;
    return data;
  }
}

class Packages {
  Packages();

  Packages.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{};
  }
}

class Variable {
  String? key;
  String? value;
  String? type;

  Variable({this.key, this.value, this.type});

  Variable.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    value = json['value']?.toString();
    type = json['type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    data['type'] = type;
    return data;
  }
}

class ProtocolProfileBehavior {
  bool? disableBodyPruning;

  ProtocolProfileBehavior({this.disableBodyPruning});

  ProtocolProfileBehavior.fromJson(Map<String, dynamic> json) {
    disableBodyPruning = json['disableBodyPruning'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['disableBodyPruning'] = disableBodyPruning;
    return data;
  }
}
