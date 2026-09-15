import Foundation

/// Role: Data. ISO-8601 week key for one working-timetable document (daykey).
struct ISOWeekDate: Hashable, Sendable, Codable, Equatable, Comparable {
    var year: Int
    var week: Int

    var daykey: String {
        "\(padded(year, digits: 4))-W\(padded(week, digits: 2))"
    }

    private func padded(_ value: Int, digits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumIntegerDigits = digits
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func < (lhs: ISOWeekDate, rhs: ISOWeekDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        return lhs.week < rhs.week
    }

    static func iso8601Calendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        return calendar
    }

    static func of(_ date: Date, calendar: Calendar? = nil) -> ISOWeekDate {
        let iso = calendar ?? iso8601Calendar()
        let day = iso.startOfDay(for: date)
        return ISOWeekDate(
            year: iso.component(.yearForWeekOfYear, from: day),
            week: iso.component(.weekOfYear, from: day)
        )
    }

    static func current(on date: Date = Date()) -> ISOWeekDate {
        of(Calendar.current.startOfDay(for: date))
    }

    static func parse(daykey: String) -> ISOWeekDate? {
        let pieces = daykey.split(separator: "-")
        guard pieces.count == 2, pieces[1].first == "W" else { return nil }
        guard let year = Int(pieces[0]), let week = Int(pieces[1].dropFirst()) else { return nil }
        guard year > 0, (1 ... 53).contains(week) else { return nil }
        return ISOWeekDate(year: year, week: week)
    }
}
