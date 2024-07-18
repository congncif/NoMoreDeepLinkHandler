# NoMoreDeepLinkHandler - Deep Link Handler

**NoMoreDeepLinkHandler** SDK enables the app to manage URL Handlers which handle the URLs to open the app. This URL might be a *schemed URL* or a *Universal link*. The `DeepLinkHandler` in **NoMoreDeepLinkHandler** SDK is designed with the **plugin mechanism** to enable scalability.

When **NoMoreDeepLinkHandler** handles a deep link, it will scan through all installed handlers, and forward that deep link to the appropriate handler. This process happens **sequentially** until the **first matching handler** is found. Otherwise, `notFoundHandler` will be called.

Each handler conforms to the protocol `DeepLinkHandlerPlugin`.

```swift
public protocol DeepLinkHandlerPlugin {
    var completionTimeout: TimeInterval { get }

    func shouldHandleDeepLink(_ url: URL) -> DeepLinkHandlerOption

    func handleDeepLink(with data: Data?, completion: @escaping () -> Void)
}
```

* A handler has a certain amount of time to process the deep link if it is selected before `completionTimeout`.
* The method `shouldHandleDeepLink` decides if this plugin will handle the deep link or not? There are 3 options of `DeepLinkHandlerOption`.

	- **no**: the plugin declines to handle the deep link. This will be ignored when processing the deep link.
	- **yes**(data: **Data**?): the plugin accepts to handle the deep link, the data should be encoded from the parameters of the deep link.
	- **yesWithBarrier**(name: **String**, data: **Data**?): the plugin accepts to handle the deep link but it has to pass a **Barrier** which is also installed into DeepLinkHandler with name. This is useful with the deep link needed to authenticate by a logged-in user.

* The method `handleDeepLink` will be called when the plugin confirmed handling the deep link. `data` is the parameters parsed from the deep link and it should be passed from `shouldHandleDeepLink ` method. Normally a plugin opens a context corresponding to the deep link. Finally calls `completion` once done.

## Installation

**NoMoreDeepLinkHandler** includes in **MobileNext** standard library and is available in private pod specs.

```ruby
# Install NoMoreDeepLinkHandler directly
pod "NoMoreDeepLinkHandler", "~> 1.0"
```

## Register a handler plugin

To register to handle a deep link `app://localhost/pay?order_id=123`, create a `DeepLinkHandlerPlugin`.

```swift
final class PaymentDeepLinkHandlerPlugin: DeepLinkHandlerPlugin {
    func shouldHandleDeepLink(_ url: URL) -> DeepLinkHandlerOption {
        switch url.path {
        case "pay":
            let data = url.deepLinkExtensions.queryData
            return .yes(data: data)
        default:
            return .no
        }
    }

    func handleDeepLink(with data: Data?, completion: @escaping () -> Void) {
        present(paymentConfirmScreen, with: data, completion: completion)
    }
}
```

##  Initialize SDK

**NoMoreDeepLinkHandler** must be initialized before use. This should occur at the app launch.

```swift
DeepLinkHandler.configure()
    .install(plugin: PaymentDeepLinkHandlerPlugin())
    .initialize()
```

## Handle open a deep link

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return DeepLinkHandler.shared.handle(deepLink: url)
}
```

## Set up a barrier

Many deep links require a logged-in user. So we need to set up an `AuthenticationDeepLinkBarrier` for this.

```swift
final class AuthenticationDeepLinkBarrier: DeepLinkHandlingBarrier {
    func status(for deepLink: URL) -> DeepLinkBarrierStatus {
        AccessToken.isValid ? .passed : .needToCheck
    }

    func performCheck(deepLink _: URL, completion: @escaping (Bool) -> Void) {
        // Navigate to Login screen
        present(loginScreen, callbackHandler: { data in
            completion(data != nil)
        })
    }
}
```

### Install barrier to DeepLinkHandler

```swift
DeepLinkHandler.configure()
      .install(plugin: PaymentDeepLinkHandlerPlugin())
      .install(barrier: AuthenticationDeepLinkBarrier())
      .initialize()
```

### Configure handler plugin

*For example, configure the above Payment handler with the barrier.*

```swift
final class PaymentDeepLinkHandlerPlugin: DeepLinkHandlerPlugin {
    func shouldHandleDeepLink(_ url: URL) -> DeepLinkHandlerOption {
        switch url.path {
        case "pay":
            let data = url.deepLinkExtensions.queryData
            return .yesWithBarrier(AuthenticationDeepLinkBarrier.self, data: data)
        default:
            return .no
        }
    }

    func handleDeepLink(with data: Data?, completion: @escaping () -> Void) {
        present(paymentConfirmScreen, with: data, completion: completion)
    }
}
```

### Open the payment deep link with barrier workflow

*Open pay URL* ⏩  *Check the barrier passed*  ⏩  *Open Payment screen*

## Deep link classification

Sometime, you need to **handle a group deep links** in a single plugin or you need to **pre-process to classify** query data gotten from URL. By that way, `DeepLinkHandlerPlugin` defines an associated parameters type, then you can switch by that parameters when `handleDeepLink`. So instead of conforming `DeepLinkHandlerPlugin`, you conform `DeepLinkHandlerCodingPlugin`.

For example, you need to handle two below deep links of **Payment**:

- `app://localhost/pay?order_id=123`
- `app://localhost/transaction/789`, `with 789 is transaction_id`

```swift
enum PaymentDeepLinkPoint: Codable {
    case makePayment(data: Data?)
    case transaction(id: String?)

    init?(url: URL) {
        let paths = url.deepLinkExtensions.pathComponents
        var iterator = paths.makeIterator()
        switch (iterator.next(), iterator.next()) {
        case ("pay", nil):
            self = .makePayment(data: url.deepLinkExtensions.queryData)
        case ("transaction", let transactionID?):
            self = .transaction(id: transactionID)
        default:
            return nil
        }
    }
}

final class PaymentDeepLinkHandlerPlugin: DeepLinkHandlerCodingPlugin {
    func shouldHandleCodingDeepLink(_ url: URL) -> DeepLinkHandlerCodingOption<PaymentDeepLinkPoint> {
        guard let point = PaymentDeepLinkPoint(url: url) else {
            return .no
        }
        return .yesWithBarrier(AuthenticationDeepLinkBarrier.self, parameters: point)
    }

    func handleCodingDeepLink(with parameters: PaymentDeepLinkPoint, completion: @escaping () -> Void) {
        switch parameters {
        case let .makePayment(data):
            present(paymentConfirmScreen, with: data, completion: completion)
        case let .transaction(id):
            present(transactionDetailScreen, with data: id?.data(using: .utf8), completion: completion)
        }
    }
}
```

## Deep link path matching

Define a `DeepLinkHandlerPlugin` with a dynamic path which has parameters value in the URL path.

*Read more about* [Path Parameters](https://www.abstractapi.com/api-glossary/path-parameters)

👉 Conforms the protocol `DeepLinkHandlerPathMatchingPlugin` instead of `DeepLinkHandlerPlugin`.

For example, you need to handle the below deep link of **Transaction**:

- `app://localhost/transaction/789`

```swift
final class TransactionDeepLinkPlugin: DeepLinkHandlerPathMatchingPlugin {
    var matchingPath: String {
        // Return path parameters pattern here
        "/transaction/{transaction_id}"
    }

    func handleDeepLink(with data: Data?, completion: @escaping () -> Void) {
        // The data is the encoded value of ["transaction_id": "789"]
        present(transactionDetailScreen, completion: completion)
    }
}
```

## DeepLinkHandler more settings

* **notFoundHandler**: Handle when no appropriate handlers are registered to handle the deep link.

```swift
DeepLinkHandler.configure()
    .withNotFoundHandler({ url in
        // Open not found screen
    })
    .install(plugin: PaymentDeepLinkHandlerPlugin())
    .initialize()
```

* **excludedSchemes** & **excludedHosts**: Filter the schemes and hosts which will be not handled by **NoMoreDeepLinkHandler**

* **blacklistSchemes** & **blacklistHosts** & **whitelistHosts** & **whitelistSchemes**: Filter before handing the deep link, only the hosts or schemes in the whitelist will be handled if this field is set. Otherwise the `forbiddenHandler` will be called. The priority is `blacklist` >> `whitelist`.

```swift
DeepLinkHandler.configure()
    .set(blacklistHosts: ["localhost"])
    .set(whitelistSchemes: ["first-scheme", "second-sechme"])
    .set(whitelistHosts: ["sample-domain.vn"])
    .with(forbiddenHandler: { url in
        print("The deep link is forbidden: \(url)")
    })
    ...
    .initialize()
```

* **mandatoryBarrier**: The barrier that requires all of deep links must pass before they are handled. 

> This might be useful for apps that require the user have to login to use every other features.

```swift
DeepLinkHandler.configure()
    .set(mandatoryBarrier: AuthenticationDeepLinkBarrier())
    ...
    .initialize()
```
