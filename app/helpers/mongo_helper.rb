
require 'mongo'

class MongoHelper

	# Set the logging levels
	Mongo::Logger.logger = ::Logger.new('logs/mongo.log')

	# Optionally set the logging level
	# Mongo::Logger.logger.level = ::Logger::INFO

	def self.distinct(field, database, collection)
		# Open a connection to the client 
		client = self.open(database)
		
		# Grab the collection that we will read from
		coll = client[collection]

		# Submit the find query
		# Note: Skip and limit don't appear to actually have an effect on runtime
		result = coll.find.distinct(field)

		# Close the MongoDB connection
		client.close

		# Return the results
		result
	end

	def self.aggregate(pipeline, database, collection)
		# Open a connection to the client 
		client = self.open(database)
		
		# Grab the collection that we will read from
		coll = client[collection]

		# Run the aggregation
		result = coll.aggregate(pipeline)

		# Close the MongoDB connection
		client.close

		# Return the results
		result
	end

	def self.find(query, database, collection)
		# Open a connection to the client 
		client = self.open(database)
		
		# Grab the collection that we will read from
		coll = client[collection]

		# Run the query
		result = coll.find(query)

		# Close the MongoDB connection
		client.close

		# Return the results
		result
	end

	def self.bulk_write(operations, database, collection)
		# Open a connection to the client 
		client = self.open(database)
		
		# Grab the collection that we will write on
		coll = client[collection]

		# Commit the bulk operation
		coll.bulk_write(operations)

		# Close the MongoDB connection
		client.close
	end

	def self.open(database)
		host = ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost'
		port = ENV['MONGO_RUBY_DRIVER_PORT'] || 27017

		# MongoDB takes an array of URIs to connect to
		connections = ["#{host}:#{port}"]

		# Open the connection
		client = Mongo::Client.new(
			connections,
			max_pool_size: 2,
			wait_queue_timeout: 2
		)

		client.use(database)
	end

end