# app/services/user_xp_updater.rb
class UserXpUpdater
    def self.update(user_id)
      xp = Vote.joins(:prediction)
               .where(user_id: user_id)
               .where.not(predictions: { result: nil })
               .sum("CASE WHEN votes.choice = predictions.result THEN 10 ELSE -2 END")
  
      User.find(user_id).update!(xp: xp)
    end
  end
  