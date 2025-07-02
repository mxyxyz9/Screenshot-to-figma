# macOS Screenshot to Figma Prototype - Build Plan

This document outlines the steps to create a native macOS application that converts a user-provided screenshot into a basic, copyable Figma prototype.

The core workflow is:
1.  User selects a screenshot.
2.  The app uses the Vision framework to detect UI elements (text and boxes).
3.  The app generates an SVG representation of these elements.
4.  The SVG is copied to the clipboard for the user to paste directly into Figma.

---

### Step 1: Project Setup and User Interface (SwiftUI)

The initial focus is on creating a simple UI to handle the screenshot input.

-   **File:** `ContentView.swift`
-   **Tasks:**
    1.  Create a state variable to hold the user's selected image (`NSImage`).
    2.  Implement a file importer using `.fileImporter()` to allow users to select a screenshot from their system.
    3.  Add an `Image` view to display the selected screenshot to the user.
    4.  Add a "Convert to Figma" button that will trigger the analysis and conversion process.
    5.  Add a text area or label to provide feedback to the user (e.g., "Copied to clipboard!").

### Step 2: UI Element Detection (Vision Framework)

This is the core logic for analyzing the image content.

-   **New File:** `ImageAnalyzer.swift`
-   **Tasks:**
    1.  Create a function that accepts an `NSImage` as input.
    2.  Convert the `NSImage` to a `CGImage` for use with the Vision framework.
    3.  Create a `VNImageRequestHandler` with the `CGImage`.
    4.  **Detect Rectangles:**
        -   Create and configure a `VNDetectRectanglesRequest`.
        -   Set parameters to look for reasonably shaped rectangles (avoiding noise).
    5.  **Detect Text:**
        -   Create and configure a `VNRecognizeTextRequest`.
    6.  Perform both requests using the handler.
    7.  Create a simple data structure to hold the results: an array of bounding boxes (`CGRect`) for rectangles and an array of recognized text objects (containing both the string and its bounding box).
    8.  Return this structured data to the caller.

### Step 3: Generate SVG from Detected Elements

Translate the Vision results into a format Figma can understand (SVG).

-   **New File:** `SVGGenerator.swift`
-   **Tasks:**
    1.  Create a function that takes the image dimensions and the arrays of detected rectangles and text from `ImageAnalyzer`.
    2.  Start building a `String` for the SVG output.
    3.  Create the root `<svg>` element, setting its `width` and `height` to match the original screenshot.
    4.  **Map Rectangles:**
        -   Iterate through the array of detected rectangle `CGRect`s.
        -   For each `CGRect`, append a `<rect>` element to the SVG string. Map the `CGRect` properties (`x`, `y`, `width`, `height`) to the corresponding SVG attributes.
        -   Use a default style (e.g., gray fill, thin black stroke).
    5.  **Map Text:**
        -   Iterate through the array of recognized text objects.
        -   For each object, append a `<text>` element to the SVG string. Use its bounding box for the `x` and `y` attributes and the recognized string as the element's content.
    6.  Return the complete SVG `String`.

### Step 4: Clipboard Integration and Finalizing the Workflow

Connect all the pieces and provide the final output to the user.

-   **File:** `ContentView.swift`
-   **Tasks:**
    1.  In the "Convert to Figma" button's action, call the `ImageAnalyzer` with the selected image.
    2.  Pass the results to the `SVGGenerator` to get the final SVG string.
    3.  Access the system clipboard using `NSPasteboard.general`.
    4.  Clear any previous content and write the new SVG string to the pasteboard.
    5.  Update the UI to show the confirmation message.

### Step 5: Testing and Refinement

-   Test the application with a variety of screenshots (e.g., different apps, websites, light/dark mode).
-   Adjust the `VNDetectRectanglesRequest` parameters to improve detection accuracy.
-   Refine the default styling in the `SVGGenerator` for better visual representation in Figma.
-   Ensure coordinate systems are handled correctly (SwiftUI's top-left origin vs. Core Graphics' bottom-left origin).
