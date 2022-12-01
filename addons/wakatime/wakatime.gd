@tool
extends EditorPlugin

const HeartBeat = preload('res://addons/wakatime/heartbeat.gd')
const Settings = preload('res://addons/wakatime/settings.gd')

const PLUGIN_PATH = 'res://addons/wakatime'
const WAKATIME_ZIP_FILEPATH = '%s/wakatime.zip' % PLUGIN_PATH

const WAKATIME_URL_FMT = 'https://github.com/wakatime/wakatime-cli/releases/download/v1.54.0/{wakatime_build}.zip'
const DECOMPRESSOR_URL_FMT = 'https://github.com/ouch-org/ouch/releases/download/0.3.1/{ouch_build}'

var last_heartbeat = HeartBeat.new()

var wakatime_dir = ''
var wakatime_cli = ''
var decompressor_cli = ''

var api_key_modal = preload('res://addons/wakatime/api_key_modal.tscn')
var bottom_panel_scn = preload('res://addons/wakatime/bottom_panel.tscn')
var bottom_panel = null
var settings = null

var is_windows = OS.has_feature('windows') or OS.has_feature('uwp')
var is_linux = OS.has_feature('linux')
var is_macos = OS.has_feature('macos')
var is_amd64 = OS.has_feature('x86_64')
var is_arm64 = OS.has_feature('arm64')

func _exit_tree():
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.editor_script_changed.disconnect(self._on_script_changed)
	remove_control_from_bottom_panel(bottom_panel)

func get_wakatime_build():
	# Default system = Linux
	var platform = 'linux'
	if is_windows:
		platform = 'windows'
	elif is_macos:
		platform = 'darwin'

	# Default architecture = x86_64 (amd64)
	var architecture = 'amd64'
	if is_amd64:
		architecture = 'amd64'
	elif is_arm64:
		architecture = 'arm64'

	return 'wakatime-cli-%s-%s' % [platform, architecture]

func get_ouch_build():
	# Default system = Linux
	var platform = 'linux-musl'
	if is_windows:
		platform = 'pc-windows-msvc'
	elif is_macos:
		platform = 'apple-darwin'

	return 'ouch-%s-%s' % ['x86_64', platform]


func get_wakatime_directory():
	if wakatime_dir == '':
		wakatime_dir = '%s/.wakatime' % get_home_directory()

	return wakatime_dir


func get_wakatime_cli():
	if wakatime_cli == '':
		var build = get_wakatime_build()
		var ext = '.exe' if is_windows else ''
		wakatime_cli = '%s/%s%s' % [get_wakatime_directory(), build, ext]

	return wakatime_cli


func get_decompressor_cli():
	if decompressor_cli == '':
		var build = get_ouch_build()
		var ext = '.exe' if is_windows else ''
		decompressor_cli = '%s/%s%s' % [PLUGIN_PATH, build, ext]

	print("Decompressor: %s" % decompressor_cli)
	return decompressor_cli


func get_home_directory():
	var home = null
	for env in ['WAKATIME_HOME', 'USERPROFILE', 'HOME']:
		home = OS.get_environment(env)
		if home:
			if is_windows:
				home = home.replace('\\', '/')
			return home

	return PLUGIN_PATH


func has_decompression_lib():
	return FileAccess.file_exists(get_decompressor_cli())


func has_wakatime_cli():
	return FileAccess.file_exists(get_wakatime_cli())


func has_wakatime_zip():
	return FileAccess.file_exists(WAKATIME_ZIP_FILEPATH)


func download_decompressor():
	pprint('Downloading Ouch! (decompression lib)...')
	var url = DECOMPRESSOR_URL_FMT.format({'ouch_build': get_ouch_build()})
	if is_windows:
		url = '%s.exe' % url

	var http = HTTPRequest.new()
	http.download_file = get_decompressor_cli()
	http.request_completed.connect(self._decompressor_download_completed)
	add_child(http)

	var error = http.request(url)
	if error != OK:
		pprint_error('Failed to download decompression lib: %s' % error)


func _decompressor_download_completed(result, status_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		pprint_error('Failed to download decompression lib')
		return

	if !has_decompression_lib():
		pprint_error('Failed to save decompression lib')
		return

	var decompressor = ProjectSettings.globalize_path(get_decompressor_cli())
	if is_linux or is_macos:
		var errors = []
		OS.execute('chmod', ['+x', decompressor], errors, true)

	pprint('Ouch! download completed. Saved at %s' % get_decompressor_cli())

	extract_files(WAKATIME_ZIP_FILEPATH, get_wakatime_directory())


func download_wakatime():
	pprint('Downloading Wakatime CLI...')
	var url = WAKATIME_URL_FMT.format({'wakatime_build': get_wakatime_build()})

	var http = HTTPRequest.new()
	http.download_file = WAKATIME_ZIP_FILEPATH
	http.request_completed.connect(self._wakatime_download_completed)
	add_child(http)

	var error = http.request(url)
	if error != OK:
		pprint_error('Failed to download Wakatime CLI: %s' % error)


func _wakatime_download_completed(result, status_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		pprint_error('Failed to download Wakatime')
		return

	pprint('Wakatime download completed. Saved at %s' % WAKATIME_ZIP_FILEPATH)

	extract_files(WAKATIME_ZIP_FILEPATH, get_wakatime_directory())


func extract_files(source_file, output_dir):
	# Both decompression lib and Wakatime zip downloads must be complete
	if not (has_decompression_lib() and has_wakatime_zip()):
		return

	pprint('Extracting files from Wakatime zip')
	var decompressor = ProjectSettings.globalize_path(get_decompressor_cli())
	var source = ProjectSettings.globalize_path(source_file)
	var destination = ProjectSettings.globalize_path(output_dir)
	var errors = []
	var args = ['--yes', 'decompress', source, '--dir', destination]
	var error = OS.execute(decompressor, args, errors, true, true)
	if error:
		pprint_error(errors)
		return

	if has_wakatime_cli():
		pprint('Wakatime CLI installed at %s' % get_wakatime_cli())
	else:
		pprint_error('Failed to install Wakatime CLI')

	# Remove unnecessary files
	pprint('Cleaning downloaded files')
	clean_downloaded_files()


func clean_downloaded_files():
	if has_wakatime_zip():
		delete_file(WAKATIME_ZIP_FILEPATH)

	if has_decompression_lib():
		delete_file(get_decompressor_cli())


func delete_file(path):
	var dir = DirAccess.new()
	var error = dir.remove(path)
	if error != OK:
		pprint_error('Failed to remove %s' % path)
	else:
		pprint('File %s removed' % path)


func check_dependencies():
	if has_wakatime_cli():
		return

	download_wakatime()

	if !has_decompression_lib():
		download_decompressor()


func check_old_plugin_version_installed():
	var old_versions = ['wakatime-cli-10.1.0', 'wakatime-cli-10.2.1']

	var version_installed = null
	for cli_version in old_versions:
		var wakatime_cli_dir = '%s/%s' % [PLUGIN_PATH, cli_version]
		if DirAccess.dir_exists_absolute(wakatime_cli_dir):
			version_installed = wakatime_cli_dir

	if version_installed == null:
		return

	pprint('Deleting old Wakatime CLI version: %s' % version_installed)
	delete_recursive(version_installed)


func delete_recursive(path):
	var directory = DirAccess.open(path)
	if directory != null:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != '':
			if directory.current_is_dir():
				delete_recursive('%s/%s' % [path, file_name])
			else:
				directory.remove(file_name)
			file_name = directory.get_next()

		# Remove current path
		directory.remove(path)
	else:
		pprint_error('Failed to remove %s' % path)


func setup_plugin():
	pprint('Initializing %s plugin...' % get_user_agent())

	check_old_plugin_version_installed()

	check_dependencies()

	# Load all settings from .cfg file
	settings = Settings.new()

	# Check wakatime api key
	if settings.get(Settings.WAKATIME_API_KEY) == '':
		open_api_key_modal()

	await get_tree().process_frame

	# Register editor changed callback
	var script_editor = get_editor_interface().get_script_editor()
	script_editor.editor_script_changed
	script_editor.call_deferred('connect', 'editor_script_changed', Callable(self, '_on_script_changed'))

	# Build Wakatime panel
	bottom_panel = bottom_panel_scn.instantiate()
	add_control_to_bottom_panel(bottom_panel, 'Wakatime')


func _ready():
	setup_plugin()


func get_current_file():
	return get_editor_interface().get_script_editor().get_current_script()


func handle_activity(file, is_write=false):
	if not (file and has_wakatime_cli()):
		return

	var filepath = ProjectSettings.globalize_path(file.resource_path)

	if is_write or filepath != last_heartbeat.filepath or enough_time_has_passed(last_heartbeat.timestamp):
		send_heartbeat(filepath, is_write)


func send_heartbeat(filepath, is_write):

	var wakatime_api_key = settings.get(Settings.WAKATIME_API_KEY)
	var heartbeat = HeartBeat.new(filepath, Time.get_unix_time_from_system(), is_write)

	var cmd = [
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
		cmd.append('--hide-file-names')

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
	OS.execute(wakatime_cli, PackedStringArray(cmd), [])

	last_heartbeat = heartbeat


func enough_time_has_passed(last_sent_time):
	return Time.get_unix_time_from_system() - last_heartbeat.timestamp >= HeartBeat.FILE_MODIFIED_DELAY


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
	var prompt = api_key_modal.instantiate()
	prompt.init(self)
	add_child(prompt)
	prompt.popup_centered()
	await prompt.popup_hide
	prompt.queue_free()


func pprint(message):
	print('[godot-wakatime] %s' % message)


func pprint_error(message):
	push_error('[godot-wakatime] %s' % message)


func get_user_agent():
	return 'godot/%s %s/%s' % [get_engine_version(), get_plugin_name(), get_plugin_version()]


func get_plugin_name():
	return 'godot-wakatime'


func get_plugin_version():
	return '1.4.0'


func get_engine_version():
	return '%s.%s.%s' % [   Engine.get_version_info()['major'],
							Engine.get_version_info()['minor'],
							Engine.get_version_info()['patch']]
