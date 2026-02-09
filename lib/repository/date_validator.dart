import 'dart:developer' as developer;

import 'package:good_app/repository/models/ocr_response.dart';

/// 台灣超市常見有效日期格式的驗證與提取工具
class DateValidator {
  /// 民國年起始年份
  static const int _minguoBaseYear = 1911;

  /// 英文月份縮寫對照表
  static const Map<String, int> _monthAbbr = {
    'JAN': 1,
    'FEB': 2,
    'MAR': 3,
    'APR': 4,
    'MAY': 5,
    'JUN': 6,
    'JUL': 7,
    'AUG': 8,
    'SEP': 9,
    'OCT': 10,
    'NOV': 11,
    'DEC': 12,
  };

  /// 英文月份縮寫 regex pattern
  static final String _monthPattern = '(${_monthAbbr.keys.join('|')})';

  static int _parseMonthAbbr(String monthStr) {
    return _monthAbbr[monthStr.toUpperCase()] ?? 0;
  }

  /// 簡單驗證日期的有效性
  static bool validateDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;

    final monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    // 閏年處理
    if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
      monthDays[1] = 29;
    }

    if (day > monthDays[month - 1]) return false;

    return true;
  }

  /// 驗證日期是否為未來日期（未過期）
  static bool validateExpiryDate(int year, int month, int day) {
    if (!validateDate(year, month, day)) return false;
    try {
      final expDate = DateTime(year, month, day);
      final currentDate = DateTime.now();
      return !expDate.isBefore(currentDate);
    } catch (_) {
      return false;
    }
  }

  /// 從文字中提取日期資訊，支援台灣超市常見的有效日期格式。
  ///
  /// 支援格式:
  /// - 英文月份: DD MMM YY, DD MMM YYYY, YYYY MMM DD, MMM YYYY, MMM DD YY, MMM DD YYYY
  /// - 民國年格式: YYY/MM/DD, YYY-MM-DD, YYY.MM.DD, YYY MM DD, YYYMMDD
  /// - 西元年月日: YYYY/MM/DD, YYYY-MM-DD, YYYY.MM.DD, YYYY MM DD, YYYYMMDD
  /// - 西元日月年: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD MM YYYY, DDMMYYYY
  /// - 兩位數年份: YY/MM/DD, YY-MM-DD, YY.MM.DD, YY MM DD
  /// - 年月格式: YYYY/MM, YYYY-MM (day 預設為 1)
  /// - 月年格式: MM/YYYY, MM-YYYY (day 預設為 1)
  /// - 月日格式: MM/DD, MM-DD (year 使用當前年份)
  ///
  /// 分隔符: '.' '-' '/' 空格
  ///
  /// 返回 [OcrDate] 如果找到日期，否則返回 null
  static OcrDate? extractDate(String text) {
    developer.log('test: $text', name: 'DateValidator');
    text = text.trim();

    // 英文月份格式 (三個部分): DD MMM YY, DD MMM YYYY, YYYY MMM DD
    final patternEngMonth3 = RegExp(
      r'(\d{1,4})\s*[/\-.\s]\s*' + _monthPattern + r'\s*[/\-.\s]\s*(\d{2,4})',
      caseSensitive: false,
    );
    var match = patternEngMonth3.firstMatch(text);
    if (match != null) {
      developer.log('match 英文月份', name: 'DateValidator');
      final part1 = int.parse(match.group(1)!);
      final monthStr = match.group(2)!;
      final part3 = int.parse(match.group(3)!);
      final month = _parseMonthAbbr(monthStr);

      if (month > 0) {
        int year, day;
        if (part1 > 31) {
          // YYYY MMM DD
          year = part1;
          day = part3;
        } else {
          // DD MMM YY 或 DD MMM YYYY
          day = part1;
          year = part3;
          if (year < 100) year += 2000;
        }
        if (validateDate(year, month, day)) {
          return OcrDate(year: year, month: month, day: day);
        }
      }
    }

    // 英文月份格式 (兩個部分): MMM YYYY, MMM YY (無日期，預設 day=1)
    final patternEngMonth2 = RegExp(
      '^$_monthPattern'
      r'\s*[/\-.\s]\s*(\d{2,4})$',
      caseSensitive: false,
    );
    match = patternEngMonth2.firstMatch(text);
    if (match != null) {
      developer.log('match 英文月份2', name: 'DateValidator');
      final monthStr = match.group(1)!;
      var year = int.parse(match.group(2)!);
      final month = _parseMonthAbbr(monthStr);

      if (month > 0) {
        if (year < 100) year += 2000;
        if (validateDate(year, month, 1)) {
          return OcrDate(year: year, month: month, day: 1);
        }
      }
    }

    // MMM DD YY, MMM DD YYYY 格式
    final patternMmmDdYy = RegExp(
      '^$_monthPattern'
      r'\s*[/\-.\s]\s*(\d{1,2})\s*[/\-.\s]\s*(\d{2,4})$',
      caseSensitive: false,
    );
    match = patternMmmDdYy.firstMatch(text);
    if (match != null) {
      developer.log('match MMM DD YY, MMM DD YYYY', name: 'DateValidator');
      final monthStr = match.group(1)!;
      final day = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);
      final month = _parseMonthAbbr(monthStr);

      if (month > 0) {
        if (year < 100) year += 2000;
        if (validateDate(year, month, day)) {
          return OcrDate(year: year, month: month, day: day);
        }
      }
    }

    // YYYY MM 格式 (無日期，預設 day=1)
    final patternYyyyMm = RegExp(r'^(\d{4})\s*[/\-.\s]\s*(\d{1,2})$');
    match = patternYyyyMm.firstMatch(text);
    if (match != null) {
      developer.log('match YYYY MM', name: 'DateValidator');
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      if (validateDate(year, month, 1)) {
        return OcrDate(year: year, month: month, day: 1);
      }
    }

    // MM YYYY 格式 (無日期，預設 day=1)
    final patternMmYyyy = RegExp(r'^(\d{1,2})\s*[/\-.\s]\s*(\d{4})$');
    match = patternMmYyyy.firstMatch(text);
    if (match != null) {
      developer.log('match MM YYYY', name: 'DateValidator');
      final month = int.parse(match.group(1)!);
      final year = int.parse(match.group(2)!);
      if (validateDate(year, month, 1)) {
        return OcrDate(year: year, month: month, day: 1);
      }
    }

    // MM DD 格式 (無年份，使用當前年份)
    final patternMmDd = RegExp(r'^(\d{1,2})\s*[/\-.\s]\s*(\d{1,2})$');
    match = patternMmDd.firstMatch(text);
    if (match != null) {
      developer.log('match MM DD', name: 'DateValidator');
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);
      final year = DateTime.now().year;
      if (validateDate(year, month, day)) {
        return OcrDate(year: year, month: month, day: day);
      }
    }

    // 民國年格式 (3位數年份): YYY-MM-DD, YYY/MM/DD, YYY.MM.DD, YYY MM DD
    final patternMinguo = RegExp(
      r'^(\d{3})\s*[/\-.\s]\s*(\d{1,2})\s*[/\-.\s]\s*(\d{1,2})$',
    );
    match = patternMinguo.firstMatch(text);
    if (match != null) {
      developer.log('match 民國年', name: 'DateValidator');
      final minguoYear = int.parse(match.group(1)!);
      if (minguoYear >= 1 && minguoYear <= 200) {
        final year = minguoYear + _minguoBaseYear;
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        if (validateDate(year, month, day)) {
          return OcrDate(year: year, month: month, day: day);
        }
        return null;
      }
    }

    // 西元年格式:
    // YYYY-MM-DD, YYYY/MM/DD, YYYY.MM.DD, YYYY MM DD 或
    // DD-MM-YYYY, DD/MM/YYYY, DD.MM.YYYY, DD MM YYYY
    final patternSeparated = RegExp(
      r'(\d{2,4})\s*[/\-.\s]\s*(\d{2})\s*[/\-.\s]\s*(\d{2,4})',
    );
    match = patternSeparated.firstMatch(text);
    if (match != null) {
      developer.log('match 西元年格式', name: 'DateValidator');
      final part1 = int.parse(match.group(1)!);
      final part2 = int.parse(match.group(2)!);
      final part3 = int.parse(match.group(3)!);

      int year, month, day;
      if (part1 > 31) {
        // YYYY/MM/DD
        year = part1;
        month = part2;
        day = part3;
      } else if (part3 > 31) {
        // DD/MM/YYYY
        year = part3;
        month = part2;
        day = part1;
      } else {
        // 預設為年月日順序
        year = part1;
        month = part2;
        day = part3;
      }

      if (year < 2000) year += 2000;

      if (validateDate(year, month, day)) {
        return OcrDate(year: year, month: month, day: day);
      }
      return null;
    }

    // 無分隔符格式: YYYYMMDD, DDMMYYYY, 或 YYYMMDD (民國年)
    final patternNoSep = RegExp(r'(\d{7,8})');
    match = patternNoSep.firstMatch(text);
    if (match != null) {
      developer.log('match 無分隔符格式', name: 'DateValidator');
      final dateStr = match.group(1)!;

      int year, month, day;
      if (dateStr.length == 8) {
        final firstFour = int.parse(dateStr.substring(0, 4));

        if (firstFour > 1231) {
          // YYYYMMDD
          year = firstFour;
          month = int.parse(dateStr.substring(4, 6));
          day = int.parse(dateStr.substring(6, 8));
        } else {
          // DDMMYYYY
          day = int.parse(dateStr.substring(0, 2));
          month = int.parse(dateStr.substring(2, 4));
          year = int.parse(dateStr.substring(4, 8));
        }
      } else {
        // len == 7, YYYMMDD (民國年)
        year = int.parse(dateStr.substring(0, 3)) + _minguoBaseYear;
        month = int.parse(dateStr.substring(3, 5));
        day = int.parse(dateStr.substring(5, 7));
      }

      developer.log(
        'Extracting date from date_str: $year $month $day',
        name: 'DateValidator',
      );

      if (validateDate(year, month, day)) {
        return OcrDate(year: year, month: month, day: day);
      }
      return null;
    }

    // YY MM DD 格式 (2位數年份)
    final patternYyMmDd = RegExp(
      r'(\d{2})\s*[/\-.\s]\s*(\d{2})\s*[/\-.\s]\s*(\d{2})',
    );
    match = patternYyMmDd.firstMatch(text);
    if (match != null) {
      developer.log('match YY MM DD', name: 'DateValidator');
      var year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      if (validateDate(year, month, day)) {
        return OcrDate(year: year, month: month, day: day);
      }
    }

    return null;
  }

  /// 從文字中提取有效日期（單一日期視為有效日期）
  static OcrResponse extractExpiryDate(String text) {
    final date = extractDate(text);
    if (date == null) {
      return const OcrResponse(count: 0);
    }
    return OcrResponse(count: 1, date: OcrDateInfo(expiration: date));
  }

  static (int, int, int) _dateToTuple(OcrDate date) {
    return (date.year, date.month, date.day);
  }

  static String? _extract6DigitString(String text) {
    final match = RegExp(r'(\d{6})').firstMatch(text);
    return match?.group(1);
  }

  /// 根據指定格式解析 6 位數日期字串
  static OcrDate? _parse6DigitDate(String dateStr, String formatType) {
    if (dateStr.length != 6) return null;

    int year, month, day;
    if (formatType == 'YYMMDD') {
      year = int.parse(dateStr.substring(0, 2)) + 2000;
      month = int.parse(dateStr.substring(2, 4));
      day = int.parse(dateStr.substring(4, 6));
    } else {
      // DDMMYY
      day = int.parse(dateStr.substring(0, 2));
      month = int.parse(dateStr.substring(2, 4));
      year = int.parse(dateStr.substring(4, 6)) + 2000;
    }

    if (validateDate(year, month, day)) {
      return OcrDate(year: year, month: month, day: day);
    }
    return null;
  }

  /// 判斷 6 位數日期的格式是 YYMMDD 還是 DDMMYY
  static String _determine6DigitFormat(String dateStr) {
    final currentYear = DateTime.now().year;
    final firstTwo = int.parse(dateStr.substring(0, 2)) + 2000;
    final lastTwo = int.parse(dateStr.substring(4, 6)) + 2000;

    final diffFirst = (firstTwo - currentYear).abs();
    final diffLast = (lastTwo - currentYear).abs();

    return diffLast <= diffFirst ? 'DDMMYY' : 'YYMMDD';
  }

  /// 從文字中提取所有日期
  static List<OcrDate> _extractAllDates(String text) {
    final dates = <OcrDate>[];

    final datePatterns = [
      r'\d{4}[/\-.]\d{1,2}[/\-.]\d{1,2}', // YYYY/MM/DD
      r'\d{1,2}[/\-.]\d{1,2}[/\-.]\d{4}', // DD/MM/YYYY
      r'\d{2}[/\-.]\d{1,2}[/\-.]\d{1,2}', // YY/MM/DD
      r'\d{8}', // YYYYMMDD
      r'\d{1,2}\s*/\s*\d{1,2}\s*/\s*\d{4}', // DD / MM / YYYY
      r'\d{1,2}\s*/\s*\d{1,2}\s*/\s*\d{2}', // DD / MM / YY
    ];

    final combinedPattern = datePatterns.map((p) => '($p)').join('|');
    final matches = RegExp(combinedPattern).allMatches(text);

    for (final match in matches) {
      final dateStr = match.group(0)!;
      final date = extractDate(dateStr);
      if (date != null) {
        final tuple = _dateToTuple(date);
        final isDuplicate = dates.any((d) => _dateToTuple(d) == tuple);
        if (!isDuplicate) {
          dates.add(date);
        }
      }
    }

    return dates;
  }

  /// 從合併的文字中提取製造日期和有效日期。
  ///
  /// 支援格式:
  /// - PD, MFG 或 "製造" 後跟隨製造日期
  /// - BB, EXP 或 "有效" 後跟隨有效日期
  /// - 若無標示但有兩組日期，較舊為製造日期，較新為有效日期
  static OcrResponse extractMultipleDates(String text) {
    OcrDate? productionDate;
    OcrDate? expirationDate;
    final textUpper = text.toUpperCase();

    // 檢查是否有關鍵字標示
    final hasPdKeyword =
        textUpper.contains('PD') ||
        textUpper.contains('MFG') ||
        text.contains('製造');
    final hasBbKeyword =
        textUpper.contains('BB') ||
        textUpper.contains('EXP') ||
        text.contains('有效');

    // 找出關鍵字位置
    final pdIdx = textUpper.indexOf('PD');
    final mfgIdx = textUpper.indexOf('MFG');
    final pdCnIdx = text.indexOf('製造');
    final bbIdx = textUpper.indexOf('BB');
    final expIdx = textUpper.indexOf('EXP');
    final bbCnIdx = text.indexOf('有效');

    // 取得製造日期後的文字
    String? afterPdText;
    if (pdIdx != -1) {
      afterPdText = text.substring(pdIdx + 2);
    } else if (mfgIdx != -1) {
      afterPdText = text.substring(mfgIdx + 3);
    } else if (pdCnIdx != -1) {
      afterPdText = text.substring(pdCnIdx + 2);
    }

    // 取得有效日期後的文字
    String? afterBbText;
    if (bbIdx != -1) {
      afterBbText = text.substring(bbIdx + 2);
    } else if (expIdx != -1) {
      afterBbText = text.substring(expIdx + 3);
    } else if (bbCnIdx != -1) {
      afterBbText = text.substring(bbCnIdx + 2);
    }

    // 檢查兩者是否都是 6 位數格式
    final pd6Digit = afterPdText != null
        ? _extract6DigitString(afterPdText)
        : null;
    final bb6Digit = afterBbText != null
        ? _extract6DigitString(afterBbText)
        : null;

    if (pd6Digit != null && bb6Digit != null) {
      final formatType = _determine6DigitFormat(bb6Digit);
      developer.log(
        'Both 6-digit format detected, using $formatType',
        name: 'DateValidator',
      );
      productionDate = _parse6DigitDate(pd6Digit, formatType);
      expirationDate = _parse6DigitDate(bb6Digit, formatType);
    } else {
      if (afterPdText != null) {
        productionDate = extractDate(afterPdText);
      }
      if (afterBbText != null) {
        expirationDate = extractDate(afterBbText);
      }
    }

    // 如果沒有任何關鍵字標示，嘗試提取所有日期並比較
    if (!hasPdKeyword && !hasBbKeyword) {
      final dates = _extractAllDates(text);
      if (dates.length >= 2) {
        final tuple1 = _dateToTuple(dates[0]);
        final tuple2 = _dateToTuple(dates[1]);
        if (tuple1.$1 < tuple2.$1 ||
            (tuple1.$1 == tuple2.$1 && tuple1.$2 < tuple2.$2) ||
            (tuple1.$1 == tuple2.$1 &&
                tuple1.$2 == tuple2.$2 &&
                tuple1.$3 <= tuple2.$3)) {
          productionDate = dates[0];
          expirationDate = dates[1];
        } else {
          productionDate = dates[1];
          expirationDate = dates[0];
        }
      } else if (dates.length == 1) {
        expirationDate = dates[0];
      }
    }

    // 根據找到的日期數量回傳結果
    if (productionDate != null && expirationDate != null) {
      return OcrResponse(
        count: 2,
        date: OcrDateInfo(
          production: productionDate,
          expiration: expirationDate,
        ),
      );
    } else if (productionDate != null) {
      return OcrResponse(
        count: 1,
        date: OcrDateInfo(production: productionDate),
      );
    } else if (expirationDate != null) {
      return OcrResponse(
        count: 1,
        date: OcrDateInfo(expiration: expirationDate),
      );
    } else {
      return const OcrResponse(count: 0);
    }
  }
}
