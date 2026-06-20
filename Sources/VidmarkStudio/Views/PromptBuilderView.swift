import SwiftUI

struct PromptBuilderView: View {
    @ObservedObject var store: StudioStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Master Prompt + Episode Sidecar")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Copy this into your preferred planning or generation tool. The app does not call paid APIs.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    store.copyPromptToClipboard()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                Button {
                    try? store.saveSidecar()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)

            TextEditor(text: .constant(store.generatedPrompt))
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.quaternary)
                )
                .padding([.horizontal, .bottom], 20)
        }
    }
}
