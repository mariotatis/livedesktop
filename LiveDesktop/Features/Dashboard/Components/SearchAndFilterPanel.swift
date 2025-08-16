import SwiftUI

struct SearchAndFilterPanel: View {
    @Binding var searchText: String
    @Binding var selectedFilterOption: String?
    @Binding var selectedNavItem: String
    @Binding var isSearching: Bool
    
    let filterOptions: [String]
    let onSearchTextChange: (String) -> Void
    let onClearSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search wallpapers...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .onChange(of: searchText) { newValue in
                        onSearchTextChange(newValue)
                    }
                
                // Clear button
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        onClearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
            )
            .cornerRadius(25)
            
            // Filter Dropdown - Hidden for now, might add later
            // DropDownPicker(
            //     selection: $selectedFilterOption,
            //     options: filterOptions,
            //     maxWidth: 180,
            //     placeholder: "Filter"
            // )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .zIndex(1000)
    }
}
