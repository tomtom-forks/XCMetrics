import Foundation
import XCMetricsClient
import XCMetricsUtils

public struct GitHubActionsPlugin {
    
    private let shell: ShellOutFunction
    
    public init(shell: @escaping ShellOutFunction = shellGetStdout) {
        self.shell = shell
    }
    
    public func create() -> XCMetricsPlugin {
        return XCMetricsPlugin(name: "Load Average", body: { _ -> [String : String] in
            guard !getEnv("CI").isEmpty else { return [:] }
            
            return [
                "github_job": getEnv("GITHUB_JOB"),
                "github_repository": getEnv("GITHUB_REPOSITORY"),
                "github_run_attempt": getEnv("GITHUB_RUN_ATTEMPT"),
                "github_run_id": getEnv("GITHUB_RUN_ID"),
                "github_workflow": getEnv("GITHUB_WORKFLOW"),
                "github_is_nightly": getEnv("is_nightly"),
            ]
        })
    }
    
    private func getEnv(_ key: String) -> String {
        return ProcessInfo.processInfo.environment[key] ?? ""
    }
}
