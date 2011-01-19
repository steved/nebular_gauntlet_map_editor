# This is a map class that parses
# and renders a TMX (xml) file
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'yaml'

class Map
	attr_accessor :tilesets, :layers, :name, :width, :height, :background, :map_name, :dir, :tilewidth, :tileheight, :map_width, :map_height

	private
	@surface = nil

	@map_file = ""

	@source_file  = "" # Image file

	# Width and Height in tiles
	@map_width = 0 
	@map_height = 0 

	# Tile width/height
	@tilewidth = 0
	@tileheight = 0

	public
	# Create a new map instance
	# - _file_ TMX File from which to load
	def initialize(width = nil, height = nil, tilewidth = nil, tileheight = nil)
		@x = @y = 0

		@tilesets = []

		@state = :alive # For collision compat

		@solids = [] # Array of solid tiles

		# Variable for holding variables
		@layers = []

		if width && height && tilewidth && tileheight
			@map_width, @map_height, @tilewidth, @tileheight = width, height, tilewidth, tileheight
			@width = @map_width * @tilewidth 
			@height = @map_height * @tileheight
		end
	end

	def load_map(file)
	    if file[0..0] == "/"
		  @name = file.split("/")[-1].split(".")[0]
		else
		  @name = file.split("\\")[-1].split(".")[0]
		end
		
		@filename = file
		@map_file = YAML::load(File.open(@filename))["map"]

		# Get height and width in tiles
		@map_width = @map_file["width"]
		@map_height = @map_file["height"]

		# Get tilewidth and height
		@tilewidth = @map_file["tilewidth"]
		@tileheight = @map_file["tileheight"]

		# Set width/height
		@width = @map_width * @tilewidth
		@height = @map_height * @tileheight

		if file[0..0] == "/"
			@map_name = file.split("/")[-1]
			@dir = file.split("/")[0..-2].join("/") + "/"
		else
			@map_name = file.split("\\")[-1]
			@dir = file.split("\\")[0..-2].join("\\") + "\\"
		end

		@background = @dir + "/images/" + @map_file["background"] if @map_file["background"]
	end

	# Loads tilesets and rows
	def load_tiles
		if @map_file["tilesets"]
			@map_file["tilesets"].each do |name, values|
				@tilesets << Tileset.new(name, values["image"], values["firstgid"], values["tilewidth"], values["tileheight"])
			end
			@tilesets.sort! {|a,b| a.firstgid <=> b.firstgid}
		end

		if @map_file["layers"]
			@map_file["layers"].each do |name, values|
				@layers << Layer.new(name, values["opacity"], values["width"], values["height"], values["data"])
			end
		end
	end
end
