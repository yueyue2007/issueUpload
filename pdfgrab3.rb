#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

require 'roo'
require 'builder'
# require 'pdf-reader'
require 'builder'
require 'base64'
require 'date'



#1. 检查参数及配置文件是否存在？
usage  = '''
	本程序读取ods文件中的参数，生成最终的xml文件 。
    pdfgrab3.rb step2.ods
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



xml_file = "#{tree['journal_path']}_#{tree['year']}_#{tree['number']}.xml"


#调用php，导入刊期和文章
 phpcommand = " sudo php  /var/www/ojs/tools/importExport.php NativeImportExportPlugin import "
 phpcommand << xml_file
 phpcommand << " "+tree['journal_path']+" "+tree["username"]

 puts "using the following commands importing articles ..."
 puts phpcommand
 system(phpcommand)