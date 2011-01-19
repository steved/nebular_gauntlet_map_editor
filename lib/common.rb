module Common
  def has_extension(filename, ext)
    File.basename(filename, ext) != File.basename(filename)
  end	

  def load_image(file)
    if has_extension(file, ".gif")
      img = FXGIFImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".bmp")
      img = FXBMPImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".xpm")
      img = FXXPMImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".png")
      img = FXPNGImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".jpg")
      img = FXJPGImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".pcx")
      img = FXPCXImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".tif")
      img = FXTIFImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".tga")
      img = FXTGAImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    elsif has_extension(file, ".ico")
      img = FXICOImage.new($app, nil, IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP)
    end

    # Perhaps failed?
    if !img
      warn "Error loading image type: #{file}"
      return
    end

    begin
      FXFileStream.open(file, FXStreamLoad) { |stream| img.loadPixels(stream) }
      img.create
    rescue
      warn "Error loading image file: #{file}"
      return
    end
    return img
  end
end
