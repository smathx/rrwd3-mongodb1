class Racer
  
  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  def self.mongo_client
   Mongoid::Clients.default
  end

  def self.collection
   self.mongo_client[:racers]
  end
  
  def self.all(prototype = {}, sort = {:number => 1}, skip = 0, limit = nil)
    
    prototype = prototype.slice(:number, :first_name, :last_name, 
                                :gender, :group, :secs) if !prototype.nil?

    result = collection.find(prototype)
                       .sort(sort)
                       .skip(skip)
    
    result = result.limit(limit) unless limit.nil?
    return result
  end
  
  def initialize(params = {})
    @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
  end

  def self.find(id)
    result = collection.find(:_id => BSON::ObjectId(id)).first
    return result.nil? ? nil: Racer.new(result)
  end
  
  def self.dbid(id)
    BSON::ObjectId.from_string(id.nil? ? @id: id)
  end
  
  def save
    result = self.class.collection.insert_one(
              number: @number, 
              first_name: @first_name, 
              last_name: @last_name, 
              gender: @gender,
              group: @group,
              secs: @secs)
    @id = result.inserted_id.to_s
  end
  
  def update(params)
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
    
    # remove id from params
    
    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs)

    self.class.collection.update_one(
      { _id: BSON::ObjectId.from_string(@id)}, params)
  end
  
  def destroy
    self.class.collection.delete_one(number: @number)
  end
  
  # ActiveModel 
  
  include ActiveModel::Model
  
  def persisted?
    !@id.nil?
  end
  
  def created_at
    nil
  end
  
  def updated_at
    nil
  end
  
  # Paginate
  
  def self.paginate(params)
    Rails.logger.debug("paginate(#{params})")
    
    page = (params[:page] ||= 1).to_i
    limit = (params[:per_page] ||= 30).to_i
    offset = (page - 1) * limit
    sort = { number: 1 } #params[:sort] ||= {}

    racers = []
    all(params, sort, offset, limit).each do |doc|
      racers << Racer.new(doc)
    end

    total = all(params, sort, 0, 1).count
    
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end    
  end

end
