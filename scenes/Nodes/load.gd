extends PixflowNode

@onready var file_dialog = $FileDialog
@onready var texture_rect = $TextureRect

func _ready() -> void:
	node_type = "Load"
	image = Image.new()
	var err = image.load("res://icon.svg")
	if err != OK:
		push_error("Failed to load image from: res://icon.svg")
		return

func _on_menu_button_pressed() -> void:
	file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	var selected_image = Image.new()
	var err = selected_image.load(path)
	if err != OK:
		push_error("Failed to load image from: " + path)
		return

	image = selected_image.duplicate()  # Store full-res image

	# Resize thumbnail to height 100, keeping aspect ratio
	var thumb = image.duplicate()
	var target_height: int = TARGET_IMAGE_HEIGHT
	var scale: float = float(target_height) / float(thumb.get_height())
	var target_width = int(thumb.get_width() * scale)
	thumb.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)

	var preview_texture = ImageTexture.create_from_image(thumb)
	texture_rect.texture = preview_texture
	
	get_parent().get_parent().execute_graph_bfs()
