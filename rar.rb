require 'pry'

# initialize the byte stream
# parse the headers.
# detect where the file actually begins
# then after the last byte of the file has been retrieved
# then repeat the header parser, EXCEPT for the MARK_HEAD, as that only
# exists at the beginning of the RAR file.

# so, RAR => { header data,
# { RARsubclass => block_header, data_block},
# { RARsubclass => block_header, data_block}}
# MARKER_BLOCK   => 7 bytes, (+4)
# ARCHIVE HEADER => 13 bytes
# FILE HEADER    => 40 + X bytes

class Reader
  attr_reader :data
  def initialize
    @data = IO.read('saga.rar', 400, 0)
  end

  def parse_meta
    until @data.empty?
      case @data[2].bytes
      when [0x72]
        marker_block
      when [0x73]
        @archive_header = parse_archive_header
      when [0x74]
        @file_header = parse_file_header
      end
    end
  end

  def marker_block
    if @data[0..3] == "Rar!"
      @header = @data.slice!(0..6)
      # @header = head_flag.last == "1" ? @data.slice!(0..10) : @data.slice!(0..6)
    else
    end
  end

  def marker_head
    binding.pry
  end

  def parse_archive_header
    {
      crc: @data.slice!(0..1),
      type: @data.slice!(0),
      flags: @data.slice!(0..1),
      size: @data.slice!(0..1),
      res: @data.slice!(0..5)    
    }
  end

  def parse_file_header
    size = @data[5..6].unpack("S").first
    file_header = @data.slice!(0..(size - 1))

    header = FileHeader.new(file_header)
    header.to_hash

    # {
    #   crc: file_header.slice!(0..1),
    #   type: file_header.slice!(0),
    #   flags: file_header.slice!(0..1),
    #   size: file_header.slice!(0..1),
    #   pack_size: file_header.slice!(0..3),
    #   unp_size: file_header.slice!(0..3),
    #   host_size: file_header.slice!(0),
    #   file_crc: file_header.slice!(0..3),
    #   ftime: file_header.slice!(0..3),
    #   unp_ver: file_header.slice!(0),
    #   method: file_header.slice!(0),
    #   name_size: name_size(file_header),

    # }

    # {
    #   crc: @data.slice!(0..1),
    #   type: @data.slice!(0),
    #   flags: @data.slice!(0..1),

    # }
  end

  def name_size(file_header)
    file_header.slice!(0..1).unpack("S").first
  end

  def initial_block
    @data.slice!(0..6)    
  end

  def head_flag
    @data[3..4].unpack("B16").first.split("")  
  end
end

class FileHeader
  def initialize(file_header)
    @file_header = file_header
  end

  def to_hash
    block
    sizes
    file_attributes
    binding.pry
  end

  def block
    @block = {
      crc: @file_header.slice!(0..1),
      type: @file_header.slice!(0),
      flags: flags,
      size: @file_header.slice!(0..1)
    }
  end

  def flags
    @flags = @file_header.slice!(0..1).unpack("B16").first.split("")
  end

  def sizes
    binding.pry
    @file_sizes = {
      pack_size: pack_size,
      unp_size: unp_size,
      host_os: @file_header.slice!(0)
    }
  end

  def file_attributes
    @file_attr = {
      file_crc: @file_header.slice!(0..3),
      ftime: @file_header.slice!(0..3),
      unp_ver: @file_header.slice!(0),
      method: @file_header.slice!(0),
      name_size: name_size,
      attributes: attributes,

      filename: file_name
    }
  end

  def file_name
    @filename = @file_header.slice!(0..(@filename_length - 1))
  end

  def salt
    binding.pry
  end

  def pack_size
    @file_header.slice!(0..3).unpack("S")
  end

  def unp_size
    @file_header.slice!(0..3).unpack("C")
  end

  def name_size
    @filename_length = @file_header.slice!(0..1).unpack("S").first
  end

  def attributes
    @file_header.slice!(0..3)
  end
end



rar = Reader.new
rar.parse_meta
binding.pry