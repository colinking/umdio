module BSON
	class ObjectId
	  def self.parse(id)
	    fail unless BSON::ObjectId::legal?(id)
	    BSON::ObjectId(id)
	  end
	end
end