class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  def authenticate_user
    authenticate_or_request_with_http_token do |token, _options|
      Rails.logger.info "Database Config: #{ActiveRecord::Base.connection_db_config.inspect}"
      Rails.logger.info "Received Token: #{token}"
      Rails.logger.info "Environment: #{Rails.env}"
      begin
        decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
        Rails.logger.info "Decoded JWT: #{decoded.inspect}"
        user_id = decoded[0]['user_id']
        jti = decoded[0]['jti']
        Rails.logger.info "Looking for user with ID: #{user_id}, JTI: #{jti.inspect}"
        @current_user = User.find_by(id: user_id, jti: jti)
        Rails.logger.info "Found User: #{@current_user.inspect}"
        if @current_user
          Rails.logger.info "Authentication successful for user ID: #{user_id}"
          true # Explicitly return true to continue the request
        else
          Rails.logger.info "No user found for ID: #{user_id}, JTI: #{jti.inspect}"
          render json: { status: 401, message: 'Invalid or expired token.' }, status: :unauthorized
          false # Explicitly return false to halt
        end
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound => e
        Rails.logger.error "Error: #{e.message}"
        render json: { status: 401, message: 'Invalid or expired token.' }, status: :unauthorized
        false
      end
    end
  end
end