
class Api::V1::RewardsController < ApplicationController
  before_action :authenticate_user
  before_action :set_reward, only: [:redeem]
  before_action :authorize_admin, only: [:create, :update, :destroy]

  def index
    rewards = Reward.all
    render json: {
      status: 200,
      message: "Rewards retrieved successfully.",
      data: rewards.map { |r| { id: r.id, name: r.name, description: r.description, points_cost: r.points_cost, reward_type: r.reward_type, stock: r.stock } }
    }, status: :ok
  end

  def create
    reward = Reward.new(reward_params)
    if reward.save
      render json: { status: 201, message: "Reward created successfully.", data: reward }, status: :created
    else
      render json: { status: 422, message: reward.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def redeem
    unless @reward
      return render json: { error: "Unable to redeem reward." }, status: :unprocessable_entity
    end
  
    Rails.logger.debug "current_user.points: #{@current_user.points.inspect} (#{@current_user.points.class})"
    Rails.logger.debug "reward.points_cost: #{@reward.points_cost.inspect} (#{@reward.points_cost.class})"

    user_total_points = @current_user.points.sum(:points)  # sums all Point.points values for the user

    if user_total_points < @reward.points_cost
      return render json: { status: 400, message: "Not enough points" }, status: :bad_request
    end

  
    ActiveRecord::Base.transaction do
      # Deduct points — assuming points is an association or points log model
      @current_user.points.create!(
        points: -@reward.points_cost,
        user_id: @current_user.id,
        reward_id: @reward.id,
        awarded_at: Time.current,
        # result: "redeemed",
        prediction_id: @current_user.predictions.last&.id,
        choice: nil, # Assuming no choice is needed for rewards
      )
  
      # Create redemption record
      user_reward = @current_user.user_rewards.create!(
        reward: @reward,
        redeemed_at: Time.now.utc,
        code: (['airtime', 'data', 'badge'].include?(@reward.reward_type) ? generate_unique_code : nil)
      )      
    end
  
    render json: { status: 200, message: "Reward redeemed successfully." }, status: :ok
  
  rescue ActiveRecord::RecordInvalid => e
    render json: { status: 422, message: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end
  
  

  private

  def set_reward
    @reward = Reward.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 404, message: "Reward not found." }, status: :not_found
  end

  def reward_params
    params.require(:reward).permit(:name, :description, :points_cost, :reward_type, :stock)
  end

  def authorize_admin
    unless @current_user.admin?
      render json: { status: 403, message: "Unauthorized: Admin access required." }, status: :forbidden
    end
  end

  def generate_unique_code
    loop do
      code = SecureRandom.alphanumeric(10).upcase
      break code unless UserReward.exists?(code: code)
    end
  end
end
