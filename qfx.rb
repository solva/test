require 'quicken_parser'
require 'cgi'
require 'stringio'

# binding.pry
ofx_fname = ARGV[0]

# ---- HACK
# Add below code to the OFX parserto handle SGML case were 
# CGI characters are not escaped
#
is_sgml = nil

escaped = File.new(ofx_fname).reduce("") do |filtered, line|
	if is_sgml==nil
		begin
		  m = line.match(/^\s*DATA\s*:\s*(\w+)\s*$/)
		rescue
			# FIXME
			puts "Bad UTF encoding"
		end
		is_sgml = m && m.captures[0]=="OFXSGML" 
	end

	if is_sgml==true && line.start_with?("<NAME>")
	  filtered << ("<NAME>"+CGI.escapeHTML(line[6..-1]))
	else
		filtered << line
	end
end

ofx_safe = StringIO.new(escaped)

begin 
  ofx = QuickenParser::Parser.new(ofx_safe).parse
  puts "There are #{ofx.accounts.length} accounts in #{ofx_fname}"
rescue
	# debugger
	raise
end

ofx.accounts.each do |act|

	puts "Account ##{act.number}/#{act.type}, currency #{act.currency}, #{act.transactions.length} transactions, timespan #{act.transactions.timespan}"
	act.transactions.each do |trans|
	  # Normalize transaction name to get account
	  name = trans.name.sub(/([A-Z]\d[A-Z]\d[A-Z]\d\s*|\s*#.*|\s*_F\s*)$/,"")

		# puts "#{'%8s' % trans.type} #{trans.timestamp.strftime('%d-%m-%y')} #{'%8.2f' % trans.amount} #{name} #{trans.memo}"
		puts "#{name}"

	end
end



