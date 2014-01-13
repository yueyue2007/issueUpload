# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby
require 'rexml/document'
require 'base64'
require 'optparse'
include REXML


#analysis the command line 
options = {}
option_parser = OptionParser.new do |opts|
	opts.banner = "ojs upload program: add html embed to xml\n
	               ruby xmltest.rb -s issue.xml"
	options[:switch] = false
	opts.on('-s','--switch','turn pdf into png first switch') do 
		options[:switch] = true 
	end	
end.parse!

if ARGV.length == 0
	puts "no xml file,exiting..."
	puts "please input -h to get help"
	exit 
end

file = File.open(ARGV[0])

doc = Document.new file
root = doc.root 

pdf_files = []

articles = root.elements.to_a("//section/article")
articles.each do |article|
	#put article title
	puts article.elements["title"].text 
	galley = article.elements["galley"]

	#tiqu pdf base64 and save 
	filename = galley.elements["file"].elements["embed"].attributes["filename"]
	p filename 
	pdf_files << filename 
	pdf_content = Base64.decode64(galley.elements["file"].elements["embed"].text )
	File.open(filename,'w+') do |f|
		f << pdf_content 
	end

	# 将pdf转为html
	html_filename = File.basename(filename,".pdf") + ".html"
	puts html_filename
	unless options[:switch]
		pdf2html = "pdf2htmlEX  "
		pdf2html << filename		
		pdf2html << "  "<<html_filename
		puts "transforming article pdf to html.."
		system(pdf2html)
	else
		#transform the pdf into png
		commstr = "mkdir pngdir"
		system(commstr)

		commstr = "pdftoppm -png "
		commstr << "#{filename}  pngdir/#{File.basename(filename,'.pdf')}"
		puts commstr
		system(commstr)

		commstr = "convert pngdir/*.png "
		commstr << filename
		puts commstr
		system(commstr)

		pdf2html = "pdf2htmlEX  "
		pdf2html << filename		
		pdf2html << "  "<<html_filename
		puts "transforming article pdf to html.."
		system(pdf2html)

		commstr = "rm -r pngdir"
		system(commstr)			
		
	end
	

	# 将html加入到xml中
	html_galley = Element.new "htmlgalley"
	html_galley.attributes["locale"] = "zh_CN"
	label = html_galley.add_element "label"
	label.text = "HTML"
	html_file = html_galley.add_element "file"
	embed = html_file.add_element "embed"
	embed.attributes["encoding"] = "base64"
	embed.attributes["filename"] = html_filename
	embed.attributes["mime_type"] = "application/html"
	File.open(html_filename) do |f|
		embed.text = Base64.encode64(f.read)		
	end

	article.insert_before galley, html_galley	
end
# 保存到新文件中	
new_file_name = File.basename(ARGV[0],".xml")
new_file_name += "_html.xml"
puts new_file_name
new_file = File.new(new_file_name,"w+")
doc.write new_file

# 将所有的pdf文件和成一个，并html格式,check whether there is error occured?

commstr = "rm *.html"
puts "deleteing all generated  html files ..."
system(commstr)

commstr = "pdfunite  "
pdf_files.each {|pdf| commstr << "#{pdf}  "}
commstr << " sum.pdf"
puts commstr
puts "unite all the pdf into one pdf:sum.pdf"
system(commstr)

commstr = "pdf2htmlEX sum.pdf "
puts "transfoming the sum.pdf into sum.html..."
system(commstr)

commstr = "rm *.pdf"
system(commstr)


