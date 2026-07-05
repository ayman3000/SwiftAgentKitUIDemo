# SwiftAgentKitUIDemo

Build a real macOS AI chat client in SwiftUI without rebuilding the agent stack from scratch.

`SwiftAgentKitUIDemo` is a standalone Xcode macOS app that shows how to combine [SwiftAgentKitUI](https://github.com/ayman3000/SwiftAgentKitUI.git), [SwiftAgentKit](https://github.com/ayman3000/SwiftAgentKit.git), and [LLMProviderKit](https://github.com/ayman3000/LLMProviderKit.git) into a practical desktop client. The app opens directly into the chat experience, supports local Ollama by default, includes provider/model controls, and shows the live agent event timeline beside the conversation.

This repository is intentionally small. It does not vendor the packages it demonstrates; it uses normal Xcode Swift Package references to the GitHub repositories.

> If this demo helped you understand the Swift AI stack, a ⭐ on the related packages is appreciated.

## What You Get

- A real `.xcodeproj` macOS app target named `SwiftAgentKitUIDemo`
- A first-screen chat UI powered by `AgentChatView`
- A secondary event/debug timeline powered by `AgentEventView`
- Provider selection for Ollama, OpenAI, Anthropic, and Gemini
- Model picker plus custom model override
- API key field for cloud providers
- Tool-calling toggle with safe demo tools
- Ollama model discovery from the local Ollama server
- Clear provider errors surfaced in the chat UI and timeline
- Terminal and Xcode build/run workflows

## Why These Packages Helped

### SwiftAgentKitUI

`SwiftAgentKitUI` is the reason this demo can be a thin client instead of a full UI framework. It provides production-shaped SwiftUI components for the hard parts of an agent chat surface:

- `AgentChatView` handles transcript rendering, user input, assistant responses, streaming preview support, cancellation, and tool-call timeline display.
- `AgentEventView` renders the agent lifecycle event stream, which is essential when debugging providers, model calls, tool calls, retries, and completion state.

In this demo, the main app screen is mostly composition:

```swift
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

    AgentEventView(agent: viewModel.activeAgent)
}
```

That is a useful boundary: the demo owns app-specific configuration, while `SwiftAgentKitUI` owns the chat and event presentation.

### SwiftAgentKit

`SwiftAgentKit` gives the app a clean agent runtime. The selected provider, selected model, system prompt, turn count, and tools are all expressed through `AgentConfig`.

```swift
let agent = Agent(config: AgentConfig(
    provider: provider,
    model: selectedModel,
    temperature: 0.2,
    systemPrompt: """
    You are the assistant inside SwiftAgentKitUIDemo. Be concise and direct.
    If tools are available and useful, call them instead of guessing.
    """,
    maxTurns: toolsEnabled ? 6 : 1,
    tools: toolsEnabled ? DemoTools.all : []
))
```

The most important benefit is that the selected model is not just UI state. When the user changes provider, model, custom model, API key, or tool mode, the demo rebuilds the active `Agent` with the actual selected provider/model configuration.

### LLMProviderKit

`LLMProviderKit` keeps provider integration out of the UI. The demo can switch between local and cloud providers through one provider protocol while still using each provider's native request shape.

```swift
let configuration = LLMProviderConfiguration(
    name: providerName,
    baseURL: baseURL,
    apiKey: apiKey,
    defaultModel: selectedModel
)

let provider: any LLMProvider = OllamaProvider(configuration: configuration)
```

The package was especially useful for Ollama. The demo can ask the local server for installed models instead of hardcoding a model that might not exist:

```swift
let provider = DemoProvider.ollama.makeProvider(
    apiKey: nil,
    defaultModel: selectedModel
)

let models = try await provider.availableModels()
```

Tool calling is also delegated to the provider layer. The demo does not disable Ollama tool calling globally; when tools are enabled, it registers safe tools and lets `LLMProviderKit` send native tool definitions to providers that support them.

## Project Structure

```text
SwiftAgentKitUIDemo/
├── SwiftAgentKitUIDemo.xcodeproj
├── SwiftAgentKitUIDemo/
│   ├── App/
│   ├── Models/
│   ├── Stores/
│   ├── Support/
│   ├── Tools/
│   └── Views/
├── .codex/
│   └── environments/environment.toml
└── README.md
```

Key files:

- `Views/ContentView.swift`: root chat + event timeline layout
- `Views/ConfigurationBar.swift`: provider/model/API key/tool controls
- `Stores/DemoAgentViewModel.swift`: active provider/model state and agent rebuilding
- `Models/DemoProvider.swift`: provider metadata and provider construction
- `Tools/DemoTools.swift`: small safe tools for testing tool calling

## Dependencies

The app uses Xcode package references only:

- [SwiftAgentKitUI](https://github.com/ayman3000/SwiftAgentKitUI.git)
- [SwiftAgentKit](https://github.com/ayman3000/SwiftAgentKit.git)
- [LLMProviderKit](https://github.com/ayman3000/LLMProviderKit.git)

The resolved package pins are stored in `SwiftAgentKitUIDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

No package source is copied into this repository.

## Requirements

- macOS
- Xcode with macOS SwiftUI support
- Optional: Ollama for local models
- Optional: OpenAI, Anthropic, or Gemini API key for cloud providers

## Open In Xcode

1. Open `SwiftAgentKitUIDemo.xcodeproj`.
2. Select the `SwiftAgentKitUIDemo` scheme.
3. Let Xcode resolve Swift Package dependencies.
4. Build and run the macOS app.

If Xcode shows this issue:

```text
Macro "SwiftAgentKitMacros" from package "SwiftAgentKit" must be enabled before it can be used
```

expand the issue in Xcode and choose the option to trust or enable the `SwiftAgentKitMacros` macro from `SwiftAgentKit`. This is a one-time local Xcode trust step for Swift package macros. The CLI command below uses `-skipMacroValidation` so noninteractive terminal builds do not stop on that prompt.

## Build From Terminal

```bash
xcodebuild \
  -project SwiftAgentKitUIDemo.xcodeproj \
  -scheme SwiftAgentKitUIDemo \
  -destination "platform=macOS" \
  -skipMacroValidation \
  build
```

## Ollama Setup

Ollama is the default provider so the app can run without cloud credentials.

1. Install Ollama from [ollama.com](https://ollama.com).
2. Start the local Ollama server.
3. Pull at least one chat model:

```bash
ollama pull llama3.2
```

4. Launch the app.
5. Choose `Ollama` in the provider picker.
6. Click the refresh button in the model bar.

The app loads local models from:

```text
http://localhost:11434/api/tags
```

It does not hardcode an Ollama model. If no models are returned, pull a model with `ollama pull`, refresh again, or type the exact installed model name in the custom model field.

## Cloud Provider Setup

The provider picker supports OpenAI, Anthropic, and Gemini through `LLMProviderKit`.

- OpenAI: paste an OpenAI API key and choose or enter a model such as `gpt-4o-mini`.
- Anthropic: paste an Anthropic API key and choose one of the curated Claude model IDs.
- Gemini: paste a Gemini API key and choose or enter a Gemini model ID.

API keys are held in memory for the current app run. This demo does not persist secrets.

## Model Selection Behavior

The app has two model inputs:

- `Model`: a picker populated from provider model listing or suggested models.
- `Custom model name`: a manual override.

The custom model name takes precedence over the picker. The active agent is rebuilt whenever provider, model, custom model, API key, or tool mode changes.

```swift
var selectedModel: String? {
    customModelName.nilIfBlank ?? selectedModelID.nilIfBlank
}
```

That selected model is passed into `AgentConfig`, so the agent actually uses the model shown in the configuration bar.

### Where Model Lists Come From

Model discovery is provider-specific:

- Ollama models are loaded live from the local Ollama server through `OllamaProvider.availableModels()`.
- OpenAI models are loaded live through `OpenAIProvider.availableModels()` when an API key is available.
- Gemini models are loaded live through `GeminiProvider.availableModels()` when an API key is available.
- Anthropic models come from `LLMProviderKit`'s curated `AnthropicProvider.curatedModels` list.

If live model listing fails, the demo falls back to a small set of suggested model IDs for OpenAI and Gemini so the UI remains usable. These suggestions are only fallbacks; the custom model field can override all picker values.

If the underlying packages or providers expose new models, the demo can use them in two ways:

- Live-listed models appear after refreshing the provider model list.
- Package-curated models appear after resolving/building against an updated package revision.

You can always type a provider-supported model ID manually in `Custom model name`, even if it is not listed in the picker.

## Tool Calling

The demo includes small safe tools so you can test tool-calling behavior without granting file or shell access.

```swift
enum DemoTools {
    static var all: [any AgentTool] {
        [
            CurrentDateTimeTool(),
            DemoAppInfoTool()
        ]
    }
}
```

Example tool:

```swift
struct CurrentDateTimeTool: AgentTool {
    let name = "current_datetime"
    let description = "Returns the current local date and time for the user's machine."
    let parameters = ToolParameters.empty

    func execute(parameters: [String: Any]) async throws -> AgentToolResult {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .long

        return .success(
            toolCallId: "",
            toolName: name,
            result: "Local date and time: \(formatter.string(from: Date()))"
        )
    }
}
```

When tools are enabled, these tools are registered with the active agent:

```swift
tools: toolsEnabled ? DemoTools.all : []
```

Ollama tool calling is not disabled globally. If the selected local model supports tool calling, `LLMProviderKit` sends the native tool definitions and `SwiftAgentKit` runs the agent loop.

## Error Handling

Provider/model errors are not hidden. If a selected provider or model fails, the error appears in the chat UI and the event timeline.

Common examples:

- Ollama server is not running
- The selected Ollama model is not installed
- A cloud API key is missing or invalid
- A cloud account does not have access to the selected model
- A selected model does not support tool calls

## Troubleshooting

### Xcode asks about macros

`SwiftAgentKit` includes a macro target. In Xcode, allow the macro when prompted. In Terminal, use `-skipMacroValidation` as shown above.

### Ollama returns no models

Run:

```bash
ollama list
```

If the list is empty, pull a model:

```bash
ollama pull llama3.2
```

Then refresh models in the app.

### Ollama says the model does not exist

The model name must match an installed Ollama model. Use `ollama list`, then choose that model from the picker or enter it exactly in the custom model field.

### Tool calls do not happen

Tool calling depends on model capability and provider support. Try a model that advertises tool support, keep the Tools toggle on, and ask a tool-relevant question such as:

```text
What time is it on my machine?
```

### Cloud model listing fails

Check the API key and account access. You can still enter a model ID manually in the custom model field.

## Repository

Target GitHub repository:

```text
https://github.com/ayman3000/SwiftAgentKitUIDemo
```
