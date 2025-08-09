
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
    if @reward.stock <= 0
    return render json: { status: 422, message: "Reward out of stock." }, status: :unprocessable_entity
    end
    if @current_user.points < @reward.points_cost
    return render json: { status: 422, message: "Insufficient points." }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
    @current_user.update!(points: @current_user.points - @reward.points_cost)
    @reward.update!(stock: @reward.stock - 1)
    code = @reward.reward_type.in?(['airtime', 'data']) ? generate_unique_code : nil
    user_reward = @current_user.user_rewards.create!(reward: @reward, redeemed_at: Time.now.utc, code: code)
    @current_user.activities.create!(action: 'redeemed_reward', target_type: 'Reward', target_id: @reward.id)
    render json: {
        status: 200,
        message: "Reward redeemed successfully.",
        data: {
        user_id: @current_user.id,
        reward_id: @reward.id,
        name: @reward.name,
        code: user_reward.code,
        points_remaining: @current_user.points,
        redeemed_at: user_reward.redeemed_at
        }
    }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
    render json: { status: 422, message: e.message }, status: :unprocessable_entity
    end
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
    unless current_user.admin?
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
