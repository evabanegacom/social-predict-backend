class Api::V1::LeaderboardsController < ApplicationController
  before_action :authenticate_user

  def index
  period = params[:period].in?(%w[weekly monthly all_time]) ? params[:period] : 'all_time'
  category = params[:category].presence

  # Define time range
  time_range = case period
               when 'weekly'
                 1.week.ago..Time.now.utc
               when 'monthly'
                 1.month.ago..Time.now.utc
               else
                 nil
               end

  # Base users query who have votes matching conditions
  users = User.joins(:votes)
              .joins('INNER JOIN predictions ON predictions.id = votes.prediction_id')
              .where('predictions.result IS NOT NULL') # only resolved predictions

  # Filter by category if given
  users = users.where(predictions: { category: category }) if category

  # Filter by vote time range if applicable
  users = users.where(votes: { created_at: time_range }) if time_range

  # Group and calculate XP dynamically with CASE for scoring
  users = users
          .group('users.id')
          .select(
            'users.id',
            'users.username',
            'users.phone',
            "SUM(CASE WHEN (votes.choice = predictions.result) THEN 10 ELSE -2 END) AS xp"
          )
          .having('SUM(CASE WHEN (votes.choice = predictions.result) THEN 10 ELSE -2 END) > 0')
          .order('xp DESC')
          .limit(100)

  leaderboard = users.map.with_index(1) do |user, index|
    {
      rank: index,
      user_id: user.id,
      username: user.username || user.phone,
      points: user.xp.to_i
    }
  end

  # Find current user's rank (or default)
  current_user_rank = leaderboard.find { |entry| entry[:user_id] == @current_user.id } || {
    rank: nil,
    user_id: @current_user.id,
    username: @current_user.username || @current_user.phone,
    points: 0
  }

  render json: {
    status: 200,
    message: 'Leaderboard retrieved successfully.',
    data: {
      period: period,
      category: category || 'all',
      leaderboard: leaderboard,
      current_user: current_user_rank
    }
  }, status: :ok
end

end