//
//  HelpView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 6/1/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct HelpView: View {
    @State var currentPage = 0
    private let numPages = 3

    var body: some View {
        VStack {
            Group {
                if currentPage == 0 {
                    Text("Page 1")
                } else if currentPage == 1 {
                    Text("Page 2")
                } else {
                    Text("Page 3")
                }
            }.frame(width: 100).transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))

            Button("Next") {
//                guard self.currentPage < self.numPages - 1 else { return }
                withAnimation(.easeInOut) {
                    self.currentPage += 1
                    if self.currentPage == self.numPages {
                        self.currentPage = 0
                    }
                }
            }
            Button("Prev") {
                guard self.currentPage > 0 else { return }

                withAnimation(.easeInOut) {
                    self.currentPage -= 1
                }
            }
            CaruselDots(numDots: numPages, activeIndex: $currentPage).padding()
        }
    }
}

struct CaruselDots: View {
    var numDots: Int
    @Binding var activeIndex: Int

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 15) {
                ForEach(0..<numDots) { _ in
                    Circle().frame(width: 15, height: 15).foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                }
            }
            Circle().frame(width: 15, height: 15).foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4)).offset(x: CGFloat(self.activeIndex) * 15 * 2)
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HelpView()
            CaruselDots(numDots: 3, activeIndex: .constant(1)).padding()
        }
    }
}
