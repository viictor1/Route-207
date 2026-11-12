class_name ProceduralTextures
extends RefCounted


const SIZE := 64

const _ASPHALT := Color(0.113, 0.119, 0.133)
const _DIRT := Color(0.247, 0.212, 0.161)
const _ROCK := Color(0.318, 0.310, 0.336)

static var _cache: Dictionary = {}


static func asphalt() -> Texture2D:
	return _texture("asphalt")


static func dirt() -> Texture2D:
	return _texture("dirt")


static func rock() -> Texture2D:
	return _texture("rock")


static func _texture(kind: String) -> Texture2D:
	if not _cache.has(kind):
		_cache[kind] = _build(kind)
	return _cache[kind]


static func _build(kind: String) -> Texture2D:
	var fine := _noise(0.18, 11)
	var coarse := _noise(0.055, 22)
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			var f := fine.get_pixel(x, y).r
			var c := coarse.get_pixel(x, y).r
			image.set_pixel(x, y, _shade(kind, f, c))
	return ImageTexture.create_from_image(image)


static func _noise(frequency: float, seed_value: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_octaves = 3
	return noise.get_seamless_image(SIZE, SIZE)


static func _shade(kind: String, fine: float, coarse: float) -> Color:
	match kind:
		"asphalt":
			var value := _ASPHALT.lightened(0.035 * fine + 0.02 * coarse)
			if fine > 0.74:
				value = value.lightened(0.09)
			return value
		"dirt":
			return _DIRT.darkened(0.09 * (1.0 - fine)).lightened(0.05 * coarse)
		"rock":
			return _ROCK.lightened(0.07 * fine).darkened(0.07 * (1.0 - coarse))
	return Color.MAGENTA
