class ApiConstants {
  // Base URL - Change this to your computer's IP address for physical device testing
  // For Android Emulator use: http://10.0.2.2:8888
  // For physical device use: http://YOUR_IP:8888 (e.g., http://192.168.1.100:8888)
  static const String baseUrl = 'http://10.0.2.2:5000';
  
  // API Endpoints
  
  // Auth endpoints
  static const String login = '/api/v1/auth/login';
  static const String validateToken = '/api/v1/auth/validate-token';
  static const String getProfile = '/api/v1/auth/me';
  static const String updateProfile = '/api/v1/auth/token/update-profile';
  
  // Public Product endpoints (no auth required)
  static const String publicProducts = '/api/v1/public/products/all';
  static String publicProductById(int id) => '/api/v1/public/products/$id';
  static String relatedProducts(int id) => '/api/v1/public/products/$id/related';
  
  // Cart endpoints (auth required)
  static const String cart = '/api/v1/cart';
  static const String cartItems = '/api/v1/cart/items';
  static String cartItem(int itemId) => '/api/v1/cart/items/$itemId';
  
  // Order endpoints (auth required)
  static const String orders = '/api/v1/orders';
  static const String myOrders = '/api/v1/orders/my-orders';
  static String orderById(int id) => '/api/v1/orders/$id';
  
  // Banner endpoints (public)
  static const String publicBanners = '/api/v1/public/banners';
  
  // Category endpoints (public)
  static const String publicCategories = '/api/v1/public/categories';
  
  // Brand endpoints (public)
  static const String publicBrands = '/api/v1/public/brands';
  
  // Headers
  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  
  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
}
