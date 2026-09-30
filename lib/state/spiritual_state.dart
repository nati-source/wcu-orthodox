part of 'fellowship_state.dart';

/// Feature slice managing Ethiopian Liturgical Calendar, Fasting & Daily Prayers (Wudase Maryam).
class SpiritualState extends ChangeNotifier {
  final FellowshipState root; SpiritualState(this.root);
  void refresh() => notifyListeners();
}

mixin SpiritualStateMixin on ChangeNotifier {
  // ----------------------------------------------------
  // DOMAIN 8: ETHIOPIAN LITURGICAL CALENDAR & FASTING
  // ----------------------------------------------------
  late EthiopianCalendarDay _currentCalendarDay;
  List<EthiopianCalendarDay> _calendarWeek = [];

  EthiopianCalendarDay get currentCalendarDay => _currentCalendarDay;
  List<EthiopianCalendarDay> get calendarWeek => List.unmodifiable(_calendarWeek);

  void selectCalendarDay(EthiopianCalendarDay day) {
    _currentCalendarDay = day;
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 9: AGPEYA DAILY PRAYER & HOROLOGION
  // ----------------------------------------------------
  PrayerBookModel _wudaseMaryam = const PrayerBookModel(
    id: 'bk-wudase',
    title: 'Wudase Maryam (Praise of St. Mary)',
    titleGeEz: 'ውዳሴ ማርያም (ዘሰባቱ ዕለታት)',
    description: 'Daily praises composed by St. Ephrem the Syrian and St. Cyriacus of Behnesa.',
    sections: [],
  );

  PrayerBookModel _yezewetirTselot = const PrayerBookModel(
    id: 'bk-yezewetir',
    title: 'Yezewetir Tselot (Daily Prayers)',
    titleGeEz: 'ጸሎት ዘዘወትር',
    description: 'Canonical Daily Prayers chanted by Orthodox faithful morning and evening.',
    sections: [],
  );

  PrayerBookModel get wudaseMaryam => _wudaseMaryam;
  PrayerBookModel get yezewetirTselot => _yezewetirTselot;
  List<PrayerBookModel> get orthodoxPrayerBooks => [_wudaseMaryam, _yezewetirTselot];

  int _selectedPrayerDayIndex = 0; // 0: Sunday, 1: Monday, ...
  double _prayerFontSize = 16.0;

  int get selectedPrayerDayIndex => _selectedPrayerDayIndex;
  double get prayerFontSize => _prayerFontSize;

  PrayerBookModel get currentDayPrayerBook =>
      orthodoxPrayerBooks[_selectedPrayerDayIndex.clamp(0, orthodoxPrayerBooks.length - 1)];

  void setPrayerDay(int dayIndex) {
    _selectedPrayerDayIndex = dayIndex.clamp(0, 6);
    notifyListeners();
  }

  void setPrayerFontSize(double size) {
    _prayerFontSize = size.clamp(12.0, 28.0);
    notifyListeners();
  }

}

