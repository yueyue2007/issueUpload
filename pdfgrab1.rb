#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-


################################################################
#   本程序的目的是将导出的ods文件和pdf文件名关联起来
#   2013-12-11
################################################################

require 'roo'
require 'chinese_pinyin'
require 'builder'
require 'csv'


#1. 检查参数及配置文件是否存在？
usage  = '''
	本程序读取ods文件中的参数，生成step2.csv文件。
    pdfgrab1.rb step1.ods 
	'''

if !(ARGV.length == 1)
  puts usage
  exit;
end

#1 检查ods文件是否存在？
if !File.exist?(File.expand_path(ARGV[0]))
  puts "ods文件不存在，请检查参数是否正确。"
  exit
end

#2 导入xlsx配置文件，分析其参数是否正确？
oo = Roo::OpenOffice.new("step1.ods")
oo.default_sheet = oo.sheets.first

#journal 保存所有的信息
journal = []

be = oo.first_row + 1
year_and_issue1 =[oo.cell(2,'D').to_i,oo.cell(2,'F').to_i]
year_and_issue = oo.cell(2,'D').to_i.to_s + "_" + oo.cell(2,'F').to_i.to_s
puts year_and_issue 
be.upto(oo.last_row) do |row|
	#将信息保存到journal二维数组中
	article = {}
	#提取作者姓名，并去除;
	author = oo.cell(row,'A')
	authors_cn = ""
	authors_py = ""
	if author.include?(';')
		authors = author.split(';')
		authors.each do|name| 
			authors_cn += "#{name} "
			article[:author_cn] = authors_cn

			#pinyin 
			name_en = Pinyin.t(name).split(" ")
			
			authors_py << name_en[0].upcase
			authors_py << " "
			name_en[1].capitalize!
			1.upto(name_en.length-1).each do |index|
				authors_py << name_en[index]
			end
			authors_py << " "
			article[:author_py] = authors_py 
		end
	end

	article[:title] = oo.cell(row,'B')
	page_count = oo.cell(row,'G')
	#提取页码，排序用
	if page_count.include?('-')
		page_no = page_count.split('-')
		# puts page_no[0]	
		article[:page_no] = page_no[0]
	end

	#关联pdf文件名
	# puts Dir.pwd 
	testchars = ""
	if article[:title].length >= 5
		testchars = article[:title][0..4]
	end
	# puts testchars 
	Dir.glob("*.pdf") do |filename|
		# puts filename 
		if filename.include?(testchars)
			article[:file_link] = filename
		end
	end 

	journal.push article
end
journal.sort! {|a,b| a[:page_no].to_i <=> b[:page_no].to_i}
# puts journal

#写入到csv文件中
CSV.open("step2.csv","w") do |csv|
	csv << ["pdf文件位置"]
	csv << ["标题","#{year_and_issue1[0]}年第#{year_and_issue1[1]}期"]
	csv << ["卷"]
	csv << ["期","#{year_and_issue1[1]}"]
	csv << ["年份","#{year_and_issue1[0]}"]
	csv << ["页码修正","-4"]
	csv << ["期刊路径","hxlt"]
	csv << ["管理员账户名","ojsadmin"]
	csv << []
	csv << ["栏目","文章标题","摘要","作者中文名","作者英文名","pdf文件链接"]

	# csv << [year_and_issue.to_s]
	journal.each  do |article|
		# csv << ["",article[:title],"略",article[:author_cn]，article[:author_py]，article[:file_link]]
		csv << []
		csv << ['',article[:title],'略',article[:author_cn],article[:author_py],article[:file_link]]
	end
end

puts "请检查step2.csv是否正确，并将其转化为step2.ods，然后执行 pdfgrab2.rb  step2.ods 生成最终的CSV文件。"


