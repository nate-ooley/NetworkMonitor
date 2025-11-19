import SwiftUI

struct DeviceDetailSheet<Content: View>: View {
    @ObservedObject var viewModel: NetworkCanvasViewModel
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .sheet(item: $viewModel.selectedDevice) { device in
                NavigationStack {
                    DeviceDetailView(details: viewModel.details(for: device))
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { viewModel.clearSelection() }
                            }
                        }
                }
            }
    }
}
