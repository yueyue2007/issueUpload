# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'roo'
require 'builder'
require 'base64'
require 'date'
require 'optparse'
require 'pdf-reader'
require 'net/ssh'
require 'net/scp'

def  print_tree(tree)
  str  =  %Q{
    pdf文件    ： #{tree['filename']}
    标题       ： #{tree['title']}
    number: #{tree['number']}  year : #{tree['year']} 
    期刊路径   ： #{tree['journal_path']}
    管理员账户 ： #{tree['username']}
  }
  puts str
  puts ""
  tree['sections'].each do |section|
    puts sprintf("    栏目：%15.15s  文章数：%4d",section['title'],section['articles'].length)
    puts ""
    section['articles'].each do |article|
      puts "      #{article['title']}   #{article['author_CN']}   #{article['pages']} --  #{article['pages_end']}"
      puts ""
    end
  end
end

#1. 检查参数及配置文件是否存在？
options = {}
options_parser = OptionParser.new do |opts|
  opts.banner = "期刊文章上传程序，用法如下： \n 
    ruby xmlbuild2 --pdf PDF --xlsx XLSX "
  opts.on("--pdf PDF","提交的pdf文件名") do |pdf|
    options[:pdf_file] = pdf 
  end

  opts.on("--xlsx XLSX","包含目录页的xlsx文件名") do |xlsx|
    options[:xlsx_file] = xlsx 
  end
end.parse!
unless options[:pdf_file]&&options[:xlsx_file]
  puts "缺少参数，请输入ruby xmlbuild.rb -h查看帮助。"
  exit
end

puts options.inspect

if !File.exist?(options[:pdf_file])
  puts "文件#{options[:pdf_file]}不存在，请检查参数是否正确。"
  exit
end

if !File.exist?(options[:xlsx_file])
  puts "文件#{options[:xlsx_file]}不存在，请检查参数是否正确。"
  exit
end

puts "读取xlsx文件，开始分析参数..."

#2 导入xlsx配置文件，分析其参数是否正确？
oo = Roo::Excelx.new(options[:xlsx_file])
oo.default_sheet = oo.sheets.first

tree  =  {}
tree['filename']      =  options[:pdf_file]
tree['title']         =  oo.cell(2,'B')
# tree['volume']        =  oo.cell(3,'B').to_i
tree['number']        =  oo.cell(3,'B').to_i
tree['year']          =  oo.cell(4,'B').to_i
tree['amend']         =  oo.cell(5,'B').to_i
tree['journal_path']  =  oo.cell(6,'B')
tree['username']      =  oo.cell(7,'B')

tree['sections']      =  []
pathname  =  File.dirname(tree['filename']) #暂时不用
basename  =  File.basename(tree['filename'],".pdf")

pages = Array.new
10.upto(oo.last_row) do |row|
  if oo.cell(row,'A')  #是栏目行
    section ={}
    section['title']  =  oo.cell(row,'A')
    #section['abbr']  =  oo.cell(row,'B')
    section['articles'] = []
    tree['sections'] << section
  else
    article  =  {}
    article['title']      =  oo.cell(row,'B')
    article['author_CN']  =  oo.cell(row,'D')
    article['author_EN']  =  oo.cell(row,'E')
    article['abstract']   =  oo.cell(row,'C')
    article['pages']      =  oo.cell(row,'F').to_i - tree['amend'].to_i
    pages << article['pages']  
    article['email']      = "  "
    tree['sections'][-1]['articles'] << article
  end
end
# 修正页码
reader = PDF::Reader.new(options[:pdf_file])
pages << reader.page_count - tree['amend']
pages.shift 
tree['sections'].each do |section|
  section['articles'].each do |article|
    article['pages_end'] = pages.shift
    if article['pages'] >= article['pages_end']
      puts "页码不对：#{article['title']}:  #{article['pages']} -- #{article['pages_end']}"
      exit 
    end
  end
end

# print_tree(tree)

# 从pdf文件中抽取文章的pdf
puts "从#{tree['filename']}中提取各篇文章的pdf:"
tree['sections'].each do |section|
  section['articles'].each do |article|
    commstr  =  "pdftk  A=#{tree['filename']}"
    from  =  article['pages']
    to    =  article['pages_end']    
    article['filename']  =  "#{basename}_#{from}_#{to}.pdf"
    puts "...第#{from}页---第#{to}页---- #{article['title']}" 
    commstr  += "  cat A#{from}-#{to}  output  #{article['filename']}"
    puts commstr
    system(commstr)
  end
end


# #4  生成XML文件

builder = Builder::XmlMarkup.new
builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
builder.declare! :DOCTYPE,:issues,:SYSTEM,"native.dtd"
xml = builder.issues do |is|
  is.issue(:published=>"true",:identification=>"title",:current=>"false") do |issue|
    issue.title("#{tree['title']}",:locale=>"zh_CN")    
    issue.access_date(Time.now.strftime("%m-%d-%Y"))
    # issue.volume("#{tree['volume']}")
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
                filename = pathname + "/" +article_yaml['filename']
                #puts filename
               # p filename
                File.open(filename,'rb') do |f|
                  data = f.read
                  encode_data = Base64.encode64(data)
                  file.embed("#{encode_data}",:filename=>"#{article_yaml['filename']}",:encoding=>"base64",:mime_type=>"application/pdf")
                end                 
             end                
            end
          end
        end
      end
    end
  end
end


xml_file = File.dirname(tree['filename'])+"/"+File.basename(tree['filename'],".pdf")+".xml"
puts ""
puts "...生成XML导入文件：  #{xml_file}"
File.open(xml_file,"w") {|f| f<<xml}


# delete all pdf files of every article
tree['sections'].each do |section|
  section['articles'].each do |article|   
   if File.exist?(article['filename'])
    system("rm #{article['filename']}")
   end
  end
end

# 上传xml文件到web服务器...
HOST = '172.16.10.9'
USER = 'hxltxb'

# Net::SSH.start(HOST,USER) do |ssh|  
#   ssh.scp.upload!(xml_file,'./pdfs/') do |ch,name,sent,total|
#     print "\r#{name}: #{(sent.to_f * 100 /total.to_f).to_i}%"
#   end
# end

#  #调用php，导入刊期和文章
#  phpcommand = " sudo php  /var/www/ojs/tools/importExport.php NativeImportExportPlugin import "
#  phpcommand << xml_file
#  phpcommand << " "+tree['journal_path']+" "+tree["username"]

#  puts "使用如下所示命令将期刊导入到网站中..."
#  puts phpcommand
#  system(phpcommand)










