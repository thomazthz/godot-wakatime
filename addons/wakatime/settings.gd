tool

const Utils = preload('res://addons/wakatime/utils.gd')
const SETTINGS_FILE = '%s/settings.cfg' % Utils.PLUGIN_PATH


const SECTION_NAME = 'godot-wakatime'
const PYTHON_PATH = 'python'
const WAKATIME_API_KEY = 'wakatime_api_key'

var _settings = {
	PYTHON_PATH: null,
	WAKATIME_API_KEY: null,
}


func _init():
	load_all_settings()


static func save_setting(key, value):
	var config = ConfigFile.new()
	config.load(SETTINGS_FILE)
	config.set_value(SECTION_NAME, key, value)
	config.save(SETTINGS_FILE)


static func load_setting(key):
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	var value = null
	if err == OK:
		if config.has_section_key(SECTION_NAME, key):
			value = config.get_value(SECTION_NAME, key)
	return value


func load_all_settings():
	for key in _settings:
		_settings[key] = load_setting(key)


func get(key):
	if _settings.has(key):
		return _settings[key]
	return null
