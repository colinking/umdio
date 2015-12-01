require 'open-uri' # Imports the open command
require 'nokogiri' # For HTML parsing

# Add the following code to your file (hacker_news_scraper.rb)
url = 'https://news.ycombinator.com/'
webpage = open(url)
html = webpage.read

# Print out the HTML that is returned
# puts html

# Parse the html string into a Nokogiri Document
phtml = Nokogiri::HTML(html)

articles = phtml.search('td.title > a')

articles.each do |article|
	puts "Title: #{article.text}"
	puts "Link: #{article['href']}"
end