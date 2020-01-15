//
//  ApiSourceDetailView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct ApiSourceDetailView: View {
    var body: some View {
        GeometryReader { g in
            Text("API source").frame(width: g.size.width, height: g.size.height)
        }
    }
}

struct ApiSourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ApiSourceDetailView()
    }
}
