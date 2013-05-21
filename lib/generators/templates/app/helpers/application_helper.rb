module ApplicationHelper

  ##
	# Page Titles - Set individual page title elements
  # Accepts a String or Array.
  # Sets yield(:title) to a String for use in <title>.
  #
  #   --Array--
  #   title ["Example", "Nashville, TN"]
  #   => "Example - Page - Title"
  #
  #   --String--
  #   title "Example Page Title"
  #   => "Example Page Title"
  #
  def title title_partials
    title = if title_partials.is_a? String
      title_partials
    elsif title_partials.is_a? Array
      title_partials.reject(&:blank?).join(' - ')
    end
    content_for(:title) { title }
  end


  ##
  # Display IcoMoon font icon
  #
  def icon key
    raw "<i data-icon=&#x#{h(key)}></i>"
  end


  ##
  # SVG Image tag with a fallback for the Modernizr script
  #
  def svg_image_tag filename, options = {}
    filename.gsub! /\.svg$/i, ""
    options["data-svg-fallback"] ||= asset_path("#{filename}.png")
    image_tag "#{filename}.svg", options
  end


	##
	# Date: Jan 1, 2012
	#
	def date_short(date)
		date.strftime("%b %e, %Y") if !date.blank?
	end


	##
	# Date: 1/1/2012
	#
	def date_compact(date)
		date.strftime("%-m/%-d/%Y") if !date.blank?
	end

end
