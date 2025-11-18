import SwiftUI

struct DeviceNodeView: View {
    let device: NetworkDevice
    @State private var isHovered = false
    var isSelected: Bool = false
    var onTap: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 6) {
            // Device icon
            ZStack {
                Circle()
                    .fill(deviceStatusColor.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: device.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(deviceStatusColor)
            }
            
            // Device name
            Text(device.displayName)
                .font(.geneva(size: 10))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            // Optional: Show device type or IP
            if isHovered {
                Text(device.deviceType.rawValue)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                Text(device.ipAddress)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: isHovered ? 5 : 3, x: 2, y: 2)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            deviceContextMenu
        }
    }
    
    private var deviceStatusColor: Color {
        if !device.isOnline {
            return .red
        }
        return device.deviceType.category == .apple ? .blue : .primary
    }
    
    private var borderColor: Color {
        if isSelected {
            return .accentColor
        }
        if isHovered {
            return .primary
        }
        return .gray.opacity(0.5)
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2.5 : (isHovered ? 2 : 1)
    }
    
    @ViewBuilder
    private var deviceContextMenu: some View {
        Button("Inspect Device") {
            // TODO: Show device details
        }
        
        Button("Test Connection") {
            // TODO: Ping device
        }
        
        if !device.recommendedProtocols.isEmpty {
            Menu("Connect via...") {
                ForEach(device.recommendedProtocols, id: \.self) { proto in
                    Button(proto.rawValue) {
                        // TODO: Connect using this protocol
                    }
                }
            }
        }
        
        Divider()
        
        Button("Remove from Canvas") {
            // TODO: Remove device
        }
        .foregroundColor(.red)
    }
}

#Preview {
    DeviceNodeView(
        device: NetworkDevice(
            name: "MacBook Pro",
            displayName: "MacBook Pro",
            ipAddress: "192.168.1.100",
            deviceType: .mac
        )
    )
    .frame(width: 200, height: 200)
}

//
//  DeviceNodeView.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

