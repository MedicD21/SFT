import Foundation

extension Date {
    var dayKey: Date {
        Calendar.current.startOfDay(for: self)
    }
}

