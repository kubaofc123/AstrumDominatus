class_name EngineScriptLibrary

class utility:
	static func get_os_process_running_count(process_name) -> int:
		if OS.get_name() == "Windows": # Verify that we are on Windows
			var output = []
			# Execute "get-process" in powershell and save data in "output":
			var argument = []
			argument.append('/C')
			argument.append(str("get-process ", process_name, " | measure-object -line | select Lines -expandproperty Lines"))
			OS.execute('powershell.exe', argument, output, false)
			#OS.execute('powershell.exe', ['/C', "get-process AuroraLauncher | measure-object -line | select Lines -expandproperty Lines"], output, false)
			#print(output)
			var result = output[0].to_int()
			#print("Number of Aurora Launchers processes: " + str(result))
			return result
		return -1


	static func get_files_in_folder_recursive(path : String, suffix_array : Array[String]) -> PackedStringArray:
		var files : PackedStringArray = []

		#if OS.has_feature("export"):
		#	var temp_array : Array[String]
		#	for a in suffix_array:
		#		temp_array.append(a + ".import")
		#		temp_array.append(a + ".remap")
		#	suffix_array.append_array(temp_array)

		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()

			while file_name != "":
				var file_path = path.path_join(file_name)

				if dir.current_is_dir():
					if file_name != "." and file_name != "..":
						var subfolder_files = get_files_in_folder_recursive(file_path, suffix_array)
						files += subfolder_files
				else:
					if suffix_array.is_empty():
						files.append(file_path)
					if OS.has_feature("export"):
						if file_name.ends_with(".import") or file_name.ends_with(".remap"):
							file_name = file_path.get_basename()
							file_path = file_path.get_basename()
					if suffix_array.has(file_name.get_extension()):
						files.append(file_path)
					#var __search_result := suffix_array.find(file_name.get_extension())
					#if __search_result != -1:
					#	files.append(file_path)

				file_name = dir.get_next()

			dir.list_dir_end()
		else:
			push_error('EngineScriptLibrary::get_files_in_folder_recursive(): Failed to open ', path)

		return files


	static func get_files_in_folder(path : String, suffix_array : Array[String]) -> PackedStringArray:
		var files : PackedStringArray

		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()

			while file_name != "":
				var file_path = path.path_join(file_name)

				if dir.current_is_dir():
					pass
				else:
					if suffix_array.is_empty():
						continue
					var __search_result := suffix_array.find(file_name.get_extension())
					if __search_result != -1:
						files.append(file_path)

				file_name = dir.get_next()

			dir.list_dir_end()
		else:
			push_error('EngineScriptLibrary::get_files_in_folder_recursive(): Failed to open ', path)

		return files


	# Use this instead of regular load() as it handles remapped files
	static func load_asset(path : String) -> Resource:
		#print("EngineScriptLibrary::load_asset(): " + path)
		if OS.has_feature("export"):
			# Regular load if not .remap or .import
			if not path.ends_with(".remap"):
				return load(path)

			# Open the file
			var __config_file = ConfigFile.new()
			__config_file.load(path)

			# Load the remapped file
			var __remapped_file_path = __config_file.get_value("remap", "path")
			__config_file = null
			return load(__remapped_file_path)
		else:
			return load(path)


	static func get_random_string(in_string_length : int, in_capital_letters : bool = false) -> String:
		var characters
		if in_capital_letters:
			characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890'
		else:
			characters = 'abcdefghijklmnopqrstuvwxyz1234567890'
		var word: String = ""
		var n_char = len(characters)
		for i in range(in_string_length):
			word += characters[randi()% n_char]
		return word


class crypto:
	## Padding byte array to block size multiplication
	static func pad_pkcs7(data: PackedByteArray, block_size: int = 16) -> PackedByteArray:
		assert(block_size > 0, "Block size must be positive")
		var padding_size = block_size - (data.size() % block_size)
		var padding = PackedByteArray()
		padding.resize(padding_size)
		padding.fill(padding_size)
		return data + padding

	static func unpad_pkcs7(data: PackedByteArray) -> PackedByteArray:
		if data.size() == 0:
			return data
		var padding_size = data[data.size() - 1]
		return data.slice(0, data.size() - padding_size)

	static func encode_aes(p_data : Variant, p_key_bytes : PackedByteArray) -> PackedByteArray:
		var __padded_bytes = EngineScriptLibrary.crypto.pad_pkcs7(var_to_bytes(p_data), 16)

		# Encrypt data with AES CBC
		var __crypto = Crypto.new()
		var __iv = __crypto.generate_random_bytes(16)
		var __aes = AESContext.new()
		__aes.start(AESContext.MODE_CBC_ENCRYPT, p_key_bytes, __iv)
		var __encrypted_data = __aes.update(__padded_bytes)
		__aes.finish()

		return __iv + __encrypted_data

	static func decode_aes(p_data : PackedByteArray, p_key_bytes : PackedByteArray) -> Variant:
		# Decrypt data with AES CBC
		var __aes = AESContext.new()
		var __iv = p_data.slice(0, 16)
		var __encrypted_data = p_data.slice(16, p_data.size())
		__aes.start(AESContext.MODE_CBC_DECRYPT, p_key_bytes, __iv)
		var __decrypted_data = __aes.update(__encrypted_data)
		__aes.finish()

		var __unpadded_data = EngineScriptLibrary.crypto.unpad_pkcs7(__decrypted_data)

		return bytes_to_var(__unpadded_data)
