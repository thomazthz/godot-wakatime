# godot-wakatime

Godot plugin for metrics, insights, and time tracking automatically generated from your Godot usage.


## Dependecies


Wakatime-cli uses Python to send the heartbeats to api.

For Linux/macOS users:
  - No dependencies. Python binary will be automatically found on your system.

For Windows users:
  - Download and install [Python] on system.
  
    **or**
  
  - Download and extract [Python embeddable zip file] to the root path of the plugin (addons/wakatime). The extracted folder must contain `python` on its name to be automatically found by script.


## Installation


1. Download and extract the zip from releases or clone the repository.
2. Put the extracted directory into your `addons` directory of your project. Create `addons` directory at the root of your project if you don't have one.
3. Activate `godot-wakatime` on Plugins tab at menu `Project -> Project Settings -> Plugins`.
4. Enter your Wakatime API Key on opened prompt.
5. Use Godot script editor for a while and check on https://wakatime.com/api/v1/users/current or https://wakatime.com/dashboard to see your coding activity :)


## Tracking GDScript files

For now, [`pygments` doesn't support GDScript by default](https://bitbucket.org/birkenfeld/pygments-main/issues/1429/add-lexer-for-gdscript-from-godot-game). The workaround is to use a custom rule to force any files ending with `.gd` to be categorized as GDScript. (https://wakatime.com/settings/rules)

![custom_rule_gdscript](https://user-images.githubusercontent.com/1638660/38779468-420acd1c-409f-11e8-9765-f0ee59a43774.jpg)


## Caveat

All heartbeats sent are printed to Godot output console. `OS.execute` do this by default and can't be disabled. **Be careful to not reveal your printed API key to anyone**.


## TODO

- [ ] Debug mode
- [ ] Logs
- [ ] Download and extract wakatime-cli from repo during plugin setup.
- [ ] Add more [cmdline args](https://wakatime.com/help/creating-plugin#sending-file-to-wakatime-cli:executing-background-process) and let users change it on bottom panel
- [ ] Remove cmdline output from Windows editor.



[Python]: <https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe>
[Python embeddable zip file]: <https://www.python.org/ftp/python/3.6.4/python-3.6.4-embed-amd64.zip>
