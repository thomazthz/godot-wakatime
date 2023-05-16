# godot-wakatime

Godot plugin for metrics, insights, and time tracking automatically generated from your Godot usage.

- [godot-wakatime](#godot-wakatime)
  - [Dependencies](#dependencies)
  - [Installation](#installation)
    - [Activation](#activation)
  - [Configuring](#configuring)
  - [Supported Godot \<\> Plugin versions](#supported-godot--plugin-versions)


![wakatime_dashboard](https://user-images.githubusercontent.com/1638660/40685625-24ec905a-636b-11e8-8c78-6d1ed833466d.png)


## Dependencies

As there is no easy way to unzip files in GDScript, this plugin uses [Ouch!](https://github.com/ouch-org/ouch) to decompress Wakatime CLI right from the Github page.

But there is no need to manually download it as the Godot Wakatime plugin automatically downloads, uses and deletes as needed


## Installation

The easiest and fastest way is to install directly from Godot's AssetLib

1. Access Godot's AssetLib inside the engine (`F4` default keybind)
2. Search for `godot-wakatime` and click on install button


Or, you can manually install the latest version following the next steps

1. Download and extract latest zip file from [**releases**](https://github.com/thomazthz/godot-wakatime/releases).
2. Copy or move the `wakatime` directory from the extracted zip and put into your project's `addons` directory. Create the `addons` directory at the root of your project if you don't have one.


### Activation

- Activate `godot-wakatime` on Plugins tab at menu `Project -> Project Settings -> Plugins`.
- Enter your Wakatime API Key on the opened prompt.
- Use Godot script editor for a while and check on https://wakatime.com/api/v1/users/current or https://wakatime.com/dashboard to see your coding activity :)


## Configuring

Some settings are available in the editor bottom panel as soon as the plugin is active

Wakatime settings and plugin settings (like Python binary path) are stored in the file at `<GODOT_PROJECT>/addons/wakatime/settings.cfg`.

![godot_wakatime_control](https://user-images.githubusercontent.com/1638660/40685673-4860f1ac-636b-11e8-89f3-229171ce5e0d.png)


## Supported Godot <> Plugin versions

|     Godot     | Godot Wakatime |
| :-----------: | :------------: |
| 3.3.x - 3.5.x |     v1.4.0     |
|    >=4.0.x    |     v2.0.0     |

Tested **Windows** and **Linux**.

It has Mac OS support as well, but has not yet been tested.
