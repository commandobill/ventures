# 📊 Goblin Ventures (Ashita Addon)

> Easily track Goblin Venture EXP areas in FFXI. Automatically pulls the latest data, alerts you when zones are near completion, and shows it all in a clean GUI.

---

![GUI Screenshot](GUI.PNG)

---

## ✨ Features

- 📈 Automatically captures and parses EXP Area data from `!ventures`
- 🪧 Displays level range, area name, and completion percentage
- 🟢 Auto-refreshes every 60 seconds (configurable)
- 🚨 Alerts you in chat when a zone crosses **90% completion**
- 🚫 Prevents spamming alerts — only alerts **if % increased**
- 🧠 Skips refresh if you are zoning — and **retries automatically** after 5 seconds
- 🎨 GUI with styled columns (toggleable)
- 🛠 Settings interface to control GUI & Alerts
- ⏰ **Time estimation** with confidence levels for completion predictions

---

## 💬 In-Game Commands

| Command | Description |
|--------|-------------|
| `/ventures` | Generates a popup to configure your settings |
| `/ventures config` | Generates a popup to configure your settings |
| `/ventures force` | Immediately fetches the latest Venture data |
| `/ventures settings` | Shows the current GUI and Alert settings |
| `/ventures settings gui` | Toggles the GUI display ON/OFF |
| `/ventures settings alerts` | Toggles command-line alerts ON/OFF |
| `/ventures settings audio` | Toggles audio alerts ON/OFF |

---

## 🔁 Auto Refresh

- The addon will automatically call `!ventures` every **60 seconds**  
- You can change the interval by modifying this in the code:
  ```lua
  auto_refresh_interval = 60 -- seconds
  ```

---

## 🚨 Example Alert

When an EXP area crosses the alert threshold (default: 90%), you will see:

![Command Line Alert](cl.png)

You will only be alerted once per increase — no spam!

---

## 🧠 Zoning Detection

If the addon detects that you're zoning (zone ID = 0), it will:

- Skip the current `!ventures` call
- Print a small message: `Zoning detected. Will retry shortly...`
- Retry automatically after 5 seconds

---

## ⏰ Time Estimation Feature

The addon now includes intelligent time estimation for venture completion:

### **How It Works**
- **Data Collection**: Tracks completion percentage changes with timestamps
- **Rate Calculation**: Computes progress rate (% per hour) from recent updates
- **Confidence Analysis**: Measures consistency of progress patterns
- **Time Prediction**: Estimates time remaining until 100% completion

### **Confidence Levels**
- 🟢 **HIGH**: Very consistent progress patterns
- 🟡 **MEDIUM**: Moderately consistent progress
- 🔴 **LOW**: Inconsistent or insufficient data

### **Configuration**
- **Enable/Disable**: Toggle time estimation on/off
- **Data Points**: Configure minimum updates needed (3-8, default: 4)
- **Display Options**: Show/hide completion time estimates

### **UI Display**
- **Main View**: Shows "47% : 2h 15m" format
- **Tooltip**: Detailed information on hover
- **Color Coding**: 
  - Completion percentage: Alert threshold colors (orange/green)
  - Time estimate: Confidence-based colors (green/yellow/red)
- **Smart Detection**: Automatically detects stalled progress

---

## 🧪 Notes

- Only EXP Areas are currently parsed
- Completion is pulled from in-game `!ventures` system
- Supports both **manual** and **auto** refresh
- Does not require any external tools or plugins

---

## ✅ To-Do / Planned Features

- [ ] Popup notification when zones reach 90%+
- [ ] Configurable alert threshold
- [ ] Persist settings between sessions
- [ ] Settings GUI

---

## 🙏 Credits

Built by **Commandobill** 

Contributions by **Seekey**, **Phatty** & **Chunk**

Tested on private server environments. Feedback and contributions welcome!
