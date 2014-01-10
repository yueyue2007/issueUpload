#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-


################################################################
#   本程序的目的是生成最终要使用的xlsx文件
#   2013-12-11
################################################################

require 'roo'
require 'builder'
# require 'pdf-reader'
require 'builder'
require 'base64'
require 'date'


def  print_tree(tree)
  str  =  %Q{
    pdf文件    ： #{tree['filename']}
    标题       ： #{tree['title']}
    Volume:#{tree['volume']}  number: #{tree['number']}  year : #{tree['year']} 
    期刊路径   ： #{tree['journal_path']}
    管理员账户 ： #{tree['username']}
  }
  puts str
  puts ""
  tree['sections'].each do |section|
    puts sprintf("    栏目：%15.15s  文章数：%4d",section['title'],section['articles'].length)
    puts ""
    section['articles'].each do |article|
      puts "      #{article['title']}   #{article['author_CN']}   #{article['pages']}"
      puts ""
    end
  end
end

#1. 检查参数及配置文件是否存在？
usage  = '''
	本程序读取ods文件中的参数，生成最终的xml文件 。
    pdfgrab2.rb step2.ods
	'''

if !(ARGV.length == 1)
  puts usage
  exit;
end

#1 检查ods文件是否存在？
if !File.exist?(File.expand_path(ARGV[0]))
  puts "step2.ods文件不存在，请检查参数是否正确。"
  exit
end

oo = Roo::OpenOffice.new("step2.ods")
oo.default_sheet = oo.sheets.first


#从ods文件中提取信息，保存到tree中
tree  =  {}
# tree['filename']      =  oo.cell(1,'B')
tree['title']         =  oo.cell(2,'B')
tree['volume']        =  oo.cell(3,'B').to_i
tree['number']        =  oo.cell(4,'B').to_i
tree['year']          =  oo.cell(5,'B').to_i
# tree['amend']         =  oo.cell(6,'B').to_i
tree['journal_path']  =  oo.cell(7,'B')
tree['username']      =  oo.cell(8,'B')

tree['sections']      =  []

11.upto(oo.last_row) do |row|
  if oo.cell(row,'A')  #是栏目行
    section ={}
    section['title']  =  oo.cell(row,'A')
    #section['abbr']  =  oo.cell(row,'B')
    section['articles'] = []
    tree['sections'] << section
  elsif oo.cell(row,'B')
    article  =  {}
    article['title']      =  oo.cell(row,'B')
    article['author_CN']  =  oo.cell(row,'D')
    article['author_EN']  =  oo.cell(row,'E')
    article['abstract']   =  oo.cell(row,'C')
    article['pdf_file']   =  oo.cell(row,'F')   
    article['email']      = "  "
    tree['sections'][-1]['articles'] << article
  end
end

print_tree(tree)

#4  生成XML文件

builder = Builder::XmlMarkup.new
builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
builder.declare! :DOCTYPE,:issues,:SYSTEM,"native.dtd"
xml = builder.issues do |is|
  is.issue(:published=>"true",:identification=>"title",:current=>"false") do |issue|
    issue.title("#{tree['title']}",:locale=>"zh_CN")    
    issue.access_date(Time.now.strftime("%m-%d-%Y"))
    issue.volume("#{tree['volume']}")
    issue.number("#{tree['number']}")
    issue.year("#{tree['year']}")
    tree['sections'].each do |section_yaml|
      issue.section do |section_xml|
        section_xml.title("#{section_yaml['title']}",:locale=>"zh_CN")
        #section_xml.abbrev("#{section_yaml['abbrev']}",:locale=>"zh_CN")
        section_yaml['articles'].each do |article_yaml|
          section_xml.article(:locale=>"zh_CN") do |article_xml|
            article_xml.title("#{article_yaml['title']}",:locale=>"zh_CN")
            article_xml.abstract("#{article_yaml['abstract']}",:locale=>"zh_CN")
            article_xml.author(:primary_contact=>"true") do |author|
              author.firstname("#{article_yaml['author_CN']}")
              author.lastname("#{article_yaml['author_EN']}")
              author.email("#{article_yaml['email']}"+"   ")
            end
            article_xml.date_published(Time.now.strftime("%m-%d-%Y"))
            article_xml.galley(:locale=>"zh_CN") do |galley|
              galley.label("PDF")
              galley.file  do |file|               
                filename = article_yaml['pdf_file']
                puts filename
               # p filename
                File.open(filename,'rb') do |f|
                  data = f.read
                  encode_data = Base64.encode64(data)
                  file.embed("#{encode_data}",:filename=>"#{article_yaml['pdf_file']}",:encoding=>"base64",:mime_type=>"application/pdf")
                end                 
             end                
            end
          end
        end
      end
    end
  end
end


xml_file = "#{tree['journal_path']}_#{tree['year']}_#{tree['number']}.xml"
puts ""
puts "...生成XML导入文件：  #{xml_file}"
File.open(xml_file,"w") {|f| f<<xml}


#调用php，导入刊期和文章
 # phpcommand = " sudo php  /var/www/ojs/tools/importExport.php NativeImportExportPlugin import "
 # phpcommand << xml_file
 # phpcommand << " "+tree['journal_path']+" "+tree["username"]

 # puts "using the following commands importing articles ..."
 # puts phpcommand
 # system(phpcommand)
