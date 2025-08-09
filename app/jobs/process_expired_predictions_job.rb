class ProcessExpiredPredictionsJob < ApplicationJob
  queue_as :default

  def perform
    predictions = Prediction.where(status: 'approved')
                             .where('expires_at < ?', Time.current)
                             .where(result: nil)
  
    puts "Found #{predictions.count} expired predictions"
  
    predictions.each do |prediction|
      result = %w[Yes No].sample
      prediction.update(result: result)
      puts "Updated Prediction ##{prediction.id} => #{result}"
    end
  end
  
end

