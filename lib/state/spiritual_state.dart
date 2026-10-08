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
  EthiopianCalendarDay _currentCalendarDay = EthiopianCalendarHelper.fromGregorian(DateTime.now());
  List<EthiopianCalendarDay> _calendarWeek = EthiopianCalendarHelper.generateWeek();

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
    sections: [
      PrayerSectionModel(
        id: 'wud-mon',
        titleGeEz: 'ውዳሴ ዘሰኑይ (ሰኞ)',
        titleAmharic: 'የሰኞ ውዳሴ ማርያም',
        titleEn: 'Monday Praises of St. Mary',
        geEzText: '''ፈቀደ እግዚእ ያግዕዞ ለአዳም ኅዙነ ወትኩዘ ልብ፡ ወያግብኦ ኀበ ዘቀዳሚ መንበሩ።
አክሊለ ሠነይትኪ ኦ ድንግል ንጽሕት።
ተፈሥሒ ኦ ድንግል ንጽሕት ዘአልቦታ ሙስና፡ ዘተወልደ እምኔኪ አምላከ ቅዱሳን።
ዘአልቦ ጥንት ወዘአልቦ ማኅለቅት ዘከማሁ።
እስመ ውእቱ አክበረኪ ወአልዐለኪ እምኩሉ ፍጥረት።
ኪሩቤል ወሱራፌል ይሰግዱ ለኪ ወይዌድሱኪ በዕለተ ዕረፍት።''',
        amharicText: '''ጌታ ልቡ ያዘነና የተከዘ አዳምን ነፃ ያወጣው ዘንድ፥ ወደ ቀደመ ቦታውም ይመልሰው ዘንድ ወደደ።
ንጽሕት ድንግል ሆይ፥ መልካም አክሊላችን አንቺ ነሽ።
ጥፋት የሌለብሽ ንጽሕት ድንግል ሆይ ደስ ይበልሽ፤ ከአንቺ የተወለደው የቅዱሳን አምላክ ነው።
እርሱ መጀመሪያና መጨረሻ የሌለው ነው።
ከፍጡራን ሁሉ በላይ አክብሮሻልና፥ ከፍ ከፍም አድርጎሻልና።
ኪሩቤልና ሱራፌል በሰንበት ቀን ይሰግዱልሻል፥ ያመሰግኑሻልም።''',
      ),
      PrayerSectionModel(
        id: 'wud-tue',
        titleGeEz: 'ውዳሴ ዘሠሉስ (ማክሰኞ)',
        titleAmharic: 'የማክሰኞ ውዳሴ ማርያም',
        titleEn: 'Tuesday Praises of St. Mary',
        geEzText: '''አክሊለ ምክሕነ ወቀዳሚተ መድኃኒትነ፡ ወመሠረተ ንጽሕነ ኮነ በማርያም ድንግል፡ እንተ ወለደት ለነ ዘእግዚአብሔር ቃለ።
ዘኮነ ሰብአ በእንተ መድኃኒትነ።
እምድኅረ ኮነ ሰብአ ፈጸመ ኩሎ ሕገ ወትእዛዘ።
ዘአልቦ ኃጢአት ወዘኢረከበ ቦቱ ዐመፃ።
ተፈሥሒ ኦ ማርያም ድንግል ዘተፀነሰ በማኅፀንኪ መድኅነ ዓለም።''',
        amharicText: '''የመመኪያችን ዘውድ፥ የመዳናችን መጀመሪያ፥ የንጽሕናችን መሠረት የእግዚአብሔርን ቃል በወለደችልን በድንግል ማርያም ሆነ።
እርሱ ስለ እኛ መዳን ሰው ሆነ።
ሰው ከሆነም በኋላ ሕግንና ትእዛዝን ሁሉ ፈጸመ።
ኃጢአት የሌለበትና በደል ያልተገኘበት ነው።
የዓለም መድኃኒት በማኅፀንሽ የተፀነሰ ድንግል ማርያም ሆይ ደስ ይበልሽ።''',
      ),
      PrayerSectionModel(
        id: 'wud-wed',
        titleGeEz: 'ውዳሴ ዘረቡዕ (ረቡዕ)',
        titleAmharic: 'የረቡዕ ውዳሴ ማርያም',
        titleEn: 'Wednesday Praises of St. Mary',
        geEzText: '''ኩሉ ሠራዊተ ሰማያት ይብሉ ብፅዕት አንቲ፡ ታቦት ንጽሕት ዘአልቦታ ርኩስ።
ዘአስተርአየ ውስቴታ ማኅደረ መለኮት።
አንቲ ውእቱ ደብተራ ዘተሰመይኪ ቅድስተ ቅዱሳን።
ዘውስቴታ ታቦት ዘወርቅ ጽሩይ፡ ዘአልቦታ ጥልቀት።
ጽላተ ኪዳን ዘጸሐፎን በአጻብዒሁ እግዚአብሔር።''',
        amharicText: '''የሰማይ ሠራዊት ሁሉ እድለኛ ነሽ ይላሉ፤ እድፍ ጉድፍ የሌለብሽ ንጽሕት ታቦት ነሽና።
የመለኮት ማደሪያ በእርሷ የታየባት።
ቅድስተ ቅዱሳን የተባልሽ ድንኳን አንቺ ነሽ።
በውስጧ ምንም ጉድለት የሌለበት የጠራ የወርቅ ታቦት አለ።
እግዚአብሔር በጣቶቹ የጻፋቸው የኪዳን ጽላት በውስጧ አሉ።''',
      ),
      PrayerSectionModel(
        id: 'wud-thu',
        titleGeEz: 'ውዳሴ ዘሐሙስ (ሐሙስ)',
        titleAmharic: 'የሐሙስ ውዳሴ ማርያም',
        titleEn: 'Thursday Praises of St. Mary',
        geEzText: '''ዕፀ ጳጦስ እንተ ርእያ ሙሴ በነደ እሳት እንዘ ተነድድ ወኢትውዒ፡ ማርያም ይእቲ።
ዘነደ እሳተ መለኮቱ ኢያውዓያ።
ተፈሥሒ ኦ ምልዕተ ጸጋ ዘተወልደ እምኔኪ ክርስቶስ።
ብርሃን ዘእምብርሃን፡ አምላክ ዘእምአምላክ ዘበአማን።
ወልደ እግዚአብሔር ሕያው።''',
        amharicText: '''ሙሴ በእሳት ነበልባል ስትነድድ ሳለች ያልተቃጠለች ያያት ዛፍ (ዕፀ ጳጦስ) ማርያም ናት።
የመለኮቱ እሳት ነበልባል አላቃጠላትምና።
ጸጋን የተመላሽ ሆይ ደስ ይበልሽ፤ ከአንቺ የተወለደው ክርስቶስ ነው።
ከብርሃን የተገኘ ብርሃን፥ ከእውነተኛ አምላክ የተገኘ እውነተኛ አምላክ ነው።
የሕያው እግዚአብሔር ልጅ።''',
      ),
      PrayerSectionModel(
        id: 'wud-fri',
        titleGeEz: 'ውዳሴ ዘዓርብ (ዓርብ)',
        titleAmharic: 'የዓርብ ውዳሴ ማርያም',
        titleEn: 'Friday Praises of St. Mary',
        geEzText: '''ብፅዕት አንቲ ኦ ማርያም ወቡሩክ ፍሬ ከርሥኪ።
ድንግል ማርያም ወላዲተ አምላክ።
ዘአልቦ ሙስና ወዘኢይማስን በውሳጣ።
ተፈሥሒ ኦ ቅድስት ድንግል ዘበእንቲአኪ ተሣሃለነ እግዚአብሔር።
ወአድኃነነ እምደይን።''',
        amharicText: '''ማርያም ሆይ አንቺ የተባረክሽ ነሽ፥ የማኅፀንሽም ፍሬ የተባረከ ነው።
አምላክን የወለድሽ ድንግል ማርያም ሆይ።
በውስጧ ጥፋት የሌለባትና የማትጠፋ።
ቅድስት ድንግል ሆይ ደስ ይበልሽ፤ በአንቺ ምክንያት እግዚአብሔር ይቅር አለን።
ከፍርድም አዳነን።''',
      ),
      PrayerSectionModel(
        id: 'wud-sat',
        titleGeEz: 'ውዳሴ ዘቀዳሚት (ቅዳሜ)',
        titleAmharic: 'የቅዳሜ ውዳሴ ማርያም',
        titleEn: 'Saturday Praises of St. Mary',
        geEzText: '''ቅድስት ወብፅዕት አንቲ ድንግል ማርያም፡ ታቦተ ጽድቅ ወማኅደረ ሰላም።
እስመ እምኔኪ ተወልደ ፀሐየ ጽድቅ።
ዘአብርሃ ለኩሉ ፍጥረት በብርሃነ መለኮቱ።
ተፈሥሒ ኦ ድንግል ንጽሕት ዘአስተርአየ በላዕሌኪ ስብሐተ እግዚአብሔር።''',
        amharicText: '''ድንግል ማርያም ሆይ አንቺ ቅድስትና የተመሰገንሽ ነሽ፤ የእውነት ታቦትና የሰላም ማደሪያ ነሽ።
ከአንቺ የጽድቅ ፀሐይ ተወልዷልና።
በመለኮቱ ብርሃን ለፍጥረት ሁሉ ያበራ።
የእግዚአብሔር ክብር በአንቺ ላይ የታየ ንጽሕት ድንግል ሆይ ደስ ይበልሽ።''',
      ),
      PrayerSectionModel(
        id: 'wud-sun',
        titleGeEz: 'ውዳሴ ዘእሑድ (እሑድ)',
        titleAmharic: 'የእሑድ ውዳሴ ማርያም',
        titleEn: 'Sunday Praises of St. Mary',
        geEzText: '''ይዌድስዋ መላእክት ለማርያም በውስተ መንጦላዕት፡ ወይብሉ ብፅዕት አንቲ እምኩሎን አንስት።
እስመ ተወልደ እምኔኪ መድኅነ ዓለም።
ተፈሥሒ ኦ ድንግል ምልዕተ ጸጋ፡ እግዚአብሔር ምስሌኪ።
ኪሩቤል ወሱራፌል ይሰግዱ ለኪ።''',
        amharicText: '''መላእክት በመጋረጃው ውስጥ ሆነው ማርያምን ያመሰግኗታል፤ ከሴቶች ሁሉ አንቺ የተባረክሽ ነሽ ይላሉ።
የዓለም መድኃኒት ከአንቺ ተወልዷልና።
ጸጋን የተመላሽ ድንግል ሆይ ደስ ይበልሽ፤ እግዚአብሔር ከአንቺ ጋር ነው።
ኪሩቤልና ሱራፌል ይሰግዱልሻል።''',
      ),
    ],
  );

  PrayerBookModel _yezewetirTselot = const PrayerBookModel(
    id: 'bk-yezewetir',
    title: 'Yezewetir Tselot (Daily Prayers)',
    titleGeEz: 'ጸሎት ዘዘወትር',
    description: 'Canonical Daily Prayers chanted by Orthodox faithful morning and evening.',
    sections: [
      PrayerSectionModel(
        id: 'yzt-1',
        titleGeEz: 'በስመ አብ ወወልድ ወመንፈስ ቅዱስ',
        titleAmharic: 'የመክፈቻ ጸሎት',
        titleEn: 'Introductory Trinitarian Prayer',
        geEzText: '''በስመ አብ ወወልድ ወመንፈስ ቅዱስ አሐዱ አምላክ አሜን።
ስብሐት ለአብ ስብሐት ለወልድ ስብሐት ለመንፈስ ቅዱስ።
ስብሐት ለእግዝእትነ ማርያም ድንግል ወላዲተ አምላክ።
ስብሐት ለመስቀለ ክርስቶስ ዕፀ መድኃኒት።''',
        amharicText: '''በአብ በወልድ በመንፈስ ቅዱስ አንድ አምላክ ስም አሜን።
ለአብ ምስጋና ይሁን፥ ለወልድ ምስጋና ይሁን፥ ለመንፈስ ቅዱስ ምስጋና ይሁን።
አምላክን ለወለደች ለእመቤታችን ለድንግል ማርያም ምስጋና ይሁን።
ለመድኃኒት እንጨት ለክርስቶስ መስቀል ምስጋና ይሁን።''',
      ),
      PrayerSectionModel(
        id: 'yzt-2',
        titleGeEz: 'አቡነ ዘበሰማያት',
        titleAmharic: 'የጌታ ጸሎት (አባታችን ሆይ)',
        titleEn: 'The Lord’s Prayer (Our Father)',
        geEzText: '''አቡነ ዘበሰማያት፡ ይቀደስ ስምከ፡ ትምጻእ መንግሥትከ፡ ለይኩን ፈቃድከ በከመ በሰማይ ከማሁ በምድር።
ሲሳየነ ዘለለ ዕለትነ ሀበነ ዮም፡ ኅድግ ለነ አበሳነ ወጌጋየነ በከመ ንሕነኒ ንኅድግ ለዘአበሰ ለነ።
ኢታብአነ እግዚኦ ውስተ መንሱት፡ አላ አድኅነነ ወባልሐነ እምኩሉ እኩይ።
እስመ ዚአከ ይእቲ መንግሥት ኃይል ወስብሐት ለዓለመ ዓለም አሜን።''',
        amharicText: '''በሰማያት የምትኖር አባታችን ሆይ፥ ስምህ ይቀደስ፤ መንግሥትህ ትምጣ፤ ፈቃድህ በሰማይ እንደ ሆነች እንዲሁም በምድር ትሁን።
የዕለት እንጀራችንን ዛሬ ስጠን፤ እኛም የበደሉንን ይቅር እንደምንል በደላችንን ይቅር በለን።
አቤቱ ወደ ፈተና አታግባን፥ ከክፉ ሁሉ አድነን እንጂ።
መንግሥት ያንተ ናትና ኃይልም ክብርም ለዘለዓለሙ አሜን።''',
      ),
    ],
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

