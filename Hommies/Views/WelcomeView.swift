import SwiftUI


struct WelcomeView: View {
        @EnvironmentObject var authViewModel: AuthViewModel
    @State private var logoVisible = false
    @State private var titleVisible = false
    @State private var taglineVisible = false

    @State private var buttonsVisible = false

    @State private var isFloating = false
    
    @State private var showSignUp = false
    @State private var showSignIn = false
    let orangeColor = Color(hex: "E8622A")
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
            
                LinearGradient(
                    // Array of colors to transition between
                    colors: [
                        Color(hex: "1A0A00"),  // very dark brown at top
                        Color(hex: "3D1500"),  // dark orange-brown in middle
                        Color(hex: "E8622A")   // Hommies orange at bottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
            
               
                GeometryReader { geometry in
                   
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 250, height: 250)
                        .position(x: 50, y: geometry.size.height - 30)
                    
                   
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 180, height: 180)
                        .position(x: geometry.size.width - 40, y: 100)
                }
                .ignoresSafeArea()
                
                // MARK: - Main Content
          
                VStack(spacing: 0) {
                    
                    Spacer()
                    
                    // MARK: - Logo/Icon Section
                    ZStack {
          
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 140, height: 140)
                        
                        // Inner circle
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 110, height: 110)
                       
                        Text("🏠")
                            .font(.system(size: 60))
            
                            .offset(y: isFloating ? -10 : 0)
                
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                                value: isFloating
                            )
                    }
               
                    .opacity(logoVisible ? 1 : 0)
                    
                    .scaleEffect(logoVisible ? 1 : 0.5)
                 
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: logoVisible)
                    Spacer().frame(height: 30)
                    
                    // MARK: - App Name
                    Text("Hommies")
                        
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: titleVisible ? 0 : 30)
                        .opacity(titleVisible ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: titleVisible)
                    
                    Spacer().frame(height: 12)
                    
                    // MARK: - Tagline
                    Text("Your student home, sorted.")
                        .font(.title3)
                     
                        .fontWeight(.medium)
                      
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(taglineVisible ? 1 : 0)
                        .animation(.easeIn(duration: 0.6), value: taglineVisible)
                    
                    Spacer().frame(height: 12)
                    
                    
                    HStack(spacing: 8) {
            
                        LanguagePill(emoji: "🇺🇸", language: "EN")
                        LanguagePill(emoji: "🇪🇸", language: "ES")
                        LanguagePill(emoji: "🇮🇳", language: "HI")
                    }
                    .opacity(taglineVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: taglineVisible)
                    
                    Spacer()
                    
                    // MARK: - Buttons
                    // Buttons appear last in the animation sequence
                    VStack(spacing: 16) {
                        
                        // Get Started Button → goes to SignUpView
                        // NavigationLink pushes SignUpView onto the navigation stack
                        NavigationLink(destination: SignUpView()) {
                            // HStack arranges icon and text horizontally
                            HStack {
                                Text("Get Started")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                // Spacer pushes icon to the right
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                            }
                            .foregroundColor(orangeColor)
                            .padding(.horizontal, 28)  // horizontal padding inside button
                            .padding(.vertical, 18)    // vertical padding inside button
                            .background(Color.white)   // white background
                            // cornerRadius rounds the corners of the button
                            .cornerRadius(16)
                            // shadow adds a drop shadow behind the button
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        // Sign In Button → goes to SignInView
                        NavigationLink(destination: SignInView()) {
                            HStack {
                                Text("Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .font(.title2)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 18)
               
                            .background(Color.clear)
                            .cornerRadius(16)
    
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                  
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                            )
                        }
                    }
                 
                    .padding(.horizontal, 32)
                    .opacity(buttonsVisible ? 1 : 0)
                 
                    .offset(y: buttonsVisible ? 0 : 40)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: buttonsVisible)
                    
                    Spacer().frame(height: 50)
                }
            }
            // .onAppear runs when this view appears on screen
            // We trigger the animations in sequence with delays
            .onAppear {
                // Start floating animation immediately
                isFloating = true
                
                // DispatchQueue.main.asyncAfter runs code after a delay
                // delay 0.2 seconds → show logo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    logoVisible = true
                }
                // delay 0.5 seconds → show title
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    titleVisible = true
                }
                // delay 0.8 seconds → show tagline
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    taglineVisible = true
                }
                // delay 1.1 seconds → show buttons
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    buttonsVisible = true
                }
            }
            // Hide the default navigation bar on this screen
            // Welcome screen looks better without a nav bar
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Language Pill Component

struct LanguagePill: View {
    

    let emoji: String
    let language: String
    
    var body: some View {
       
        HStack(spacing: 4) {
            Text(emoji)
                .font(.caption)
            Text(language)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        // Semi-transparent white background for the pill shape
        .background(Color.white.opacity(0.2))
        // capsule shape = fully rounded ends like a pill
        .clipShape(Capsule())
    }
}
