tool
extends PopupPanel

onready var api_key_line_edit = $vbox_container/hbox_container_top/line_edit
onready var show_btn = $vbox_container/hbox_container_top/show_btn
onready var save_btn = $vbox_container/hbox_container_bottom/save_btn
onready var cancel_btn = $vbox_container/hbox_container_bottom/cancel_btn

var curr_settings = null


func _ready():
	save_btn.connect('pressed', self, '_on_confirm')
	show_btn.connect('pressed', self, '_on_toggle_secret_text')
	cancel_btn.connect('pressed', self, '_on_cancel')
	api_key_line_edit.connect('text_entered', self, '_on_confirm')

	if curr_settings and api_key_line_edit:
		var curr_api_key = curr_settings.get(curr_settings.WAKATIME_API_KEY)
		api_key_line_edit.text = curr_api_key


func init(settings):
	curr_settings = settings


func _on_confirm(text=null):
	curr_settings.save_setting(curr_settings.WAKATIME_API_KEY, api_key_line_edit.text)
	hide_popup()


func _on_cancel():
	hide_popup()


func _on_toggle_secret_text():
	api_key_line_edit.secret = not api_key_line_edit.secret
	show_btn.text = 'Show' if api_key_line_edit.secret else 'Hide'


func hide_popup():
	if self.visible:
		self.visible = false
	queue_free()