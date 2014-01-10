# -*- encoding : utf-8 -*-
require 'prawn'
require 'prawn/layout'

Prawn::Document.generate("image.pdf") do |pdf|
	pdf.font "#{Prawn::BASEDIR}/data/fonts/msyh.ttf"
	puts Prawn::BASEDIR
	pdf.text "爱还"
	pdf.image "sihua-1.png",:width => 400

end
