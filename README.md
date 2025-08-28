我没有下面的key，最终编译失败远程打包失败
```
enum Secrets {
    static func getApiKey() -> String {
        return "YOUR_OPENAI_KEY"   // ← 替换为你的真实 key
    }

    static func getRunwayApiKey() -> String {
        return "YOUR_RUNWAY_KEY"   // ← 替换为你的真实 key
    }
}
```

# AI Wallpaper App
**In my local git repo, I have normal commit system, but I am too lazy to .gitignore and remove from history all the sensitive files, so from time to time I just paste the project here. Also, if you could not tell, the Readme is Ai generated 😉**

This iOS application is a technical showcase of integrating multiple AI APIs and native iOS development to create a functional tool for generating and setting AI-powered live wallpapers. The app demonstrates proficiency in API integration, mobile development with Objective-C, and user interface design, leveraging advanced technologies to deliver a seamless workflow.

## Project Purpose

The goal of this project was to build an app that generates unique live wallpapers by combining AI-driven image creation, text generation, and animation with native iOS functionality. It integrates OpenAI's DALL-E for image generation, ChatGPT for naming, the Runway API for animation, and Objective-C for creating live wallpapers compatible with iOS.

## Core Workflow

The app's functionality is broken down into a series of technical steps:

1. **Image Generation**  
   - Users input a text description or select a predefined style (e.g., "Fantasy," "Anime," "Nature").  
   - The DALL-E API generates a high-resolution static image based on the input.  
   - *Technical Note*: This step involves handling API requests and parsing image data for display.

2. **Image Naming**  
   - ChatGPT generates a creative name for the image, adding a unique identifier to each creation.  
   - *Technical Note*: Text generation is achieved through OpenAI's API, requiring prompt engineering and response processing.

3. **Image Animation**  
   - The static image is sent to the Runway API, which transforms it into a short, looping animation.  
   - *Technical Note*: This requires managing asynchronous API calls and handling video output for further processing.

4. **Live Wallpaper Creation**  
   - The animated image is converted into a Live Photo using Objective-C, leveraging iOS’s native APIs (e.g., `PHLivePhoto`).  
   - Users can set the result as their wallpaper directly from the Photos app.  
   - *Technical Note*: This step demonstrates deep iOS integration, requiring precise handling of media formats and system permissions.

## Technology Stack

- **DALL-E (OpenAI)**: Generates high-quality images from text prompts or styles.  
- **ChatGPT (OpenAI)**: Produces creative names for each generated image.  
- **Runway API**: Animates static images into dynamic loops.  
- **Objective-C**: Implements Live Photo creation and iOS-specific functionality.  
- **SwiftUi**: Provides the user interface, including style selection, input fields, and gallery views.

## Technical Implementation

- **API Integration**:  
  - Custom clients were built for DALL-E, ChatGPT, and Runway APIs, managing authentication, request formatting, and error handling.  
  - Asynchronous networking ensures smooth performance during API calls.

- **Objective-C Development**:  
  - Used to interface with iOS’s Photos framework for Live Photo creation.  
  - Handles conversion of Runway’s video output into a format compatible with `PHLivePhoto`.

- **Data Management**:  
  - Generated wallpapers are stored locally and displayed in a scrollable gallery, showcasing persistence and UI skills.

## Visual Demonstration

The provided image is a series of eight iPhone screenshots illustrating the app's workflow:

![Frame 3](https://github.com/user-attachments/assets/08f5369b-0926-45c4-b2f1-432325001224)

1. **Home Screen**: Displays style options ("Fantasy," "Anime," "Nature") and a "New Wallpaper" button.  
2. **Input Screen**: Shows a text field with the prompt "A troll sitting at a desk" and selected style "Fantasy."  
3. **Generated Image**: Presents a troll at a desk with options to "Save to Photos" or "Animate!"  
4. **Animation Process**: Displays a loading spinner over the troll image during Runway API processing.  
5. **Live Wallpaper**: Shows the animated troll set as the iPhone lock screen with a "Pinch to Crop" option.  
6. **Wallpaper History**: Lists previously generated wallpapers (e.g., troll, abstract, desert).  
7. **Gallery View**: Offers a scrollable list of pre-generated wallpapers.  

## Challenges Overcome

- **API Synchronization**: Coordinating responses from three distinct APIs required robust error handling and retry logic.  
- **Performance Optimization**: Processing large image and video data was optimized to minimize memory usage on iOS devices.  
- **Live Photo Compatibility**: There is simply not much documentaion about Live Wallpapers - simply had to look and use other repositories.

## Skills Demonstrated

- **API Integration**: Seamless use of DALL-E, ChatGPT, and Runway APIs.  
- **iOS Development**: Advanced Objective-C programming for Live Photo creation.  
- **UI/UX Design**: Intuitive interface with style selection and gallery features.  
- **Problem Solving**: Overcame technical hurdles in API and media handling.

This project reflects a strong command of modern AI tools and native iOS development, resulting in a fully functional app that pushes the boundaries of mobile creativity.
