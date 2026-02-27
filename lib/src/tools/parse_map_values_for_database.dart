import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_reflection/maxi_reflection.dart';
import 'package:maxi_sql/src/tools/parse_value_for_database.dart';

class ParseMapValuesForDatabase implements SyncFunctionality<Map<String, dynamic>> {
  final Map<String, dynamic> values;

  const ParseMapValuesForDatabase({required this.values});

  @override
  Result<Map<String, dynamic>> execute() {
    final newMap = <String, dynamic>{};

    for (final enti in values.entries) {
      final value = enti.value;
      final convResult = ParseValueForDatabase(value: value, parseBinaryToBase64: true).execute();
      if (convResult.itsCorrect) {
        newMap[enti.key] = convResult.content;
      } else {
        final error = convResult.error.message;
        return NegativeResult.property(
          propertyName: FixedOration(message: enti.key),
          message: FlexibleOration(message: 'Error converting the value of the field %1: %2', textParts: [enti.key, error]),
        );
      }
    }

    return ResultValue(content: newMap);
  }
}
