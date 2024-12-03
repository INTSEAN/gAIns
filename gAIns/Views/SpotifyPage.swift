//
//  SpotifyPage.swift
//  gAIns
//
//  Created by SEAN DONOVAN on 11/14/24.
//
import SwiftUI

struct SpotifyPage: View {
    @State private var isMainPagePresented = false

    var body: some View {
        NavigationView {
            VStack {
                Image("landing_background_image") // Replace with your landing page background image
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.top)
                    .frame(maxHeight: .infinity)

                Spacer()

                Button(action: {
                    isMainPagePresented = true
                }) {
                    Text("Start Here")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black) // Customize the button color
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isMainPagePresented, content: {
                SpotifyView()
            })
        }
    }
}

struct LandingPage_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyPage()
    }
}
