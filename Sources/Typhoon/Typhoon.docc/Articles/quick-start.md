# Quick Start

Get up and running with Typhoon in minutes.

## Overview

Typhoon is a powerful retry policy framework for Swift that helps you handle transient failures gracefully. This guide will help you integrate Typhoon into your project and start using retry policies immediately.

## Basic Usage

### Your First Retry

Import Typhoon and create a retry service with a simple constant strategy:

```swift
import Typhoon

let retryService = RetryPolicyService(
    strategy: .constant(retry: 3, duration: .seconds(1))
)

do {
    let result = try await retryService.retry {
        try await fetchDataFromAPI()
    }
    print("Success: \(result)")
} catch {
    print("Failed after 3 retries: \(error)")
}
```

This will:
- Try your operation immediately
- If it fails, wait 1 second and retry
- Repeat up to 3 times

### Network Request Example

Here's a practical example with URLSession:

```swift
import Foundation
import Typhoon

func fetchUser(id: String) async throws -> User {
    let retryService = RetryPolicyService(
        strategy: .exponential(retry: 3, duration: .milliseconds(500))
    )
    
    return try await retryService.retry {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
}
```

## Choosing a Strategy

Typhoon provides three retry strategies:

### Constant Strategy

Best for predictable, fixed delays:

```swift
// Retry 5 times with 2 seconds between attempts
.constant(retry: 5, duration: .seconds(2))
```

**Timeline:** 0s (initial) → 2s → 2s → 2s → 2s → 2s

### Exponential Strategy

Ideal for backing off from failing services:

```swift
// Retry 4 times with exponentially increasing delays
.exponential(retry: 4, multiplier: 2.0, duration: .seconds(1))
```

**Timeline:** 0s (initial) → 1s → 2s → 4s → 8s

### Exponential with Jitter

Best for preventing thundering herd problems:

```swift
// Retry with exponential backoff, jitter, and cap
.exponential(
    retry: 5,
    jitterFactor: 0.2,
    maxInterval: .seconds(30),
    multiplier: 2.0,
    duration: .seconds(1)
)
```

**Timeline:** 0s (initial) → ~1s → ~2s → ~4s → ~8s → ~16s (with randomization)

## Common Patterns

### Wrapping in a Service Class

Create a reusable service with built-in retry logic:

```swift
import Typhoon

class APIClient {
    private let retryService = RetryPolicyService(
        strategy: .exponential(retry: 3, duration: .milliseconds(500))
    )
    
    func get<T: Decodable>(endpoint: String) async throws -> T {
        try await retryService.retry {
            let url = URL(string: "https://api.example.com/\(endpoint)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }
}

// Usage
let client = APIClient()
let user: User = try await client.get(endpoint: "users/123")
```

### Error Handling

Handle specific errors after all retries are exhausted:

```swift
do {
    let data = try await retryService.retry {
        try await performOperation()
    }
    // Handle success
} catch NetworkError.serverUnavailable {
    print("Server is down")
} catch NetworkError.timeout {
    print("Request timed out")
} catch {
    print("Unexpected error: \(error)")
}
```

### Configuration for Different Scenarios

```swift
// Quick operations (file I/O, cache access)
let quickRetry = RetryPolicyService(
    strategy: .constant(retry: 3, duration: .milliseconds(100))
)

// Network requests
let networkRetry = RetryPolicyService(
    strategy: .exponential(retry: 4, multiplier: 1.5, duration: .seconds(1))
)

// Critical operations (payments, data persistence)
let criticalRetry = RetryPolicyService(
    strategy: .exponential(
        retry: 5,
        jitterFactor: 0.15,
        maxInterval: .seconds(60),
        multiplier: 2.0,
        duration: .seconds(2)
    )
)
```

## Next Steps

Now that you have the basics, explore:

- <doc:advanced-retry-strategies> - Deep dive into retry strategies
- <doc:best-practices> - Learn best practices and patterns

## See Also

- ``RetryPolicyService``
- ``RetryPolicyStrategy``
