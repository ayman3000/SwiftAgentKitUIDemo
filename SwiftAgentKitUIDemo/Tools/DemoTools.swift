import Foundation
import SwiftAgentKit

enum DemoTools {
    static var all: [any AgentTool] {
        [
            CurrentDateTimeTool(),
            DemoAppInfoTool()
        ]
    }
}

struct CurrentDateTimeTool: AgentTool {
    let name = "current_datetime"
    let description = "Returns the current local date and time for the user's machine."
    let parameters = ToolParameters.empty

    func execute(parameters: [String: Any]) async throws -> AgentToolResult {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .long

        let result = """
        Local date and time: \(formatter.string(from: Date()))
        Time zone: \(TimeZone.current.identifier)
        """

        return .success(toolCallId: "", toolName: name, result: result)
    }
}

struct DemoAppInfoTool: AgentTool {
    let name = "demo_app_info"
    let description = "Returns information about this SwiftAgentKitUI demo app and its enabled capabilities."
    let parameters = ToolParameters.empty

    func execute(parameters: [String: Any]) async throws -> AgentToolResult {
        let result = """
        SwiftAgentKitUIDemo is a macOS SwiftUI demo app that embeds AgentChatView as the primary chat surface and AgentEventView as the event timeline. It supports Ollama by default plus OpenAI, Anthropic, and Gemini when API keys are configured.
        """

        return .success(toolCallId: "", toolName: name, result: result)
    }
}
