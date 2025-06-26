# Font Setup Instructions for Forkly App

## Option 1: Using Info.plist (Created)

I've created an Info.plist file with the necessary font declarations. To make it work:

1. In Xcode, right-click on the "Forkly-v2" folder in the Project Navigator
2. Select "Add Files to 'Forkly-v2'..."
3. Navigate to the newly created Info.plist file
4. Click "Add"

## Option 2: Using Project Settings (Modern Approach)

For newer Xcode projects that don't use a separate Info.plist file:

1. Select your project in the Project Navigator
2. Select the "Forkly-v2" target
3. Go to the "Info" tab
4. Expand "Custom iOS Target Properties" if it's not already expanded
5. Right-click and select "Add Row"
6. Add a key named "Fonts provided by application" (which is `UIAppFonts` internally)
7. Set it as an Array type
8. Add an item to the array with the value "Pacifico-Regular.ttf"

## Verifying Font Setup

To verify the font is properly set up:

1. Make sure the font file is included in your project and is part of the target's "Copy Bundle Resources" build phase
2. Check that the font is being loaded in your app by adding this debug code to your app's initialization:

```swift
// Add this to your Forkly_v2App.swift file's init() method
for family in UIFont.familyNames.sorted() {
    let names = UIFont.fontNames(forFamilyName: family)
    print("Family: \(family) Font names: \(names)")
}
```

This will print all available font families and names to the console when your app launches.

## Troubleshooting

If the font isn't loading:

1. Verify the font filename exactly matches what's in the Info.plist or project settings
2. Make sure the font file is included in the target's "Copy Bundle Resources" build phase
3. Check that the font file is actually in your project's bundle
4. Try cleaning the build folder (Shift+Command+K) and rebuilding 