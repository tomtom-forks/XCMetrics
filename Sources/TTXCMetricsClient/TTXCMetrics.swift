import Foundation
import XCMetricsClient
import XCMetricsPlugins

public struct TTXCMetrics {
    public static func main() {
        let metrics = XCMetrics.parseOrExit()
        let configuration = XCMetricsConfiguration()
        configuration.add(plugin: ThermalThrottlingPlugin().create())
        configuration.add(plugin: LoadAveragePlugin().create())
        configuration.add(plugin: GitHubActionsPlugin().create())
        
        // The git directory is usually Xcode's `$SRCROOT` environment variable
        let gitDirectory: String? = ProcessInfo.processInfo.environment["SRCROOT"]
        if let gitDirectory {
            configuration.add(plugin: GitPlugin(gitDirectoryPath: gitDirectory).create())
        }
        
        metrics.run(with: configuration)
    }
}
