import SwiftUI

struct SearchAndFilterPanel: View {
    @Binding var searchText: String
    @Binding var selectedFilterOption: String?
    
    let filterOptions: [String]
    
    var body: some View {
        HStack(spacing: 16) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search wallpapers...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
            )
            .cornerRadius(25)
            
            // Filter Dropdown
            DropDownPicker(
                selection: $selectedFilterOption,
                options: filterOptions,
                maxWidth: 180,
                placeholder: "Filter"
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .zIndex(1000)
    }
}
