/// ErrorResponse Class in API Integration
class ErrorResponse {
  String? message; // Add message field directly
  List<Errors>? errors; // List of errors

  // Constructor with the message and errors fields
  ErrorResponse({this.message, this.errors});

  // JSON deserialization
  ErrorResponse.fromJson(Map<String, dynamic> json) {
    // Parse message directly from JSON
    message = json['message'];

    // Parse list of errors if present
    if (json['errors'] != null) {
      errors = <Errors>[];
      json['errors'].forEach((v) {
        errors!.add(Errors.fromJson(v));
      });
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    // Add message to the JSON
    if (message != null) {
      data['message'] = message;
    }

    // Add list of errors if present
    if (errors != null) {
      data['errors'] = errors!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}

class Errors {
  String? code;
  String? message;

  Errors({this.code, this.message});

  // JSON deserialization for Errors class
  Errors.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    message = json['message'];
  }

  // JSON serialization for Errors class
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['message'] = message;
    return data;
  }
}
