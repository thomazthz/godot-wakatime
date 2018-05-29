tool

const Utils = preload('res://addons/wakatime/utils.gd')
const SETTINGS_FILE = '%s/settings.cfg' % Utils.PLUGIN_PATH

const SECTION_NAME = 'godot-wakatime'
const PYTHON_PATH = 'python'
const WAKATIME_API_KEY = 'wakatime_api_key'
const HIDE_PROJECT_NAME = 'hide_project_name'
const HIDE_FILENAMES = 'hide_filenames'
const INCLUDE = 'include'
const EXCLUDE = 'exclude'

var _settings = {
	PYTHON_PATH: null,
	WAKATIME_API_KEY: null,
	HIDE_PROJECT_NAME: false,
	HIDE_FILENAMES: false,
}


func _init():
	load_all_settings()


func save_setting(key, value, multiline=false):
	var config = ConfigFile.new()
	config.load(SETTINGS_FILE)

	if multiline:
		value = value.split('\n', false)

	config.set_value(SECTION_NAME, key, value)
	var err = config.save(SETTINGS_FILE)
	# update cache
	if err == OK:
		_settings[key] = value


func load_setting(key):
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
	return load_setting(key)
