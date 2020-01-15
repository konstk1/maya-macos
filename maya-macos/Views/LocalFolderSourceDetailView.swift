//
//  LocalFolderSourceDetailView.swift
//  maya-macos
//
//  Created by Konstantin Klitenik on 1/15/20.
//  Copyright © 2020 KK. All rights reserved.
//

import SwiftUI

struct LocalFolderSourceDetailView: View {
    var body: some View {
        GeometryReader { g in
            Text("Local folder source").frame(width: g.size.width, height: g.size.height)
        }
    }
}

struct LocalFolderSourceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        LocalFolderSourceDetailView()
    }
}
