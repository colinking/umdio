
require_relative 'scraper_manager.rb'

# Load all of the scrapers
# scrapers = []
Dir['./scrapers/*.rb'].each do |file| 
	# scrapers.push(file); 
	require file 
end



## Handle running the scrapers
scrapers = [ReviewsScraper]


ScraperManager.run(scrapers)
# if ARGV.length > 0
# 	scraper = ARGV[0].downcase
# 	if scraper == "all"
# 		# ScraperManager.run(scrapers)
# 	elsif scraper in scrapers
# 		# ScraperManager.run(scraper)
# 	else
# 		puts "SCRAPER DRIVER ERROR: Scraper specified is not a known scraper"
# 	end
# else
# 	puts "SCRAPER DRIVER ERROR: No scraper specified"
# end