extends GraphNode

@export var TARGET_IMAGE_HEIGHT = 200
@export var image: Image

@onready var texture_rect = $TextureRect

func update(input_image: Image) -> Image:
	# Make a copy to avoid modifying the original input
	image = input_image.duplicate()
	image.convert(Image.FORMAT_RGB8)  # Ensure it's in a modifiable format

	for y in image.get_height():
		for x in image.get_width():
			var color = image.get_pixel(x, y)
			var gray = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			image.set_pixel(x, y, Color(gray, gray, gray, color.a))
	
	var thumb = image.duplicate()
	var target_height: int = TARGET_IMAGE_HEIGHT
	var scale: float = float(target_height) / float(thumb.get_height())
	var target_width = int(thumb.get_width() * scale)
	thumb.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)

	var preview_texture = ImageTexture.create_from_image(thumb)
	texture_rect.texture = preview_texture
	
	return image
