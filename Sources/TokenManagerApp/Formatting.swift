import Foundation
import TokenManagerCore

extension MoneyAmount {
    var displayString: String {
        "\(self.currency) \(NSDecimalNumber(decimal: self.amount).stringValue)"
    }
}
