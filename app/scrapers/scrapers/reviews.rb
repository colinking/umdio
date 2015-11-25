
require 'people'

require_relative './../scraper_manager.rb'


class ReviewsScraper < Scraper

	DATABASE = 'umdevals'
	COLLECTION = 'reviews'

	def initialize 
		super

		# We're going to need a list of URLs to Professor's pages on ourumd.org
		# These are stored in Mongo after running a ProfessorScraper

		# So let's run a ProfessorScraper
		ScraperManager.run([ProfessorsScraper])

		# Now we want to connect to Mongo and pull out the review urls we need
		client = MongoHelper.open(DATABASE)

		# Make the array of review urls
		@urls = []
		client[COLLECTION].find().each do |review_data|
			@urls.push({
				url: review_data[:review_url],
				meta: {
					professor_abv: review_data[:professor_abv]
				}
			})
		end

		client.close

		@np = People::NameParser.new

		# For storing data as we scrape it
		@reviews = {}
		@full_names = {}
		@first_names = {}
		@last_names = {}
		@ratings = {}
	end

	def url_callback(resp, meta)

		professor_abv = meta[:professor_abv]

		# Open the URL and grab the HTML
		review_doc = Nokogiri::HTML(resp.body)

		# 1) Get the Full Name

		# The full name is stored in an anchor tag on the page
		full_name_a = review_doc.search('#content p.pageheading a')[0]

		# Strip off any extra whitespace
		full_name = clean_string(full_name_a.text)

		# Use the People library to parse and titlecase the name
		parsed_name = @np.parse(full_name)
		@full_names[professor_abv] = parsed_name[:orig]
		@first_names[professor_abv] = parsed_name[:first]
		@last_names[professor_abv] = parsed_name[:last]


		# 2) Get the Average Rating

		# The average rating is stored as an image, where the numeric score is passed in the image src
		average_rating_img = review_doc.search('#content img')[0]

		# Get the numeric rating from the src of the img
		@ratings[professor_abv] = get_rating(average_rating_img)

		# 3) Parse the reviews

		# Each review is a table row on the page
		review_trs = review_doc.search('#content > table tr')

		# This array will be used to store objects for the parsed reviews
		reviews = []

		review_trs.each do |review|
			# Each review is split into 2 td's, one is the sidebar on the left and the other is the text of the review on the right
			review_sections = review.search('td')
			sidebar_td = review_sections[0]
			text_td = review_sections[1]

			if sidebar_td != nil
				# Username
				username_html = sidebar_td.search('b').first
				username = clean_string(username_html.text)

				# Rating
				rating = nil
				if (average_rating_img = sidebar_td.search('img').first) != nil
					rating = get_rating(average_rating_img)
				end

				# Course
				course_html = sidebar_td.children[4]
				course = nil
				# Use regex to match out the course code
				if course_html.text =~ /Course: ([A-Z]{4}\d\d\d[A-Z]?)/
					course = $1
				end

				# Grade
				grade_html = sidebar_td.children[6]
				grade = nil
				# Use regex to match out the expected grade
				if grade_html.text.scrub("") =~ /Grade Expected: ([A-F][+-]?)/
					grade = $1
				end

				# Date
				date_html = sidebar_td.children[8]
				if date_html
					date = DateTime.parse(date_html.text)
				end
			end

			if text_td != nil
				# Review
				review = clean_string(text_td.text)
			end

			review_obj = {
				username: username,
				rating: rating,
				course: course,
				grade: grade,
				date: date,
				review: review
			}

			reviews.push(review_obj)
		end

		# Insert the review into @reviews
		@reviews[professor_abv] = reviews

	end

	def done
		operations = []

		@reviews.each_key do |professor_abv|
			operations.push({
				update_one: {
					filter: { professor_abv: professor_abv },
					update: {
						'$set': {
							reviews: @reviews[professor_abv],
							professor: @full_names[professor_abv],
							first_name: @first_names[professor_abv],
							last_name: @last_names[professor_abv],
							rating: @ratings[professor_abv]
						}
					},
					upsert: true
				}
			})

		end
		MongoHelper.bulk_write(operations, 'umdevals', 'reviews')
	end

	private 

	def get_rating(rating_img)
		# It's possible that no reviews have been made, so the rating_img could be nil
		average_rating = nil
		if rating_img
			average_rating_src = rating_img['src']
			# Use regex to capture the number from the src
			# which is in the format: "stars?avg=3.75"
			if average_rating_src =~ /avg=([0-9.]+)/
				# $1 returns the captured value from the regex (from the paraenthesis)
				average_rating_text = $1
				# Convert it to a float
				average_rating = average_rating_text.to_f
			end
		end
		return average_rating
	end
end