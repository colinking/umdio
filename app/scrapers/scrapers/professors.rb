
require 'cgi'

class ProfessorsScraper < Scraper

	DATABASE = 'umdevals'
	COLLECTION = 'reviews'

	def initialize
		super

		# The names of the professors are pulled from the dropdown on this page
		@urls = [
			{ url: "http://www.ourumd.com/viewreviews/" }
		]
		@review_urls = []
		@class_urls = []
	end

	def url_callback(resp, meta)
		# Have Nokogiri parse the HTML
		html = Nokogiri::HTML(resp.body)

		# Search (using jQuery selectors) for the dropdown values
		# Parse these and grab the Professor names
		results = html.search('#body select option')

		results.each do |option|
			
			# Grab the value of the option, which is the plaintext name of the professor (usually like 'Zimmerman, D')
			professor_name = option['value']
			
			# URL encode the name so that we can create the URLs to scrape
			url_encoded_prof = CGI::escape(professor_name)
			
			# URL for a list of the Professor's reviews
			review_url = "http://www.ourumd.com/reviews/?id=#{url_encoded_prof}"
			# URL for a list of the Professor's classes + grades
			classes_url = "http://www.ourumd.com/prof/#{url_encoded_prof}"

			# Keep track of this url to process later
			@review_urls.push({
				url: review_url,
				professor_abv: professor_name
			})
			@class_urls.push({
				url: classes_url,
				professor_abv: professor_name
			})
		end
	end

	def done
		puts "Gathered #{@review_urls.length} Professors."

		# Now that we have scraped all of the data, we want to insert it into MongoDB
		operations = []

		@review_urls.each_with_index do |review_url_data, index|
			data = {
				professor_abv: review_url_data[:professor_abv],
				review_url: review_url_data[:url],
				class_url: @class_urls[index][:url]
			}

			operations.push({
				update_one: {
					filter: { professor_abv: data[:professor_abv] },
					update: { '$set' => data },
					upsert: true
				}
			})

		end
		MongoHelper.bulk_write(operations, DATABASE, COLLECTION)
	end
end