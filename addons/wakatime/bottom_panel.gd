tool
extends Control

onready var btn_api_key = $hbox_container/btn_api_key
onready var cb_proj_name = $hbox_container/vbox_container_01/cb_hide_project_name
onready var cb_filenames = $hbox_container/vbox_container_01/cb_hide_filenames
onready var ledit_include = $hbox_container/panel_include/ledit_include
onready var ledit_exclude = $hbox_container/panel_exclude/ledit_exclude

var api_key_modal = preload('res://addons/wakatime/api_key_modal.tscn')
var curr_settings = null


func init(settings):
	self.curr_settings = settings

	cb_proj_name.pressed = curr_settings.get(curr_settings.HIDE_PROJECT_NAME) or false
	cb_filenames.pressed = curr_settings.get(curr_settings.HIDE_FILENAMES) or false

	btn_api_key.connect('pressed', self, '_on_btn_pressed')
	cb_proj_name.connect('toggled', self, '_on_flag_change', [curr_settings.HIDE_PROJECT_NAME])
	cb_filenames.connect('toggled', self, '_on_flag_change', [curr_settings.HIDE_FILENAMES])

	ledit_include.connect('text_entered', self, '_on_text_enter', ['include'])
	ledit_exclude.connect('text_entered', self, '_on_text_enter', ['exclude'])


func _on_btn_pressed():
	var prompt = api_key_modal.instance()
	prompt.init(curr_settings)
	add_child(prompt)
	prompt.popup_centered()


func _on_flag_change(is_pressed, key):
	curr_settings.save_setting(key, is_pressed)


func _on_text_enter(text, key):
	curr_settings.save_setting(key, text)

