
module UMDIO
  class Reviews < Grape::API
    version 'v0', using: :path
    default_format :json

    resource :reviews do

      paginate
      get '/' do
        paginate MongoHelper.distinct('reviews', 'umdevals', 'professors')
      end

      paginate
      get '/recent' do

        results = MongoHelper.aggregate([
          {:$unwind => '$reviews'}, {:$sort => {'reviews.date': -1}}
        ], 'umdevals', 'professors')
        
        paginate results.to_a
      end

      resource :professors do

        params do
          optional :first_name, allow_blank: false, type: String
          optional :last_name, allow_blank: false, type: String
        end
        paginate
        get '/' do
          query = {}
          query[:first_name] = params[:first_name] if params[:first_name]
          query[:last_name] = params[:last_name] if params[:last_name]

          paginate MongoHelper.aggregate([{:$match => query}, {:$project => {:professor => true}}, {:$sort => {:professor => 1}}], 'umdevals', 'professors').to_a
        end

        params do
          requires :id, type: BSON::ObjectId
        end
        route_param :id do

          after_validation do
            @professor = MongoHelper.find({_id: params[:id]}, 'umdevals', 'professors').to_a[0]
          end

          get '/' do
            @professor
          end

          get '/rating' do
            { :rating => @professor[:rating] }
          end
        end
      end
    end
  end
end