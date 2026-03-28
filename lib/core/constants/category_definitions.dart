import 'package:flutter/material.dart';

// ── Master category + sub-category definitions ────────────────────────────────
//
// Each entry: {'id': localId, 'name': displayName}
// localId matches the BE id. The FE defines these so the app works fully
// offline — the BE only stores the id on the transaction record.

/// Income categories with their sub-categories.
const incomeCategories = <Map<String, dynamic>>[
  {'id': 1, 'name': 'Active income'},
  {'id': 2, 'name': 'Side Hustle'},
  {'id': 3, 'name': 'Business'},
  {'id': 4, 'name': 'Investment'},
];

const incomeCategorySubcategories = <String, List<Map<String, dynamic>>>{
  'Active income': [
    {'id': 101, 'name': 'Salary'},
    {'id': 102, 'name': 'Bonus'},
  ],
  'Side Hustle': [
    {'id': 103, 'name': 'Freelancing'},
    {'id': 104, 'name': 'Consultation'},
    {'id': 105, 'name': 'Affiliate'},
    {'id': 106, 'name': 'Ads'},
  ],
  'Business': [
    {'id': 107, 'name': 'Product sales'},
    {'id': 108, 'name': 'Reseller'},
  ],
  'Investment': [
    {'id': 109, 'name': 'Interest'},
    {'id': 110, 'name': 'Dividends'},
    {'id': 111, 'name': 'Capital gain'},
    {'id': 112, 'name': 'Rental'},
  ],
};

/// Expense categories with their sub-categories.
const expenseCategories = <Map<String, dynamic>>[
  {'id':  5, 'name': 'Bills'},
  {'id':  6, 'name': 'Education'},
  {'id':  7, 'name': 'Entertainment'},
  {'id':  8, 'name': 'Family and Friends'},
  {'id':  9, 'name': 'Financial'},
  {'id': 10, 'name': 'Food and Beverage'},
  {'id': 11, 'name': 'Health'},
  {'id': 12, 'name': 'Personal'},
  {'id': 13, 'name': 'Pet'},
  {'id': 14, 'name': 'Service'},
  {'id': 15, 'name': 'Shop'},
  {'id': 16, 'name': 'Transport'},
  {'id': 17, 'name': 'Vacation'},
];

const expenseCategorySubcategories = <String, List<Map<String, dynamic>>>{
  'Bills': [
    {'id': 201, 'name': 'Electricity'},
    {'id': 202, 'name': 'Environmental Fees'},
    {'id': 203, 'name': 'House'},
    {'id': 204, 'name': 'Installment'},
    {'id': 205, 'name': 'Insurance'},
    {'id': 206, 'name': 'Paylater'},
    {'id': 207, 'name': 'Rent'},
    {'id': 208, 'name': 'Subscription'},
    {'id': 209, 'name': 'Internet'},
    {'id': 210, 'name': 'Water'},
  ],
  'Education': [
    {'id': 211, 'name': 'Course'},
    {'id': 212, 'name': 'School'},
    {'id': 213, 'name': 'Stationery'},
    {'id': 214, 'name': 'Book'},
    {'id': 215, 'name': 'College'},
  ],
  'Entertainment': [
    {'id': 216, 'name': 'Cinema'},
    {'id': 217, 'name': 'Concert'},
    {'id': 218, 'name': 'Hang out'},
    {'id': 219, 'name': 'Karaoke'},
    {'id': 220, 'name': 'Photobox'},
    {'id': 221, 'name': 'Streaming'},
    {'id': 222, 'name': 'Games'},
  ],
  'Family and Friends': [
    {'id': 223, 'name': 'Baby Gear'},
    {'id': 224, 'name': 'Childcare'},
    {'id': 225, 'name': 'Loan'},
    {'id': 226, 'name': 'Present'},
    {'id': 227, 'name': 'Transfer'},
  ],
  'Financial': [
    {'id': 228, 'name': 'Charity'},
    {'id': 229, 'name': 'Cryptocurrency'},
    {'id': 230, 'name': 'Top Up'},
    {'id': 231, 'name': 'Tax'},
  ],
  'Food and Beverage': [
    {'id': 232, 'name': 'Breakfast'},
    {'id': 233, 'name': 'Cafe'},
    {'id': 234, 'name': 'Dinner'},
    {'id': 235, 'name': 'Lunch'},
    {'id': 236, 'name': 'Street Food'},
  ],
  'Health': [
    {'id': 237, 'name': 'Clinic'},
    {'id': 238, 'name': 'Doctor Consultation'},
    {'id': 239, 'name': 'Health Insurance'},
    {'id': 240, 'name': 'Mental Health'},
    {'id': 241, 'name': 'Pharmacy'},
  ],
  'Personal': [
    {'id': 242, 'name': 'Grooming'},
    {'id': 243, 'name': 'Gym'},
    {'id': 244, 'name': 'Hobby'},
    {'id': 245, 'name': 'Salon'},
    {'id': 246, 'name': 'Skincare'},
    {'id': 247, 'name': 'Spa'},
    {'id': 248, 'name': 'Yoga Class'},
  ],
  'Pet': [
    {'id': 249, 'name': 'Pet Accessories'},
    {'id': 250, 'name': 'Pet Care'},
    {'id': 251, 'name': 'Pet Food'},
    {'id': 252, 'name': 'Pet Grooming'},
    {'id': 253, 'name': 'Toys'},
  ],
  'Service': [
    {'id': 254, 'name': 'Car Maintenance'},
    {'id': 255, 'name': 'Cleaning Service'},
    {'id': 256, 'name': 'Delivery Service'},
    {'id': 257, 'name': 'Electronics Repair'},
    {'id': 258, 'name': 'Furniture Maintenance'},
    {'id': 259, 'name': 'Motorcycle Maintenance'},
    {'id': 260, 'name': 'Online Delivery'},
  ],
  'Shop': [
    {'id': 261, 'name': 'Beauty'},
    {'id': 262, 'name': 'Electronics'},
    {'id': 263, 'name': 'Furniture'},
    {'id': 264, 'name': 'Gadgets'},
    {'id': 265, 'name': 'Grocery'},
    {'id': 266, 'name': 'Kitchenware'},
    {'id': 267, 'name': 'Online Shop'},
    {'id': 268, 'name': 'Tools'},
  ],
  'Transport': [
    {'id': 269, 'name': 'Bus'},
    {'id': 270, 'name': 'Flight'},
    {'id': 271, 'name': 'Fuel'},
    {'id': 272, 'name': 'Online Transportation'},
    {'id': 273, 'name': 'Parking'},
    {'id': 274, 'name': 'Ship'},
    {'id': 275, 'name': 'Taxi'},
    {'id': 276, 'name': 'Toll Road'},
    {'id': 277, 'name': 'Train'},
    {'id': 278, 'name': 'Vehicle Charging'},
  ],
  'Vacation': [
    {'id': 279, 'name': 'Activity'},
    {'id': 280, 'name': 'Culinary'},
    {'id': 281, 'name': 'Documentation'},
    {'id': 282, 'name': 'Souvenir'},
    {'id': 283, 'name': 'Ticketing & Sightseeing'},
    {'id': 284, 'name': 'Tour Guide'},
    {'id': 285, 'name': 'Transportation'},
    {'id': 286, 'name': 'Visa'},
    {'id': 287, 'name': 'Hotel'},
  ],
};

// ─────────────────────────────────────────────────────────────────────────────

/// Maps BE category name → local asset icon path.
const incomeCategoryIcons = <String, String>{
  'Active income': 'assets/icons/Income/Category/Active_income.webp',
  'Business':      'assets/icons/Income/Category/Business.webp',
  'Investment':    'assets/icons/Income/Category/Investment.webp',
  'Side Hustle':   'assets/icons/Income/Category/side_hustle.webp',
};

/// Maps BE sub-category name → local asset icon path.
const incomeSubCategoryIcons = <String, String>{
  'Salary':         'assets/icons/Income/Sub Category/Active income/Salary.webp',
  'Bonus':          'assets/icons/Income/Sub Category/Active income/Bonus.webp',
  'Product sales':  'assets/icons/Income/Sub Category/Business/Product_sales.webp',
  'Reseller':       'assets/icons/Income/Sub Category/Business/Reseller.webp',
  'Capital gain':   'assets/icons/Income/Sub Category/Investment/Capital_gain.webp',
  'Dividends':      'assets/icons/Income/Sub Category/Investment/Dividends.webp',
  'Interest':       'assets/icons/Income/Sub Category/Investment/Interest.webp',
  'Rental':         'assets/icons/Income/Sub Category/Investment/Rental.webp',
  'Ads':            'assets/icons/Income/Sub Category/Side Hustle/Ads.webp',
  'Affiliate':      'assets/icons/Income/Sub Category/Side Hustle/Afiliate.webp',
  'Consultation':   'assets/icons/Income/Sub Category/Side Hustle/Consultation.webp',
  'Freelancing':    'assets/icons/Income/Sub Category/Side Hustle/Freelancing.webp',
};

// ── Expense ───────────────────────────────────────────────────────────────────

const expenseCategoryIcons = <String, String>{
  'Bills':           'assets/icons/expense/Category/Bills.webp',
  'Education':       'assets/icons/expense/Category/Education.webp',
  'Family & Friends':'assets/icons/expense/Category/Family_Friends.webp',
  'Family and Friends':'assets/icons/expense/Category/Family_Friends.webp',
  'Financial':       'assets/icons/expense/Category/Financial.webp',
  'Food & Beverage': 'assets/icons/expense/Category/Food_and_beverage.webp',
  'Food and Beverage':'assets/icons/expense/Category/Food_and_beverage.webp',
  'Health':          'assets/icons/expense/Category/Health.webp',
  'Personal':        'assets/icons/expense/Category/Personal.webp',
  'Pet':             'assets/icons/expense/Category/Pet.webp',
  'Service':         'assets/icons/expense/Category/Service.webp',
  'Service & Maintenance':'assets/icons/expense/Category/Service.webp',
  'Transport':       'assets/icons/expense/Category/Transport.webp',
  'Entertainment':   'assets/icons/expense/Category/entertainment.webp',
  'Shop':            'assets/icons/expense/Category/shop.webp',
  'Vacation':        'assets/icons/expense/Category/vacation.webp',
};

const expenseSubCategoryIcons = <String, String>{
  // Bills
  'Electricity':       'assets/icons/expense/Sub category/Bills/Electricity.webp',
  'Environmental Fees':'assets/icons/expense/Sub category/Bills/Environmental_Fees.webp',
  'House':             'assets/icons/expense/Sub category/Bills/House.webp',
  'Installment':       'assets/icons/expense/Sub category/Bills/Installment.webp',
  'Insurance':         'assets/icons/expense/Sub category/Bills/Insurance.webp',
  'Paylater':          'assets/icons/expense/Sub category/Bills/Paylater.webp',
  'Rent':              'assets/icons/expense/Sub category/Bills/Rent.webp',
  'Subscription':      'assets/icons/expense/Sub category/Bills/Subscription.webp',
  'Internet':          'assets/icons/expense/Sub category/Bills/internet.webp',
  'Water':             'assets/icons/expense/Sub category/Bills/water.webp',
  // Education
  'Course':            'assets/icons/expense/Sub category/Education/Course.webp',
  'School':            'assets/icons/expense/Sub category/Education/School.webp',
  'Stationery':        'assets/icons/expense/Sub category/Education/Stationoary.webp',
  'Book':              'assets/icons/expense/Sub category/Education/book.webp',
  'College':           'assets/icons/expense/Sub category/Education/college.webp',
  // Entertainment
  'Cinema':            'assets/icons/expense/Sub category/Entertainment/Cinema.webp',
  'Concert':           'assets/icons/expense/Sub category/Entertainment/Concert.webp',
  'Hang out':          'assets/icons/expense/Sub category/Entertainment/Hang_out.webp',
  'Karaoke':           'assets/icons/expense/Sub category/Entertainment/Karaoke.webp',
  'Photobox':          'assets/icons/expense/Sub category/Entertainment/Photobox.webp',
  'Streaming':         'assets/icons/expense/Sub category/Entertainment/Streaming.webp',
  'Games':             'assets/icons/expense/Sub category/Entertainment/games.webp',
  // Family and Friends
  'Baby Gear':         'assets/icons/expense/Sub category/Family and Friends/Baby_gear.webp',
  'Childcare':         'assets/icons/expense/Sub category/Family and Friends/Childcare.webp',
  'Loan':              'assets/icons/expense/Sub category/Family and Friends/Loan.webp',
  'Present':           'assets/icons/expense/Sub category/Family and Friends/Present.webp',
  'Transfer':          'assets/icons/expense/Sub category/Family and Friends/Transfer.webp',
  // Financial
  'Charity':           'assets/icons/expense/Sub category/Financial/Charity.webp',
  'Cryptocurrency':    'assets/icons/expense/Sub category/Financial/Cryptocurrency.webp',
  'Top Up':            'assets/icons/expense/Sub category/Financial/Top_up.webp',
  'Tax':               'assets/icons/expense/Sub category/Financial/tax.webp',
  // Food and Beverage
  'Breakfast':         'assets/icons/expense/Sub category/Food and Beverage/Breakfast.webp',
  'Cafe':              'assets/icons/expense/Sub category/Food and Beverage/Cafe.webp',
  'Dinner':            'assets/icons/expense/Sub category/Food and Beverage/Dinner.webp',
  'Lunch':             'assets/icons/expense/Sub category/Food and Beverage/Lunch.webp',
  'Street Food':       'assets/icons/expense/Sub category/Food and Beverage/Street_food.webp',
  // Health
  'Clinic':            'assets/icons/expense/Sub category/Health/Clinic.webp',
  'Doctor Consultation':'assets/icons/expense/Sub category/Health/Doctor_Consultation.webp',
  'Health Insurance':  'assets/icons/expense/Sub category/Health/Health_insurance.webp',
  'Mental Health':     'assets/icons/expense/Sub category/Health/Mental_health.webp',
  'Pharmacy':          'assets/icons/expense/Sub category/Health/Pharmacy.webp',
  // Personal
  'Grooming':          'assets/icons/expense/Sub category/Personal/Grooming.webp',
  'Gym':               'assets/icons/expense/Sub category/Personal/Gym.webp',
  'Hobby':             'assets/icons/expense/Sub category/Personal/Hobby.webp',
  'Salon':             'assets/icons/expense/Sub category/Personal/Salon.webp',
  'Skincare':          'assets/icons/expense/Sub category/Personal/Skincare.webp',
  'Spa':               'assets/icons/expense/Sub category/Personal/Spa.webp',
  'Yoga Class':        'assets/icons/expense/Sub category/Personal/Yoga_class.webp',
  // Pet
  'Pet Accessories':   'assets/icons/expense/Sub category/Pet/Pet_accesories.webp',
  'Pet Care':          'assets/icons/expense/Sub category/Pet/Pet_care.webp',
  'Pet Food':          'assets/icons/expense/Sub category/Pet/Pet_food.webp',
  'Pet Grooming':      'assets/icons/expense/Sub category/Pet/Pet_grooming.webp',
  'Toys':              'assets/icons/expense/Sub category/Pet/Toys.webp',
  // Service and Maintenance
  'Car Maintenance':   'assets/icons/expense/Sub category/Service and Maintenance/Car_maintenance.webp',
  'Cleaning Service':  'assets/icons/expense/Sub category/Service and Maintenance/Cleaning Service.webp',
  'Delivery Service':  'assets/icons/expense/Sub category/Service and Maintenance/Delivery_service.webp',
  'Electronics Repair':'assets/icons/expense/Sub category/Service and Maintenance/Electronics.webp',
  'Furniture Maintenance':'assets/icons/expense/Sub category/Service and Maintenance/Furniture_maintenance.webp',
  'Motorcycle Maintenance':'assets/icons/expense/Sub category/Service and Maintenance/Motorcycle_maintenance.webp',
  'Online Delivery':   'assets/icons/expense/Sub category/Service and Maintenance/Online_delivery.webp',
  // Shop
  'Beauty':            'assets/icons/expense/Sub category/Shop/Beauty.webp',
  'Electronics':       'assets/icons/expense/Sub category/Shop/Electronics.webp',
  'Furniture':         'assets/icons/expense/Sub category/Shop/Furniture.webp',
  'Gadgets':           'assets/icons/expense/Sub category/Shop/Gadgets.webp',
  'Grocery':           'assets/icons/expense/Sub category/Shop/Grocery.webp',
  'Kitchenware':       'assets/icons/expense/Sub category/Shop/Kitchenware.webp',
  'Online Shop':       'assets/icons/expense/Sub category/Shop/Online_shop.webp',
  'Tools':             'assets/icons/expense/Sub category/Shop/Tools.webp',
  // Transport
  'Bus':               'assets/icons/expense/Sub category/Transport/Bus.webp',
  'Flight':            'assets/icons/expense/Sub category/Transport/Flight.webp',
  'Fuel':              'assets/icons/expense/Sub category/Transport/Fuel.webp',
  'Online Transportation':'assets/icons/expense/Sub category/Transport/Online_Transportation.webp',
  'Parking':           'assets/icons/expense/Sub category/Transport/Parking.webp',
  'Ship':              'assets/icons/expense/Sub category/Transport/Ship.webp',
  'Taxi':              'assets/icons/expense/Sub category/Transport/Taxi.webp',
  'Toll Road':         'assets/icons/expense/Sub category/Transport/Toll_road.webp',
  'Train':             'assets/icons/expense/Sub category/Transport/Train.webp',
  'Vehicle Charging':  'assets/icons/expense/Sub category/Transport/Vehicle_Charging.webp',
  // Vacation
  'Activity':          'assets/icons/expense/Sub category/vacation/Activity.webp',
  'Culinary':          'assets/icons/expense/Sub category/vacation/Culinary.webp',
  'Documentation':     'assets/icons/expense/Sub category/vacation/Documentation.webp',
  'Souvenir':          'assets/icons/expense/Sub category/vacation/Souvenir.webp',
  'Ticketing & Sightseeing':'assets/icons/expense/Sub category/vacation/Ticketing_sighseeing.webp',
  'Tour Guide':        'assets/icons/expense/Sub category/vacation/Tour_guide.webp',
  'Transportation':    'assets/icons/expense/Sub category/vacation/Transportation.webp',
  'Visa':              'assets/icons/expense/Sub category/vacation/Visa.webp',
  'Hotel':             'assets/icons/expense/Sub category/vacation/hotel.webp',
};

// ── Category colors ───────────────────────────────────────────────────────────

const incomeCategoryColors = <String, Color>{
  'Active income': Color(0xFF064E3B),
  'Business':      Color(0xFF0F172A),
  'Side Hustle':   Color(0xFF2DD4BF),
  'Investment':    Color(0xFF94A3B8),
};

const expenseCategoryColors = <String, Color>{
  'Food & Beverage':     Color(0xFF10B981),
  'Food and Beverage':   Color(0xFF10B981),
  'Education':           Color(0xFF06B6D4),
  'Pet':                 Color(0xFFA855F7),
  'Bills':               Color(0xFF3B82F6),
  'Financial':           Color(0xFF204480),
  'Shop':                Color(0xFFF59E0B),
  'Health':              Color(0xFFEF4444),
  'Transport':           Color(0xFF64748B),
  'Entertainment':       Color(0xFFAFEB39),
  'Family & Friends':    Color(0xFFCDCEFF),
  'Family and Friends':  Color(0xFFCDCEFF),
  'Vacation':            Color(0xFFF97316),
  'Service':             Color(0xFF8B5CF6),
  'Service & Maintenance': Color(0xFF8B5CF6),
  'Personal':            Color(0xFFFF3ABD),
};

const _fallbackColors = <Color>[
  Color(0xFF635AFF),
  Color(0xFF4BC9F0),
  Color(0xFF2DCE89),
  Color(0xFFFB6340),
  Color(0xFFFFD600),
  Color(0xFFE91E8C),
  Color(0xFF8E24AA),
  Color(0xFF00BCD4),
];

// ── Reverse sub-category → parent category map ────────────────────────────────

/// Maps each income sub-category name → its parent category name.
final _incomeSubToCategory = <String, String>{
  for (final e in incomeCategorySubcategories.entries)
    for (final sub in e.value) sub['name'] as String: e.key,
};

/// Maps each expense sub-category name → its parent category name.
final _expenseSubToCategory = <String, String>{
  for (final e in expenseCategorySubcategories.entries)
    for (final sub in e.value) sub['name'] as String: e.key,
};

// ── Case-insensitive lookup helper ────────────────────────────────────────────

V? _ciGet<V>(Map<String, V> map, String name) {
  final v = map[name];
  if (v != null) return v;
  final lower = name.toLowerCase();
  for (final e in map.entries) {
    if (e.key.toLowerCase() == lower) return e.value;
  }
  return null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Resolves the icon path for a category name given the transaction type.
/// Case-insensitive.
String? categoryIconPath(String name, {String type = 'income'}) =>
    _ciGet(type == 'expense' ? expenseCategoryIcons : incomeCategoryIcons, name);

/// Resolves the icon path for a sub-category name given the transaction type.
/// Case-insensitive.
String? subCategoryIconPath(String name, {String type = 'income'}) =>
    _ciGet(type == 'expense' ? expenseSubCategoryIcons : incomeSubCategoryIcons, name);

/// Returns the local sub-category list (with ids) for a category.
/// Case-insensitive on [categoryName].
List<Map<String, dynamic>> localSubcategories(String categoryName, {String type = 'income'}) {
  final map = type == 'expense'
      ? expenseCategorySubcategories
      : incomeCategorySubcategories;
  return _ciGet(map, categoryName) ?? [];
}

/// Returns the local category list for the given transaction type.
List<Map<String, dynamic>> localCategories({String type = 'income'}) =>
    type == 'expense' ? expenseCategories : incomeCategories;

/// Returns the defined color for a category name. Falls back to a rotating
/// palette when the name is unknown. Case-insensitive.
Color categoryColor(String name, {String type = 'income', int fallbackIndex = 0}) {
  final map = type == 'expense' ? expenseCategoryColors : incomeCategoryColors;
  return _ciGet(map, name) ?? _fallbackColors[fallbackIndex % _fallbackColors.length];
}

/// Returns the color for a sub-category by inheriting its parent category color.
/// Falls back to [fallbackIndex] if the parent is unknown.
Color subCategoryColor(String subName, {String type = 'income', int fallbackIndex = 0}) {
  final reverseMap = type == 'expense' ? _expenseSubToCategory : _incomeSubToCategory;
  final parentName = _ciGet(reverseMap, subName);
  if (parentName == null) return _fallbackColors[fallbackIndex % _fallbackColors.length];
  return categoryColor(parentName, type: type, fallbackIndex: fallbackIndex);
}
