tool

const PLUGIN_PATH = 'res://addons/wakatime'
const WAKATIME_CLI_ROOT_PATH = '%s/wakatime-cli-10.2.1' % PLUGIN_PATH
const WAKATIME_CLI_PATH = '%s/wakatime/cli.py' % WAKATIME_CLI_ROOT_PATH

const REG_PREFIX_KEYS = [
	'HKEY_CURRENT_USER',
	'HKEY_LOCAL_MACHINE',
]

const REG_PYTHON_KEYS = [
	'Software\\Python',
	'WOW6432Node\\Python',
]

const PYTHON_REG_PATH = 'Software\\Python'
const REG_LOCATIONS = 'HKEY_CURRENT_USER'


static func get_python_binary():
	var binary_path = null
	var is_windows = OS.get_name() == 'Windows'
	var paths = [
		'/',
		'/usr/local/bin',
		'/usr/bin',
	]

	if is_windows:
		paths.clear()
		var local_python_dir = _get_local_python_dir()
		if local_python_dir:
			paths.append(local_python_dir)

	for path in paths:
		binary_path = _get_python_bin_from_path(path, is_windows)
		if binary_path:
			return binary_path

	if is_windows:
		binary_path = _get_python_bin_from_windows_reg()

	if binary_path:
		print('Python found: %s' % binary_path)

	return binary_path


static func _get_local_python_dir():
	var dirs = _list_dir(PLUGIN_PATH)['directories']
	for dir in dirs:
		if 'python' in dir.to_lower():
			return '%s/%s' % [PLUGIN_PATH, dir]
	return null


static func _check_python_bin(bin):
	var f = File.new()
	if not f.file_exists(bin):
		return false

	var output = []
	OS.execute(bin, PoolStringArray(['--version']), true, output)
	return output != []


static func _get_python_bin_from_windows_reg():
	var output = []
	var reg_paths = []

	for prefix in REG_PREFIX_KEYS:
		for python_key in REG_PYTHON_KEYS:
			var reg_path = '%s\\%s\\PythonCore' % [prefix, python_key]
			OS.execute('reg', PoolStringArray(['query', reg_path]), true, output)

			for key in output:
				if not key.strip_edges():
					continue
				var version = key.strip_edges().split('\\')[-1]
				reg_paths.append('%s\\%s\\PythonCore\\%s\\InstallPath' % [prefix, python_key, version])

	for path in reg_paths:
		OS.execute('reg', PoolStringArray(['query', path, '/v', 'ExecutablePath']), true, output)
		for key in output:
			if not key.strip_edges():
				continue
			var bin = key.strip_edges().split(' ', false)[-1]
			if bin.ends_with('.exe') and _check_python_bin(bin):
				return bin

	return null


static func _get_python_bin_from_path(path, is_windows):
	var suffix = 'w' if is_windows else ''

	var regex = RegEx.new()
	regex.compile('^python%s(\\d\\.\\d)?(\\.exe)?$' % suffix)

	var binaries = []

	var files = _list_dir(path)['files']
	for file_name in files:
		var r = regex.search(file_name)
		if r:
			var full_path = '%s/%s' % [path, r.get_string()]
			binaries.append(ProjectSettings.globalize_path(full_path))

	binaries.sort()
	binaries.invert()

	for bin in binaries:
		if _check_python_bin(bin):
			return bin

	return null


static func _list_dir(path):
	var dir = Directory.new()
	var result = {
		'files': [],
		'directories': []
	}

	dir.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while (file_name != ""):
		if dir.current_is_dir():
			result['directories'].append(file_name)
		else:
			result['files'].append(file_name)
		file_name = dir.get_next()

	return result
