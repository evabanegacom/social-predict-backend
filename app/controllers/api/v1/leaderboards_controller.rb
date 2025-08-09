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

    # Base query for users with points
    users = User.where('xp > 0')

    # Filter by category if provided
    if category
      users = users.joins(votes: :prediction)
                   .where(predictions: { category: category })
                   .group('users.id')
                   .having('SUM(CASE WHEN votes.choice = predictions.result THEN 100 ELSE -10 END) > 0')
    end

    # Apply time range for votes if not all_time
    if time_range
      users = users.joins(votes: :prediction)
                   .where(votes: { created_at: time_range })
                   .group('users.id')
    end

    # Calculate rankings
    leaderboard = users.order(xp: :desc)
                      .limit(100)
                      .select(:id, :username, :phone, :xp)
                      .map.with_index(1) do |user, index|
                        {
                          rank: index,
                          user_id: user.id,
                          username: user.username || user.phone,
                          points: user.xp
                        }
                      end

    # Find current user's rank
    current_user_rank = leaderboard.find { |entry| entry[:user_id] == @current_user.id } || { rank: nil, user_id: @current_user.id, username: @current_user.username || @current_user.phone, points: @current_user.xp }

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