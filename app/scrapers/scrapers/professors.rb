
require 'cgi'

class ProfessorsScraper < Scraper

	DATABASE = 'umdevals'
	COLLECTION = 'professors'

	def initialize
		super

		# The names of the professors are pulled from the dropdown on this page
		@urls = ["http://www.ourumd.com/viewreviews/"]
		@professors = []
	end

	def url_callback(resp, meta)
		# Have Nokogiri parse the HTML
		html = Nokogiri::HTML(resp.body)

		# Search (using jQuery selectors) for the dropdown values
		# Parse these and grab the Professor names
		results = html.search('select[name=id] option')

		results.each do |option|
			
			# Grab the value of the option, which is the plaintext name of the professor (usually like 'Zimmerman, D')
			professor_abv = option.text
  			@professors.push(professor_abv)
		end
			# URL encode the name so that we can create the URLs to scrape
		# 	url_encoded_prof = CGI::escape(professor_abv)
			
		# 	# URL for a list of the Professor's reviews
		# 	review_url = "http://www.ourumd.com/reviews/?id=#{url_encoded_prof}"
		# 	# URL for a list of the Professor's classes + grades
		# 	# classes_url = "http://www.ourumd.com/prof/#{url_encoded_prof}"

		# 	# Keep track of this url to process later
		# 	@review_urls.push({
		# 		url: review_url,
		# 		professor_abv: professor_abv
		# 	})
		# 	# @class_urls.push({
		# 	# 	url: classes_url,
		# 	# 	professor_abv: professor_abv
		# 	# })
		# end
	end

	def done
		puts "Gathered #{@professors.length} Professors."

		# Now that we have scraped all of the data, we want to insert it into MongoDB
		operations = []

		@professors.each do |professor_abv|
			operations.push({
				update_one: {
					filter: { professor_abv: professor_abv },
					update: { '$set' => { professor_abv: professor_abv } },
					upsert: true
				}
			})

		end

		MongoHelper.bulk_write(operations, DATABASE, COLLECTION)
	end
end