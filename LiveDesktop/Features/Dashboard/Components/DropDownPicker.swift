import SwiftUI

struct DropDownPicker: View {
    @Binding var selection: String?
    var state: DropDownPickerState = .bottom
    var options: [String]
    var maxWidth: CGFloat = 180
    var placeholder: String = "Select"
    
    @State var showDropdown = false
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State var zindex = 1000.0
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            VStack(spacing: 0) {
                if state == .top && showDropdown {
                    OptionsView()
                }
                
                HStack {
                    Text(selection == nil ? placeholder : selection!)
                        .foregroundColor(selection != nil ? .white : .gray)
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: state == .top ? "chevron.up" : "chevron.down")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees((showDropdown ? -180 : 0)))
                }
                .padding(.horizontal, 20)
                .frame(width: maxWidth, height: 48)
                .background(Color.clear)
                .contentShape(.rect)
                .onTapGesture {
                    index += 1
                    zindex = index
                    withAnimation(.snappy) {
                        showDropdown.toggle()
                    }
                }
                .zIndex(10)
                
                if state == .bottom && showDropdown {
                    OptionsView()
                }
            }
            .clipped()
            .background(Color(hex: "#1f1f1f"))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
            )
            .cornerRadius(25)
            .frame(height: size.height, alignment: state == .top ? .bottom : .top)
        }
        .frame(width: maxWidth, height: 48)
        .zIndex(zindex)
    }
    
    func OptionsView() -> some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                HStack {
                    Text(option)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .opacity(selection == option ? 1 : 0)
                }
                .animation(.none, value: selection)
                .frame(height: 40)
                .contentShape(.rect)
                .padding(.horizontal, 15)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selection = option
                        showDropdown.toggle()
                    }
                }
            }
        }
        .background(Color(hex: "#1f1f1f"))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(
            // Custom border without top edge
            Path { path in
                let rect = CGRect(x: 0, y: 0, width: maxWidth, height: CGFloat(options.count * 40))
                let cornerRadius: CGFloat = 25
                
                // Start from top-left (no top border)
                path.move(to: CGPoint(x: 0, y: 0))
                
                // Left border
                path.addLine(to: CGPoint(x: 0, y: rect.height - cornerRadius))
                path.addQuadCurve(to: CGPoint(x: cornerRadius, y: rect.height), 
                                control: CGPoint(x: 0, y: rect.height))
                
                // Bottom border
                path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: rect.height))
                path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height - cornerRadius), 
                                control: CGPoint(x: rect.width, y: rect.height))
                
                // Right border
                path.addLine(to: CGPoint(x: rect.width, y: 0))
            }
            .stroke(Color.gray.opacity(0.1), lineWidth: 1.5)
        )
        .transition(.move(edge: state == .top ? .bottom : .top).combined(with: .opacity).animation(.easeInOut(duration: 0.15)))
        .zIndex(1)
    }
}
