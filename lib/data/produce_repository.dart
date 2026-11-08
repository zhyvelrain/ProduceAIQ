import 'produce_item.dart';

// 10 curated produce items from Chapter 3 (5 fruits, 5 vegetables).
//
// NUTRITION: every `nutrition` map below is copied from the official
// DOST-FNRI Philippine Food Composition Table Online Database (PhilFCT),
// Release 1, December 2019 -- per 100 g edible portion. FNRI food IDs:
//   Ampalaya D018 | Banana E008 | Kangkong D242 | Mango E051
//   Papaya E069   | Pineapple E073 | Sitaw D232 | Talbos ng Kamote D244
//   Talong D073   | Watermelon E064
// vitamin_a_mcg is FNRI's Retinol Activity Equivalent (RAE, ug).
// FNRI does not report potassium for banana (E008), so banana shows
// vitamin C as its third value instead.
// These must stay identical to ph_food_composition (Dart + PHP).

class ProduceRepository {
  static final List<ProduceItem> _catalog = [
    ProduceItem(
      id: 'banana',
      commonName: 'Saging',
      scientificName: 'Musa acuminata',
      category: 'fruit',
      family: 'Musaceae',
      history:
          'Katutubo sa Timog-Silangang Asya at New Guinea, kumalat ang '
          'saging sa mga tropikal na rehiyon sa tulong ng mga sinaunang '
          'mandaragat na Austronesyano, at kasalukuyang isa sa '
          'pinakamaraming inaning prutas sa Pilipinas.',
      shelfLife: '3-7 araw sa temperatura ng silid kapag hinog na',
      // FNRI E008 - Banana, cavendish, ripe
      nutrition: {
        'calories_kcal': 104,
        'carbs_g': 23.1,
        'vitamin_c_mg': 10,
      },
      recipes: [
        'Turon',
        'Banana cue',
        'Maruya',
      ],
      overripeRecipes: [
        'Banana bread',
        'Banana smoothie',
        'Banana pancakes',
      ],
      visualIdTips:
          'Hugis-pahaba at bahagyang baluktot na bunga, nakabuwig '
          'tulad ng kamay; berde kapag hilaw, ganap na dilaw na may '
          'maliliit na kayumangging batik kapag hinog na, at madaling '
          'natatanggal ang makapal na balat mula sa laman.',
      translations: {
        'filipino': 'Saging',
        'spanish': 'Plátano',
        'malay': 'Pisang',
        'indonesian': 'Pisang',
        'chinese': '香蕉 (Xiāngjiāo)',
        'japanese': 'バナナ (Banana)',
      },
    ),
    ProduceItem(
      id: 'mango',
      commonName: 'Mangga',
      scientificName: 'Mangifera indica',
      category: 'fruit',
      family: 'Anacardiaceae',
      history:
          'Unang inalagaan sa Timog Asya mahigit 4,000 taon na ang '
          'nakalilipas, ipinakilala ang mangga sa Pilipinas ng mga '
          'mangangalakal na Espanyol, at ang mangga ng Pilipinas na '
          '"Carabao" ay kilala na ngayon sa buong mundo dahil sa '
          'katamisan nito.',
      shelfLife: '4-7 araw sa temperatura ng silid kapag hinog na',
      // FNRI E051 - Mango, Manila super, ripe
      nutrition: {
        'calories_kcal': 70,
        'carbs_g': 16.4,
        'vitamin_c_mg': 46,
      },
      recipes: [
        'Green mango salad',
        'Mango shake',
        'Mango float',
      ],
      overripeRecipes: [
        'Mango smoothie',
        'Mango jam',
        'Mango sorbet',
      ],
      visualIdTips:
          'Hugis-itlog na bunga na may matulis na dulo; berdeng balat '
          'na unti-unting nagiging dilaw-kahel habang humihinog, at '
          'bahagyang lumalambot malapit sa tangkay kapag oras na para '
          'kainin.',
      translations: {
        'filipino': 'Mangga',
        'spanish': 'Mango',
        'malay': 'Mangga',
        'indonesian': 'Mangga',
        'chinese': '芒果 (Mángguǒ)',
        'japanese': 'マンゴー (Mangō)',
      },
    ),
    ProduceItem(
      id: 'papaya',
      commonName: 'Papaya',
      scientificName: 'Carica papaya',
      category: 'fruit',
      family: 'Caricaceae',
      history:
          'Nagmula sa timog Mexico at Central America, dinala ang '
          'papaya sa kabuuan ng Pacific sa pamamagitan ng kalakalang '
          'Galyon ng mga Espanyol, at ngayon ay itinatanim buong taon '
          'sa buong Pilipinas.',
      shelfLife: '5-7 araw sa temperatura ng silid kapag hinog na',
      // FNRI E069 - Papaya fruit, ripe
      nutrition: {
        'calories_kcal': 53,
        'carbs_g': 12.1,
        'vitamin_c_mg': 74,
      },
      recipes: [
        'Atchara (pickled papaya)',
        'Tinolang papaya',
      ],
      overripeRecipes: [
        'Papaya smoothie',
        'Papaya lassi',
      ],
      visualIdTips:
          'Malaki at pahabang bunga, berdeng balat na nagiging '
          'kahel-dilaw kapag hinog na, may malambot na kahel na laman '
          'at puno ng itim na buto sa gitna kapag hiniwa.',
      translations: {
        'filipino': 'Papaya',
        'spanish': 'Papaya',
        'malay': 'Betik',
        'indonesian': 'Pepaya',
        'chinese': '木瓜 (Mùguā)',
        'japanese': 'パパイヤ (Papaiya)',
      },
    ),
    ProduceItem(
      id: 'pineapple',
      commonName: 'Pinya',
      scientificName: 'Ananas comosus',
      category: 'fruit',
      family: 'Bromeliaceae',
      history:
          'Katutubo sa Timog Amerika, dinala ang pinya sa Pilipinas ng '
          'mga Kastilang mananakop noong ika-16 na siglo, at ngayon ay '
          'malawakang itinatanim, kabilang na para sa piña na hibla ng '
          'tela.',
      shelfLife: '2-4 araw sa temperatura ng silid kapag hinog na',
      // FNRI E073 - Pineapple
      nutrition: {
        'calories_kcal': 55,
        'carbs_g': 13,
        'vitamin_c_mg': 20,
      },
      recipes: [
        'Sinigang na baboy sa pinya',
        'Pineapple juice',
      ],
      overripeRecipes: [
        'Pineapple jam',
        'Pineapple vinegar',
      ],
      visualIdTips:
          'Silindrikal na bunga na may matinik na korona ng dahon at '
          'matigas na balat na may disenyong parang diamante; ang '
          'berde-kayumangging balat ay nagiging ginintuang-dilaw at '
          'nagbibigay ng matamis na amoy kapag hinog na.',
      translations: {
        'filipino': 'Pinya',
        'spanish': 'Piña',
        'malay': 'Nanas',
        'indonesian': 'Nanas',
        'chinese': '菠萝 (Bōluó)',
        'japanese': 'パイナップル (Painappuru)',
      },
    ),
    ProduceItem(
      id: 'watermelon',
      commonName: 'Pakwan',
      scientificName: 'Citrullus lanatus',
      category: 'fruit',
      family: 'Cucurbitaceae',
      history:
          'Unang inalagaan sa Hilagang-Silangang Aprika, ang pakwan ay '
          'ngayon ay itinatanim bilang pangunahing panseasong pananim '
          'na pinagkakakitaan sa Pilipinas, lalo na tuwing tag-init sa '
          'Luzon at Mindanao.',
      shelfLife: '2-3 linggo kung buo; 3-4 araw kapag hiniwa na at '
          'nasa refrigerator',
      // FNRI E064 - Melon, watermelon
      nutrition: {
        'calories_kcal': 31,
        'carbs_g': 7.2,
        'vitamin_c_mg': 7,
      },
      recipes: [
        'Watermelon juice',
        'Fruit salad',
      ],
      overripeRecipes: [
        'Watermelon smoothie',
        'Watermelon agua fresca',
      ],
      visualIdTips:
          'Malaki, bilog hanggang oval na bunga na may makapal na '
          'berdeng balat, kadalasang guhit-guhit; ang mapurol '
          '(hindi makintab) na balat at ang dilaw na "ground spot" '
          'kung saan ito nakapatong sa lupa ay parehong senyales ng '
          'pagkahinog.',
      translations: {
        'filipino': 'Pakwan',
        'spanish': 'Sandía',
        'malay': 'Tembikai',
        'indonesian': 'Semangka',
        'chinese': '西瓜 (Xīguā)',
        'japanese': 'スイカ (Suika)',
      },
    ),
    ProduceItem(
      id: 'kangkong',
      commonName: 'Kangkong',
      scientificName: 'Ipomoea aquatica',
      category: 'vegetable',
      family: 'Convolvulaceae',
      history:
          'Isang halos-tubigang gulay na dahon na katutubo sa tropikal '
          'na Asya, ang kangkong ay isang pangunahing gulay sa mga '
          'palengke sa Pilipinas, itinatanim sa mga bahang bukid, '
          'kanal, at maging sa mga pond sa bahay.',
      shelfLife: '2-3 araw sa refrigerator',
      // FNRI D242 - Swamp cabbage leaves
      nutrition: {
        'calories_kcal': 39,
        'carbs_g': 5.5,
        'iron_mg': 1.5,
      },
      recipes: [
        'Ginisang kangkong',
        'Kangkong salad with bagoong',
      ],
      visualIdTips:
          'Mahaba at butas-butas na tangkay na may makitid, hugis-'
          'palaso na dahon; pinakasariwa kapag malutong at maningning '
          'na berde ang tangkay, walang paninilaw sa gilid ng mga '
          'dahon.',
      translations: {
        'filipino': 'Kangkong',
        'spanish': 'Espinaca de agua',
        'english': 'Water spinach',
        'malay': 'Kangkung',
        'indonesian': 'Kangkung',
        'chinese': '空心菜 (Kōngxīncài)',
      },
    ),
    ProduceItem(
      id: 'sitaw',
      commonName: 'Sitaw',
      scientificName: 'Vigna unguiculata subsp. sesquipedalis',
      category: 'vegetable',
      family: 'Fabaceae',
      history:
          'Isang uri ng cowpea na pinaniniwalaang nagmula sa '
          'Timog-Silangang Asya, ang sitaw ay isang pangunahing gulay '
          'na legume sa mga palengke at hardin sa bahay sa buong '
          'Pilipinas.',
      shelfLife: '4-6 araw sa refrigerator',
      // FNRI D232 - String/yard long bean pod, green
      nutrition: {
        'calories_kcal': 38,
        'carbs_g': 6.2,
        'vitamin_c_mg': 2,
      },
      recipes: [
        'Ginisang sitaw',
        'Pinakbet',
      ],
      visualIdTips:
          'Napakahaba (30-70cm), payat, kasing-nipis ng lapis na '
          'berdeng balat na tumutubo nang magkapares; dapat malutong '
          'pumutok kapag ibinaluktot at matigas ang pakiramdam, hindi '
          'kunot o lambot sa buong haba.',
      translations: {
        'filipino': 'Sitaw',
        'spanish': 'Habichuela larga',
        'english': 'Yardlong bean / String bean',
        'malay': 'Kacang panjang',
        'indonesian': 'Kacang panjang',
        'chinese': '豆角 (Dòujiǎo)',
      },
    ),
    ProduceItem(
      id: 'ampalaya',
      commonName: 'Ampalaya',
      scientificName: 'Momordica charantia',
      category: 'vegetable',
      family: 'Cucurbitaceae',
      history:
          'Pinaniniwalaang nagmula sa subcontinent ng India o '
          'katimugang Tsina, mahalaga ang ampalaya sa Pilipinas '
          'bilang pagkain at gamot-bayan.',
      shelfLife: '5-7 araw sa refrigerator',
      // FNRI D018 - Bitter melon/gourd fruit
      nutrition: {
        'calories_kcal': 23,
        'carbs_g': 4.2,
        'vitamin_c_mg': 2,
      },
      recipes: [
        'Ampalaya con carne',
        'Ginisang ampalaya with egg',
      ],
      visualIdTips:
          'Pahabang bunga na may kakaibang balat na may bukol-bukol '
          'at guhit-guhit na ibabaw; maputlang berde hanggang '
          'katamtamang berde kapag handa nang lutuin, nagiging '
          'dilaw-kahel at bumubuka kapag sobrang hinog na.',
      translations: {
        'filipino': 'Ampalaya',
        'spanish': 'Melón amargo',
        'english': 'Bitter melon / Bitter gourd',
        'malay': 'Peria',
        'indonesian': 'Pare',
        'chinese': '苦瓜 (Kǔguā)',
        'japanese': 'ゴーヤ (Gōya)',
      },
    ),
    ProduceItem(
      id: 'talong',
      commonName: 'Talong',
      scientificName: 'Solanum melongena',
      category: 'vegetable',
      family: 'Solanaceae',
      history:
          'Unang inalagaan sa Timog at Silangang Asya, ang talong ay '
          'matagal nang itinatanim sa Pilipinas sa loob ng mga siglo '
          'at isa sa pinakamaraming inaning gulay sa bansa.',
      shelfLife: '5-7 araw sa refrigerator',
      // FNRI D073 - Eggplant
      nutrition: {
        'calories_kcal': 29,
        'carbs_g': 5.5,
        'fiber_g': 1.6,
      },
      recipes: [
        'Tortang talong',
        'Ensaladang talong',
      ],
      visualIdTips:
          'Makintab at makinis ang balat na bunga, karaniwang '
          'matingkad na lila at pahaba sa mga uring Pilipino; dapat '
          'masikip at makintab ang balat, hindi mapurol o kulubot, '
          'at may matibay na berdeng kalyx.',
      translations: {
        'filipino': 'Talong',
        'spanish': 'Berenjena',
        'english': 'Eggplant',
        'malay': 'Terung',
        'indonesian': 'Terong',
        'chinese': '茄子 (Qiézi)',
        'japanese': 'なす (Nasu)',
      },
    ),
    ProduceItem(
      id: 'talbos_ng_kamote',
      commonName: 'Talbos ng Kamote',
      scientificName: 'Ipomoea batatas',
      category: 'vegetable',
      family: 'Convolvulaceae',
      history:
          'Ang mga kainin na dahon at usbong ng halamang kamote, ang '
          'talbos ng kamote ay isang murang gulay na dahon na mayaman '
          'sa sustansya at malawakang kinakain ng mga mahihirap na '
          'pamilyang Pilipino.',
      shelfLife: '2-3 araw sa refrigerator',
      // FNRI D244 - Sweet potato leaves (vitamin A = RAE, ug)
      nutrition: {
        'calories_kcal': 49,
        'carbs_g': 7.2,
        'vitamin_a_mcg': 481,
      },
      recipes: [
        'Ginisang kamote tops',
        'Kamote tops with bagoong',
      ],
      visualIdTips:
          'Hugis-puso, malambot na mga dahon sa manipis na gumagapang '
          'na baging; pumili ng mga buwig na matingkad na berde ang '
          'dahon, walang mantsa, at walang malansa o itim na tangkay.',
      translations: {
        'filipino': 'Talbos ng Kamote',
        'spanish': 'Hojas de camote',
        'english': 'Sweet potato leaves/tops',
        'malay': 'Pucuk ubi keledek',
        'indonesian': 'Daun ubi jalar',
        'chinese': '番薯叶 (Fānshǔ yè)',
      },
    ),
  ];

  /// Returns all 10 item ids.
  List<String> listIds() => _catalog.map((item) => item.id).toList();

  /// Returns a single item by id, or null if not found.
  ProduceItem? get(String produceId) {
    final lowerId = produceId.toLowerCase();
    try {
      return _catalog.firstWhere((item) => item.id == lowerId);
    } catch (_) {
      return null;
    }
  }

  /// Returns all items in a category ("fruit" or "vegetable").
  List<ProduceItem> listByCategory(String category) {
    final lowerCategory = category.toLowerCase();
    return _catalog.where((item) => item.category == lowerCategory).toList();
  }

  List<String> listFamilies() {
    final families = _catalog.map((item) => item.family).toSet().toList();
    families.sort();
    return families;
  }

  /// Returns all produce items in the catalog.
  List<ProduceItem> getAllProduce() => List.unmodifiable(_catalog);
}

final produceRepository = ProduceRepository();