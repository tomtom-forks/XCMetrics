import Foundation
import XCMetricsClient
import XCMetricsUtils

public struct LoadAveragePlugin {

    private let shell: ShellOutFunction

    public init(shell: @escaping ShellOutFunction = shellGetStdout) {
        self.shell = shell
    }

    public func create() -> XCMetricsPlugin {
        return XCMetricsPlugin(name: "Load Average", body: { _ -> [String : String] in
            guard let uptimeStdout = try? shell("uptime", [], nil, nil) else { return [:] }

            let loadAverages = parse(uptimeStdout)

            if loadAverages.count == 3 {
                return [
                  "last_1_min_load_average": loadAverages[0],
                  "last_5_min_load_average": loadAverages[1],
                  "last_15_min_load_average": loadAverages[2],
                  ]
            } else {
                return [:]
            }
        })
    }

    /// Takes the uptime command's output and returns an array
    /// with the load averages in order: 1 min, 5 min, 15 min
    private func parse(_ uptimeStdout: String) -> [String] {
        let components = uptimeStdout.components(separatedBy: ",")

        guard let loadAverages = components.last else { return [] }

        let trimmedLoadAverages = loadAverages.replacingOccurrences(of: "load averages: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedLoadAverages.split(separator: " ").map { String($0) }
    }
}
