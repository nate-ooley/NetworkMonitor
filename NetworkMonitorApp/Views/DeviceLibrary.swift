import SwiftUI

struct DeviceLibrary: View {
    @ObservedObject var viewModel: NetworkCanvasViewModel
    @State private var searchText = ""
    @State private var selectedCategory: DeviceCategory? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Devices")
                .font(.chicago(size: 16))
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.accentColor.opacity(0.1))
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search devices...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.geneva(size: 12))
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    CategoryPill(
                        title: "All",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach([DeviceCategory.apple, .networking, .smartHome, .server], id: \.self) { category in
                        CategoryPill(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 4)
            
            Divider()
            
            // Device list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredDevices) { device in
                        DeviceLibraryRow(device: device)
                            .draggable(device) {
                                // Drag preview
                                DeviceNodeView(device: device)
                                    .opacity(0.8)
                            }
                            .onTapGesture {
                                viewModel.addDeviceToCanvas(device)
                            }
                    }
                }
                .padding(8)
            }
            
            Divider()
            
            // Status footer
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(viewModel.isScanning ? .green : .secondary)
                Text("\(viewModel.discoveredDevices.count) devices")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    viewModel.refreshDevices()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var filteredDevices: [NetworkDevice] {
        var devices = viewModel.discoveredDevices
        
        // Filter by category
        if let category = selectedCategory {
            devices = devices.filter { $0.deviceType.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            devices = devices.filter { device in
                device.name.localizedCaseInsensitiveContains(searchText) ||
                device.ipAddress.contains(searchText) ||
                device.deviceType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return devices
    }
}

struct DeviceLibraryRow: View {
    let device: NetworkDevice
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: device.iconName)
                .frame(width: 24, height: 24)
                .foregroundColor(device.isOnline ? .primary : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
                    .font(.geneva(size: 11))
                    .lineLimit(1)
                
                Text(device.ipAddress)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if device.confidence > 0.7 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 10))
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DeviceLibrary(viewModel: NetworkCanvasViewModel())
        .frame(width: 250, height: 600)
}

//
//  DeviceLibrary.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//
