class XpUpdater
    def self.update_all!
      sql = <<~SQL
        UPDATE users
        SET xp = subquery.xp_sum
        FROM (
          SELECT
            users.id AS user_id,
            COALESCE(SUM(CASE WHEN votes.choice = predictions.result THEN 10 ELSE -2 END), 0) AS xp_sum
          FROM users
          LEFT JOIN votes ON votes.user_id = users.id
          LEFT JOIN predictions ON predictions.id = votes.prediction_id AND predictions.result IS NOT NULL
          GROUP BY users.id
        ) AS subquery
        WHERE users.id = subquery.user_id
      SQL
  
      ActiveRecord::Base.connection.execute(sql)
    end
  end
  