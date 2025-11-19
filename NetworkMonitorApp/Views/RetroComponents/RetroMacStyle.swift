import SwiftUI
import AppKit

// View Modifier for Retro Mac styling
struct RetroMacStyle: ViewModifier {
    var isSelected: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor : Color.primary,
                                   lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 2)
    }
}

extension View {
    func retroMacStyle(isSelected: Bool = false) -> some View {
        modifier(RetroMacStyle(isSelected: isSelected))
    }
}

// Classic Mac fonts helper
extension Font {
    static func chicago(size: CGFloat) -> Font {
        // Try to use Chicago font, fallback to system
        if let _ = NSFont(name: "Chicago", size: size) {
            return .custom("Chicago", size: size)
        }
        return .system(size: size, weight: .medium, design: .monospaced)
    }
    
    static func geneva(size: CGFloat) -> Font {
        if let _ = NSFont(name: "Geneva", size: size) {
            return .custom("Geneva", size: size)
        }
        return .system(size: size, weight: .regular)
    }
}

//
//  RetroMacStyle.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

