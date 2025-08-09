set :output, "log/cron.log"

every 1.day, at: '12:00 am' do
  runner "ProcessExpiredPredictionsJob.perform_now"
end