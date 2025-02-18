import Foundation
import XCMetricsClient
import XCMetricsUtils

public struct GitHubActionsPlugin {
    
    private let shell: ShellOutFunction
    
    public init(shell: @escaping ShellOutFunction = shellGetStdout) {
        self.shell = shell
    }
    
    public func create() -> XCMetricsPlugin {
        return XCMetricsPlugin(name: "GitHub Actions Environment", body: { _ -> [String : String] in
            guard !getEnv("CI").isEmpty else { return [:] }
            
            var env = ProcessInfo.processInfo.environment
            
            // Convert keys to lowercase to preserve compatibility with old plugin versions
            for key in env.keys {
                env[key.lowercased()] = env.removeValue(forKey: key)
            }
            
            return env
        })
    }
    
    private func getEnv(_ key: String) -> String {
        return ProcessInfo.processInfo.environment[key] ?? ""
    }
}
