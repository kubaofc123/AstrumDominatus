class_name BackendConnection
extends Node

#=============================== VARIABLES ===============================

#================ PUBLIC ================

signal signal_planet_status_response(p_data : Dictionary)
signal signal_successful_operation_response(p_data : Dictionary)

const VERSION : int = 1

#================ PRIVATE ================

var _peer : StreamPeerTCP = null

#=============================== FUNCTIONS ===============================

#================ PUBLIC ================

func get_planet_status() -> void:
	# OpCode | Version
	while _peer:
		await get_tree().create_timer(0.2).timeout
		
	_peer = StreamPeerTCP.new()
	_peer.connect_to_host(Global.main.backend_address, Global.main.backend_port)
	while _peer.get_status() != StreamPeerSocket.Status.STATUS_CONNECTED:
		await get_tree().create_timer(0.5).timeout
	var __request : PackedByteArray
	__request.resize(3)
	__request.encode_u8(0, 1)			# OpCode
	__request.encode_u16(1, VERSION)		# Version
	_peer.put_data(__request)
	

func submit_successful_operation_result(p_difficulty : int) -> void:
	# OpCode | Version | Difficulty
	while _peer:
		await get_tree().create_timer(0.2).timeout
		
	_peer = StreamPeerTCP.new()
	_peer.connect_to_host(Global.main.backend_address, Global.main.backend_port)
	while _peer.get_status() != StreamPeerSocket.Status.STATUS_CONNECTED:
		await get_tree().create_timer(0.5).timeout
	var __request : PackedByteArray
	__request.resize(4)
	__request.encode_u8(0, 2)				# OpCode
	__request.encode_u16(1, VERSION)			# Version
	__request.encode_u8(3, p_difficulty)		# Difficulty
	_peer.put_data(__request)
	
#================ PRIVATE ================

func _process(delta: float) -> void:
	if not _peer:
		return
	
	_peer.poll()
	if _peer.get_status() == StreamPeerSocket.Status.STATUS_CONNECTED:
		var __bytes_available : int = _peer.get_available_bytes()
		if __bytes_available > 0:
			var __response_arr : Array = _peer.get_data(__bytes_available)
			var __bytes : PackedByteArray = __response_arr[1]
			if __bytes.size() > 0:
				# Process response
				var __op_code : int = __bytes.decode_u8(0)
				match __op_code:
					1:
						# OpCode | Result | Planet Data
						var __result : int = __bytes.decode_u8(1)
						var __planet_data = bytes_to_var(__bytes.slice(2, __bytes.size()))
						_peer.disconnect_from_host()
						_peer = null
						var __signal_dict : Dictionary
						__signal_dict["planet_data"] = __planet_data
						signal_planet_status_response.emit(__signal_dict)
						return
					2:
						# OpCode | Result | Contribution Points | Planet Data
						var __result : int = __bytes.decode_u8(1)
						var __contribution_points : int = __bytes.decode_u64(2)
						var __planet_data = bytes_to_var(__bytes.slice(10, __bytes.size()))
						_peer.disconnect_from_host()
						_peer = null
						var __signal_dict : Dictionary
						__signal_dict["contribution_points"] = __contribution_points
						__signal_dict["planet_data"] = __planet_data
						signal_successful_operation_response.emit(__signal_dict)
						return
					_:
						pass
	
#=============================== CALLBACKS ===============================

########################## END OF FILE ##########################
