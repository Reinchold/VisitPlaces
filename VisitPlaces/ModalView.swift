//
//  ModalView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 18.06.22.
//

import SwiftUI
import Combine

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
    
    @Binding var isActive: Bool
    @EnvironmentObject var rootViewModel: RootViewModel

    @Environment(\.colorScheme) var colorScheme
    
    @State var orientationShapeWidth: CGFloat
    
    @GestureState private var dragState = DragState.inactive
    
    var modalHeight: CGFloat = 0
    
    var content: () -> Content
    
    var body: some View {
        
        let drag = DragGesture()
            .updating($dragState) { drag, state, transaction in
                state = .dragging(translation: drag.translation)
            }
            .onEnded(onDragEnded)
        
        let spacer: CGFloat = 40
        
        return Group {
            ZStack {
                VStack{
                    Spacer()
                    
                    ZStack(alignment: .top) {
                        
                        // Header + body
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.black : Color.white)
                            .frame(width: orientationShapeWidth,
                                   height: modalHeight+spacer)
                            .cornerRadius(10, corners: [.topLeft, .topRight])
                            .shadow(radius: 5)
                        
                        // Horizontal line
                        Rectangle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 100, height: 4, alignment: .center)
                            .cornerRadius(5)
                            .padding(.top, 18)
                        
                        VStack(spacing: 0) {
                            Divider()
                                .background(.gray)
                                .frame(width: orientationShapeWidth)
                            
                            content()
                                .frame(width: orientationShapeWidth, height: modalHeight)
                                .clipped()
                        }
                        .padding(.top, spacer)
                    }
                    .offset(y: rootViewModel.isShownAutocompletePredictions && !rootViewModel.isShownSettingView ? ((self.dragState.isDragging && dragState.translation.height >= 1) ? dragState.translation.height : 0) : modalHeight+spacer)
                    .animation(.interpolatingSpring(stiffness: 200, damping: 30.0, initialVelocity: 10.0))
                    .gesture(drag)
                }
            }
            .offset(y: -rootViewModel.keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { rootViewModel.keyboardHeight = $0 }
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        let dragThreshold = modalHeight * (2/3)
        if drag.predictedEndTranslation.height > dragThreshold || drag.translation.height > dragThreshold {
            rootViewModel.isShownAutocompletePredictions.toggle()
        }
    }
}

