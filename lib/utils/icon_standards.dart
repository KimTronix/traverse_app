import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Icon standards and mappings for consistent icon usage across the app
class IconStandards {
  // Use runtime (non-const) maps that point to Iconsax constants.
  // This avoids const-initialization issues and lets us safely use Iconsax icon data.
  static final Map<String, IconData> bookingTypeIcons = {
  'hotel': Iconsax.home,
    'accommodation': Iconsax.home,
    'flight': Iconsax.airplane,
    'activity': Iconsax.activity,
    'activities': Iconsax.activity,
    'car_rental': Iconsax.car,
    'transport': Iconsax.car,
    'tour': Iconsax.map,
    'tours': Iconsax.map,
  };

  // Attraction Category Icons
  static final Map<String, IconData> attractionCategoryIcons = {
  'food': Iconsax.cup,
  'restaurants': Iconsax.reserve,
  'culture': Iconsax.gallery,
  'sites': Iconsax.location,
  'game_parks': Iconsax.activity,
  'recreation': Iconsax.game,
  'nature': Iconsax.tree,
  'shopping': Iconsax.shopping_bag,
  };

  // Service Provider Category Icons
  static final Map<String, IconData> serviceProviderIcons = {
    'transport': Iconsax.car,
  'hotels': Iconsax.home,
  'accommodation': Iconsax.home,
    'tours': Iconsax.map,
  'restaurants': Iconsax.reserve,
    'car_rental': Iconsax.car,
    'activities': Iconsax.activity,
    'guides': Iconsax.user,
  };

  // Payment Method Icons
  static final Map<String, IconData> paymentMethodIcons = {
  'credit_card': Iconsax.card,
    'debit_card': Iconsax.card,
  'paypal': Iconsax.wallet,
    'apple_pay': Iconsax.money_tick,
    'google_pay': Iconsax.money_tick,
    'bank_transfer': Iconsax.bank,
    'digital_wallet': Iconsax.wallet,
    'cash': Iconsax.dollar_circle,
  };

  // Social Media Icons
  static final Map<String, IconData> socialMediaIcons = {
  'google': Iconsax.grid_1,
  'facebook': Iconsax.book,
  'twitter': Iconsax.timer,
  'instagram': Iconsax.instagram,
  'linkedin': Iconsax.link,
  };

  // Navigation Icons - Perfect Modern Set
  static final Map<String, IconData> navigationIcons = {
    // Explore/Home - Search for travel discovery
    'explore': Iconsax.search_normal_1,
    'explore_outlined': Iconsax.search_normal,
    'home': Iconsax.home,
    'home_outlined': Iconsax.home,

    // Travel Planning - Route/Map for itinerary
    'map': Iconsax.map,
    'map_outlined': Iconsax.map,
    'plan': Iconsax.map_1,
    'plan_outlined': Iconsax.map_1,

    // Messages/Chat - Beautiful message icons
    'chat': Iconsax.message,
    'chat_outlined': Iconsax.message,
    'messages': Iconsax.messages,
    'messages_outlined': Iconsax.messages,

    // Wallet - Modern wallet with money
    'wallet': Iconsax.wallet,
    'wallet_outlined': Iconsax.wallet,
    'money': Iconsax.money,
    'money_outlined': Iconsax.money,

    // Profile - Person with modern styling
    'profile': Iconsax.profile_circle,
    'profile_outlined': Iconsax.profile_circle,
    'user': Iconsax.user,
    'user_outlined': Iconsax.user,
  };

  // Action Icons - Beautiful & Modern
  static final Map<String, IconData> actionIcons = {
    // Social Actions
    'like': Iconsax.heart,
    'like_outlined': Iconsax.heart,
    'favorite': Iconsax.lovely,
    'favorite_outlined': Iconsax.lovely,

    // Communication
    'comment': Iconsax.message_text,
    'comment_outlined': Iconsax.message_text,
    'share': Iconsax.share,
    'share_outlined': Iconsax.share,

    // Bookmarking & Saving
    'bookmark': Iconsax.bookmark,
    'bookmark_outlined': Iconsax.bookmark,
    'save': Iconsax.archive_add,
    'save_outlined': Iconsax.archive_add,

    // Search & Discovery
    'search': Iconsax.search_normal_1,
    'search_outlined': Iconsax.search_normal_1,
    'filter': Iconsax.filter,
    'filter_outlined': Iconsax.filter,

    // Location & Travel
    'place': Iconsax.location,
    'place_outlined': Iconsax.location,
    'flight': Iconsax.airplane,
    'flight_outlined': Iconsax.airplane,

    // Content Actions
    'edit': Iconsax.edit,
    'edit_outlined': Iconsax.edit,
    'add': Iconsax.add_circle,
    'add_outlined': Iconsax.add_circle,

    // Utility Icons
    'calendar': Iconsax.calendar,
    'calendar_outlined': Iconsax.calendar,
    'time': Iconsax.clock,
    'time_outlined': Iconsax.clock,
    'notifications': Iconsax.notification,
    'notifications_outlined': Iconsax.notification,

    // Security & Privacy
    'lock': Iconsax.lock,
    'lock_outlined': Iconsax.lock,
    'security': Iconsax.shield_security,
    'security_outlined': Iconsax.shield_security,
    'visibility': Iconsax.eye,
    'visibility_outlined': Iconsax.eye,
    'visibility_off': Iconsax.eye_slash,
    'visibility_off_outlined': Iconsax.eye_slash,

    // Business & Money
    'business': Iconsax.building,
    'business_outlined': Iconsax.building,
    'monetization': Iconsax.money_recive,
    'monetization_outlined': Iconsax.money_recive,
    'trophy': Iconsax.award,
    'trophy_outlined': Iconsax.award,

    // Media & Interaction
    'play': Iconsax.play,
    'play_outlined': Iconsax.play,
    'download': Iconsax.document_download,
    'download_outlined': Iconsax.document_download,
    'copy': Iconsax.copy_success,
    'copy_outlined': Iconsax.copy_success,

    // System Actions
    'logout': Iconsax.logout,
    'logout_outlined': Iconsax.logout,
    'more_vert': Iconsax.more,
    'more_outlined': Iconsax.more,
    'help': Iconsax.info_circle,
    'help_outlined': Iconsax.info_circle,
    'error': Iconsax.danger,
    'error_outlined': Iconsax.danger,

    // Chart & Analytics
    'chart': Iconsax.chart,
    'chart_outlined': Iconsax.chart,
    'people': Iconsax.people,
    'people_outlined': Iconsax.people,
    'gift': Iconsax.gift,
    'gift_outlined': Iconsax.gift,
  };

  // Status Icons
  static final Map<String, IconData> statusIcons = {
    'success': Iconsax.tick_circle,
  'error': Iconsax.danger,
    'warning': Iconsax.warning_2,
    'info': Iconsax.info_circle,
    'note': Iconsax.document,
  'badge': Iconsax.medal_star,
    'pending': Iconsax.clock,
  'loading': Iconsax.login,
  };

  // Admin Icons
  static final Map<String, IconData> adminIcons = {
  'dashboard': Iconsax.grid_1,
  'users': Iconsax.user_add,
    'locations': Iconsax.location,
    'analytics': Iconsax.graph,
    'reports': Iconsax.document,
  'statistics': Iconsax.chart,
    'revenue': Iconsax.money_add,
    'bookings': Iconsax.calendar_1,
    'admin_panel': Iconsax.setting_2,
  };

  // Common UI Icons
  static final Map<String, IconData> uiIcons = {
  'back': Iconsax.back_square,
    'close': Iconsax.close_square,
    'add': Iconsax.add_square,
    'remove': Iconsax.minus_square,
    'edit': Iconsax.edit_2,
    'search': Iconsax.search_normal,
    'filter': Iconsax.filter,
    'more': Iconsax.more,
    'settings': Iconsax.setting_2,
    'help': Iconsax.info_circle,
    'logout': Iconsax.logout_1,
  'visibility': Iconsax.eye,
    'download': Iconsax.import,
    'copy': Iconsax.copy,
    'share': Iconsax.export,
    'calendar': Iconsax.calendar_1,
    'time': Iconsax.clock,
    'location': Iconsax.location,
    'success': Iconsax.tick_circle,
    'planning': Iconsax.map,
    'star': Iconsax.star,
    'phone': Iconsax.call,
    'email': Iconsax.sms,
    'camera': Iconsax.camera,
    'image': Iconsax.image,
    'add_photo_alternate': Iconsax.gallery_add,
    'play': Iconsax.play,
    'send': Iconsax.send_2,
    'notifications': Iconsax.notification,
    'check': Iconsax.tick_circle,
    'arrow_forward': Iconsax.arrow_right_2,
    'arrow_down': Iconsax.arrow_down_2,
  'qr_code': Iconsax.code,
  'security': Iconsax.shield,
    'lock': Iconsax.lock,
  'visibility_off': Iconsax.forbidden,
  'people': Iconsax.user_minus,
    'person': Iconsax.user,
    'info': Iconsax.info_circle,
    'flight': Iconsax.airplane,
    'comment': Iconsax.message_2,
    'note': Iconsax.document,
  'badge': Iconsax.medal_star,
  'smart_toy': Iconsax.programming_arrow,
  'add_comment': Iconsax.message_add,
    'attach_money': Iconsax.dollar_circle,
    'account_balance_wallet': Iconsax.wallet,
    'wallet_outlined': Iconsax.wallet,
    'person_outline': Iconsax.user,
  'timeline': Iconsax.timer,
  'video_library': Iconsax.video_square,
  'error_outline': Iconsax.arrange_circle,
  'image_not_supported': Iconsax.video_slash,
    'favorite': Iconsax.heart5,
    'favorite_border': Iconsax.heart1,
    'play_circle_outline': Iconsax.play,
    'add_circle_outline': Iconsax.add_circle,
    'confirmation_number': Iconsax.ticket,
  'mark_email_read': Iconsax.magicpen,
    'email_outlined': Iconsax.sms,
    'check_circle': Iconsax.tick_circle,
    'place_outlined': Iconsax.location,
    'business_outlined': Iconsax.briefcase,
    'book': Iconsax.book_1,
  'bookmark_border': Iconsax.bookmark_2,
    'admin_panel_settings': Iconsax.setting_2,
    'person_add': Iconsax.user_add,
    'file_download': Iconsax.import,
    'code': Iconsax.code,
  'table_chart': Iconsax.chart,
  'inbox_outlined': Iconsax.message_text,
    'monetization_on': Iconsax.money,
    'emoji_events': Iconsax.medal_star,
    'card_giftcard': Iconsax.gift,
  'train': Iconsax.bus,
    'directions_bus': Iconsax.bus,
    'show_chart': Iconsax.graph,
  'bar_chart': Iconsax.chart,
    'info_outline': Iconsax.info_circle,
    'photo_library': Iconsax.gallery,
  'touch_app': Iconsax.finger_cricle,
    'article': Iconsax.document_text,
    'group': Iconsax.people,
    'terms': Iconsax.document_text,
    'conditions': Iconsax.document_text,
    'privacy': Iconsax.security_user,
    'policy': Iconsax.security_card,
    'legal': Iconsax.courthouse,
    'agreement': Iconsax.document_text,
    'login': Iconsax.login,
    'login_outlined': Iconsax.login,
    'person_add_outlined': Iconsax.user_add,
    'arrow_forward_ios': Iconsax.arrow_right_3,
  };

  // Standard Icon Sizes
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 20.0;
  static const double largeIconSize = 24.0;
  static const double extraLargeIconSize = 32.0;
  static const double heroIconSize = 48.0;

  /// Get booking type icon with fallback
  static IconData getBookingTypeIcon(String type) {
    return bookingTypeIcons[type.toLowerCase()] ?? Icons.bookmark;
  }

  /// Get attraction category icon with fallback
  static IconData getAttractionCategoryIcon(String category) {
    return attractionCategoryIcons[category.toLowerCase()] ?? Icons.place;
  }

  /// Get service provider icon with fallback
  static IconData getServiceProviderIcon(String category) {
    return serviceProviderIcons[category.toLowerCase()] ?? Icons.business;
  }

  /// Get payment method icon with fallback
  static IconData getPaymentMethodIcon(String method) {
    return paymentMethodIcons[method.toLowerCase()] ?? Icons.payment;
  }

  /// Get social media icon with fallback
  static IconData getSocialMediaIcon(String platform) {
    return socialMediaIcons[platform.toLowerCase()] ?? Icons.public;
  }

  /// Get navigation icon with fallback
  static IconData getNavigationIcon(String type) {
    return navigationIcons[type.toLowerCase()] ?? Icons.home;
  }

  /// Get action icon with fallback
  static IconData getActionIcon(String action) {
    return actionIcons[action.toLowerCase()] ?? Icons.touch_app;
  }

  /// Get status icon with fallback
  static IconData getStatusIcon(String status) {
    return statusIcons[status.toLowerCase()] ?? Icons.help;
  }

  /// Get admin icon with fallback
  static IconData getAdminIcon(String type) {
    return adminIcons[type.toLowerCase()] ?? Icons.admin_panel_settings;
  }

  /// Get UI icon with fallback
  static IconData getUIIcon(String type) {
    return uiIcons[type.toLowerCase()] ?? Icons.help_outline;
  }

  /// Get standard icon size based on context
  static double getIconSize(String context) {
    switch (context.toLowerCase()) {
      case 'small':
      case 'chip':
      case 'badge':
        return smallIconSize;
      case 'medium':
      case 'button':
      case 'list':
        return mediumIconSize;
      case 'large':
      case 'card':
      case 'header':
        return largeIconSize;
      case 'extra_large':
      case 'dialog':
        return extraLargeIconSize;
      case 'hero':
      case 'splash':
        return heroIconSize;
      default:
        return mediumIconSize;
    }
  }
}