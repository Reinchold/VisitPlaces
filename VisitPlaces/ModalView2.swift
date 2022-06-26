//
//  ModalView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 18.06.22.
//

import SwiftUI
import Combine

struct ModalView2<Content: View> : View {
    
    @Environment(\.colorScheme) var colorScheme
    @GestureState private var dragState = DragState.inactive
    
    @Binding var isShown: Bool
    
    @State var orientationShapeWidth: CGFloat
    var modalHeight: CGFloat
    
    var content: () -> Content
    var callback: (() -> Void)?
    let spacer: CGFloat = 40
    
    var body: some View {
        //        VStack {
        //            Rectangle()
        //                .fill(colorScheme == .dark ? Color.black : Color.green)
        //                .frame(width: UIScreen.main.bounds.size.width,
        //                       height: modalHeight)
        //        }.offset(y: modalHeight)
                
                Group {
                   ZStack {
                       VStack(spacing: 0) {
                           Spacer()

                           ZStack(alignment: .top) {

                               VStack(spacing: 0) {
                                   // Header
                                   Rectangle()
                                       .fill(colorScheme == .dark ? Color.black : Color.green)
                                       .frame(width: UIScreen.main.bounds.size.width,
                                              height: spacer)
                                       .cornerRadius(10, corners: [.topLeft, .topRight])
                                       .shadow(radius: 5)

                                   VStack {
                                       Text("123")
                                   }.frame(width: UIScreen.main.bounds.size.width,
                                           height: modalHeight-spacer)
                                   .background(Color.brown)
                               }
                           }

                       }
                       .background(Color.clear)
                       .offset(y: modalHeight)
                   }
                   .background(Color.orange)
        //           .offset(y: isShown ? -26 : modalHeight)
                   .animation(.interpolatingSpring(stiffness: 200, damping: 30.0, initialVelocity: 10.0))
                }.background(Color.purple)
            }
}

