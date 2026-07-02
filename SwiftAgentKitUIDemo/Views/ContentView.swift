import SwiftAgentKitUI
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DemoAgentViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationBar(viewModel: viewModel)

            Divider()

            HSplitView {
                AgentChatView(
                    agent: viewModel.activeAgent,
                    configuration: AgentChatConfiguration(
                        showToolCalls: true,
                        showStreamingPreview: true,
                        useStreaming: false,
                        toolCallTimelineHeight: 130,
                        inputPlaceholder: "Message \(viewModel.effectiveModelDescription)..."
                    )
                )
                .id(viewModel.activeAgentID)
                .frame(minWidth: 520, minHeight: 420)
                .layoutPriority(2)

                AgentEventView(agent: viewModel.activeAgent)
                    .id(viewModel.activeAgentID)
                    .frame(minWidth: 440, idealWidth: 500)
                    .layoutPriority(1)
            }
        }
        .frame(minWidth: 1080, minHeight: 620)
        .task {
            await viewModel.refreshModelsFromSelectedProvider()
        }
    }
}
