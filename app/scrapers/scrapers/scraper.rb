
class Scraper

	attr_reader :urls

	def initialize
		# @urls: Array of Objects that contain URL (String) and metadata (Object)
		@urls = []
	end

	# (Required)
	def url_callback(resp, meta)
		raise NotImplementedError
	end

	# (Optional)
	def done
		
	end

	protected

	# Removes leading and trailing whitespace, plus extra spaces and any tabs
	def clean_string(str) 
		return str.strip.delete("\t").squeeze(' ') if str
	end

end
