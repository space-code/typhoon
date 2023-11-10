![Typhoon: a service for retry policies](https://raw.githubusercontent.com/space-code/typhoon/dev/Resources/typhoon.png)

<h1 align="center" style="margin-top: 0px;">typhoon</h1>

<p align="center">
<a href="https://github.com/space-code/typhoon/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/space-code/typhoon?style=flat"></a> 
<a href="https://swiftpackageindex.com/space-code/typhoon"><img alt="Swift Compability" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fspace-code%2Ftyphoon%2Fbadge%3Ftype%3Dswift-versions"></a>
<a href="https://swiftpackageindex.com/space-code/typhoon"><img alt="Platform Compability" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fspace-code%2Ftyphoon%2Fbadge%3Ftype%3Dplatforms"/></a> 
<a href="https://github.com/space-code/typhoon"><img alt="CI" src="https://github.com/space-code/Typhoon/actions/workflows/ci.yml/badge.svg?branch=main"></a>
<a href="https://github.com/apple/swift-package-manager" alt="typhoon on Swift Package Manager" title="typhoon on Swift Package Manager"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" /></a>
</p>

## Description
`Typhoon` is a service for retry policies.

- [Usage](#usage)
- [Requirements](#requirements)
- [Installation](#installation)
- [Communication](#communication)
- [Contributing](#contributing)
- [Author](#author)
- [License](#license)

## Usage

`Typhoon` provides two retry policy strategies:

```swift
/// A retry strategy with a constant number of attempts and fixed duration between retries.
case constant(retry: Int, duration: DispatchTimeInterval)

/// A retry strategy with an exponential increase in duration between retries.
case exponential(retry: Int, multiplier: Double, duration: DispatchTimeInterval)
```

Create a `RetryPolicyService` instance and pass a desired strategy like this:

```swift
import Typhoon

let retryPolicyService = RetryPolicyService(strategy: .constant(retry: 10, duration: .seconds(1)))

do {
    _ = try await retryPolicyService.retry { 
        // Some logic here ...
     }
} catch {
    // Catch an error here ...
}
```

## Requirements

- iOS 15.0+ / macOS 12+ / tvOS 15.0+ / watchOS 8.0+ / visionOS 1.0+
- Xcode 14.0
- Swift 5.7

## Installation
### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but `typhoon` does support its use on supported platforms.

Once you have your Swift package set up, adding `typhoon` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/space-code/typhoon.git", .upToNextMajor(from: "1.0.0"))
]
```

## Communication
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Contributing
Bootstrapping development environment

```
make bootstrap
```

Please feel free to help out with this project! If you see something that could be made better or want a new feature, open up an issue or send a Pull Request!

## Author
Nikita Vasilev, nv3212@gmail.com

## License
typhoon is available under the MIT license. See the LICENSE file for more info.