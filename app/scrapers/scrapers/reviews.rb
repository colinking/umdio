
require 'cgi'
require 'people'

class ReviewsScraper < Scraper

  DATABASE = 'umdevals'
  COLLECTION = 'professors'

  def initialize 
    super

    # We're going to need a list of URLs to Professor's pages on ourumd.org
    # These are stored in Mongo after running a ProfessorsScraper

    # Find all of the documents in the MongoDB database
    results = MongoHelper.find({}, DATABASE, COLLECTION)

    # Make the array of review urls
    results.each do |professor_doc|
      @urls.push({
        url: getReviewsURL(professor_doc[:professor_abv]),
        meta: {
          professor_abv: professor_doc[:professor_abv]
        }
      })
    end

    # For storing data as we scrape it
    @professors = {}
  end

  def url_callback(resp, meta)

    # Open the URL and grab the HTML
    html = Nokogiri::HTML(resp.body)

    professor_data = {}

    # 1) Get the Full Name
    parseName(html, professor_data)

    # 2) Get the Average Rating
    parseRating(html, professor_data)

    # 3) Parse the reviews
    parseReviews(html, professor_data)

    # Insert the data into the global professors hash
    professor_abv = meta[:professor_abv]
    @professors[professor_abv] = professor_data

  end

  def done
    operations = []

    @professors.each_key do |professor_abv|
      operations.push({
        update_one: {
          filter: { professor_abv: professor_abv },
          update: { '$set': @professors[professor_abv] },
          upsert: true
        }
      })
    end

    MongoHelper.bulk_write(operations, DATABASE, COLLECTION)
  end

  private

  def parseName(html, professor_data)
    # The full name is stored in an anchor tag on the page
    full_name_a = html.search('#content p.pageheading a')[0]

    # Strip off any extra whitespace
    full_name = clean_string(full_name_a.text)

    # Use the People library to parse and titlecase the name
    np = People::NameParser.new
    parsed_name = np.parse(full_name)
    professor_data[:professor] = parsed_name[:orig]
    professor_data[:first_name] = parsed_name[:first]
    professor_data[:last_name] = parsed_name[:last]
  end

  def parseRating(html, professor_data)
    # The average rating is stored as an image, where the numeric score is passed in the image src
    average_rating_img = html.search('#content img')[0]

    # Get the numeric rating from the src of the img
    professor_data[:rating] = get_rating(average_rating_img)
  end

  def parseReviews(html, professor_data)
    # Each review is a table row on the page
    review_trs = html.search('#content > table tr')

    professor_data[:reviews] = []

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

      professor_data[:reviews].push(review_obj)
    end
  end

  def getReviewsURL(professor_abv)
    # URL encode the name so that it can go in a URL
    url_encoded_prof = CGI::escape(professor_abv)

    # URL for a list of the Professor's reviews
    return "http://www.ourumd.com/reviews/?id=#{url_encoded_prof}"
  end

  def get_rating(image_html)
    # It's possible that no reviews have been made, so the image_html could be nil
    average_rating = nil
    if image_html
      average_rating_src = image_html['src']
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