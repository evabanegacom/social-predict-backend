# lib/tasks/notifications.rake
namespace :notifications do
    desc "Send daily push notifications with the hottest prediction"
    task send_daily: :environment do
      hottest_prediction = Prediction.where(status: 'approved')
                                   .where('expires_at > ?', Time.now.utc)
                                   .order("vote_options->>'yes' DESC")
                                   .first
  
      if hottest_prediction
        users = User.where.not(push_token: nil)
        users.each do |user|
          message = {
            token: user.push_token,
            notification: {
              title: "🔥 Hottest Prediction of the Day!",
              body: "Vote now: #{hottest_prediction.topic}",
            },
            data: {
              prediction_id: hottest_prediction.id.to_s,
              url: "/predictions/#{hottest_prediction.id}"
            }
          }
          response = FCM_CLIENT.send(message)
          puts "Notification sent to #{user.username}: #{response}"
        end
      else
        puts "No approved predictions available."
      end
    end
  end