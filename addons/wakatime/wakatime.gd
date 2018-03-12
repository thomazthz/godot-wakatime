tool
extends EditorPlugin

const HeartBeat = preload('res://addons/wakatime/heartbeat.gd')
var last_heartbeat = HeartBeat.new()

var Utils = preload('res://addons/wakatime/utils.gd')

var wakatime_cli = ProjectSettings.globalize_path(Utils.WAKATIME_CLI_PATH)
var python = null
var wakatime_api_key = null
var api_key_modal = preload('res://addons/wakatime/api_key_modal.tscn')


func _enter_tree():
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.connect('editor_script_changed', self, '_on_script_changed')


func _exit_tree():
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.disconnect('editor_script_changed', self, '_on_script_changed')


func _ready():
	wakatime_api_key = Utils.load_settings('wakatime-api-key')
	if not wakatime_api_key:
		prompt_api_key()


func prompt_api_key():
	var prompt = api_key_modal.instance()
	prompt.connect('api_key_changed', self, '_on_api_key_changed')
	add_child(prompt)
	prompt.popup_centered()


func get_state():
	if not python:
		python = Utils.get_python_binary()
	if not wakatime_api_key:
		wakatime_api_key = Utils.load_settings('wakatime-api-key')
	return {'python': python, 'wakatime-api-key': wakatime_api_key}


func set_state(state):
	if state.has('python'):
		python = state['python']
	if state.has('wakatime-api-key'):
		wakatime_api_key = 'wakatime-api-key'


func get_current_file():
	return get_editor_interface().get_script_editor().get_current_script()


func handle_activity(file, is_write=false):
	if not (file and python):
		return

	var filepath = ProjectSettings.globalize_path(file.resource_path)

	if is_write or filepath != last_heartbeat.filepath or enough_time_has_passed(last_heartbeat.timestamp):
		send_heartbeat(filepath, is_write)


func send_heartbeat(filepath, is_write):
	var heartbeat = HeartBeat.new(filepath, OS.get_unix_time(), is_write)
	var cmd = [wakatime_cli,
			   '--entity', heartbeat.filepath,
			   '--key', wakatime_api_key,
			   '--time', heartbeat.timestamp,
			   '--project', ProjectSettings.get('application/config/name'),
			   '--plugin', get_user_agent()]

	if is_write:
		cmd.append('--write')

	var output = []
	OS.execute(python, cmd, false, output)

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


func _on_api_key_changed(new_api_key):
	wakatime_api_key = new_api_key


func get_user_agent():
	return 'godot/%s %s/%s' % [get_engine_version(), get_plugin_name(), get_plugin_version()]


func get_plugin_name():
	return 'godot-wakatime'


func get_plugin_version():
	return '1.0.0'


func get_engine_version():
	return '%s.%s.%s' % [Engine.get_version_info()['major'],
						 Engine.get_version_info()['minor'],
						 Engine.get_version_info()['patch']]
