tool
extends PopupPanel

onready var api_key_line_edit = $vbox_container/hbox_container_top/line_edit
onready var show_btn = $vbox_container/hbox_container_top/show_btn
onready var save_btn = $vbox_container/hbox_container_bottom/save_btn
onready var cancel_btn = $vbox_container/hbox_container_bottom/cancel_btn

var wakatime_ref = null
var settings = null


func _ready():
	if wakatime_ref:
		settings = wakatime_ref.settings

	if settings and api_key_line_edit:
		var curr_api_key = settings.get(settings.WAKATIME_API_KEY)
		if curr_api_key:
			api_key_line_edit.text = curr_api_key

	save_btn.connect('pressed', self, '_on_confirm')
	show_btn.connect('pressed', self, '_on_toggle_secret_text')
	cancel_btn.connect('pressed', self, '_on_cancel')
	api_key_line_edit.connect('text_entered', self, '_on_confirm')


func init(wakatime):
	self.wakatime_ref = wakatime


func _on_confirm(text=null):
	settings.save_setting(settings.WAKATIME_API_KEY, api_key_line_edit.text)
	hide_popup()


func _on_cancel():
	hide_popup()


func _on_toggle_secret_text():
	api_key_line_edit.secret = not api_key_line_edit.secret
	show_btn.text = 'Show' if api_key_line_edit.secret else 'Hide'


func hide_popup():
	if self.visible:
		self.visible = false
