
module UMDIO
	class Reviews < Grape::API
		version 'v0', using: :path
		default_format :json

		resource :reviews do

			desc 'Gets a list of all reviews.'
			paginate
			get '/' do
				paginate MongoHelper.distinct('reviews', 'umdevals', 'professors')
			end

			desc 'Returns the most recent reviews to ourumd'
			paginate
			get '/recent' do

				# skip_to = (params[:page] - 1) * params[:per_page]

				results = MongoHelper.aggregate([
					{:$unwind => '$reviews'}, {:$sort => {'reviews.date': -1}} #, {:$skip => skip_to}, {:$limit => params[:per_page]}
				], 'umdevals', 'professors')
				
				paginate results.to_a
			end

			resource :professors do

				desc 'Returns a list of professors that have reviews or searches for a professor'
				params do
				  optional :first, allow_blank: false, type: String
				  optional :last, allow_blank: false, type: String
				end
				paginate
				get '/' do
					query = {}
					query[:first_name] = params[:first] if params[:first]
					query[:last_name] = params[:last] if params[:last]
					query[:reviews] = {:$ne => []}
					if params[:first] or params[:last]
						paginate MongoHelper.aggregate([{:$match => query}, {:$project => {:professor => true}}, {:$sort => {:professor => 1}}], 'umdevals', 'professors').to_a
					else
						paginate MongoHelper.aggregate([{:$match => {:reviews => {:$ne => []}}}, {:$project => {:professor => true}}, {:$sort => {:professor => 1}}], 'umdevals', 'professors').to_a
					end
				end

				params do
				  requires :id, type: BSON::ObjectId
				end
				route_param :id do

					after_validation do
						@professor = MongoHelper.find({_id: params[:id]}, 'umdevals', 'professors')
					end

					desc 'Returns the reviews for the professor'
					paginate
					get '/' do
						@professor.to_a[0] || []
					end

					desc 'Returns the most recent reviews for a given professor'
					get '/recent' do
						#@professor.to_a[0][:reviews].sort_by { |review| if review[:date] then review[:date] else Date.new() end }.reverse || []
						@professor.to_a[0][:reviews] || []
					end

					desc 'Gets the rating for the given professor'
					get '/ratings' do
						{ :rating => @professor.to_a[0][:rating] }
					end
				end
			end
		end
	end
end