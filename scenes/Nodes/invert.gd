extends PixflowNode

@onready var texture_rect = $TextureRect

func _ready() -> void:
	node_type = "Invert"

func update(input_image: Image) -> Image:
	if not input_image:
		push_error("Input image is null")
		return
	var image = input_image.duplicate()
	image.convert(Image.FORMAT_RGB8)

	for y in image.get_height():
		for x in image.get_width():
			var c = image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1.0 - c.r, 1.0 - c.g, 1.0 - c.b, c.a))

	var thumb = image.duplicate()
	var scale = float(TARGET_IMAGE_HEIGHT) / float(thumb.get_height())
	thumb.resize(int(thumb.get_width() * scale), TARGET_IMAGE_HEIGHT, Image.INTERPOLATE_LANCZOS)
	texture_rect.texture = ImageTexture.create_from_image(thumb)

	return image
