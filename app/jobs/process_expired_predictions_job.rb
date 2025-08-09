class ProcessExpiredPredictionsJob < ApplicationJob
  queue_as :default

  def perform
    Prediction.where(status: 'approved').where('expires_at < ?', Time.now.utc).where(result: nil).each do |prediction|
      # For demo, randomly set result; in production, use admin input or external data
      prediction.update(result: %w[Yes No].sample)
    end
  end
end