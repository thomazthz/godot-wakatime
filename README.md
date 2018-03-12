# godot-wakatime

Godot plugin for metrics, insights, and time tracking automatically generated from your Godot usage.


## Dependecies


Wakatime-cli uses Python to send the heartbeats to api.

For Linux/macOS users:
  - No dependencies. Python binary will be automatically found on your system.

For Windows users:
  - Download and install [Python] on system.
  or
  - Download and extract [Python embeddable zip file] to the root path of the plugin (addons/wakatime). The extracted folder must contain `python` on its name to be automatically found by script.


## Installation


1. Download and extract the zip from releases or clone the repository.
2. Put the extracted directory into your `addons` directory of your project. Create `addons` directory at the root of your project if you don't have one.
3. Activate `godot-wakatime` on Plugins tab at menu `Project -> Project Settings -> Plugins`.
4. Enter your Wakatime API Key on opened prompt.
5. Use Godot script editor for a while and check on https://wakatime.com/api/v1/users/current or https://wakatime.com/dashboard to see your coding activity :)



## Caveat


All heartbeats sent are printed to Godot output console. `OS.execute` do this by default and can't be disabled. **Be careful to not reveal your printed API key to anyone**.


## TODO

- Download and extract wakatime-cli from their repo during plugin setup.
- Add more cmdline args like `--exclude`, `--lineno`, `--hidefilenames`, etc and let users change it.
- Remove cmdline output on Windows.


[Python]: <https://www.python.org/ftp/python/3.6.4/python-3.6.4-amd64.exe>
[Python embeddable zip file]: <https://www.python.org/ftp/python/3.6.4/python-3.6.4-embed-amd64.zip>
