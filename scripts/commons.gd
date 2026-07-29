class_name Commons
extends RefCounted

static func blend(a: Variant, b: Variant, factor: float, speed: float, delta: float) -> Variant:
	var weight = 1.0 - pow(1.0 - factor, delta / speed)
	return lerp(a, b, weight)
