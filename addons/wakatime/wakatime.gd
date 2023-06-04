@tool
extends EditorPlugin

const HeartBeat = preload('res://addons/wakatime/heartbeat.gd')

const PLUGIN_PATH = 'res://addons/wakatime'
const WAKATIME_ZIP_FILEPATH = '%s/wakatime.zip' % PLUGIN_PATH

const WAKATIME_URL_FMT = 'https://github.com/wakatime/wakatime-cli/releases/download/v1.54.0/{wakatime_build}.zip'
const DECOMPRESSOR_URL_FMT = 'https://github.com/ouch-org/ouch/releases/download/0.3.1/{ouch_build}'

const API_KEY_MENU_ITEM_NAME = 'Wakatime API Key'
const CONFIG_MENU_ITEM_NAME = 'Wakatime Config File'

var last_heartbeat = HeartBeat.new()

var wakatime_dir = null
var wakatime_cli = null
var decompressor_cli = null

const ApiKeyPrompt = preload('res://addons/wakatime/api_key_prompt.tscn')

var is_windows = OS.has_feature('windows') or OS.has_feature('uwp')
var is_linux = OS.has_feature('linux')
var is_macos = OS.has_feature('macos')
var is_amd64 = OS.has_feature('x86_64')
var is_arm64 = OS.has_feature('arm64')

var debug = false


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


func get_wakatime_directory() -> String:
    if wakatime_dir == null:
        wakatime_dir = '%s/.wakatime' % get_home_directory()

    return wakatime_dir


func get_wakatime_cli() -> String:
    if wakatime_cli == null:
        var build = get_wakatime_build()
        var ext = '.exe' if is_windows else ''
        wakatime_cli = '%s/%s%s' % [get_wakatime_directory(), build, ext]

    return wakatime_cli


func get_decompressor_cli() -> String:
    if decompressor_cli == null:
        var build = get_ouch_build()
        var ext = '.exe' if is_windows else ''
        decompressor_cli = '%s/%s%s' % [PLUGIN_PATH, build, ext]

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


func get_config_filepath() -> String:
    return '%s/.wakatime.cfg' % get_home_directory()


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
    http.connect('request_completed', Callable(self, '_decompressor_download_completed'))
    add_child(http)

    var error = http.request(url)
    if error != OK:
        disable_plugin()
        pprint_error('Failed to download decompression lib: %s' % error)


func _decompressor_download_completed(result, status_code, headers, body):
    if result != HTTPRequest.RESULT_SUCCESS:
        pprint_error('Failed to download decompression lib')
        disable_plugin()
        return

    if !has_decompression_lib():
        pprint_error('Failed to save decompression lib')
        disable_plugin()
        return

    var decompressor = ProjectSettings.globalize_path(get_decompressor_cli())
    if is_linux or is_macos:
        OS.execute('chmod', ['+x', decompressor], [], true)

    pprint('Ouch! download completed. Saved at %s' % get_decompressor_cli())

    extract_files(WAKATIME_ZIP_FILEPATH, get_wakatime_directory())


func download_wakatime():
    pprint('Downloading Wakatime CLI...')
    var url = WAKATIME_URL_FMT.format({'wakatime_build': get_wakatime_build()})

    var http = HTTPRequest.new()
    http.download_file = WAKATIME_ZIP_FILEPATH
    http.connect('request_completed', Callable(self, '_wakatime_download_completed'))
    add_child(http)

    var error = http.request(url)
    if error != OK:
        pprint_error('Failed to download Wakatime CLI: %s' % error)
        disable_plugin()


func _wakatime_download_completed(result, status_code, headers, body):
    if result != HTTPRequest.RESULT_SUCCESS:
        pprint_error('Failed to download Wakatime')
        disable_plugin()
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
    var error = OS.execute(decompressor, args, errors, true)
    if error:
        pprint_error(errors)
        disable_plugin()
        return

    if has_wakatime_cli():
        pprint('Wakatime CLI installed at %s' % get_wakatime_cli())
    else:
        disable_plugin()
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
    var dir = DirAccess.open('res://')
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

func get_api_key():
    var output = []
    var err = OS.execute(get_wakatime_cli(), ['--config-read', 'api_key'], output)
    if err == -1:
        return null

    var api_key = output[0].strip_edges()
    if api_key.is_empty():
        return null

    return api_key


func request_api_key():
    var prompt = ApiKeyPrompt.instantiate()
    _set_api_key_on_prompt(prompt, get_api_key())
    _register_api_key_signals(prompt)
    add_child(prompt)
    prompt.popup_centered()
    await prompt.popup_hide
    prompt.queue_free()


func open_config_file():
    OS.shell_open(get_config_filepath())


func setup_plugin():
    pprint('Initializing %s plugin.' % get_user_agent())

    check_dependencies()

    var api_key = get_api_key()
    if api_key == null:
        request_api_key()

    await get_tree().process_frame

    # Adds tool menu item command to open API key prompt
    add_tool_menu_item(API_KEY_MENU_ITEM_NAME, request_api_key)
    # Adds tool menu item command to open global WakaTime config file
    add_tool_menu_item(CONFIG_MENU_ITEM_NAME, open_config_file)
    # Register editor changed callback
    var script_editor = get_editor_interface().get_script_editor()
    script_editor.call_deferred('connect', 'editor_script_changed', Callable(self, '_on_script_changed'))


func _disable_plugin():
    remove_tool_menu_item(API_KEY_MENU_ITEM_NAME)
    remove_tool_menu_item(CONFIG_MENU_ITEM_NAME)
    var script_editor = get_editor_interface().get_script_editor()
    if script_editor.is_connected('editor_script_changed', Callable(self, '_on_script_changed')):
        script_editor.disconnect('editor_script_changed', Callable(self, '_on_script_changed'))


func _ready():
    setup_plugin()


func _exit_tree():
    _disable_plugin()


func get_current_file():
    return get_editor_interface().get_script_editor().get_current_script()


func handle_activity(file, is_write=false):
    if not (file and has_wakatime_cli()):
        return

    var filepath = ProjectSettings.globalize_path(file.resource_path)

    if is_write or filepath != last_heartbeat.filepath or enough_time_has_passed(last_heartbeat.timestamp):
        send_heartbeat(filepath, is_write)


func _send_heartbeat(cmd_args):
    if wakatime_cli == null:
        wakatime_cli = get_wakatime_cli()

    var output = []
    var exit_code = OS.execute(wakatime_cli, cmd_args, output, true)
    if debug:
        if exit_code == -1:
            pprint('Failed to send heartbeat: %s' % output)
        else:
            pprint('Heartbeat sent: %s' % output)


func send_heartbeat(filepath, is_write):
    var wakatime_api_key = get_api_key()
    if wakatime_api_key == null:
        pprint_error('Failed to get API key')
        return

    var heartbeat = HeartBeat.new(filepath, Time.get_unix_time_from_system(), is_write)
    var cmd = ['--entity', heartbeat.filepath,
               '--key', wakatime_api_key,
               '--plugin', get_user_agent()]

    if is_write:
        cmd.append('--write')

    cmd.append('--project')
    cmd.append(ProjectSettings.get('application/config/name'))

    var cmd_callable = Callable(self, '_send_heartbeat').bind(cmd)
    WorkerThreadPool.add_task(cmd_callable)

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
func _save_external_data():
    var file = get_current_file()
    handle_activity(file, true)


func _set_api_key_on_prompt(instance: PopupPanel, api_key):
    if api_key == null:
        api_key = ''
    var text_edit = instance.get_node('vbox_container/hbox_container_top/line_edit')
    text_edit.text = api_key


func _register_api_key_signals(instance: PopupPanel):
    var show_btn = instance.get_node('vbox_container/hbox_container_top/show_btn')
    var save_btn = instance.get_node('vbox_container/hbox_container_bottom/save_btn')
    var text_edit = instance.get_node('vbox_container/hbox_container_top/line_edit')

    show_btn.connect('pressed', Callable(self, '_on_toggle_secret_text').bind(instance))
    save_btn.connect('pressed', Callable(self, '_on_save_api_key').bind(instance))
    instance.connect('popup_hide', Callable(self, '_on_popup_hide').bind(instance))


func disable_plugin():
    pprint_error('Disabling wakatime-godot plugin due some setup error. ' \
                 + 'Check your internet connection and reload the plugin')
    get_editor_interface().call_deferred('set_plugin_enabled', 'wakatime', false)


func _on_popup_hide(prompt: PopupPanel):
    prompt.queue_free()


func _on_toggle_secret_text(prompt: PopupPanel):
    var text_edit = prompt.get_node('vbox_container/hbox_container_top/line_edit')
    var show_btn = prompt.get_node('vbox_container/hbox_container_top/show_btn')

    text_edit.secret = not text_edit.secret
    show_btn.text = 'Show' if text_edit.secret else 'Hide'


func _on_save_api_key(prompt: PopupPanel):
    var text_edit = prompt.get_node('vbox_container/hbox_container_top/line_edit')
    var api_key = text_edit.text.strip_edges()
    var err = OS.execute(get_wakatime_cli(), ['--config-write', 'api_key=%s' % api_key])
    if err == -1:
        pprint_error('Failed to save API key')

    prompt.visible = false


func pprint(message):
    print('[godot-wakatime] %s' % message)


func pprint_error(message):
    push_error('[godot-wakatime] %s' % message)


func get_user_agent():
    return 'godot/%s %s/%s' % [get_engine_version(), _get_plugin_name(), get_plugin_version()]


func _get_plugin_name():
    return 'godot-wakatime'


func get_plugin_version():
    return '1.5.0'


func get_engine_version():
    return '%s.%s.%s' % [	Engine.get_version_info()['major'],
                            Engine.get_version_info()['minor'],
                            Engine.get_version_info()['patch']]
