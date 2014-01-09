#!/usr/bin/env ruby
require 'rexml/document'
require 'base64'
include REXML

file = File.open("issue-45.xml")

doc = Document.new file
root = doc.root 

articles = root.elements.to_a("//section/article")
articles.each do |article|
	#put article title
	p article.elements[1].text 
	galley = article.elements[5]

	#tiqu pdf base64 and save 
	filename = galley.elements["file"].elements["embed"].attributes["filename"]
	pdf_content = Base64.decode64(galley.elements["file"].elements["embed"].text )
	File.open(filename,'w+') do |f|
		f << pdf_content 
	end

	# 将pdf转为html
	pdf2html = "pdf2htmlEX  "
	pdf2html << filename
	html_filename = File.basename(filename,".pdf") + ".html"
	puts html_filename
	pdf2html << "  "<<html_filename
	system(pdf2html)
	# 将html加入到xml中


	# 保存到新文件中

	new_file = File.new("new.xml","w+")
	doc.write new_file 
	# 将所有的pdf文件和成一个，并专程html格式...


end