tool
extends PopupDialog

onready var save_btn = $hbox_container/save_btn
onready var cancel_btn = $hbox_container/cancel_btn
onready var api_key_line_edit = $line_edit

var curr_settings = null


func _ready():
	save_btn.connect('pressed', self, '_on_confirm')
	cancel_btn.connect('pressed', self, '_on_cancel')
	api_key_line_edit.connect('text_entered', self, '_on_confirm')


func init(settings):
	self.curr_settings = settings


func _on_confirm(text=null):
	curr_settings.save_setting(curr_settings.WAKATIME_API_KEY, api_key_line_edit.text)
	hide_popup()


func _on_cancel():
	hide_popup()


func hide_popup():
	if self.visible:
		self.visible = false
	queue_free()