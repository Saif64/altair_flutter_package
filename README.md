# Altair

A powerful Flutter network client built on top of Dio with built-in authentication, caching, and stale-while-revalidate support.

## Features

- 🔐 **Built-in Authentication** - Automatic token refresh and request retry
- 📦 **Built-in Caching** - Cache responses with configurable TTL
- 🔄 **Stale-While-Revalidate** - Use stale cached data while fetching fresh data in the background
- 🛠️ **Easy Configuration** - Simple setup with sensible defaults
- 📱 **Flutter-friendly** - Designed for Flutter applications
- 🔌 **Extensible** - Access the underlying Dio instance for advanced usage

## Installation

```yaml
dependencies:
  altair: ^0.1.0
```

## Quick Start

```dart
import 'package:altair/altair.dart';

// Create a client with configuration
final client = Altair(
  config: AltairConfig(
    baseUrl: 'https://api.example.com',
    refreshTokenPath: '/auth/refresh',
    accessTokenPath: '/auth/login',
  ),
);

// Login
final loginResponse = await client.login(
  username: 'user@example.com',
  password: 'password123',
);

// Make API requests
final usersResponse = await client.get('/api/users');
```

## Configuration

```dart
final client = Altair(
  config: AltairConfig(
    // Required
    baseUrl: 'https://api.example.com',
    
    // Authentication (optional, defaults shown)
    refreshTokenPath: '/auth/refresh',
    accessTokenPath: '/auth/token',
    autoAuthenticate: true,
    
    // Caching (optional, defaults shown)
    enableCache: true,
    cacheTtl: 300, // 5 minutes
    useStaleWhileRevalidate: true,
    
    // Timeouts (optional, defaults shown)
    connectTimeout: 30000, // 30 seconds
    receiveTimeout: 30000, // 30 seconds
    sendTimeout: 30000, // 30 seconds
    
    // Headers & Query Params (optional)
    defaultHeaders: {'Accept': 'application/json'},
    defaultQueryParams: {'version': '1.0'},
    
    // Custom Dio Options (optional)
    dioOptions: BaseOptions(
      // Custom Dio options
    ),
  ),
);
```

## Authentication

### Login

```dart
final response = await client.login(
  username: 'user@example.com',
  password: 'password123',
);

if (response.success) {
  print('Login successful: ${response.data?.accessToken}');
} else {
  print('Login failed: ${response.message}');
}
```

### Logout

```dart
await client.logout();
```

### Check Authentication Status

```dart
final isAuthenticated = await client.isAuthenticated();
```

### Get Current Tokens

```dart
final tokens = await client.getTokens();
```

### Refresh Token Manually

```dart
final response = await client.refreshToken();
```

## Making Requests

### GET Request

```dart
final response = await client.get<Map<String, dynamic>>(
  '/api/users',
  queryParameters: {'page': 1},
);

if (response.success) {
  print('From cache: ${response.fromCache}');
  print('Data: ${response.data}');
} else {
  print('Error: ${response.message}');
}
```

### POST Request

```dart
final response = await client.post<Map<String, dynamic>>(
  '/api/users',
  data: {
    'name': 'John Doe',
    'email': 'john@example.com',
  },
);
```

### Other Request Methods

```dart
// PUT
final putResponse = await client.put('/api/users/1', data: {...});

// PATCH
final patchResponse = await client.patch('/api/users/1', data: {...});

// DELETE
final deleteResponse = await client.delete('/api/users/1');
```

### Using Type Converters

```dart
final response = await client.get<User>(
  '/api/users/1',
  converter: (data) => User.fromJson(data),
);
```

## Caching

### Clear Cache

```dart
await client.clearCache();
```

### Disable Cache for Specific Requests

```dart
final response = await client.get(
  '/api/users',
  options: Options(extra: {'no-cache': true}),
);
```

## Advanced Usage

### Access Dio Instance

```dart
final dio = client.dio;

// Now you can use the dio instance directly
dio.interceptors.add(LogInterceptor());
```

### Custom Token Storage

```dart
// Implement your own token storage
class MyTokenStorage implements TokenStorage {
  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    // Custom implementation
  }

  @override
  Future<AuthTokens?> getTokens() async {
    // Custom implementation
  }

  @override
  Future<void> clearTokens() async {
    // Custom implementation
  }
}

// Use your custom token storage
final client = Altair(
  config: AltairConfig(...),
  tokenStorage: MyTokenStorage(),
);
```

## License

MIT License