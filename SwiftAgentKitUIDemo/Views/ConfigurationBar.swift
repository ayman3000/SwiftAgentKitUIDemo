import SwiftUI

struct ConfigurationBar: View {
    @ObservedObject var viewModel: DemoAgentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                providerPicker
                modelPicker
                customModelField
                toolsToggle
                refreshButton
            }

            HStack(spacing: 12) {
                if viewModel.selectedProvider.requiresAPIKey {
                    SecureField("API key", text: Binding(
                        get: { viewModel.currentAPIKey },
                        set: { viewModel.setCurrentAPIKey($0) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
                }

                Text("Active: \(viewModel.selectedProvider.displayName) / \(viewModel.effectiveModelDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let usesTools = viewModel.selectedModelUsesTools {
                    Label(usesTools ? "Model advertises tools" : "Model has no tools flag", systemImage: usesTools ? "wrench.and.screwdriver" : "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(usesTools ? Color.secondary : Color.orange)
                        .lineLimit(1)
                }

                Spacer()

                Text(viewModel.modelStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var providerPicker: some View {
        Picker("Provider", selection: $viewModel.selectedProvider) {
            ForEach(DemoProvider.allCases) { provider in
                Text(provider.displayName).tag(provider)
            }
        }
        .frame(width: 160)
    }

    private var modelPicker: some View {
        Picker("Model", selection: $viewModel.selectedModelID) {
            if viewModel.availableModels.isEmpty {
                Text("No models loaded").tag("")
            } else {
                ForEach(viewModel.availableModels) { model in
                    Text(model.displayName ?? model.id).tag(model.id)
                }
            }
        }
        .frame(width: 260)
        .disabled(!viewModel.customModelName.isEmpty)
    }

    private var customModelField: some View {
        TextField("Custom model name", text: $viewModel.customModelName)
            .textFieldStyle(.roundedBorder)
            .frame(width: 220)
    }

    private var toolsToggle: some View {
        Toggle("Tools", isOn: $viewModel.toolsEnabled)
            .toggleStyle(.switch)
            .controlSize(.small)
    }

    private var refreshButton: some View {
        Button {
            viewModel.refreshModels()
        } label: {
            if viewModel.isRefreshingModels {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .help("Refresh available models")
        .disabled(viewModel.isRefreshingModels)
    }
}
