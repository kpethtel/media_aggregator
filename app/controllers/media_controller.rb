class MediaController < ActionController::Base
  def index
    gatherer = MediaGatherer.new
    gatherer.call
    render json: gatherer.aggregate
  end
end
