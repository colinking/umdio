source 'https://rubygems.org'

gem 'mongo', '>=2.1' # DB
# gem 'bson_ext'
gem 'rake' # Server
gem 'dotenv'
gem 'jekyll' # Documentation
gem 'rouge'
gem 'grape' # API Framework
gem 'grape-cache_control' # Caching 
gem 'kaminari'
gem 'api-pagination'

group :development do
  gem 'rspec' # Testing
  gem 'pry'
  gem 'shotgun' 
  gem 'better_errors'
end

group :test do
  gem 'rack-test', :require => 'rack/test'
  gem 'simplecov', :require => false
end

# the gems needed for the courses scraper, and likely for other scrapers
group :scrape do
  gem 'nokogiri'
  gem 'ruby-progressbar' # Console progress bar
  gem 'typhoeus' # Asynch HTTP Requests
  gem 'em-http-request' 
  gem 'people' # For parsing Professor names
  # gem 'benchmark' # Benchmarks
end
