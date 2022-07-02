//
//  ModalView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 18.06.22.
//

import SwiftUI
import Combine

enum ModalScreenPosition {
    case top
    case middle
}

enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .inactive:
            return false
        case .dragging:
            return true
        }
    }
}

struct ModalView<Content: View> : View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    @Environment(\.colorScheme) var colorScheme
    @GestureState private var dragState = DragState.inactive
    @Binding var isShown: Bool
    @State var offset: CGFloat = 0
    @State var position: ModalScreenPosition = .middle
    var midHeight: CGFloat
    var width: CGFloat
    var isFullScreenable = false
    
    var content: () -> Content
    var callback: (() -> Void)?
    
    // UIScreen height
    private var maxHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.size.height
        let safeAreaTop = UIApplication.shared.safeAreaInsets?.top ?? 0
        
        return screenHeight-safeAreaTop
    }
    
    var body: some View {
        
        let spacer: CGFloat = 40
        
        let drag = DragGesture()
            .updating($dragState) { drag, state, transaction in
                state = .dragging(translation: drag.translation)
            }
            .onEnded(onDragEnded)
        
        var offsetCondition: CGFloat {
            guard isShown else { return maxHeight }
            
            if dragState.isDragging {
                return dragState.translation.height + offset
            } else {
                return offset
            }
        }
        
        return Group {
            ZStack {
                VStack{
                    Spacer()
                    
                    ZStack(alignment: .top) {
                        
                        VStack(spacing: 0) {
                            
                            // Header
                            ZStack(alignment: .center) {
                                
                                // Header - body
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.black : Color.white)
                                    .frame(width: width,
                                           height: spacer)
                                    .cornerRadius(10, corners: [.topLeft, .topRight])
                                    .shadow(radius: 5)
                                
                                // Horizontal line
                                Rectangle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 50, height: 4, alignment: .center)
                                    .cornerRadius(2)
                            }
                            
                            Divider()
                                .background(.gray)
                                .frame(width: width)
                            
                            ZStack {
                                // Content
                                content()
                                    .padding(.bottom, offset)
                                    .frame(width: width, height: maxHeight-spacer)
                                    .clipped()
                                    .background(.white)
                            }
                        }
                        .padding(.top, spacer)
                    }
                    .offset(y: offsetCondition)
                    .animation(.interpolatingSpring(stiffness: 200, damping: 30.0, initialVelocity: 10.0))
                    .gesture(drag)
                }
            }
            .offset(y: -rootViewModel.keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { rootViewModel.keyboardHeight = $0 }
            .onAppear {
                withAnimation {
                    offset = maxHeight-midHeight
                }
            }
        }
    }
    
    // MARK: - Calculate end of dragging
    private func onDragEnded(drag: DragGesture.Value) {
        if position == .top {
            // calculate in half the screen.
            let startMiddleThreshold = maxHeight * (1/6)
            let endMiddleThreshold = maxHeight * (4/6)
            let middleRange: ClosedRange<CGFloat> = startMiddleThreshold...endMiddleThreshold
            
            // calculate to close the screen.
            let startCloseThreshold = maxHeight * (5/6)
            let endCloseThreshold = maxHeight
            let closeRange: ClosedRange<CGFloat> = startCloseThreshold...endCloseThreshold
            
            if middleRange ~= drag.predictedEndTranslation.height {
                position = .middle
                offset = maxHeight-midHeight
            } else if closeRange ~= drag.predictedEndTranslation.height {
                position = .middle
                offset = maxHeight-midHeight
                callback?()
            }
        } else if position == .middle {
            let dragThreshold = midHeight * (2/3)
            if drag.predictedEndTranslation.height < 0 || drag.translation.height < 0 {
                offset = 0
                position = .top
            } else if drag.predictedEndTranslation.height > dragThreshold || drag.translation.height > dragThreshold {
                position = .middle
                callback?()
            }
        }
    }
    
}

