import 'dart:convert';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_reflection/maxi_reflection.dart';

class ParseValueForDatabase implements SyncFunctionality<dynamic> {
  final dynamic value;
  final bool parseBinaryToBase64;

  const ParseValueForDatabase({required this.value, required this.parseBinaryToBase64});

  @override
  Result<dynamic> execute() {
    if (value == null) {
      return NegativeResult.controller(
        code: ErrorCode.nullValue,
        message: const FixedOration(message: 'Null values cannot be stored in the database'),
      );
    }

    if (value is num || value is String || value is bool) {
      return ResultValue(content: value);
    }

    if (value is Enum) {
      return (value as Enum).index.asResultValue();
    }

    if (value is DateTime) {
      return PrimitiveConverter.castInt(value);
    }
    if (value is List<int>) {
      if (parseBinaryToBase64) {
        return volatileFunction(
          error: (ex, st) => NegativeResult.controller(
            code: ErrorCode.invalidFunctionality,
            message: FixedOration(message: 'Could not convert binary to base64 for the database'),
          ),
          function: () => base64.encode(value),
        );
      } else {
        return ResultValue(content: value);
      }
    }
    if (value is Map<String, dynamic> || value is List) {
      return volatileFunction(
        error: (ex, st) => NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FixedOration(message: 'Could not convert value to JSON for the database'),
        ),
        function: () => json.encode(value),
      );
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'Values of type %1 cannot be stored in the database', textParts: [value.runtimeType]),
      );
    }
  }
}
