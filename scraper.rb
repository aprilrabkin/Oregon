require 'mechanize'
require "rest_client"
require 'pry-nav'
require 'nokogiri'
require 'csv'

class Scraper 
	attr_reader :rows, :ids, :noko
	def initialize
		@rows = []
	end

	def get_ocd_ids
		page = RestClient.get("https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-us/census_autogenerated/us_census_places.csv")
		noko = Nokogiri::HTML(page)
		@ids = noko.text.lines.select do |line|
			line =~ /state:or/
		end.reject do |line|
			line =~ /place:/
		end.map do |line|
		  line.gsub(/,.+/, '').gsub(/\n/, '')
		end 
	end 

	def fetch_page
		page = RestClient.get("http://sos.oregon.gov/elections/Pages/countyofficials.aspx")
		@noko = Nokogiri::HTML(page)
	end

	def iterate_through_page
		i = 0
		while i < 35 do # Benton to Yamhill
			jurisdiction_name = noko.css('.ms-rteElement-H3').css('a')[i*2].text.gsub("​", '') + " County"
			office = jurisdiction_name + " Clerk"
			phone = noko.css('.ms-rteElement-H3')[i].next_element.text.scan(/\d{3}\-\d{3}-\d{4}/).first #any extensions add by hand
			website = noko.css('.ms-rteElement-H3').css('a')[i*2].attribute('href').value
			id = @ids.find do |i| #any cities must be found by hand
				name = jurisdiction_name.gsub(" County", "").rstrip#.gsub(" ", "_").gsub("'","~").gsub(".","")
				i =~ /county:#{name}/i
			end || ""
			i += 1
			@rows << [jurisdiction_name, "Oregon", office, phone, website, id]	#
		end


	end			

	def write_into_CSV_file
		CSV.open("spreadsheet.csv", "wb") do |csv|
			@rows.map do |line|
				csv << line
			end
		end
	end

end

a = Scraper.new
a.get_ocd_ids
a.fetch_page
a.iterate_through_page
a.write_into_CSV_file