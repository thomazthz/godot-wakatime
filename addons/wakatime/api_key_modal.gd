tool
extends PopupDialog

signal api_key_changed(api_key)

onready var save_btn = $save_btn
onready var cancel_btn = $cancel_btn
onready var api_key_line_edit = $line_edit

const Utils = preload('res://addons/wakatime/utils.gd')


func _ready():
	save_btn.connect('pressed', self, '_on_confirm')
	cancel_btn.connect('pressed', self, '_on_cancel')
	api_key_line_edit.connect('text_entered', self, '_on_confirm')


func _on_confirm(text=null):
	Utils.save_settings('wakatime-api-key', api_key_line_edit.text)
	emit_signal('api_key_changed', api_key_line_edit.text)
	hide_popup()


func _on_cancel():
	hide_popup()


func hide_popup():
	if self.visible:
		self.visible = false
	queue_free()