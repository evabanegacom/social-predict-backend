class Api::V1::UsersController < ApplicationController
  # skip_before_action :authenticate_user, only: [:create, :login]
  before_action :authenticate_user, only: [:me, :logout]
  before_action :set_user, only: [:update_admin]
  # before_action :authorize_admin, only: [:update_admin]

  def create
    user = User.new(user_params)
    if user.save
      token = encode_token(user)
      render json: { status: 200, message: 'Signed up successfully.', data: { user: user, token: token } }, status: :ok
    else
      render json: { status: 422, message: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def login
    Rails.logger.info "Identifier param: #{params[:identifier].inspect}"
  Rails.logger.info "Password param: #{params[:password].inspect}"
    identifier = params[:identifier]
    user = User.find_by(username: identifier) || User.find_by(phone: identifier)
    if user&.authenticate(params[:password])
      token = encode_token(user)
      render json: { status: 200, message: 'Logged in successfully.', data: { user: user, token: token } }, status: :ok
    else
      render json: { status: 401, message: 'Invalid identifier or password.' }, status: :unauthorized
    end
  end

  def update_admin
    if @user.update(admin: admin_params[:admin])
      render json: {
        status: 200,
        message: "User admin status updated successfully.",
        data: {
          id: @user.id,
          username: @user.username,
          admin: @user.admin
        }
      }, status: :ok
    else
      render json: { status: 422, message: @user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update_push_token
    if current_user.update(push_token: params[:push_token])
      render json: { status: 200, message: "Push token updated successfully." }, status: :ok
    else
      render json: { status: 422, message: current_user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def logout
    if @current_user
      @current_user.update(jti: SecureRandom.uuid)
      render json: { status: 200, message: 'Logged out successfully.' }, status: :ok
    else
      render json: { status: 401, message: 'No active session.' }, status: :unauthorized
    end
  end

  def me
    render json: {
      status: 200,
      message: 'User data retrieved successfully.',
      data: {
        id: @current_user.id,
        username: @current_user.username,
        phone: @current_user.phone,
        points: @current_user.xp,
        voting_history: @current_user.voting_history
      }
    }, status: :ok
  end

  private

  def user_params
    permitted = params.require(:user).permit(:username, :phone, :password, :password_confirmation)
    permitted[:phone] = nil if permitted[:phone].blank?
    permitted
  end
  

  def admin_params
    params.require(:user).permit(:admin)
  end

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 404, message: "User not found." }, status: :not_found
  end

  def encode_token(user)
    expiration_time = 7.days.from_now.to_i
    payload = {
      user_id: user.id,
      jti: user.jti,
      exp: expiration_time
    }
  
    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  rescue => e
    Rails.logger.error("JWT encoding error: #{e.message}")
    nil
  end
  
end