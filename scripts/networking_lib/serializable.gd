class_name Serializable 
extends Resource

@export var serialization_info: Array[SerializationInfo]

func _init(p_serialization_info: Array[SerializationInfo] = []):
	self.serialization_info = p_serialization_info
	

func encode_sub_byte(p_value: int, p_bits: int, p_buf: PackedByteArray, p_bit_offset: int):
	@warning_ignore("integer_division")
	var byte_offset := p_bit_offset / 8
	var bit_index := p_bit_offset % 8
	while p_bits > 0:
		var bits_to_write := mini(p_bits, 8) - bit_index
		var byte_mask := (0b1 << bits_to_write)-1
		var scratch_mask := ~(byte_mask << bit_index)
		var scratch := p_buf.decode_u8(byte_offset) & scratch_mask
		scratch |= p_value & byte_mask << bit_index
		p_buf.encode_u8(byte_offset, scratch)
		p_bit_offset += bits_to_write
		byte_offset += 1
		p_bits -= bits_to_write
		p_value >>= bits_to_write
		bit_index = p_bit_offset % 8

func compress_float(p_value: float, p_info: FloatInfo) -> int:
	var normalized_value := (p_value - p_info.min_value) * p_info.inv_diff # normalize the value to the range [0,1]
	return floori(normalized_value * (p_info.resolution)) # map to the set {0, 1, ..., resolution }

func serialize_float(p_value: float, p_info: FloatInfo, p_buf: PackedByteArray, p_bit_offset: int) -> int:
	p_value = clampf(p_value, p_info.min_value, p_info.max_value)
	var compressed_float := compress_float(p_value, p_info)
	encode_sub_byte(compressed_float, p_info.num_bits, p_buf, p_bit_offset)
	return p_info.num_bits
	
func deserialize_float(p_info: FloatInfo, p_buf: PackedByteArray, p_bit_offet: int):
	pass

func serialize_int(p_value: int, p_info: IntInfo, p_buf: PackedByteArray, p_bit_offset: int) -> int:
	p_value = clampi(p_value, p_info.min_value, p_info.max_value)
	var shifted_int := p_value - p_info.min_value
	encode_sub_byte(shifted_int, p_info.num_bits, p_buf, p_bit_offset)
	return p_info.num_bits

func serialize_bool(p_value: bool, p_buf: PackedByteArray, p_bit_offset: int) -> int:
	encode_sub_byte(1 if p_value else 0, 1, p_buf, p_bit_offset)
	return 1

func serialize_vector3(p_value: Vector3, p_info: Vector3Info, p_buf: PackedByteArray, p_bit_offset: int) -> int:
	var ret: int = 0
	for val in p_value:
		p_bit_offset += serialize_float(val, p_info.info, p_buf, p_bit_offset)
		ret += p_info.info.num_bits
	return ret

func serialize_quaternion(p_value: Quaternion, p_info: QuaternionInfo, p_buf: PackedByteArray, p_bit_offset: int) -> int:
	p_bit_offset += serialize_float(p_value.x, p_info.float_info, p_buf, p_bit_offset)
	p_bit_offset += serialize_float(p_value.y, p_info.float_info, p_buf, p_bit_offset)
	p_bit_offset += serialize_float(p_value.z, p_info.float_info, p_buf, p_bit_offset)
	p_bit_offset += serialize_float(p_value.w, p_info.float_info, p_buf, p_bit_offset)
	return p_info.float_info.num_bits * 4

func serialize(p_obj: Object, p_buf: PackedByteArray, p_bit_offset: int):
	for field in self.serialization_info:
		assert(field.name in p_obj, "[ERROR] Attempted to serialize %s but failed to find field %s " % [p_obj.get_meta("name", "Unknown"), field.name])
		match typeof(p_obj[field.name]):
			TYPE_FLOAT:
				p_bit_offset += serialize_float(p_obj[field.name], field, p_buf, p_bit_offset)
			TYPE_INT:
				p_bit_offset += serialize_int(p_obj[field.name], field, p_buf, p_bit_offset)
			TYPE_BOOL:
				p_bit_offset += serialize_bool(p_obj[field.name], p_buf, p_bit_offset)
			TYPE_VECTOR3:
				p_bit_offset += serialize_vector3(p_obj[field.name], field, p_buf, p_bit_offset)
			TYPE_QUATERNION:
				p_bit_offset += serialize_quaternion(p_obj[field.name], field, p_buf, p_bit_offset)
			TYPE_ARRAY:
				pass
			TYPE_STRING:
				pass
			TYPE_OBJECT:
				pass
	
	var_to_bytes()
