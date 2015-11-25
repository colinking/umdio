
require 'mongo'
require 'benchmark'
require 'em-http-request'
require 'typhoeus'
require 'ruby-progressbar'
require 'nokogiri'

require_relative './../helpers/mongo_helper.rb'
require_relative './scrapers/scraper.rb'

# Load all of the scrapers
Dir['./scrapers/*.rb'].each { |file| require file }

class ScraperManager
	MAX_CONCURRENT_HTTP_REQ = 10 # Try

	def self.run(scraper_classes)
		puts "#{scraper_classes.length} Scraper(s) Scraping"

		# Take the list of scraper classes and run each
		scraper_classes.each do |scraper_class|
			if scraper_class.ancestors.include? Scraper
				puts "#{scraper_class}: STARTED"

				benchmarks = Benchmark.measure do
					run_test(scraper_class)
				end
				puts "Benchmarks for: #{scraper_class}"
				display_benchmarks(benchmarks)
			else
				puts 'Scraper passed to ScraperRunner does not inherit from Scraper'
			end
		end
	end

	# TODO: More Expressive Benchmarking
	# TODO: Benchmarking for MongoHelper
	def self.display_benchmarks(benchmarks)
		puts benchmarks
	end

	def self.run_test(scraper_class)
		# Typhoeus::Hydra allows us to make HTTP requests async
		# 20 concurrent requests worked well on my computer
		# Any more started to trigger issues where variables weren't properly set
		hydra = Typhoeus::Hydra.new(max_concurrency: MAX_CONCURRENT_HTTP_REQ)

		# Initialize the Scraper
		scraper = scraper_class.new
		
		retry_count = 0
		
		# Progress bar for tracking progress
		pb = ProgressBar.create(format: "%a %e %P% Processed: %c from %C", total: scraper.urls.length)

		# Queue all of the url's to make
		scraper.urls.each do |url_data|

			# Parse out the url and metadata
			url = url_data[:url]
			meta = url_data[:meta]
			
			request = Typhoeus::Request.new(url)
			hydra.queue(request)
			# Have Hydra call the callback on completion
			request.on_complete do |resp|
				if resp.success?
					pb.increment
					pb.refresh if !pb.finished?

					# Call the Scraper's callback to indicate that a url has finished
					scraper.url_callback(resp, meta)
				else
					retry_count += 1
					# puts "Response failed! (#{resp.code}) ...Retrying..."
					hydra.queue request
				end
			end
		end
		# Do your magic, Hydra
		hydra.run

		# Let the scraper finish anything up
		scraper.done
		puts "#{scraper.class}: FINISHED (#{retry_count} retries)"
	end
end
