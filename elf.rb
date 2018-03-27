require './monkey_patch'
require './machine_arch_list'

class ELF
	# ============================================================================
	# ELF Identifer
	# ============================================================================
	ELF_SIZE_HALF_WORD	= 2
	ELF_SIZE_WORD				= 4
	ELF_SIZE_XWORD			= 8
	ELF_SIZE_ADDR_32		= 4
	ELF_SIZE_ADDR_64		= 8
	ELF_SIZE_OFFSET_32	= 4
	ELF_SIZE_OFFSET_64	= 8

	# ============================================================================
	# ELF Identifer
	# ============================================================================
	ELF_IDENT_SIZE	                  = 16
	ELF_IDENT_OFFSET_MAGIC_NUMBER 		= 0
	ELF_IDENT_OFFSET_CLASS						= 4
	ELF_IDENT_OFFSET_ENDIAN						= 5
	ELF_IDENT_OFFSET_FORMAT_VERSION  	= 6
	ELF_IDENT_OFFSET_OS_ABI				  	= 7
	ELF_IDENT_OFFSET_OS_ABI_VERSION 	= 8

	# ============================================================================
	# ELF32
	# ============================================================================
	ELF32_OFFSET_IDENTIFER   					= 0
	ELF32_OFFSET_TYPE        					= ELF32_OFFSET_IDENTIFER 						+ ELF_IDENT_SIZE
	ELF32_OFFSET_MACHINE     					= ELF32_OFFSET_TYPE 				    		+ ELF_SIZE_HALF_WORD
	ELF32_OFFSET_VERSION     					= ELF32_OFFSET_MACHINE 				 			+ ELF_SIZE_HALF_WORD
	ELF32_OFFSET_ENTRY       					= ELF32_OFFSET_VERSION 							+ ELF_SIZE_WORD
	ELF32_OFFSET_PROGRAM_HEADER	 			= ELF32_OFFSET_ENTRY 		  					+ ELF_SIZE_ADDR_32
	ELF32_OFFSET_SECTION_HEADER 			= ELF32_OFFSET_PROGRAM_HEADER 			+ ELF_SIZE_OFFSET_32
	ELF32_OFFSET_FLAGS								= ELF32_OFFSET_SECTION_HEADER				+ ELF_SIZE_OFFSET_32
	ELF32_OFFSET_ELF_HEADER_SIZE			= ELF32_OFFSET_FLAGS 								+ ELF_SIZE_WORD
	ELF32_OFFSET_PROGRAM_HEADER_SIZE  = ELF32_OFFSET_ELF_HEADER_SIZE		 	+ ELF_SIZE_HALF_WORD
	ELF32_OFFSET_PROGRAM_HEADER_NUM 	= ELF32_OFFSET_PROGRAM_HEADER_SIZE  + ELF_SIZE_HALF_WORD
	ELF32_OFFSET_SECTION_HEADER_SIZE 	= ELF32_OFFSET_PROGRAM_HEADER_NUM 	+ ELF_SIZE_HALF_WORD
	ELF32_OFFSET_SECTION_HEADER_NUM 	= ELF32_OFFSET_SECTION_HEADER_SIZE 	+ ELF_SIZE_HALF_WORD
	ELF32_OFFSET_SECTION_NAME_IDX 	  = ELF32_OFFSET_SECTION_HEADER_NUM 	+ ELF_SIZE_HALF_WORD

	# ============================================================================
	# ELF64
	# TODO Check Offset Pos
	# ============================================================================
	ELF64_OFFSET_IDENTIFER   					= 0
	ELF64_OFFSET_TYPE        					= ELF64_OFFSET_IDENTIFER 						+ ELF_IDENT_SIZE
	ELF64_OFFSET_MACHINE     					= ELF64_OFFSET_TYPE      						+ ELF_IDENT_SIZE
	ELF64_OFFSET_VERSION     					= ELF64_OFFSET_MACHINE   						+ ELF_SIZE_HALF_WORD
	ELF64_OFFSET_ENTRY       					= ELF64_OFFSET_VERSION   						+ ELF_SIZE_HALF_WORD
	ELF64_OFFSET_PROGRAM_HEADER	 			= ELF64_OFFSET_ENTRY     						+ ELF_SIZE_ADDR_32
	ELF64_OFFSET_SECTION_HEADER 			= ELF64_OFFSET_PROGRAM_HEADER       + ELF_SIZE_OFFSET_64
	ELF64_OFFSET_FLAGS								= ELF64_OFFSET_SECTION_HEADER       + ELF_SIZE_OFFSET_64
	ELF64_OFFSET_ELF_HEADER_SIZE			= ELF64_OFFSET_FLAGS                + ELF_SIZE_WORD
	ELF64_OFFSET_PROGRAM_HEADER_ENTRY = ELF64_OFFSET_ELF_HEADER_SIZE      + ELF_SIZE_HALF_WORD
	ELF64_OFFSET_PROGRAM_HEADER_NUM 	= ELF64_OFFSET_PROGRAM_HEADER_ENTRY + ELF_SIZE_HALF_WORD
	ELF64_OFFSET_SECTION_HEADER_NUM 	= ELF64_OFFSET_PROGRAM_HEADER_NUM   + ELF_SIZE_HALF_WORD
	ELF64_OFFSET_SECTION_NAME_IDX 	  = ELF64_OFFSET_SECTION_HEADER_NUM   + ELF_SIZE_HALF_WORD

	# ============================================================================
	# Legal values for e_type (object file type)
	# ============================================================================
	ELF_ET_NONE	= 0
	ELF_ET_REL	= 1
 	ELF_ET_EXEC = 2
	ELF_ET_DYN	= 3
	ELF_ET_CORE	= 4

	# Spacer

	# ============================================================================
	# Load Object File
	# ============================================================================
	def load filepath
		bin = File.binread(filepath).unpack("C*")

		elf_ident = bin[0, ELF_IDENT_SIZE]

		# check magic number
		unless is_elf? elf_ident
			throw "This is not ELF Format File"
		end

		# Check ELF class
		val = elf_ident[ELF_IDENT_OFFSET_CLASS].ord
		case val
		when 1
			@elf_class = :CLASS_ELF32
		when 2
			@elf_class = :CLASS_ELF64
		else
			throw "Invalid ELF Class:#{val}"
		end

		# Check Endian
		val = elf_ident[ELF_IDENT_OFFSET_ENDIAN].ord
		case val
		when 1
			@elf_endian = :ELF_LITTLE_ENDIAN
		when 2
			@elf_endian = :ELF_BIG_ENDIAN
		else
			throw "Invalid ELF Endian:#{val}"
		end

		# Check ELF Format Version
		val = elf_ident[ELF_IDENT_OFFSET_FORMAT_VERSION].ord
		unless val == 1
			throw "Unsuppoted ELF Format Version:#{val}"
		end
		@elf_version = val

		# Check OS ABI
		val = elf_ident[ELF_IDENT_OFFSET_OS_ABI].ord
		case val
		when 0
			@os_abi = :OS_ABI_UNIX
		when 3
			@os_abi = :OS_ABI_LINUX
		else
			throw "Unsuppoted OS ABI Format:#{val}"
		end

		# Check OS ABI Version
		@os_abi_version = elf_ident[ELF_IDENT_OFFSET_OS_ABI_VERSION]

		@bin = bin
		@ident = elf_ident

		is_little = @elf_endian == :ELF_LITTLE_ENDIAN
		case @elf_class
		when :CLASS_ELF32
			@elf_type             = @bin[ELF32_OFFSET_TYPE, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_machine          = @bin[ELF32_OFFSET_MACHINE, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_version          = @bin[ELF32_OFFSET_VERSION, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_entry            = @bin[ELF32_OFFSET_ENTRY, ELF_SIZE_ADDR_32].to_i(is_little)
			@elf_program_h_offset = @bin[ELF32_OFFSET_PROGRAM_HEADER, ELF_SIZE_OFFSET_32].to_i(is_little)
			@elf_section_h_offset = @bin[ELF32_OFFSET_SECTION_HEADER, ELF_SIZE_OFFSET_32].to_i(is_little)
			@elf_flags            = @bin[ELF32_OFFSET_FLAGS, ELF_SIZE_WORD].to_i(is_little)
			@elf_h_size       		= @bin[ELF32_OFFSET_ELF_HEADER_SIZE, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_program_h_size   = @bin[ELF32_OFFSET_PROGRAM_HEADER_SIZE, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_program_h_num    = @bin[ELF32_OFFSET_PROGRAM_HEADER_NUM, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_section_h_size   = @bin[ELF32_OFFSET_SECTION_HEADER_SIZE, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_section_h_num    = @bin[ELF32_OFFSET_SECTION_HEADER_NUM, ELF_SIZE_HALF_WORD].to_i(is_little)
			@elf_section_name_idx    = @bin[ELF32_OFFSET_SECTION_NAME_IDX, ELF_SIZE_HALF_WORD].to_i(is_little)
		when :CLASS_ELF64
			# TODO ELF64
			throw "TODO ELF64........"
		else
		end
	end

	# ============================================================================
	# Get section header info by section name
	# ============================================================================
	def get_section_header section_name
		sec_idx = @sh_idx_map[section_name]

		# No such section
		return nil if sec_idx.nil?

		sec_pos = @e_shoff + (sec_idx * @sh_size)
		@bin[sec_pos, @sh_size]
	end

	# ============================================================================
	# Show ELF Header info like `readelf -h` format.
	# ============================================================================
	def show_elf_header
		puts "ELF Header:"
		show_magic
		show_elf_class
		show_endian
		show_elf_version
		show_OS_ABI
		show_ABI_version
		show_file_type
		show_machine_arch
		show_file_version
		show_entry_point
		show_program_h_offset
		show_section_h_offset
		show_elf_flags
		show_elf_h_size
		show_program_h_size
		show_program_h_num
		show_section_h_size
		show_section_h_num
		show_section_name_idx

# TODO
#		show_sections
#		initialize_section_idx_map
#		debug_section = get_section_header ".debug_info"
#		show_section_header debug_section
	end

	# ============================================================================
	# Show Section Header Info
	# ============================================================================
	def show_section_header section_header
	end

	# ============================================================================
	# Show ELF Magic Number
	# ============================================================================
	def show_magic
		puts "  Magic:   #{@ident.hex_dump(false, false)}"
	end

	# ============================================================================
	# Show ELF Class Info
	# ============================================================================
	def show_elf_class
		print "  Class:                             "
		case @elf_class
		when :CLASS_ELF32
			puts "ELF32"
		when :CLASS_ELF64
			puts "ELF32"
		else
			puts "Invalid Class"
		end
	end

	# ============================================================================
	# Show Endian Info
	# ============================================================================
	def show_endian
		endian_str = ""
		case @elf_endian
		when :ELF_LITTLE_ENDIAN
			endian_str = "2's complement, little endian"
		when :ELF_BIG_ENDIAN
			endian_str = "2's complement, big endian"
		else
			endian_str = "Invalid Endian"
		end
		puts "  Data:                              #{endian_str}"
	end

	# ============================================================================
	# Show ELF Version Info
	# ============================================================================
	def show_elf_version
		ver_str = "#{@elf_version}"
		ver_str += " (current)" if @elf_version == 1
		puts "  Version:                           #{ver_str}"
	end

	# ============================================================================
	# Show OS ABI Info
	# ============================================================================
	def show_OS_ABI
		abi_str = ""
		case @os_abi
		when :OS_ABI_UNIX
			abi_str = "UNIX - System V"
		when :OS_ABI_LINUX
			abi_str = "Linux"
		else
			abi_str = "undefined OS ABI"
		end
		puts  "  OS/ABI:                            #{abi_str}"
	end

	def show_ABI_version
		 puts "  ABI Version:                       #{@os_abi_version}"
	end

	# ============================================================================
	# Show ELF File Type Info
	# ============================================================================
	def show_file_type
		str = ""
		case @elf_type
		when ELF_ET_REL
			str = "REL (Relocatable file)"
	 	when ELF_ET_EXEC
			str = "EXEC (Executable file)"
		when ELF_ET_DYN
			str = "DYN (Shared object file)"
		when ELF_ET_CORE
			str = "CORE (Core file)"
		else
			str = "Invalid ELF Type #{@elf_type}"
		end
		puts "  Type:                              #{str}"
	end

	# ============================================================================
	# Show ELF Machine Archtecture Info
	# ============================================================================
	def show_machine_arch
		puts "  Machine:                           #{ELF_MACHINE_ARCH_LIST[@elf_machine.to_i]} (#{@elf_machine.to_i})"
	end

	# ============================================================================
	# Show Entry Point Address
	# ============================================================================
	def show_entry_point
		puts "  Entry point address:               #{@elf_entry.to_h}"
	end

	# ============================================================================
	# Show ELF File Version
	# ============================================================================
	def show_file_version
		puts "  Version:                           #{@elf_version.to_h}"
	end

	def show_program_h_offset
		puts "  Start of program headers:          #{@elf_program_h_offset.to_h} (bytes into file)"
	end

	def show_section_h_offset
		puts "  Start of section headers:          #{@elf_section_h_offset} (bytes into file)"
	end

	def show_elf_flags
			puts "  Flags:                             #{@elf_flags.to_h}"
	end

	def show_elf_h_size
		puts "  Size of this header:               #{@elf_h_size} (bytes)"
	end

	def show_program_h_size
		puts "  Size of program headers:           #{@elf_program_h_size} (bytes)"
	end

	def show_program_h_num
		puts "  Number of program headers:         #{@elf_program_h_num}"
	end

	def show_section_h_size
		puts "  Size of section headers:           #{@elf_section_h_size} (bytes)"
	end

	def show_section_h_num
		puts "  Number of section headers:         #{@elf_section_h_num}"
	end

	def show_section_name_idx
		 puts "  Section header string table index: #{@elf_section_name_idx}"
	end


	def initialize_section_idx_map
		sec_idx = 0
		while sec_idx < @e_shnum
			sec_pos = @e_shoff + (sec_idx * @sh_size)
			section = @bin[sec_pos, @sh_size]
			sec_idx += 1

			# .shstrtabにおけるセクション名のオフセット位置を取得
			name_offset = section[0, ELF_SIZE_WORD].to_i
			name = @names_section[name_offset, @names_sec_length].c_str

			# セクションヘッダのインデックスを設定
			@sh_idx_map[name] = sec_idx
		end
	end

	# ============================================================================
	# Check ELF Magic Number 0x7F ELF
	# ============================================================================
	def is_elf? elf_identifer
		return false if elf_identifer[0] != 0x7F
		return false if elf_identifer[1] != 'E'.ord
		return false if elf_identifer[2] != 'L'.ord
		return false if elf_identifer[3] != 'F'.ord
		true
	end
end
