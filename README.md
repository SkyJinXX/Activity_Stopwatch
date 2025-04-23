# Activity Stopwatch for Garmin

A highly optimized stopwatch application for Garmin watches with activity tracking capabilities, designed to maximize battery life while providing precise timing.

## Features

- **Activity Type Tracking**: Categorize each lap as Vague, Neutral, or Focused
- **Lap Management**: Record and view multiple laps with detailed timing information
- **State Preservation**: App remembers your timing session even when closed
- **Battery Status**: View remaining battery level directly within the app

## Battery Optimization

This app has been extensively optimized for power efficiency:

- **Extended Runtime**: While the system stopwatch on Forerunner 165 lasts approximately 12 hours with always-on display at low brightness, Activity Stopwatch can run for **60+ hours** under the same conditions
- **Reduced Processing**: Minimized timer callbacks and efficient UI updates
- **Optimized Storage**: Smart state management consumes minimal memory
- **Streamlined Rendering**: Efficient screen drawing to reduce power consumption

## Controls

- **START/STOP**: Press Enter button to start or pause the stopwatch
- **LAP**: Press Back button to record a lap (prompts for activity type)
- **SCROLL**: Use Up/Down buttons to navigate through recorded laps
- **SAVE**: When paused, press Down button to save and reset
- **EXIT**: swipe right-to-left to exit to watch face

## Activity Types

Each lap can be categorized into one of three activity types:
- **Focused (Green)**: High concentration tasks
- **Neutral (Yellow)**: Standard activities
- **Vague (Gray)**: Low engagement activities

## Technical Details

Built with Garmin Connect IQ SDK, utilizing native timers and optimized state management to preserve battery life. Designed for Forerunner series watches but compatible with most Garmin devices.