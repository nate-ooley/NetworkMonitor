import SwiftUI

struct ClassicMacPattern: View {
    var patternType: PatternType = .checkerboard
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let patternSize: CGFloat = 8
                
                switch patternType {
                case .checkerboard:
                    drawCheckerboard(context: context, size: size, patternSize: patternSize)
                case .diagonal:
                    drawDiagonal(context: context, size: size, patternSize: patternSize)
                case .dots:
                    drawDots(context: context, size: size, patternSize: patternSize)
                }
            }
        }
        .opacity(0.05)
    }
    
    private func drawCheckerboard(context: GraphicsContext, size: CGSize, patternSize: CGFloat) {
        for x in stride(from: 0, to: size.width, by: patternSize) {
            for y in stride(from: 0, to: size.height, by: patternSize) {
                if (Int(x/patternSize) + Int(y/patternSize)) % 2 == 0 {
                    let rect = CGRect(x: x, y: y, width: patternSize, height: patternSize)
                    context.fill(Path(rect), with: .color(.primary))
                }
            }
        }
    }
    
    private func drawDiagonal(context: GraphicsContext, size: CGSize, patternSize: CGFloat) {
        for x in stride(from: 0, to: size.width, by: patternSize) {
            for y in stride(from: 0, to: size.height, by: patternSize) {
                if (Int(x/patternSize) - Int(y/patternSize)) % 2 == 0 {
                    let rect = CGRect(x: x, y: y, width: patternSize, height: patternSize)
                    context.fill(Path(rect), with: .color(.primary))
                }
            }
        }
    }
    
    private func drawDots(context: GraphicsContext, size: CGSize, patternSize: CGFloat) {
        for x in stride(from: patternSize/2, to: size.width, by: patternSize) {
            for y in stride(from: patternSize/2, to: size.height, by: patternSize) {
                let circle = Circle()
                    .path(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                context.fill(circle, with: .color(.primary))
            }
        }
    }
    
    enum PatternType {
        case checkerboard
        case diagonal
        case dots
    }
}

//
//  ClassicMacPattern.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

