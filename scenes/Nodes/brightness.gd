extends PixflowNode

@export_range(-1.0, 1.0) var brightness: float = 0.0
@onready var texture_rect = $TextureRect

func _ready() -> void:
	node_type = "Brightness"

func update(input_image: Image) -> Image:
	if not input_image:
		push_error("Input image is null")
		return
	var image = input_image.duplicate()
	image.convert(Image.FORMAT_RGB8)

	for y in image.get_height():
		for x in image.get_width():
			var c = image.get_pixel(x, y)
			var new_c = Color(clamp(c.r + brightness, 0, 1),
							  clamp(c.g + brightness, 0, 1),
							  clamp(c.b + brightness, 0, 1),
							  c.a)
			image.set_pixel(x, y, new_c)

	var thumb = image.duplicate()
	var scale = float(TARGET_IMAGE_HEIGHT) / float(thumb.get_height())
	thumb.resize(int(thumb.get_width() * scale), TARGET_IMAGE_HEIGHT, Image.INTERPOLATE_LANCZOS)
	texture_rect.texture = ImageTexture.create_from_image(thumb)

	return image

func _on_h_slider_value_changed(value: float) -> void:
	brightness = value
	$RichTextLabel.text = str(value)
	get_parent().get_parent().execute_graph_bfs()
