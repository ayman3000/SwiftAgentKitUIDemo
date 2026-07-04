import Foundation
import LLMProviderKit
import SwiftAgentKit

@MainActor
final class DemoAgentViewModel: ObservableObject {
    @Published var selectedProvider: DemoProvider = .ollama {
        didSet {
            applyProviderDefaults()
            rebuildAgent()
        }
    }

    @Published var selectedModelID = "" {
        didSet { rebuildAgent() }
    }

    @Published var customModelName = "" {
        didSet { rebuildAgent() }
    }

    @Published var toolsEnabled = true {
        didSet { rebuildAgent() }
    }

    @Published private var apiKeys: [DemoProvider: String] = [:]
    @Published var availableModels: [LLMModelInfo] = []
    @Published var modelStatus = "Loading Ollama models..."
    @Published var isRefreshingModels = false
    @Published var activeAgent: Agent
    @Published var activeAgentID = UUID()

    private let modelCatalog = LLMModelCatalog()

    init() {
        let provider = DemoProvider.ollama.makeProvider(apiKey: nil, defaultModel: nil)
        activeAgent = Self.makeAgent(provider: provider, model: nil, toolsEnabled: true)
        availableModels = DemoProvider.ollama.curatedModels
    }

    var currentAPIKey: String {
        apiKeys[selectedProvider, default: ""]
    }

    var selectedModel: String? {
        customModelName.nilIfBlank ?? selectedModelID.nilIfBlank
    }

    var effectiveModelDescription: String {
        selectedModel ?? "No model selected"
    }

    var selectedModelUsesTools: Bool? {
        guard let selectedModel else { return nil }
        let model = availableModels.first { $0.id == selectedModel }
        guard let model else { return nil }
        return model.capabilities.contains(.tools)
    }

    func setCurrentAPIKey(_ value: String) {
        apiKeys[selectedProvider] = value
        rebuildAgent()
    }

    func refreshModels() {
        Task { await refreshModelsFromSelectedProvider() }
    }

    func refreshModelsFromSelectedProvider() async {
        let providerKind = selectedProvider
        let apiKey = currentAPIKey.nilIfBlank
        let currentModel = selectedModel
        let curatedModels = providerKind.curatedModels

        if providerKind.requiresAPIKey && apiKey == nil && providerKind != .anthropic {
            await modelCatalog.register(curatedModels, for: providerKind.providerName)
            availableModels = sortedModels(await modelCatalog.models(for: providerKind.providerName))
            modelStatus = "Enter an API key to load live \(providerKind.displayName) models. Showing curated suggestions."
            if selectedModelID.isEmpty {
                selectedModelID = availableModels.first?.id ?? ""
            }
            return
        }

        isRefreshingModels = true
        modelStatus = "Loading \(providerKind.displayName) models..."
        defer { isRefreshingModels = false }

        do {
            let provider = providerKind.makeProvider(apiKey: apiKey, defaultModel: currentModel)
            try await modelCatalog.refresh(
                from: provider,
                curatedModels: curatedModels,
                strategy: .liveWithCuratedMetadata
            )
            let models = sortedModels(await modelCatalog.models(for: providerKind.providerName))

            guard selectedProvider == providerKind else { return }
            availableModels = models
            modelStatus = models.isEmpty ? "No models returned by \(providerKind.displayName)." : "\(models.count) model(s) available."

            if selectedModelID.isEmpty || !models.contains(where: { $0.id == selectedModelID }) {
                selectedModelID = models.first?.id ?? ""
            }
        } catch {
            guard selectedProvider == providerKind else { return }
            await modelCatalog.register(curatedModels, for: providerKind.providerName)
            availableModels = sortedModels(await modelCatalog.models(for: providerKind.providerName))
            modelStatus = "\(providerKind.displayName) model load failed: \(error.localizedDescription). Showing curated suggestions."
            if selectedModelID.isEmpty {
                selectedModelID = availableModels.first?.id ?? ""
            }
        }
    }

    private func applyProviderDefaults() {
        availableModels = sortedModels(selectedProvider.curatedModels)
        selectedModelID = availableModels.first?.id ?? ""
        customModelName = ""
        modelStatus = selectedProvider == .ollama
            ? "Refresh to load local Ollama models."
            : "Use curated suggestions or refresh live models."
        refreshModels()
    }

    private func rebuildAgent() {
        let model = selectedModel
        let apiKey = currentAPIKey.nilIfBlank
        let provider = selectedProvider.makeProvider(apiKey: apiKey, defaultModel: model)
        activeAgent = Self.makeAgent(provider: provider, model: model, toolsEnabled: toolsEnabled)
        activeAgentID = UUID()
    }

    private func sortedModels(_ models: [LLMModelInfo]) -> [LLMModelInfo] {
        models.sorted { lhs, rhs in
            if lhs.isDeprecated != rhs.isDeprecated { return !lhs.isDeprecated && rhs.isDeprecated }
            return (lhs.displayName ?? lhs.id).localizedCaseInsensitiveCompare(rhs.displayName ?? rhs.id) == .orderedAscending
        }
    }

    private static func makeAgent(provider: any LLMProvider, model: String?, toolsEnabled: Bool) -> Agent {
        Agent(config: AgentConfig(
            provider: provider,
            model: model,
            temperature: 0.2,
            systemPrompt: """
            You are the assistant inside SwiftAgentKitUIDemo. Be concise and direct. If tools are available and useful, call them instead of guessing.
            """,
            maxTurns: toolsEnabled ? 6 : 1,
            tools: toolsEnabled ? DemoTools.all : []
        ))
    }
}
