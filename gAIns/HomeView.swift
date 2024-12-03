//
//  HomeView.swift
//  gAIns
//
//  Created by SEAN DONOVAN on 11/15/24.
//
import SwiftUI

struct HomeView: View {
    @State private var isExpanded = true
    @State private var selectedTab: Int? = nil

    let quotes = [
        "The only bad workout is the one that didn't happen.",
        "Your body can stand almost anything. It's your mind you have to convince.",
        "The hard days are the best because that's when champions are made.",
        "Success is walking from failure to failure with no loss of enthusiasm.",
        "The difference between try and triumph is just a little umph!",
        "The only person you are destined to become is the person you decide to be.",
        "What seems impossible today will one day become your warm-up.",
        "Don't wish it were easier. Wish you were better.",
        "Strength does not come from the body. It comes from the will.",
        "The only way to do great work is to love what you do.",
        "You got this!"
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                // Main content
                VStack {
                    Text(quotes.randomElement() ?? "")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                        .padding()
                    
                    Spacer() // Pushes the quote to the top
                }
                
                // Navigation links
                Group {
                    NavigationLink(tag: 0, selection: $selectedTab) {
                        Text("Workout View - TODO")
                    } label: { EmptyView() }
                    
                    NavigationLink(tag: 1, selection: $selectedTab) {
                        SpotifyView()
                    } label: { EmptyView() }
                    
                    NavigationLink(tag: 2, selection: $selectedTab) {
                        HealthView()
                    } label: { EmptyView() }
                }
                
                // Floating menu buttons
                VStack(spacing: 16) {
                    if isExpanded {
                        Button(action: {
                            isExpanded = false
                            selectedTab = 0
                        }) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.green))
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                        Button(action: {
                            isExpanded = false
                            selectedTab = 1
                        }) {
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.green))
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                        Button(action: {
                            isExpanded = false
                            selectedTab = 2
                        }) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.green))
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
                    // Main plus button
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "xmark" : "plus")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding(20)
                            .background(Circle().fill(Color.green))
                            .shadow(radius: 5)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    }
                }
                .padding()
            }
        }
    }
}



#Preview {
    HomeView()
}
