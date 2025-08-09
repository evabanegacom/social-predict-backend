require File.expand_path(File.dirname(__FILE__) + "/environment")
set :output, "log/cron.log"

every 1.day, at: '12:00 am' do
  runner "ProcessExpiredPredictionsJob.perform_now"
end

every :day, at: '8:00 am' do
  rake "notifications:send_daily"
end
