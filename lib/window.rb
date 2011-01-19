require 'lib/common'
require 'lib/map'
require 'lib/fxrubberband'
require 'lib/renderarea'
require 'lib/map_renderarea'
require 'lib/property_dialog'
require 'enumerator'

Area = Struct.new(:x, :y, :width, :height)
Flag = Struct.new(:x, :y, :type)
Spawn = Struct.new(:x, :y, :width, :height, :team)
SpawnPoint = Struct.new(:x, :y)
Entity = Struct.new(:name, :image, :x, :y, :extra)
Tileset = Struct.new(:name, :image, :firstgid, :tilewidth, :tileheight)
Layer = Struct.new(:name, :opacity, :width, :height, :tiles)

class MainWindow < FXMainWindow
  attr_accessor :map
  include Common


  def initialize(app)
    super(app, "Map Editor for Nebular Gauntlet", nil, nil, DECOR_ALL, 0, 0, 640, 480)

    menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    FXHorizontalSeparator.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE)

    @contents = FXHorizontalFrame.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @tab_book = FXTabBook.new(@contents, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

    @tab1 = FXTabItem.new(@tab_book, "Entity Editor", nil)
    @contents = FXHorizontalFrame.new(@tab_book, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @buttons = FXVerticalFrame.new(@contents, FRAME_SUNKEN|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 5, 0, 10, 10, 10, 10)
    general = FXLabel.new(@buttons, "General Tools", nil,JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @map_settings = FXButton.new(@buttons, "Basic Map Settings", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    @selection_button = FXButton.new(@buttons, "Selection Rectangle", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    @remove_button = FXButton.new(@buttons, "Object Remover", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)      
    @solid_areas = FXButton.new(@buttons, "Solid Areas", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    single_player = FXLabel.new(@buttons, "Single Player Tools", nil, JUSTIFY_CENTER_X|LAYOUT_FILL_X)      
    @entity_button = FXButton.new(@buttons, "Entity Placer", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)          
    @spawn_button = FXButton.new(@buttons, "Spawn Point Placer", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    multiplayer = FXLabel.new(@buttons, "MultiPlayer Tools", nil, JUSTIFY_CENTER_X|LAYOUT_FILL_X)
    @flag_button = FXButton.new(@buttons, "Flag Placer", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    @areas_button = FXButton.new(@buttons, "Solid/Spawn Areas", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)

    @canvas_frame = FXVerticalFrame.new(@contents, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 10, 10)
    @scroll_window = FXScrollWindow.new(@canvas_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @canvas_packer = FXPacker.new(@scroll_window, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @canvas = FXCanvas.new(@canvas_packer, nil, 0, LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, 0, 0, 1024, 1024)
    @canvas.connect(SEL_PAINT) {|sender, sel, event| onPaint(@canvas)}

    @tab2 = FXTabItem.new(@tab_book, "Map Editor", nil)
    @map_contents = FXHorizontalFrame.new(@tab_book, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @map_buttons = FXVerticalFrame.new(@map_contents, FRAME_SUNKEN|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 5, 0, 10, 10, 10, 10)
    @place_tool = FXButton.new(@map_buttons, "Place", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    @eraser_tool = FXButton.new(@map_buttons, "Eraser", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    @tileselect_dialog = FXButton.new(@map_buttons, nil, nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5) 
    @layer_list = FXList.new(@map_buttons, nil, 0, LAYOUT_FIX_WIDTH|LAYOUT_RIGHT|LAYOUT_FILL_Y, 0, 0, 100)
    @layer_button = FXButton.new(@map_buttons, "Add Layer", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)
    @layer_delete_button = FXButton.new(@map_buttons, "Delete Layer", nil, nil, 0, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 5, 5)

    @map_canvas_frame = FXVerticalFrame.new(@map_contents, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT, 0, 0, 0, 0, 10, 10, 10, 10)
    @map_scroll_window = FXScrollWindow.new(@map_canvas_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @map_canvas_packer = FXPacker.new(@map_scroll_window, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @map_canvas = FXCanvas.new(@map_canvas_packer, nil, 0, LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, 0, 0, 1024, 1024)
    @map_canvas.connect(SEL_PAINT) {|sender, sel, event| onPaint(@map_canvas)}

    filemenu = FXMenuPane.new(self)
    FXMenuCommand.new(filemenu, "New").connect(SEL_COMMAND) {new_map()}
    FXMenuCommand.new(filemenu, "Open").connect(SEL_COMMAND) {open()}
    FXMenuCommand.new(filemenu, "Save").connect(SEL_COMMAND) {save()}
    FXMenuCommand.new(filemenu, "Save Config As").connect(SEL_COMMAND) {save_config_as()}
    FXMenuCommand.new(filemenu, "Save Map As").connect(SEL_COMMAND) {save_map_as()}
    FXMenuSeparator.new(filemenu)
    FXMenuCommand.new(filemenu, "Exit", nil, $app, FXApp::ID_QUIT, 0)
    FXMenuTitle.new(menubar, "File", nil, filemenu)
  end

  def create
    super
    show(PLACEMENT_SCREEN)
  end

  def onPaint(canvas)
    FXDCWindow.new(canvas) do |dc|
      dc.foreground = "black"
      dc.fillRectangle(0, 0, canvas.width, canvas.height)
    end
  end

  def open
    @filename = FXFileDialog.getOpenFilename(self, "File Open", ".", "YAML Map Files (*.yaml)")
    if @filename != ""
      parse_map(@filename)
      set_canvas
    end
  end

  def save_config_as(filename = nil)
    return if !@render_area

    if filename.nil? || filename == ""
      filename = FXFileDialog.getSaveFilename(self, "File Save", ".", "YAML Config Files (*.yaml)")
    end

    filename += ".yaml" if !filename.include?(".yaml")

    File.open(filename, "w") do |file|
      YAML.dump($data, file)
    end
  end

  def save_map_as(filename = nil)
    return if !@map_renderarea

    if filename.nil? || filename == ""
      filename = FXFileDialog.getSaveFilename(self, "File Save", ".", "YAML Map Files (*.yaml)")
    end

    filename += ".yaml" if !filename.include?(".yaml")

    layers = []
    @map_renderarea.layers.each_with_index do |tile, ti|
      tiles = []
      tile.each do |x|
        x.each_with_index do |y,i|
          tiles << (y[2] + y[0])
        end
      end
      map_rows = []
      tiles.each_slice(@map.layers[ti].width) {|slice| map_rows << slice}
      layers << map_rows
    end

    output = {}
    output["map"] = {"tilesets" => {}, "width" => @map.map_width, "height" => @map.map_height, "tilewidth" => @map.tilewidth, "tileheight" => @map.tileheight, "layers" => {}}

    if @map.background
      output["map"]["background"] = @map.background.split("/")[-1]
    end

    @map.layers.each_with_index do |layer,i|
      output["map"]["layers"][layer.name] = {"opacity" => layer.opacity, "width" => layer.width, "height" => layer.height, "data" => layers[i]}
    end

    @map.tilesets.each do |tileset|
      next if tileset.nil?
      output["map"]["tilesets"][tileset.name] = {"image" => tileset.image, "firstgid" => tileset.firstgid, "tileheight" => tileset.tileheight, "tilewidth" => tileset.tilewidth}
    end

    File.open(filename, "w") do |file|
      YAML::dump(output, file)
    end
  end

  def save
    return if !@map

    dir = @map.dir
    if dir.nil? || dir == ""
      dir = FXFileDialog.getOpenDirectory(self, "Choose a directory to save files to", ".")
    end
    return if dir.nil? || dir == ""

    if !File.directory?("#{dir}/data")
      Dir.mkdir("#{dir}/data")
    end

    if !File.directory?("#{dir}/images")
      Dir.mkdir("#{dir}/images")
    end

    save_map_as("#{dir}/#{@map.name}")
    save_config_as("#{dir}/data/entities")
  end

  def new_map
    dialog = NewMap.new(self)
    dialog.execute_nonmodal
  end

  def new_layer
    dialog = LayerAddDialog.new(self)
    dialog.execute_nonmodal
  end

  def delete_layer
    @map.layers.delete_at(@layer_list.currentItem)
    @map_renderarea.layers.delete_at(@layer_list.currentItem)
    @layer_list.removeItem(@layer_list.currentItem)
    @map_renderarea.redraw_back
  end

  def parse_map(file)
    @map = Map.new
    @map.load_map(file)
    @map.load_tiles

    begin
      yaml_file = "#{@map.dir}/data/entities.yaml"
      yaml_file += ".1_8" if RUBY_VERSION =~ /1.8/
      $data = YAML::load(File.open(yaml_file))	
    rescue => e
      puts "Error loading YAML file: #{e}"
      $data = {}
    ensure
      $data["solid"] ||= []
      $data["flags"] ||= []
      $data["spawns"] ||= []
      $data["entities"] ||= []
      $data["settings"] ||= {}
    end

    $entity_names = YAML::load(File.open("lib/entities.yaml"))
  end

  def set_canvas(reload_pixmaps = true)
    if reload_pixmaps
      @pixmaps = []
      @map.tilesets.each do |set|
        image = load_image(File.dirname(@filename) + "/images/" + set.image.split("/")[-1])
        return if image.nil?
        @pixmaps << image
      end
    end

    @canvas.resize(@map.width, @map.height)
    @map_canvas.resize(@map.width, @map.height)

    @render_area = RenderArea.new(@map.width, @map.height, @canvas)
    @render_area.set_tiles(@map)
    @render_area.scroll_window = @scroll_window

    @map_renderarea = MapRenderArea.new(@map.width, @map.height, @map_canvas)
    @map_renderarea.set_tiles(@map, @pixmaps)
    @map_renderarea.scroll_window = @map_scroll_window
    @map_renderarea.tile_button = @tileselect_dialog

    @layer_list.clearItems
    @map.layers.each_with_index do |layer, n|
      @layer_list.appendItem(layer.name)
      (0..layer.height - 1).each do |x|
        (0..layer.width - 1).each do |y|
          tile = layer.tiles[x][y]

          if tile == 0
            next
          elsif tile > 0
            ttileset = nil
            pixmap = nil

            @map.tilesets.each_with_index do |tileset,i|
              if ttileset.nil?
                ttileset = tileset
                pixmap = @pixmaps[i]
              elsif tile >= tileset.firstgid
                ttileset = tileset
                pixmap = @pixmaps[i]
              end
            end
          end

          tile = tile - ttileset.firstgid
          @map_renderarea.set_tile(y, x, tile, pixmap, n, ttileset.firstgid)
        end
      end
    end
    @layer_list.selectItem(0) if @layer_list.numItems > 0
    @map_renderarea.redraw_back
    @render_area.map_renderarea = @map_renderarea

    @selection_button.connect(SEL_COMMAND) {@render_area.set_tool(0)}
    @entity_button.connect(SEL_COMMAND) {@render_area.set_tool(1)}
    @remove_button.connect(SEL_COMMAND) {@render_area.set_tool(2)}
    @flag_button.connect(SEL_COMMAND) {@render_area.set_tool(3)}
    @spawn_button.connect(SEL_COMMAND) {@render_area.set_tool(4)}
    @areas_button.connect(SEL_COMMAND) {@render_area.toggle_bands} 
    @map_settings.connect(SEL_COMMAND) {@render_area.map_settings}  
    @solid_areas.connect(SEL_COMMAND) {@render_area.solid_area}   

    @tileselect_dialog.connect(SEL_COMMAND) {@map_renderarea.tile_dialog}
    @layer_list.connect(SEL_COMMAND) {|sender, sel, event| @map_renderarea.selected_layer = event}
    @place_tool.connect(SEL_COMMAND) {@map_renderarea.tool = 0}
    @eraser_tool.connect(SEL_COMMAND) {@map_renderarea.tool = 1}
    @layer_button.connect(SEL_COMMAND) {new_layer}
    @layer_delete_button.connect(SEL_COMMAND) {delete_layer}
  end
end
