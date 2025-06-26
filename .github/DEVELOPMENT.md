# VS Code Development Setup

This project is configured for development and debugging directly in VS Code. The following setup enables you to launch, debug, and develop the game without leaving your code editor.

## Development Rules

- **No automatic README creation**: Do not add any new README files in any folder unless explicitly requested
- All development documentation should be contained within this file or other specifically designated documentation files

## Prerequisites

- VS Code with the following extensions (already included in workspace recommendations):
  - **Godot Tools** (`geequlim.godot-tools`) - Essential for GDScript debugging and LSP support
  - **Godot Files** (`alfish.godot-files`) - Enhanced syntax highlighting for Godot files

## Debug Configurations

The project includes several debug configurations in `.vscode/launch.json`:

1. **Launch Cyber Cultivation (Debug)** - Launches the full game with debugging enabled
2. **Launch Main Scene (Debug)** - Launches just the main scene defined in project settings
3. **Launch Current Scene (Debug)** - Launches the currently open scene file
4. **Attach to Godot Editor** - Attaches debugger to an already running Godot editor instance

## Available Tasks

Use `Cmd+Shift+P` → "Tasks: Run Task" to access these tasks from `.vscode/tasks.json`:

- **Open Godot Editor** - Opens the Godot editor for this project
- **Run Game** - Runs the game in headless mode
- **Run Game (Windowed)** - Runs the game with window (default)
- **Export Game (Debug)** - Exports a debug build to the `build/` folder

## How to Debug

1. **Setup Godot for Remote Debugging:**
   - Open your project in Godot Editor
   - Go to `Project → Project Settings → Debug`
   - Check "Remote Debug" and ensure "Remote Port" is set to `6007`
   - Close the project settings

2. **Start Debugging in VS Code:**
   - Set breakpoints in your `.gd` files by clicking in the gutter
   - Go to the Debug view (`Cmd+Shift+D`)
   - Select a debug configuration from the dropdown
   - Press `F5` or click the green play button

3. **Alternative Method:**
   - Use the "Attach to Godot Editor" configuration
   - Start the game from within Godot Editor
   - The debugger will connect automatically

## Tips

- The LSP server runs on port `6005` for code completion and error checking
- The debugger uses port `6007` for debugging sessions
- All paths are configured to work with the standard Godot installation on macOS
- Code formatting is enabled on save for better code consistency

## Configuration Files

The VS Code setup includes:
- `.vscode/launch.json` - Debug configurations
- `.vscode/tasks.json` - Build and run tasks
- `.vscode/settings.json` - Godot-specific settings
- `.vscode/extensions.json` - Recommended extensions
