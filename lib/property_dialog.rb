class GenericDialog < FXDialogBox
	include Responder
	include FTNonModal

	def initialize(parent, name)
		super(parent, name, DECOR_TITLE|DECOR_BORDER)

		@buttons = FXHorizontalFrame.new(self, LAYOUT_SIDE_BOTTOM|FRAME_NONE|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)

		ok_button = FXButton.new(@buttons, "Accept", nil, self, ID_ACCEPT,
								 FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
		cancel_button = FXButton.new(@buttons, "&Cancel", nil, self, ID_CANCEL,
									 FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
		ok_button.connect(SEL_COMMAND) {accept()}
		cancel_button.connect(SEL_COMMAND) {cancel()}
	end

	def accept
		hide()
		return 0
	end

	def cancel
		hide()
		return -1
	end
end

class SelectionDialog < GenericDialog
	def initialize(rubberband, parent)
		super(parent, "Selection Dialog")

		@rubberband = rubberband
		@team = :red

		@options = FXVerticalFrame.new(self, FRAME_SUNKEN|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 5, 0, 10, 10, 10, 10)

		index = 0
		$data["solid"].each do |a|
			band = @rubberband.geometry
			if a.x == band.x && a.y == band.y && a.width == band.w && a.height == band.h
				index = 0
			end
		end
		$data["spawns"].each do |b|
			band = @rubberband.geometry
			if b.x == band.x && b.y == band.y && b.width == band.w && b.height == band.h
				@team = b.team
				index = 1
			end
		end

		@choices = FXComboBox.new(@options, 25)
		@choices.appendItem("Solid")
		@choices.appendItem("Spawn Area")
		@choices.setCurrentItem(index)
		@choices.connect(SEL_COMMAND) {|sender, sel, e| role_select(@choices.findItem(e))}

		create_spawn if index == 1
	end

	def create_spawn
		@spawn_team = FXComboBox.new(@options, 25)
		@spawn_team.appendItem("Red")
		@spawn_team.appendItem("Blue")
		@spawn_team.setCurrentItem(1) if @team == :blue
		@spawn_team.connect(SEL_COMMAND) {|sender, sel, e| team_select(@spawn_team.findItem(e))}
	end

	def role_select(index)
		if index == 0
			@spawn_team.hide
		elsif index == 1
			if @spawn_team.nil?
				create_spawn
				@spawn_team.create
				self.resize(self.width, self.height + 20)
			end
			@spawn_team.show
		end
	end

	def team_select(team)
		@team = team == 0 ? :red : :blue
	end

	def accept
		rect = @rubberband.geometry
		if @choices.itemCurrent?(1)
			$data["spawns"] << Spawn.new(rect.x, rect.y, rect.w, rect.h, @team)
		elsif @choices.itemCurrent?(0)
			$data["solid"] << Area.new(rect.x, rect.y, rect.w, rect.h)
		end
		super
	end
end

class EntityDialog < GenericDialog
	def initialize(pos, parent)
		super(parent, "Entity Dialog")

		@pos = pos

		$data["entities"].each do |entity|
			if entity.x == @pos[0] && entity.y == @pos[1]
				@entity = entity.name.gsub("Powerup", " Powerup").gsub("Point", " Point")
				@eimage = entity.image
				@extra = entity.extra
			end
		end


		@options = FXVerticalFrame.new(self, FRAME_SUNKEN|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 5, 0, 10, 10, 10, 10)
		@combo = FXComboBox.new(@options, 30)
		$entity_names.each do |i|
			@combo.appendItem(i)
		end
		@combo.setCurrentItem($entity_names.index(@entity))
		@label = FXLabel.new(@options, "Please enter the image location for this entity relative to the game top dir.")
		@image = FXTextField.new(@options, 50)
		@image.text = @eimage
		@combo.connect(SEL_COMMAND) {|sender, sel, e| entity_select(@combo.findItem(e))}

		@label_2 = FXLabel.new(@options, "Extra settings for entity: ")
		@settings = {}
		@extra ||= {}

		@table = FXTable.new(@options, nil, 0, TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0, 2, 2, 2, 2)
		@table.visibleRows = 2
		@table.visibleColumns = 2
		@table.setTableSize(5, 2)
		@table.setColumnHeaderMode(LAYOUT_FIX_HEIGHT)
		@table.setColumnHeaderHeight(0)
		@table.setRowHeaderMode(LAYOUT_FIX_HEIGHT)
		@table.connect(SEL_REPLACED) {|sender, sel, e| change_item(e)}

		i = 0
		@extra.each do |setting, value|
			@table.setItemText(i, 0, setting)
			@table.setItemText(i, 1, value)
			@settings[setting] = value
			i += 1
		end
	end

	def entity_select(entity)
		@entity = $entity_names[entity]
	end

	def accept
		$data["entities"].each do |e|
			if e.x == @pos[0] && e.y == @pos[1]
				e.name = @entity.delete(" ")
				e.image = @image.text
				e.extra ||= {}
				@settings.each do |label, text|
					e.extra[label] = text
				end
			end
		end
		super
	end

	def change_item(event)
		@settings[@table.getItemText(event.fm.row, 0)] = @table.getItemText(event.fm.row, 1)
	end
end

class FlagDialog < GenericDialog
	def initialize(pos, parent)
		super(parent, "Flag Dialog")

		@pos = pos

		@team = :red

		$data["flags"].each do |flag|
			if flag.x == @pos[0] && flag.y == @pos[1]
				@team = flag.type
			end
		end     

		@options = FXVerticalFrame.new(self, FRAME_SUNKEN|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 5, 0, 10, 10, 10, 10)
		@team_combo = FXComboBox.new(@options, 25)
		@team_combo.appendItem("Red")
		@team_combo.appendItem("Blue")
		@team_combo.setCurrentItem(@team == :red ? 0: 1)
		@team_combo.connect(SEL_COMMAND) {|sender, sel, e| team_select(@team_combo.findItem(e))}
	end

	def team_select(team)
		@team = team == 0 ? :red : :blue
	end

	def accept
		$data["flags"].each do |flag|
			if flag.x == @pos[0] && flag.y == @pos[1]
				flag.type = @team
			end
		end
		super
	end
end

class SpawnPointDialog < GenericDialog
	def initialize(pos, parent)
		super(parent, "Spawn Dialog")

		@pos = pos
	end

	def accept
		$data["spawns"] << SpawnPoint.new(@pos[0], @pos[1])
		$data["spawns"].uniq!
		super
	end
end

class MapSettings < GenericDialog
	def initialize(parent)
		super(parent, "Map Settings")

		@options = FXVerticalFrame.new(self, FRAME_SUNKEN|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 5, 0, 10, 10, 10, 10)

		@settings = {}
		@table = FXTable.new(@options, nil, 0, TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0, 2, 2, 2, 2)
		@table.visibleRows = 5
		@table.visibleColumns = 5
		@table.setTableSize(5, 2)
		@table.setColumnHeaderMode(LAYOUT_FIX_HEIGHT)
		@table.setColumnHeaderHeight(0)
		@table.setRowHeaderMode(LAYOUT_FIX_HEIGHT)
		@table.connect(SEL_REPLACED) {|sender, sel, e| change_item(e)}

		i = 0
		$data["settings"].each do |setting, value|
			@table.setItemText(i, 0, setting)
			@table.setItemText(i, 1, value)
			@settings[setting] = value
			i += 1
		end
	end

	def change_item(event)
		@settings[@table.getItemText(event.fm.row, 0)] = @table.getItemText(event.fm.row, 1)
	end

	def accept
		@settings.each do |label, text|
			$data["settings"][label] = text
		end
		super
	end
end

class TileDialog < GenericDialog
	def initialize(render_area, parent)
		super(parent, "Tile Dialog")

		@render_area = render_area
		@render_area.set_tool(0)
		@render_area.rubberbands = []

		@canvas = parent
		@canvas.update

		@options = FXVerticalFrame.new(self, FRAME_SUNKEN|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 5, 0, 10, 10, 10, 10)
		$data["solid"].each_with_index do |area, y|
			button = FXButton.new(@options, "x: #{area.x}, y: #{area.y}, width: #{area.width}, height: #{area.height}")
			band = FXRubberBand.new
			band.set_geometry(FXRectangle.new(*area))
			band.hide
			button.connect(SEL_COMMAND) {|sender, sel, e| clicked(y)}
			@render_area.rubberbands << band
		end
	end

	def clicked(id)
		if !@render_area.rubberbands[id].is_hidden?
			@render_area.rubberbands[id].hide
		else
			@render_area.rubberbands[id].show
		end
		@canvas.update
	end

	def accept
		@render_area.rubberbands.each {|x| x.hide}
		@canvas.update
		super
	end
	alias :cancel :accept
end

class TilesetAddDialog < GenericDialog
	include Common
	def initialize(renderarea, parent)
		super(parent, "Add Tileset")

		@parent = parent
		@renderarea = renderarea
		@content = FXVerticalFrame.new(self, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y)

		@tilewidth_frame = FXHorizontalFrame.new(@content, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@width_label = FXLabel.new(@tilewidth_frame, "Tile width:")
		@tilewidth = FXSpinner.new(@tilewidth_frame, 2)
		@tilewidth.value = renderarea.tilewidth
		@tilewidth.editable = false

		@tileheight_frame = FXHorizontalFrame.new(@content, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@height_label = FXLabel.new(@tileheight_frame, "Tile height:")
		@tileheight = FXSpinner.new(@tileheight_frame, 2)
		@tileheight.value = renderarea.tileheight

		@tileimage_frame = FXHorizontalFrame.new(@content, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@image_label = FXLabel.new(@tileimage_frame, "Tile image (relative to game top dir):")
		@image = FXTextField.new(@tileimage_frame, 25)
		@button = FXButton.new(@tileimage_frame, "Browse", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
		@button.connect(SEL_COMMAND) do |sender, sel, event|
			filename = FXFileDialog.getOpenFilename(self, "File Open", ".", "Image files (*.*)")
			filename = filename.gsub("\\","/")
			@image.text = filename if !filename.nil?
		end
	end

	def accept
		name = 0
		name = (@renderarea.tilesets[-1].name.to_i + 1).to_s if @renderarea.tilesets[-1]
		img = load_image(@image.text)

		return if img.nil?
		@renderarea.pixmaps[name.to_i] = img
		firstgid = 1
		firstgid = @renderarea.tilesets[-1].firstgid + @tilewidth.text.to_i if @renderarea.tilesets[-1]
		tileset = Tileset.new(name, @image.text, firstgid, @tilewidth.value, @tileheight.value)
		@renderarea.tilesets << tileset
		@parent.list.appendItem("Tileset #{name}")
		@parent.list.selectItem(@parent.list.numItems - 1, true)
		super
	end
end

class TileSelectDialog < GenericDialog
	attr_accessor :list
	def initialize(renderarea, parent)
		super(parent, "Tile Selection Dialog")
		resize(600, 300)

		@selected = [0, 0]
		@selection = false
		@selected_tileset = 0
		@pixmap = nil

		@renderarea = renderarea
		@options = FXHorizontalFrame.new(self, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 5, 0, 10, 10, 10, 10)
		@canvas_frame = FXVerticalFrame.new(@options, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 5, 0, 10, 10, 10, 10)
		@list_frame = FXVerticalFrame.new(@options, FRAME_SUNKEN|LAYOUT_RIGHT|LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y, 0, 0, 125, 0, 10, 10, 10, 10)

		@scroll_window = FXScrollWindow.new(@canvas_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@canvas_packer = FXPacker.new(@scroll_window, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@canvas = FXCanvas.new(@canvas_packer, nil, 0, LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT)

		@list = FXList.new(@list_frame, nil, 0, LAYOUT_FIX_WIDTH|LAYOUT_RIGHT|LAYOUT_FILL_Y, 0, 0, 100)
		@list.connect(SEL_SELECTED) {|sender, sel, event| changeTileset}

		@add_button = FXButton.new(@list_frame, "Add Tileset", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 0, 0, 0, 0)
		@remove_button = FXButton.new(@list_frame, "Remove Tileset", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 0, 0, 0, 0)

		@add_button.connect(SEL_COMMAND) {addTileset}
		@remove_button.connect(SEL_COMMAND) {removeTileset}

		@renderarea.tilesets.each_with_index do |tileset,i|
			@list.appendItem("Tileset #{i}") if !tileset.nil?
		end

		index = @selected_tileset
		index = @list.findItem("Tileset #{renderarea.tile[1]}") if !renderarea.tile.nil?
		if @list.numItems != 0 && @renderarea.tilesets[@list.getItemText(index).split(" ")[-1].to_i].nil?
			index = 0
			until @renderarea.tilesets[@list.getItemText(index).split(" ")[-1].to_i] != nil
				index = @list.getItemText(index).split(" ")[-1].to_i
			end
		end
		changeTileset(index) if @list.numItems != 0

		@canvas.connect(SEL_PAINT) {|sender, sel, event| onPaint(event)}   
		@canvas.connect(SEL_LEFTBUTTONPRESS) {|sender, sel, event| leftButtonPress(event)}   
		@canvas.connect(SEL_RIGHTBUTTONPRESS) {|sender, sel, event| rightButtonPress(event)}  
	end

	def changeTileset(index = nil)
		index ||= @list.currentItem
		if index > -1
			@list.selectItem(index)
			@selected_tileset = @list.getItemText(index).split(" ")[-1].to_i
			@tilewidth = @renderarea.tilesets[@selected_tileset].tilewidth
			@tileheight = @renderarea.tilesets[@selected_tileset].tileheight
			@firstgid = @renderarea.tilesets[@selected_tileset].firstgid
			@pixmap = @renderarea.pixmaps[@selected_tileset]
			@canvas.resize(@pixmap.width, @pixmap.height)
		else
			@pixmap = nil
			@canvas.resize(0, 0)
		end
		@canvas.update
	end

	def addTileset
		dialog = TilesetAddDialog.new(@renderarea, self)
		dialog.execute_nonmodal
	end

	def removeTileset
		index = @list.getItemText(@list.currentItem).split(" ")[-1].to_i
		@renderarea.tilesets[index] = nil
		@renderarea.pixmaps[index] = nil
		add = 1
		if @list.currentItem == @list.numItems - 1
			add = -1
		end
		index = @list.currentItem + add
		changeTileset(index)
		@list.removeItem(@list.currentItem)
	end

	def onPaint(event)
		FXDCWindow.new(@canvas, event) do |dc|
			dc.foreground = "white"

			(0..@pixmap.width / @tilewidth - 1).each do |x|
				(0..@pixmap.height / @tileheight - 1).each do |y|
					tilenum = (x + (@pixmap.width / @tilewidth) * y)
					yimage = tilenum % (@pixmap.width / @tilewidth)
					ximage = (tilenum - yimage) / (@pixmap.height / @tileheight)
					dc.drawArea(@pixmap, yimage * @tilewidth, ximage * @tileheight, @tilewidth, @tileheight, x * @tilewidth, y * @tileheight)
					if @selection && x == @selected[0] && y == @selected[1]
						dc.foreground = "blue"
						dc.fillRectangle(x * @tilewidth, y * @tileheight, @tilewidth, @tileheight)
					end
				end
			end if @pixmap
		end
	end

	def leftButtonPress(e)
		x = e.click_x - (e.click_x % @tilewidth)
		y = e.click_y - (e.click_y % @tileheight)
		@selection = true
		@selected = [(x  - (x % @tilewidth)) / @tilewidth, (y - (y % @tileheight)) / @tileheight]
		@canvas.update
	end

	def rightButtonPress(e)
		@selection = false
		@canvas.update
	end

	def accept
		if @selection
			tilenum = @selected[0] + ((@pixmap.width / @tilewidth) * @selected[1])
			new_image = FXIcon.new($app, nil, 0, IMAGE_OPAQUE, @tilewidth, @tileheight)
			new_image.create
			FXDCWindow.new(new_image) do |dc|
				yimage = tilenum % (@pixmap.width / @tilewidth)
				ximage = (tilenum - yimage) / (@pixmap.height / @tileheight)
				dc.drawArea(@pixmap, yimage * @tilewidth, ximage * @tileheight, @tilewidth, @tileheight, 0, 0)
			end

			@renderarea.tile_button.icon = new_image
			@renderarea.tile = [@selected, @selected_tileset, @firstgid]
			@renderarea.redraw_back
		end
		super
	end
end

class NewMap < GenericDialog
	def initialize(parent)
		super(parent, "New Map")

		@window = parent
		@top = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y)

		@name_options = FXHorizontalFrame.new(@top, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@namelabel = FXLabel.new(@name_options, "Map name:")
		@nametext = FXTextField.new(@name_options, 25)

		@options = FXHorizontalFrame.new(@top, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@mapoptions = FXVerticalFrame.new(@options, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@maplabel = FXLabel.new(@mapoptions, "Map Size")
		@mapheightframe = FXHorizontalFrame.new(@mapoptions, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@mapheightlabel = FXLabel.new(@mapheightframe, "Height:")
		@mapheight = FXSpinner.new(@mapheightframe, 2) 
		@mapheight.value = 50
		@mapwidthframe = FXHorizontalFrame.new(@mapoptions, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@mapheightlabel = FXLabel.new(@mapwidthframe, "Width: ")
		@mapwidth = FXSpinner.new(@mapwidthframe, 2) 
		@mapwidth.value = 50

		@tileoptions = FXVerticalFrame.new(@options, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@tilelabel = FXLabel.new(@tileoptions, "Tile Size")
		@tileheightframe = FXHorizontalFrame.new(@tileoptions, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@tileheightlabel = FXLabel.new(@tileheightframe, "Height:")
		@tileheight = FXSpinner.new(@tileheightframe, 2)
		@tileheight.value = 32
		@tilewidthframe = FXHorizontalFrame.new(@tileoptions, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@tilewidthlabel = FXLabel.new(@tilewidthframe, "Width: ")
		@tilewidth = FXSpinner.new(@tilewidthframe, 2)
		@tilewidth.value = 32

		@background_options = FXVerticalFrame.new(@top, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@tileimage_frame = FXHorizontalFrame.new(@background_options, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@image_label = FXLabel.new(@tileimage_frame, "Background image (optional):")
		@image = FXTextField.new(@tileimage_frame, 25)
		@button = FXButton.new(@tileimage_frame, "Browse", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT)
		@button.connect(SEL_COMMAND) do |sender, sel, event|
			filename = FXFileDialog.getOpenFilename(self, "File Open", ".", "Image files (*.*)")
			filename = filename.gsub("\\","/")
			@image.text = filename if !filename.nil?
		end

	end

	def accept
		@window.map = Map.new(@mapwidth.value, @mapheight.value, @tilewidth.value, @tileheight.value)
		@window.map.background = @image.text
		@window.map.name = @nametext.text 
		if @window.map.name == "" || @window.map.name.nil?
			@window.map.name ="nil"
		end

		$data = {}
		$data["solid"] = []
		$data["flags"] = []
		$data["spawns"] = []
		$data["entities"] = []
		$data["settings"] = {}

		$entity_names = YAML::load(File.open("lib/entities.yaml"))

		if @window.map.background.nil? || @window.map.background == ""
			layer = Layer.new("Layer 0", nil, @window.map.map_width, @window.map.map_height, [])
			(0..@window.map.map_width - 1).each do |x|
				(0..@window.map.map_height - 1).each do |y|
					layer.tiles[y] = [] if !layer.tiles[y]
					layer.tiles[y][x] = 0
				end
			end
			@window.map.layers << layer
		end

		@window.set_canvas
		super
	end
end

class LayerAddDialog < GenericDialog
	def initialize(parent)
		super(parent, "Add Layer")

		@window = parent
		@top = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y)

		@mapoptions = FXVerticalFrame.new(@top, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@maplabel = FXLabel.new(@mapoptions, "Layer size")
		@mapheightframe = FXHorizontalFrame.new(@mapoptions, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@mapheightlabel = FXLabel.new(@mapheightframe, "Height:")
		@mapheight = FXSpinner.new(@mapheightframe, 2)
		@mapheight.value = 50
		@mapwidthframe = FXHorizontalFrame.new(@mapoptions, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@mapheightlabel = FXLabel.new(@mapwidthframe, "Width: ")
		@mapwidth = FXSpinner.new(@mapwidthframe, 2)
		@mapwidth.value = 50
	end

	def accept
		layer_num = @window.map.layers.length
		layer = Layer.new("Layer #{layer_num}", nil, @mapwidth.value, @mapheight.value, [])

		(0..layer.width - 1).each do |x|
			(0..layer.height - 1).each do |y|
				layer.tiles[y] = [] if !layer.tiles[y]
				layer.tiles[y][x] = 0
			end
		end

		@window.map.layers << layer
		@window.set_canvas(false)
		super
	end
end


