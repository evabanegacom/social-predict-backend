class Api::V1::PredictionsController < ApplicationController
  before_action :authenticate_user
  before_action :set_prediction, only: [:vote]
  before_action :authorize_admin, only: [:update_status]

  def index
    predictions = Prediction.where(status: 'approved')
    if params[:category].present?
      predictions = predictions.where(category: params[:category])
    end
    render json: {
      status: 200,
      message: 'Predictions retrieved successfully.',
      data: predictions.map do |p|
        {
          id: p.id,
          text: p.topic,
          user: p.user.username,
          upvotes: p.vote_options['yes'] || 0,
          downvotes: p.vote_options['no'] || 0,
          createdAt: p.created_at.to_i * 1000,
          category: p.category,
          result: p.result,
          time_left: p.time_left
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
          time_left: prediction.time_left
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
          time_left: prediction.time_left
        }
      }, status: :created
    else
      render json: { status: 422, message: prediction.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update_status
    if @prediction.update(status: status_params[:status])
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
          updated_at: @prediction.updated_at
        }
      }
    else
      render json: { status: 422, message: @prediction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def vote
    vote = @current_user.votes.build(prediction: @prediction, choice: params[:choice])
    if vote.save
      @prediction.update_vote_counts
      render json: {
        status: 200,
        message: 'Vote submitted successfully.',
        data: { prediction_id: @prediction.id, choice: vote.choice, vote_options: @prediction.vote_options }
      }, status: :ok
    else
      render json: { status: 422, message: vote.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def votingHistory
    if @current_user.votes.empty?
      render json: { status: 200, message: 'No voting history found.', data: [] }, status: :ok
    else
      history = @current_user.votes.includes(:prediction).map do |vote|
        {
          prediction_id: vote.prediction.id,
          topic: vote.prediction.topic,
          category: vote.prediction.category,
          choice: vote.choice,
          result: vote.prediction.result,
          correct: vote.prediction.result && vote.choice == vote.prediction.result,
          voted_at: vote.created_at.to_i * 1000
        }
      end
      render json: {
        status: 200,
        message: 'Voting history retrieved successfully.',
        data: history
      }, status: :ok
    end
  end

  def votes
    @current_user_votes = @current_user.votes.includes(:prediction).map do |vote|
      {
        prediction_id: vote.prediction.id,
        topic: vote.prediction.topic,
        category: vote.prediction.category,
        choice: vote.choice,
        result: vote.prediction.result,
        correct: vote.prediction.result && vote.choice == vote.prediction.result,
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

  def prediction_params
    params.require(:prediction).permit(:topic, :category, :expires_at)
  end

  def status_params
    params.permit(:status)
  end
end
