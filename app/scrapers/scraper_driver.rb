
require_relative 'scraper_manager.rb'

# Load all of the scrapers
Dir[__dir__ + '/scrapers/*.rb'].each do |file| 
	require file 
end


if ARGV.length > 0
	if ARGV[0].downcase == "all"
		all_scrapers = [ProfessorsScraper, ReviewsScraper]
		ScraperManager.run(all_scrapers)
	else
		scrapers = []
		ARGV.each do |scraper|
			begin
				scraper_class = Scraper.const_get(scraper)
				scrapers.push(scraper_class)
			rescue NameError
				puts "SCRAPER DRIVER ERROR: Scraper specified (#{scraper}) is not a known scraper"
				raise
			end
		end
		ScraperManager.run(scrapers)
	end
else
	puts "SCRAPER DRIVER ERROR: No scraper specified"
end