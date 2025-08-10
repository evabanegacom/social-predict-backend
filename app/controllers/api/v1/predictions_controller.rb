class Api::V1::PredictionsController < ApplicationController
  before_action :authenticate_user, except: [:index]
  before_action :set_prediction, only: [:vote, :show, :update_status]
  before_action :authorize_admin, only: [:update_status]

  def index
    predictions = Prediction.all
    if params[:category].present?
      predictions = predictions.where(category: params[:category])
    end

    if params[:resolved].present? && params[:resolved] == 'true'
      predictions = Prediction.where(status: 'resolved')
    end
    
    render json: {
      status: 200,
      message: 'Predictions retrieved successfully.',
      data: predictions.map do |p|
        {
          id: p.id,
          text: p.topic,
          user: p.user.username,
          status: p.status,
          upvotes: p.vote_options['yes'] || 0,
          downvotes: p.vote_options['no'] || 0,
          createdAt: p.created_at.to_i * 1000,
          category: p.category,
          result: p.result,
          time_left: p.time_left,
          expires_at: p.expires_at.to_i * 1000
        }
      end
    }, status: :ok
  end

  def show
    prediction = Prediction.find_by(id: params[:id])
    if prediction
      render json: {
        status: 200,
        message: 'Prediction details retrieved successfully.',
        data: {
          id: prediction.id,
          text: prediction.topic,
          user: prediction.user.username,
          upvotes: prediction.vote_options['yes'] || 0,
          downvotes: prediction.vote_options['no'] || 0,
          createdAt: prediction.created_at.to_i * 1000,
          category: prediction.category,
          result: prediction.result,
          status: prediction.status,
          time_left: prediction.time_left,
          expires_at: prediction.expires_at.to_i * 1000
        }
      }, status: :ok
    else
      render json: { status: 404, message: 'Prediction not found.' }, status: :not_found
    end
  end

  def create
    prediction = @current_user.predictions.build(prediction_params)
    prediction.status = 'pending'
    prediction.vote_options = { yes: 0, no: 0, maybe: 0 }
    if prediction.save
      @current_user.activities.create!(action: 'created_prediction', target_type: 'Prediction', target_id: prediction.id)
      @current_user.update_streak # Update streak
      render json: {
        status: 201,
        message: 'Prediction created successfully. Awaiting admin approval.',
        data: {
          id: prediction.id,
          text: prediction.topic,
          user: prediction.user.username,
          upvotes: prediction.vote_options['yes'] || 0,
          downvotes: prediction.vote_options['no'] || 0,
          createdAt: prediction.created_at.to_i * 1000,
          category: prediction.category,
          result: prediction.result,
          status: prediction.status,
          time_left: prediction.time_left
        }
      }, status: :created
    else
      render json: { status: 422, message: prediction.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update_status
    if @prediction.update(status_params)
      render json: {
        status: 200,
        message: "Prediction status updated successfully.",
        data: {
          id: @prediction.id,
          topic: @prediction.topic,
          category: @prediction.category,
          vote_options: @prediction.vote_options,
          expires_at: @prediction.expires_at,
          status: @prediction.status,
          user_id: @prediction.user_id,
          created_at: @prediction.created_at,
          updated_at: @prediction.updated_at,
          expires_at: @prediction.expires_at.to_i * 1000
        }
      }
    else
      render json: { status: 422, message: @prediction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def approve
    if @prediction.status == 'pending'
      if @prediction.update(status: 'approved')
        @current_user.activities.create!(action: 'approved_prediction', target_type: 'Prediction', target_id: @prediction.id)
        render json: {
          status: 200,
          message: 'Prediction approved successfully.',
          data: {
            id: @prediction.id,
            topic: @prediction.topic,
            category: @prediction.category,
            vote_options: @prediction.vote_options,
            expires_at: @prediction.expires_at,
            status: @prediction.status,
            user_id: @prediction.user_id,
            created_at: @prediction.created_at,
            updated_at: @prediction.updated_at,
            expires_at: @prediction.expires_at.to_i * 1000
          }
        }, status: :ok
      else
        render json: { status: 422, message: @prediction.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    else
      render json: { status: 400, message: 'Prediction is not in pending state.' }, status: :bad_request
    end
  end


  def reject_prediction
    prediction = Prediction.find_by(id: params[:id])
    if prediction
      prediction.update(status: 'rejected')
      @current_user.activities.create!(action: 'rejected_prediction', target_type: 'Prediction', target_id: @prediction.id)
      render json: {
        status: 200,
        message: 'Prediction rejected successfully.',
        data: {
          id: prediction.id,
          topic: prediction.topic,
          category: prediction.category,
          vote_options: prediction.vote_options,
          expires_at: prediction.expires_at,
          status: prediction.status,
          user_id: prediction.user_id,
          created_at: prediction.created_at,
          updated_at: prediction.updated_at,
          expires_at: prediction.expires_at.to_i * 1000
        }
      }, status: :ok
    else
      render json: { status: 404, message: 'Prediction not found.' }, status: :not_found
    end
  end

  def destroy
    if @prediction.destroy
      @current_user.activities.create!(action: 'deleted_prediction', target_type: 'Prediction', target_id: @prediction.id)
      render json: {
        status: 200,
        message: 'Prediction deleted successfully.'
      }, status: :ok
    else
      render json: { status: 422, message: @prediction.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def vote
    vote = @current_user.votes.build(prediction: @prediction, choice: params[:choice])
    if vote.save
      @prediction.update_vote_counts
      @current_user.activities.create!(action: 'voted', target_type: 'Prediction', target_id: @prediction.id)
      @current_user.update_streak # Update streak
      render json: {
        status: 200,
        message: 'Vote submitted successfully.',
        data: { prediction_id: @prediction.id, choice: vote.choice, vote_options: @prediction.vote_options }
      }, status: :ok
    else
      render json: { status: 422, message: vote.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  # def vote
  #   vote = @current_user.votes.build(prediction: @prediction, choice: params[:choice])
  #   if vote.save
  #     @prediction.update_vote_counts
  #     render json: {
  #       status: 200,
  #       message: 'Vote submitted successfully.',
  #       data: { prediction_id: @prediction.id, choice: vote.choice, vote_options: @prediction.vote_options }
  #     }, status: :ok
  #   else
  #     render json: { status: 422, message: vote.errors.full_messages.join(', ') }, status: :unprocessable_entity
  #   end
  # end

  def votes
    valid_results = ["Yes", "No"]
  
    @current_user_votes = @current_user.votes.includes(:prediction).map do |vote|
      if vote.prediction.result.nil?
        points = 0
        correct = false
      else
        correct = valid_results.include?(vote.prediction.result) && vote.choice == vote.prediction.result
        points = correct ? 10 : -2
      end
  
      {
        prediction_id: vote.prediction.id,
        topic: vote.prediction.topic,
        category: vote.prediction.category,
        choice: vote.choice,
        result: vote.prediction.result,
        points: points,
        correct: correct,
        voted_at: vote.created_at.to_i * 1000
      }
    end
  
    if @current_user_votes.empty?
      render json: { status: 200, message: 'No votes found for the user.', data: [] }, status: :ok
    else
      render json: {
        status: 200,
        message: 'User votes retrieved successfully.',
        data: @current_user_votes
      }, status: :ok
    end
  end
  
  
  


  private

  def set_prediction
    @prediction = Prediction.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 404, message: 'Prediction not found.' }, status: :not_found
  end

  def authorize_admin
    unless @current_user&.admin?
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def prediction_params
    params.require(:prediction).permit(:topic, :category, :expires_at)
  end

  def status_params
    params.permit(:status, :result)
  end
end
