class RenderArea
	attr_accessor :rubberbands, :map_renderarea, :scroll_window
	def initialize(width, height, canvas)
		@tool = 0
		@entities = []
		@spawn_points = []
		@flags = []
		@rubberbands = []
		@entity_width = @entity_height = 12
		@left_down = false
		@canvas = canvas
		@rubberband = nil

		@canvas.connect(SEL_LEFTBUTTONRELEASE) {|sender, sel, event| mouseReleaseEvent(event)}
		@canvas.connect(SEL_LEFTBUTTONPRESS) {|sender, sel, event| mousePressEvent(event)}
		@canvas.connect(SEL_RIGHTBUTTONRELEASE) {|sender, sel, event| contextMenuEvent(event)}
		@canvas.connect(SEL_MOTION) {|sender, sel, event| mouseMoveEvent(event)}
		@canvas.connect(SEL_PAINT) {|sender, sel, event| paintEvent(event)}

		$data["entities"].each do |e|
			@entities << [e.x, e.y]
		end
		$data["flags"].each do |flag|
			@flags << [flag.x, flag.y]
		end
		$data["spawns"].each do |spoint|
			@spawn_points << [spoint.x, spoint.y] if spoint.class == SpawnPoint
		end
		toggle_bands(true)
		@canvas.update
	end

	def mouseMoveEvent(e)
		if @left_down
			@rubberband.set_geometry(FXRectangle.new(@origin[0], @origin[1], e.win_x, e.win_y))
			@canvas.update
		end
	end

	def mousePressEvent(e)
		if @rubberband
			@rubberband = nil
		else
			@rubberbands.each {|x| x.hide}
			@origin = [e.click_x, e.click_y]
			if !@rubberband
				@rubberband = FXRubberBand.new
			end
			@rubberband.set_geometry(FXRectangle.new(@origin[0], @origin[1], 1, 1))
			@rubberband.show
			@left_down = true
		end
	end

	def mouseReleaseEvent(e)
		@left_down = false
		if !e.moved?
			if @tool == 1
				entity = [e.click_x, e.click_y]
				top_x = entity[0] - (@entity_width / 2).to_i
				top_y = entity[1] - (@entity_height / 2).to_i
				point = [top_x, top_y]
				@entities << point
				$data["entities"] << Entity.new($entity_names[0].delete(" "), "data/images/icon.bmp", point[0], point[1])
			elsif @tool == 2   		   
				type, object = find_object(e.click_x, e.click_y)
				if type == :entity
					@entities.delete(object)
					$data["entities"].delete_if {|i| i.x == object[0] && i.y == object[1]}
				elsif type == :flag
					@flags.delete(object)
					$data["flags"].delete_if {|i| i.x == object[0] && i.y == object[1]}
				elsif type == :spawn_point
					@spawn_points.delete(object)
					$data["spawns"].delete_if {|i| i.x == object[0] && i.y == object[1]}
				elsif type == :band
					object.hide
					rect = object.geometry
					$data["solid"].each do |solid|
						if rect.contains?(solid.x, solid.y)
							$data["solid"].delete(solid)
							@rubberbands.delete(object)
						end
					end
					$data["spawns"].each do |spawn|
						next if spawn.class == SpawnPoint
						if rect.contains?(spawn.x, spawn.y)
							$data["spawns"].delete(spawn)
							@rubberbands.delete(object)
						end
					end
				end
			elsif @tool == 3
				top_x = e.click_x - (@entity_width / 2).to_i
				top_y = e.click_y - (@entity_height / 2).to_i
				@flags << [top_x, top_y]
				$data["flags"] << Flag.new(top_x, top_y, :red)
			elsif @tool == 4
				spoint = FXPoint.new(e.click_x, e.click_y)
				top_x = e.click_x - (@entity_width / 2).to_i
				top_y = e.click_y - (@entity_height / 2).to_i
				@spawn_points << [top_x, top_y]
				$data["spawns"] << SpawnPoint.new(top_x, top_y)
			end
			@canvas.update
		end
	end 

	def find_object(x, y)
		@entities.each do |entity|
			if FXRectangle.new(entity[0], entity[1], @entity_width, @entity_height).contains?(x, y)
				return :entity, entity
			end
		end
		@flags.each do |flag|
			if FXRectangle.new(flag[0], flag[1], @entity_width, @entity_height).contains?(x, y)
				return :flag, flag
			end
		end
		@spawn_points.each do |spoint|
			if FXRectangle.new(spoint[0], spoint[1], @entity_width, @entity_height).contains?(x, y)
				return :spawn_point, spoint
			end
		end
		@rubberbands.each do |band|
			if band.geometry.contains?(e) && !band.is_hidden?
				return :band, band
			end
		end
		if !@rubberband.nil?			
			return :band, @rubberband if @rubberband.geometry.contains?(e)
		end
		return false
	end

	def toggle_bands(on = false)
		$data["solid"].each do |band|
			rubberband = FXRubberBand.new
			bandrect = FXRectangle.new(*band)
			rubberband.set_geometry(bandrect)
			@rubberbands << rubberband if !selection_find(bandrect)
		end
		$data["spawns"].each do |spawn|
			next if spawn.class == SpawnPoint
			rubberband = FXRubberBand.new
			spawnrect = FXRectangle.new(spawn.x, spawn.y, spawn.width, spawn.height)
			rubberband.set_geometry(spawnrect)
			@rubberbands << rubberband if !selection_find(spawnrect)
		end
		if !@rubberband.nil?
			if selection_find(@rubberband.geometry)
				@rubberbands.select {|x| x.geometry == @rubberband.geometry}[0].hide
			end
			@rubberband = nil
		end
		@rubberbands.each do |band|
			if on == true || band.is_hidden? 
				band.show
			else
				band.hide
			end
		end
		@canvas.update
	end

	def selection_find(rband)
		@rubberbands.each do |band|
			bandg = band.geometry
			if bandg.x == rband.x && bandg.y == rband.y && bandg.w == rband.w && bandg.h == rband.h
				return true
			end
		end
		return false
	end

	def contextMenuEvent(e)
		unless e.moved?
			FXMenuPane.new(@canvas) do |menuPane|  
				type, object = find_object(e.click_x, e.click_y)
				return if object.nil?
				if type == :entity
					prop = FXMenuCommand.new(menuPane, "Properties")
					prop.connect(SEL_COMMAND) {entity_properties()}
				elsif type == :flag
					prop = FXMenuCommand.new(menuPane, "Properties")
					prop.connect(SEL_COMMAND) {flag_properties()}
				elsif type == :spawn_point
					prop = FXMenuCommand.new(menuPane, "Properties")
					prop.connect(SEL_COMMAND) {spawn_properties()}
				elsif type == :band
					@rubberband = object
					object = object.geometry
					prop = FXMenuCommand.new(menuPane, "Properties")
					prop.connect(SEL_COMMAND) {selection_properties()}
				end
				menuPane.create
				@menuPos = [object[0], object[1]]
				menuPane.popup(nil, e.root_x, e.root_y)
				$app.runModalWhileShown(menuPane)
			end
		end
	end

	def map_settings
		dialog = MapSettings.new(@canvas)
		dialog.execute_nonmodal
	end

	def selection_properties
		dialog = SelectionDialog.new(@rubberband, @canvas)
		dialog.execute_nonmodal
	end

	def entity_properties
		dialog = EntityDialog.new(@menuPos, @canvas)
		dialog.execute_nonmodal
	end

	def flag_properties
		dialog = FlagDialog.new(@menuPos, @canvas)
		dialog.execute_nonmodal
	end

	def spawn_properties
		dialog = SpawnPointDialog.new(@menuPos, @canvas)
		dialog.execute_nonmodal
	end

	def solid_area
		dialog = TileDialog.new(self, @canvas)
		dialog.execute_nonmodal
	end

	def set_tool(tool)
		@tool = tool
		toggle_bands(true) if @tool == 2
	end

	def set_tiles(map)
	    @width, @height, @tilewidth, @tileheight = map.map_width, map.map_height, map.tilewidth, map.tileheight
	end

	def paintEvent(event)  
		while @flags.length > 2
			@flags.shift
		end

		FXDCWindow.new(@canvas, event) do |dc|
			dc.foreground = "white"
			dc.fillRectangle(0, 0, @width * @tilewidth, @height * @tileheight)

			dc.drawImage(@map_renderarea.image, 0, 0)

			@rubberbands.each {|band| band.draw(dc)}
			@rubberband.draw(dc) if !@rubberband.nil?

			dc.foreground = "white"
			@entities.each do |entity|
				dc.drawEllipse(entity[0], entity[1], @entity_width, @entity_height)
			end

			dc.foreground = "red"
			@flags.each do |flag|
				dc.drawEllipse(flag[0], flag[1], @entity_width, @entity_height)
			end

			dc.foreground = "blue"
			@spawn_points.each do |spoint|
				dc.drawEllipse(spoint[0], spoint[1], @entity_width, @entity_height)
			end
		end
	end
end
