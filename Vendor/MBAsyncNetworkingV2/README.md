# MBAsyncNetworking

A modern, lightweight Swift networking library that leverages async/await for clean, concise network requests with built-in OAuth authentication support.

## Features

- ✅ Built with Swift's modern concurrency model (async/await)
- ✅ Automatic OAuth token handling and refresh
- ✅ Easy request configuration and response handling
- ✅ JSON parsing with Codable
- ✅ Multipart file uploads
- ✅ Session configuration and certificate pinning
- ✅ Request logging for debugging
- ✅ Comprehensive error handling
- ✅ Unit testing support with request stubbing

## Requirements

- iOS 13.0+ / macOS 11.0+ / watchOS 7.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add MBAsyncNetworking to your project through Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/mobven/MBAsyncNetworking.git", branch: "main")
]
```

## Usage

### Initialization

Before using MBAsyncNetworking, you need to initialize the `UserSession` with a storage implementation:

```swift
// Create a storage implementation that conforms to NetworkingStorable
struct MySecureStorage: NetworkingStorable {
    // Implement the required variables accessToken & refreshToken for your own codebase.
    var accessToken: String? {
        get {
            MyKeychainManager.shared.accessToken
        }
        set {
            MyKeychainManager.shared.accessToken = accessToken
        }
    }
    
    var refreshToken: String? {
        get {
            MyKeychainManager.shared.refreshToken
        }
        set {
            MyKeychainManager.shared.refreshToken = refreshToken
        }
    }
}

// Initialize the UserSession with your storage
UserSession.initialize(with: MySecureStorage())
```

### Basic GET Request

```swift
import MBAsyncNetworking

extension API {
    enum Login: AsyncNetworkable {
        /// Login with username and password with GET request.
        case loginGet(username: String, password: String)
        
        func request() async -> URLRequest {
            switch self {
            case let .loginGet(username, password)
                await getRequest(
                    url: URL(string: "https://api.example.com/data")!,
                    queryItems: ["username": username, "password": password],
                    httpMethod: .get
                )
            }
        }
    }
}

// Make the request
do {
    let response: MyResponseType = try await API.Login.loginGet(userName: "Mobven", password: "12345").fetch()
    // Handle the response
} catch {
    // Handle the error
}
```

### POST Request with JSON Body

```swift
import MBAsyncNetworking

extension API {
    enum Login: AsyncNetworkable {
        /// Login with username and password with POST request.
        case loginPost(username: String, password: String)
        
        func request() async -> URLRequest {
            switch self {
             case let .loginPost(username, password):
                await getRequest(
                    url: URL(string: "https://api.example.com/data")!,
                    queryItems: ["username": username, "password": password],
                    httpMethod: .post
                )
            }
        }
    }
}

// Make the request
do {
    let response: MyResponseType = try await API.Login.loginGet(userName: "Mobven", password: "12345").fetch()
    // Handle the response
} catch {
    // Handle the error
}
```

### File Uploads

```swift
import MBAsyncNetworking

extension API {
    enum File: AsyncNetworkable {
    /// Multipart file upload request.
    case uploadFiles(parameters: [String: String], files: [MBAsyncNetworking.File])
    
    func request() async -> URLRequest {  
        switch self {
        case let .uploadFiles(parameters, files):
            return await uploadRequest(
                method: .post,
                url: URL(string: "https://api.example.com/upload")!,
                parameters: ["description": "Profile photo"],
                files: [file]
            )
        }
    }
}

// Make the request
do {
    let response: UploadResponse = try await API.File.uploadFiles(parameters: [:], files: [imageData]).fetch()
    // Handle the response
} catch {
    // Handle the error
}
```

### OAuth Authentication

To handle OAuth authentication, implement `OAuthProviderDelegate`:

```swift
class AuthService: OAuthProviderDelegate {
    init() {
        OAuthManager.shared.authManager.setDelegate(self)
    }
    
    func didRequestTokenRefresh() async throws -> OAuthResponse? {
        // Implement your token refresh logic here
        // Make a request to refresh tokens and return a new OAuthResponse
        return OAuthResponse(
            accessToken: "new_access_token",
            refreshToken: "new_refresh_token",
            expiresIn: 3600
        )
    }
}
```

### Testing with StubURLProtocol

```swift
// Set up test stub
let testData = """
{
    "id": 1,
    "name": "Test User"
}
""".data(using: .utf8)!

StubURLProtocol.result = .success(testData)

// Make your request, which will now return the stubbed data
let response: User = try await UserEndpoint().fetch()
```

## Network Logs Delegation

MBAsyncNetworking now supports delegation of network logs to your application. This feature allows you to process or display network requests and responses in your app's UI.

### Usage Example

```swift
import MBAsyncNetworking

// Implement the NetworkLogsDelegate protocol in your class
class NetworkMonitor: NetworkLogsDelegate {
    func didReceiveResponse(request: URLRequest, data: Data?, log: String) {
        // Handle successful network response
        print("✅ Network Request Succeeded: \(request.url?.absoluteString ?? "")")
        
        // Process or display the data as needed
        // Example: Update UI with network activity
    }
    
    func didReceiveError(request: URLRequest, error: Error?, log: String) {
        // Handle network error
        print("❌ Network Request Failed: \(request.url?.absoluteString ?? "")")
        print("Error: \(error?.localizedDescription ?? "Unknown error")")
        
        // Process or display the error as needed
        // Example: Show error alert to user
    }
}

// Set up the delegate
class YourNetworkingSetup {
    let networkMonitor = NetworkMonitor()
    
    func setupNetworking() {        
        NetworkLogsManager.shared.delegate = networkMonitor
    }
}
```

### Important Notes

- Delegate methods are optional - implement only what you need
- Delegate is held as a weak reference to prevent memory leaks

## Architecture

MBAsyncNetworking is built around the `AsyncNetworkable` protocol, which all network endpoints implement. The library handles:

- Request creation and configuration
- Authentication token management
- Response parsing with Codable
- Error handling and recovery
- Logging and debugging

## License

MBAsyncNetworking is available under the MIT license. See the LICENSE file for more info.
