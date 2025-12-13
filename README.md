![A powerful retry policy service for Swift](./Resources/typhoon.png)

<h1 align="center" style="margin-top: 0px;">typhoon</h1>

<p align="center">
<a href="https://github.com/space-code/typhoon/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/space-code/typhoon?style=flat"></a> 
<a href="https://swiftpackageindex.com/space-code/typhoon"><img alt="Swift Compatibility" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fspace-code%2Ftyphoon%2Fbadge%3Ftype%3Dswift-versions"></a>
<a href="https://swiftpackageindex.com/space-code/typhoon"><img alt="Platform Compatibility" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fspace-code%2Ftyphoon%2Fbadge%3Ftype%3Dplatforms"/></a> 
<a href="https://github.com/space-code/typhoon/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/space-code/Typhoon/actions/workflows/ci.yml/badge.svg?branch=main"></a>
<a href="https://github.com/apple/swift-package-manager" alt="typhoon on Swift Package Manager" title="typhoon on Swift Package Manager"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" /></a>
<a href="https://codecov.io/gh/space-code/typhoon"><img src="https://codecov.io/gh/space-code/typhoon/graph/badge.svg?token=u89doKdnec"/></a>
</p>

## Description
Typhoon is a modern, lightweight Swift framework that provides elegant and robust retry policies for asynchronous operations. Built with Swift's async/await concurrency model, it helps you handle transient failures gracefully with configurable retry strategies.

## Features

✨ **Multiple Retry Strategies** - Constant, exponential, and exponential with jitter  
⚡ **Async/Await Native** - Built for modern Swift concurrency  
🎯 **Type-Safe** - Leverages Swift's type system for compile-time safety  
🔧 **Configurable** - Flexible retry parameters for any use case  
📱 **Cross-Platform** - Works on iOS, macOS, tvOS, watchOS, and visionOS  
⚡ **Lightweight** - Minimal footprint with zero dependencies  
🧪 **Well Tested** - Comprehensive test coverage

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Retry Strategies](#retry-strategies)
  - [Constant Strategy](#constant-strategy)
  - [Exponential Strategy](#exponential-strategy)
  - [Exponential with Jitter Strategy](#exponential-with-jitter-strategy)
- [Common Use Cases](#common-use-cases)
- [Communication](#communication)
- [Documentation](#documentation)
- [Contributing](#contributing)
  - [Development Setup](#development-setup)
- [Author](#author)
- [License](#license)

## Requirements

| Platform  | Minimum Version |
|-----------|----------------|
| iOS       | 13.0+          |
| macOS     | 10.15+         |
| tvOS      | 13.0+          |
| watchOS   | 6.0+           |
| visionOS  | 1.0+           |
| Xcode     | 15.3+          |
| Swift     | 5.10+          |

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/space-code/typhoon.git", from: "1.3.0")
]
```

Or add it through Xcode:

1. File > Add Package Dependencies
2. Enter package URL: `https://github.com/space-code/typhoon.git`
3. Select version requirements

## Quick Start

```swift
import Typhoon

let retryService = RetryPolicyService(
    strategy: .constant(retry: 3, duration: .seconds(1))
)

do {
    let result = try await retryService.retry {
        try await fetchDataFromAPI()
    }
    print("✅ Success: \(result)")
} catch {
    print("❌ Failed after retries: \(error)")
}
```

## Usage

### Retry Strategies

Typhoon provides three powerful retry strategies to handle different failure scenarios:

```swift
/// A retry strategy with a constant number of attempts and fixed duration between retries.
case constant(retry: Int, duration: DispatchTimeInterval)

/// A retry strategy with an exponential increase in duration between retries.
case exponential(retry: Int, multiplier: Double = 2.0, duration: DispatchTimeInterval)

/// A retry strategy with exponential increase in duration between retries and added jitter.
case exponentialWithJitter(
    retry: Int, 
    jitterFactor: Double = 0.1, 
    maxInterval: DispatchTimeInterval? = .seconds(60), 
    multiplier: Double = 2.0, 
    duration: DispatchTimeInterval
)
```

### Constant Strategy

Best for scenarios where you want predictable, fixed delays between retries:

```swift
import Typhoon

// Retry up to 5 times with 2 seconds between each attempt
let service = RetryPolicyService(
    strategy: .constant(retry: 5, duration: .seconds(2))
)

do {
    let data = try await service.retry {
        try await URLSession.shared.data(from: url)
    }
} catch {
    print("Failed after 5 attempts")
}
```

**Retry Timeline:**
- Attempt 1: Immediate
- Attempt 2: After 2 seconds
- Attempt 3: After 2 seconds
- Attempt 4: After 2 seconds
- Attempt 5: After 2 seconds

### Exponential Strategy

Ideal for avoiding overwhelming a failing service by progressively increasing wait times:

```swift
import Typhoon

// Retry up to 4 times with exponentially increasing delays
let service = RetryPolicyService(
    strategy: .exponential(
        retry: 4,
        multiplier: 2.0,
        duration: .seconds(1)
    )
)

do {
    let response = try await service.retry {
        try await performNetworkRequest()
    }
} catch {
    print("Request failed after exponential backoff")
}
```

**Retry Timeline:**
- Attempt 1: Immediate
- Attempt 2: After 1 second (1 × 2⁰)
- Attempt 3: After 2 seconds (1 × 2¹)
- Attempt 4: After 4 seconds (1 × 2²)

### Exponential with Jitter Strategy

The most sophisticated strategy, adding randomization to prevent thundering herd problems:

```swift
import Typhoon

// Retry with exponential backoff, jitter, and maximum interval cap
let service = RetryPolicyService(
    strategy: .exponentialWithJitter(
        retry: 5,
        jitterFactor: 0.2,      // Add ±20% randomization
        maxInterval: .seconds(30),         // Cap at 30 seconds
        multiplier: 2.0,
        duration: .seconds(1)
    )
)

do {
    let result = try await service.retry {
        try await connectToDatabase()
    }
} catch {
    print("Connection failed after sophisticated retry attempts")
}
```

**Benefits of Jitter:**
- Prevents multiple clients from retrying simultaneously
- Reduces load spikes on recovering services
- Improves overall system resilience

## Common Use Cases

### Network Requests

```swift
import Typhoon

class APIClient {
    private let retryService = RetryPolicyService(
        strategy: .exponential(retry: 3, duration: .milliseconds(500))
    )
    
    func fetchUser(id: String) async throws -> User {
        try await retryService.retry {
            let (data, _) = try await URLSession.shared.data(
                from: URL(string: "https://api.example.com/users/\(id)")!
            )
            return try JSONDecoder().decode(User.self, from: data)
        }
    }
}
```

### Database Operations

```swift
import Typhoon

class DatabaseManager {
    private let retryService = RetryPolicyService(
        strategy: .exponentialWithJitter(
            retry: 5,
            jitterFactor: 0.15,
            maxInterval: .seconds(60),
            duration: .seconds(1)
        )
    )
    
    func saveRecord(_ record: Record) async throws {
        try await retryService.retry {
            try await database.insert(record)
        }
    }
}
```

### File Operations

```swift
import Typhoon

class FileService {
    private let retryService = RetryPolicyService(
        strategy: .constant(retry: 3, duration: .milliseconds(100))
    )
    
    func writeFile(data: Data, to path: String) async throws {
        try await retryService.retry {
            try data.write(to: URL(fileURLWithPath: path))
        }
    }
}
```

### Third-Party Service Integration

```swift
import Typhoon

class PaymentService {
    private let retryService = RetryPolicyService(
        strategy: .exponential(
            retry: 4,
            multiplier: 1.5,
            duration: .seconds(2)
        )
    )
    
    func processPayment(amount: Decimal) async throws -> PaymentResult {
        try await retryService.retry {
            try await paymentGateway.charge(amount: amount)
        }
    }
}
```

## Communication

- 🐛 **Found a bug?** [Open an issue](https://github.com/space-code/typhoon/issues/new)
- 💡 **Have a feature request?** [Open an issue](https://github.com/space-code/typhoon/issues/new)
- ❓ **Questions?** [Start a discussion](https://github.com/space-code/typhoon/discussions)
- 🔒 **Security issue?** Email nv3212@gmail.com

## Documentation

Comprehensive documentation is available: [Typhoon Documentation](https://space-code.github.io/typhoon/typhoon/documentation/typhoon/)

## Contributing

We love contributions! Please feel free to help out with this project. If you see something that could be made better or want a new feature, open up an issue or send a Pull Request.

### Development Setup

Bootstrap the development environment:

```bash
make bootstrap
```

## Author

**Nikita Vasilev**
- Email: nv3212@gmail.com
- GitHub: [@ns-vasilev](https://github.com/ns-vasilev)

## License

Typhoon is released under the MIT license. See [LICENSE](https://github.com/space-code/typhoon/blob/main/LICENSE) for details.

---

<div align="center">

**[⬆ back to top](#typhoon)**

Made with ❤️ by [space-code](https://github.com/space-code)

</div>