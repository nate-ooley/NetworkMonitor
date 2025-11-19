import SwiftUI

struct NetworkCanvasView: View {
    @StateObject private var viewModel = NetworkCanvasViewModel()
    @State private var canvasOffset: CGSize = .zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var selectedDeviceId: UUID?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background pattern
                ClassicMacPattern(patternType: .checkerboard)
                
                // Main canvas with devices
                canvasContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Device library sidebar
                HStack {
                    DeviceLibrary(viewModel: viewModel)
                        .frame(width: 250)
                        .retroMacStyle()
                        .padding()
                    
                    Spacer()
                }
            }
        }
        .dropDestination(for: NetworkDevice.self) { devices, location in
            if let device = devices.first {
                viewModel.addDeviceToCanvas(device, at: location)
            }
            return true
        }
    }
    
    private var canvasContent: some View {
        Canvas { context, size in
            // Draw grid
            drawGrid(context: context, size: size)
            
            // Draw connections
            for connection in viewModel.connections {
                if let from = viewModel.getDevicePosition(connection.fromDeviceId),
                   let to = viewModel.getDevicePosition(connection.toDeviceId) {
                    drawConnection(context: context, from: from, to: to, type: connection.connectionType)
                }
            }
        }
        .overlay(
            // Device nodes
            ZStack {
                ForEach(viewModel.devicesOnCanvas) { device in
                    DeviceNodeView(
                        device: device,
                        isSelected: selectedDeviceId == device.id
                    ) {
                        selectedDeviceId = device.id
                    }
                    .position(
                        x: device.position.x * canvasScale + canvasOffset.width,
                        y: device.position.y * canvasScale + canvasOffset.height
                    )
                    .gesture(deviceDragGesture(for: device))
                }
            }
        )
        .gesture(canvasPanGesture())
        .gesture(magnificationGesture())
    }
    
    private func deviceDragGesture(for device: NetworkDevice) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let newPosition = CGPoint(
                    x: (value.location.x - canvasOffset.width) / canvasScale,
                    y: (value.location.y - canvasOffset.height) / canvasScale
                )
                viewModel.moveDevice(device, to: newPosition)
            }
    }
    
    private func canvasPanGesture() -> some Gesture {
        DragGesture()
            .modifiers(.option) // Hold Option/Alt to pan
            .onChanged { value in
                canvasOffset = CGSize(
                    width: canvasOffset.width + value.translation.width,
                    height: canvasOffset.height + value.translation.height
                )
            }
    }
    
    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                canvasScale = max(0.5, min(value, 2.0))
            }
    }
    
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let gridSize: CGFloat = 20 * canvasScale
        
        for x in stride(from: 0, through: size.width, by: gridSize) {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(.gray.opacity(0.1)), lineWidth: 0.5)
        }
        
        for y in stride(from: 0, through: size.height, by: gridSize) {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.gray.opacity(0.1)), lineWidth: 0.5)
        }
    }
    
    private func drawConnection(context: GraphicsContext, from: CGPoint, to: CGPoint, type: ConnectionType) {
        var path = Path()
        path.move(to: from)
        
        // Calculate control point for curved line
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        let offset = abs(from.x - to.x) * 0.2
        let controlPoint = CGPoint(x: midX, y: midY - offset)
        
        path.addQuadCurve(to: to, control: controlPoint)
        
        context.stroke(
            path,
            with: .color(type.color.opacity(0.6)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: type == .wifi ? [5, 5] : [])
        )
    }
}

#Preview {
    NetworkCanvasView()
        .frame(width: 1200, height: 800)
}


//
//  NetworkCanvasView.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//


