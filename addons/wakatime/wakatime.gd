tool
extends EditorPlugin

const HeartBeat = preload('res://addons/wakatime/heartbeat.gd')
const Settings = preload('res://addons/wakatime/settings.gd')
const Utils = preload('res://addons/wakatime/utils.gd')

var last_heartbeat = HeartBeat.new()

var wakatime_cli = ProjectSettings.globalize_path(Utils.WAKATIME_CLI_PATH)

var api_key_modal = preload('res://addons/wakatime/api_key_modal.tscn')
var bottom_panel_scn = preload('res://addons/wakatime/bottom_panel.tscn')
var bottom_panel = null
var settings = null


func _exit_tree():
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.disconnect('editor_script_changed', self, '_on_script_changed')
	remove_control_from_bottom_panel(bottom_panel)


func _ready():
	# Load all settings from .cfg file
	settings = Settings.new()

	# Check python bin
	if not settings.get(Settings.PYTHON_PATH):
		var python = Utils.get_python_binary()
		if python:
			settings.save_setting(Settings.PYTHON_PATH, python)
		else:
			printerr('Python not found! Install Python from https://www.python.org/downloads/ and reload godot-wakatime plugin')
			get_editor_interface().call_deferred('set_plugin_enabled', 'wakatime', false)

	# Check wakatime api key
	if not settings.get(Settings.WAKATIME_API_KEY):
		open_api_key_modal()

	bottom_panel = bottom_panel_scn.instance()
	bottom_panel.init(self)
	add_control_to_bottom_panel(bottom_panel, 'Wakatime')

	var script_editor = get_editor_interface().get_script_editor()
	script_editor.call_deferred('connect', 'editor_script_changed', self, '_on_script_changed')


func get_state():
	if not settings:
		settings = Settings.new()
	return {'settings': settings}


func get_current_file():
	return get_editor_interface().get_script_editor().get_current_script()


func handle_activity(file, is_write=false):
	if not (file and settings.get(Settings.PYTHON_PATH)):
		return

	var filepath = ProjectSettings.globalize_path(file.resource_path)

	if is_write or filepath != last_heartbeat.filepath or enough_time_has_passed(last_heartbeat.timestamp):
		send_heartbeat(filepath, is_write)


func send_heartbeat(filepath, is_write):
	var python = settings.get(Settings.PYTHON_PATH)
	var wakatime_api_key = settings.get(Settings.WAKATIME_API_KEY)

	var heartbeat = HeartBeat.new(filepath, OS.get_unix_time(), is_write)
	var cmd = [wakatime_cli,
			   '--entity', heartbeat.filepath,
			   '--key', wakatime_api_key,
			   '--time', heartbeat.timestamp,
			   '--plugin', get_user_agent()]

	if is_write:
		cmd.append('--write')

	if not settings.get(Settings.HIDE_PROJECT_NAME):
		cmd.append('--project')
		cmd.append(ProjectSettings.get('application/config/name'))

	if settings.get(Settings.HIDE_FILENAMES):
		cmd.append('--hidefilenames')

	var includes = settings.get(Settings.INCLUDE)
	if includes:
		for include in includes:
			cmd.append('--include')
			cmd.append(include)

	var excludes = settings.get(Settings.EXCLUDE)
	if excludes:
		for exclude in excludes:
			cmd.append('--exclude')
			cmd.append(exclude)

	OS.execute(python, PoolStringArray(cmd), false, [])

	last_heartbeat = heartbeat


func enough_time_has_passed(last_sent_time):
	return OS.get_unix_time() - last_heartbeat.timestamp >= HeartBeat.FILE_MODIFIED_DELAY


# file changed
func _on_script_changed(file):
	handle_activity(file)


# file modfied
func _unhandled_key_input(ev):
	var file = get_current_file()
	handle_activity(file)


# file saved
func save_external_data():
	var file = get_current_file()
	handle_activity(file, true)


func open_api_key_modal():
	var prompt = api_key_modal.instance()
	prompt.init(self)
	add_child(prompt)
	prompt.popup_centered()
	yield(prompt, 'popup_hide')
	prompt.queue_free()


func get_user_agent():
	return 'godot/%s %s/%s' % [get_engine_version(), get_plugin_name(), get_plugin_version()]


func get_plugin_name():
	return 'godot-wakatime'


func get_plugin_version():
	return '1.3.4'


func get_engine_version():
	return '%s.%s.%s' % [Engine.get_version_info()['major'],
						 Engine.get_version_info()['minor'],
						 Engine.get_version_info()['patch']]
