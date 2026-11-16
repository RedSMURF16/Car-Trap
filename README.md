<h1 align="center">Car Trap</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=bnDntG8pp1g"><img src="https://img.youtube.com/vi/bnDntG8pp1g/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin adds a fully dynamic Car Trap system to Counter-Strike 1.6.
Car Traps can be placed, managed and configured during gameplay with runtime control over activation, team access, movement and screen shake effects.
- Create and remove Car Traps during gameplay via an in-game menu
- Three configurable Car Trap models with independent collision bounds
- Configurable per Car Trap: team access, fall strength, fall frequency and raise strength
- Configurable idle duration after the Car Trap lands
- Optional cooldown before a Car Trap can be activated again
- Configurable screen shake effect based on distance from the Car Trap
- Configurable rope, switch and impact sounds
- Dynamic Car Trap movement with falling, idle and raising states
- Dynamic Car Trap rotation and natural ghost preview placement
- Custom Car Trap setups are saved per map and automatically loaded on every map start

## 📋 Requirements
- ReGameDLL
- AMX Mod X 1.10+

## 💬 Commands
- `say /ct` - Opens the Car Trap menu.
- `say_team /ct` - Opens the Car Trap menu.
- `ct_reload` - Reloads the configuration file.

## ⚙️ Configuration
```ini
# Per-Car Trap settings (defined under each [Car Trap Name] section):
# CAR_FLAGS                = a - Shake
# CAR_TEAM                 = 0 - None             1 - Terrorist           2 - Counter-Terrorist   3 - Both
# CAR_FALL_STRENGTH        = Strength of the Car Trap's fall (MIN - MAX)
# CAR_FALL_FREQ            = Frequency of the Car Trap's fall (MIN - MAX)
# CAR_IDLE_DURATION        = Duration of the idle state in seconds
# CAR_RAISE_STRENGTH       = Strength of the Car Trap's raise (MIN - MAX)
# CAR_COOLDOWN              = Cooldown in seconds before the Car Trap can be activated again
# CAR_SHAKE_DISTANCE       = Distance in units for the shake effect
# CAR_SHAKE_AMPLITUDE      = Amplitude of the shake effect
# CAR_SHAKE_FREQUENCY      = Frequency of the shake effect
# CAR_SHAKE_DURATION       = Duration of the shake effect in seconds
# CAR_SOUND_ROPE           = Sound played for the rope
# CAR_SOUND_SWITCH         = Sound played for the switch
# CAR_SOUND_SMASH          = Sound played for the smash effect
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20video-FF0000?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=bnDntG8pp1g)
