//
//  SettingView.swift
//  VisitPlaces
//
//  Created by Roman Vostrikov on 15.06.22.
//

import SwiftUI

struct CheckboxField: View, Identifiable {
    
    @ObservedObject var rootViewModel: RootViewModel
    
    let id: String
    let label: String
    let size: CGFloat
    let color: Color
    let textSize: Int
    let callback: (String)->()
    
    init(id: String,
         label: String,
         size: CGFloat = 10,
         color: Color = VPColors.title,
         textSize: Int = 14,
         callback: @escaping (String)->(),
         rootViewModel: RootViewModel
    ) {
        self.id = id
        self.label = label
        self.size = size
        self.color = color
        self.textSize = textSize
        self.callback = callback
        self.rootViewModel = rootViewModel
    }
    
    var body: some View {
        Button(action:{
            rootViewModel.searchType = id
            self.callback(self.id)
        }) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: rootViewModel.searchType.contains(id) ? "checkmark.square" : "square")
                    .resizable()
                    .foregroundColor(self.color.opacity(0.7))
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.size, height: self.size)
                
                Text(label)
                    .font(VPFonts.SFProTextRegular16)
                
                Spacer()
            }.foregroundColor(self.color)
        }
        .foregroundColor(VPColors.systemBackground)
    }
}

enum SectionList: String, CaseIterable {
    case bar, cafe, casino, bank, clothing_store, gym, hair_care
    
    var description: String {
        switch self {
        case .bar:
            return "Bar"
        case .cafe:
            return "Cafe"
        case .casino:
            return "Kasino"
        case .bank:
            return "Bank"
        case .clothing_store:
            return "Kleidergeschäft"
        case .gym:
            return "Fitnessstudio"
        case .hair_care:
            return "Friseursalon"
        }
    }
}

struct SettingView: View {
    
    @EnvironmentObject var rootViewModel: RootViewModel
    @State private var checkboxField: [CheckboxField] = [CheckboxField]()
    
    var body: some View {
        VStack {
            Text("Wahl der Einrichtung")
                .font(VPFonts.SFProTextHeavy22)
                .foregroundColor(VPColors.title)
                .padding(.bottom, 20)
            
            List(self.generateList()) {$0}.listStyle(PlainListStyle())
            
            let result = rootViewModel.locationRadius < VPConstants.maxRadius ? "m" : "km"
            let mKm = rootViewModel.locationRadius < VPConstants.maxRadius ? rootViewModel.locationRadius : rootViewModel.locationRadius/VPConstants.maxRadius
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .scaledToFit()
                    .foregroundColor(VPColors.subTitle)
                
                Text("\(Int(mKm)) \(result)" )
                    .font(VPFonts.SFProTextHeavy16)
                    .foregroundColor(VPColors.title)
            }
            
            CustomSliderView()
                .accentColor(VPColors.title)
                .frame(width: 200, height: 44)
            
        }
        .frame(width: 200, alignment: .leading) 
    }
    
    private func checkboxSelected(id: String) {
        print("\(id) is marked")
    }
    
    private func generateList() -> Array<CheckboxField> {
        SectionList.allCases.map {
            CheckboxField(id: $0.rawValue,
                          label: $0.description,
                          size: 14,
                          textSize: 14,
                          callback: checkboxSelected,
                          rootViewModel: rootViewModel)
        }
    }

}
