//
//  LoadingView.swift
//  Forkly
//
//  Created by Juan Rodriguez on 4/12/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)

            Text("Forkly")
                .font(.custom("Pacifico-Regular", size: 36))
                .foregroundColor(.primary)

            ProgressView("Loading delicious recipes...")
                .progressViewStyle(CircularProgressViewStyle())
        }
        .padding()
    }
}
#Preview {
    LoadingView()
}
