Dir.chdir(File.expand_path(File.dirname(__FILE__)))
require 'rubygems'
gem "fxruby"
require 'fox16'
include Fox
require 'lib/window'

app = FXApp.new("Map Editor", "Nebular Gauntlet")
$app = app
MainWindow.new(app)
app.create
app.run
