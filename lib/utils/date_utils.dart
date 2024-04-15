/// 현재 날짜를 가져옵니다.
DateTime getCurrentDate() {
  return DateTime.now();
}

int getCurrentYear() {
  return getCurrentDate().year;
}

int getCurrentMonth() {
  return getCurrentDate().month;
}

int getCurrentDay() {
  return getCurrentDate().day;
}

int getDaysBetween(DateTime startDate, DateTime endDate) {
  return endDate.difference(startDate).inDays;
}

DateTime addDaysToDate(DateTime date, int days) {
  return date.add(Duration(days: days));
}

DateTime subtractDaysFromDate(DateTime date, int days) {
  return date.subtract(Duration(days: days));
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

bool isDateInRange(DateTime date, DateTime startDate, DateTime endDate) {
  return date.isAfter(startDate) && date.isBefore(endDate);
}

String getFormattedDate(DateTime dateTime) {
  return dateTime.toIso8601String();
}

String toPrettyString(DateTime dateTime) {
  final year = dateTime.year;
  final month = dateTime.month;
  final day = dateTime.day;
  return '$year년 $month월 $day일';
}
