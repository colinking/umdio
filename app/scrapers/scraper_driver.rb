
require_relative 'scraper_manager.rb'

# Load all of the scrapers
Dir['./scrapers/*.rb'].each { |file| require file }



## Handle running the scrapers
scrapers = [ReviewsScraper]


if ARGV.length > 0 and ARGV[0].downcase == "all"
	ScraperManager.run(scrapers)
else
	puts "SCRAPER DRIVER ERROR: No scraper specified"
end