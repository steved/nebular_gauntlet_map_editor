class MapRenderArea
	include Common

	attr_writer :scroll_window
	attr_reader :tilesets, :pixmaps, :layers, :tilewidth, :tileheight
	attr_accessor :tile, :tile_button, :image, :selected_layer, :tool

	def initialize(width, height, canvas)
		@left_down = false
		@canvas = canvas
		@selected_layer = 0
		@selected = nil
		@tool = 0

		@canvas.connect(SEL_LEFTBUTTONPRESS) {|sender, sel, event| leftMousePressEvent(event)}
		@canvas.connect(SEL_RIGHTBUTTONPRESS) {|sender, sel, event| rightMousePressEvent(event)}
		@canvas.connect(SEL_PAINT) {|sender, sel, event| paintEvent(event)}
	end

	def leftMousePressEvent(e)
		x = e.click_x - (e.click_x % @tilewidth)
		y = e.click_y - (e.click_y % @tileheight)
		@selected = [x, y]
		if @tool == 0
			if !@tile.nil? && !@layers[@selected_layer].nil?
				xa = @selected[0] / @tilewidth
				ya = @selected[1] / @tileheight
				tilenum = @tile[0][0] + ((@pixmaps[@tile[1]].width / @tilewidth) * @tile[0][1])
				@layers[@selected_layer][ya][xa] = [tilenum, @pixmaps[@tile[1]], @tile[2]]
				redraw_back
			end
		elsif @tool == 1
			if !@layers[@selected_layer].nil?
				xa = @selected[0] / @tilewidth
				ya = @selected[1] / @tileheight
				@layers[@selected_layer][ya][xa] = [0, nil, 0]
				redraw_back
			end
		end
		@canvas.update
	end

	def rightMousePressEvent(e)
		@selected = nil
		@canvas.update
	end

	def set_tiles(map, pixmaps)
		@width, @height, @tilewidth, @tileheight, @tilesets, @background_image = map.map_width, map.map_height, map.tilewidth, map.tileheight, map.tilesets, map.background
		@pixmaps = pixmaps

		@layers = Array.new(map.layers.length) do |i|
			Array.new(map.layers[i].height) do 
				Array.new(map.layers[i].width) { nil }
			end
		end

		if !@background_image.nil? && @background_image.length > 0 
			@background = load_image(@background_image)
		end

		if !@background 
			@background = FXImage.new($app, nil, 0, @width * @tilewidth, @height * @tileheight)
			@background.create
			FXDCWindow.new(@background) {|dc| dc.foreground = "black"; dc.fillRectangle(0, 0, @background.width, @background.height)}
		end
	end

	def set_tile(x, y, tilenum, pixmap, layer, firstgid)
		@layers[layer][y][x] = [tilenum, pixmap, firstgid]
	end

	def redraw_back
		@image = FXImage.new($app, nil, 0, @width * @tilewidth, @height * @tileheight)
		@image.create
		FXDCWindow.new(@image) {|dc| dc.drawImage(@background, 0, 0)}

		@layers.each do |layer|
			draw_layer(layer, @image)
		end
		
		@canvas.update
	end

	def draw_layer(layer, dest)
		FXDCWindow.new(dest) do |dc|
			layer.each_with_index do |x,i|
				x.each_with_index do |y,o|
					if y.nil? || y.empty? || !@pixmaps.include?(y[1])
						layer[i][o] = [0, nil, 0]
						next
					end
					tileset = @tilesets.select{|x| x.firstgid == y[2]}[0]
					yimage = y[0] % (y[1].width / tileset.tilewidth)
					ximage = (y[0] - yimage) / (y[1].height / tileset.tileheight)			
					dc.drawArea(y[1], yimage * tileset.tilewidth, ximage * tileset.tileheight, tileset.tilewidth, tileset.tileheight, o * @tilewidth, i * @tileheight)
				end
			end
		end
	end

	def paintEvent(event)  
		FXDCWindow.new(@canvas, event) do |dc|
			dc.drawImage(@image, 0, 0)

			if !@selected.nil?
				dc.foreground = "blue"
				dc.fillRectangle(@selected[0], @selected[1], @tilewidth, @tileheight)
			end
			dc.foreground = "white"
		end
	end

	def tile_dialog
		dialog = TileSelectDialog.new(self, @canvas)
		dialog.execute_nonmodal
	end
end
