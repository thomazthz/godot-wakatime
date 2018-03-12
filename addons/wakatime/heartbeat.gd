const FILE_MODIFIED_DELAY = 120

var filepath
var timestamp
var is_write

func _init(filepath = '', timestamp = 0, is_write = false):
	self.filepath = filepath
	self.timestamp = timestamp
	self.is_write = is_write
