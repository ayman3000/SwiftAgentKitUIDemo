import Foundation
import LLMProviderKit
import LLMProviderKitAnthropic
import LLMProviderKitGemini
import LLMProviderKitOllama
import LLMProviderKitOpenAI

enum DemoProvider: String, CaseIterable, Identifiable {
    case ollama
    case openAI
    case anthropic
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama: "Ollama"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama: false
        case .openAI, .anthropic, .gemini: true
        }
    }

    var providerName: String {
        switch self {
        case .ollama: OllamaProvider.name
        case .openAI: OpenAIProvider.name
        case .anthropic: AnthropicProvider.name
        case .gemini: GeminiProvider.name
        }
    }

    var baseURL: URL {
        switch self {
        case .ollama:
            URL(string: "http://localhost:11434")!
        case .openAI:
            URL(string: "https://api.openai.com/v1")!
        case .anthropic:
            URL(string: "https://api.anthropic.com/v1")!
        case .gemini:
            URL(string: "https://generativelanguage.googleapis.com/v1beta")!
        }
    }

    var suggestedModels: [LLMModelInfo] {
        switch self {
        case .ollama:
            []
        case .openAI:
            [
                LLMModelInfo(id: "gpt-5.4-mini", providerName: providerName, displayName: "GPT-5.4 mini", capabilities: [.chat, .streaming, .tools]),
                LLMModelInfo(id: "gpt-5.4", providerName: providerName, displayName: "GPT-5.4", capabilities: [.chat, .streaming, .tools]),
                LLMModelInfo(id: "gpt-5.5", providerName: providerName, displayName: "GPT-5.5", capabilities: [.chat, .streaming, .tools]),
            ]
        case .anthropic:
            AnthropicProvider.curatedModels
        case .gemini:
            [
                LLMModelInfo(id: "gemini-3.5-flash", providerName: providerName, displayName: "Gemini 3.5 Flash", capabilities: [.chat, .streaming, .tools]),
                LLMModelInfo(id: "gemini-3.1-flash-lite", providerName: providerName, displayName: "Gemini 3.1 Flash-Lite", capabilities: [.chat, .streaming, .tools]),
                LLMModelInfo(id: "gemini-3.1-pro", providerName: providerName, displayName: "Gemini 3.1 Pro", capabilities: [.chat, .streaming, .tools]),
            ]
        }
    }

    func makeProvider(apiKey: String?, defaultModel: String?) -> any LLMProvider {
        let configuration = LLMProviderConfiguration(
            name: providerName,
            baseURL: baseURL,
            apiKey: apiKey?.nilIfBlank,
            defaultModel: defaultModel?.nilIfBlank
        )

        switch self {
        case .ollama:
            return OllamaProvider(configuration: configuration)
        case .openAI:
            return OpenAIProvider(configuration: configuration)
        case .anthropic:
            return AnthropicProvider(configuration: configuration)
        case .gemini:
            return GeminiProvider(configuration: configuration)
        }
    }
}
