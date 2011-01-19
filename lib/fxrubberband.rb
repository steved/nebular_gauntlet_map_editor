class FXRubberBand
	attr_reader	:geometry
	def initialize
		@geometry = nil
		@hidden = false
	end

	def set_geometry(rect)
		@geometry = rect
	end

	def resize(width, height)
		@geometry.w = width
		@geometry.h = height
	end

	def move(x, y)
		@geometry.x = x
		@geometry.y = y
	end

	def hide
		@hidden = true
	end

	def show
		@hidden = false
	end

	def is_hidden?
		@hidden
	end

	def draw(dc)
		return if @hidden
		dc.foreground = "white"
		if @geometry.w <= 0 && @geometry.h >= 0 
			dc.drawRectangle(@geometry.x + @geometry.w, @geometry.y, @geometry.w.abs, @geometry.h)
		elsif @geometry.h <= 0 && @geometry.w >= 0
			dc.drawRectangle(@geometry.x, @geometry.y + @geometry.h, @geometry.w, @geometry.h.abs)
		elsif @geometry.w <= 0 && @geometry.h <= 0
			dc.drawRectangle(@geometry.x + @geometry.w, @geometry.y + @geometry.h, @geometry.w.abs, @geometry.h.abs)
		else
			dc.drawRectangle(@geometry.x, @geometry.y, @geometry.w, @geometry.h)
		end
	end
end
