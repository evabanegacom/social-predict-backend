class Api::V1::PredictionsController < ApplicationController
  before_action :authenticate_user
  before_action :set_prediction, only: [:vote]

  def index
    predictions = Prediction.where(status: 'approved')
    if params[:category].present?
      predictions = predictions.where(category: params[:category])
    end
    render json: {
      status: 200,
      message: 'Predictions retrieved successfully.',
      data: predictions.map { |p| { id: p.id, topic: p.topic, category: p.category, vote_options: p.vote_options, time_left: p.time_left } }
    }, status: :ok
  end

  def create
    prediction = @current_user.predictions.build(prediction_params)
    prediction.status = 'pending'
    prediction.vote_options = { yes: 0, no: 0, maybe: 0 }
    if prediction.save
      render json: {
        status: 201,
        message: 'Prediction created successfully. Awaiting admin approval.',
        data: { id: prediction.id, topic: prediction.topic, category: prediction.category, expires_at: prediction.expires_at }
      }, status: :created
    else
      render json: { status: 422, message: prediction.errors.full_messages.join(', ') }, status: :unprocessable_entity
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

  private

  def set_prediction
    @prediction = Prediction.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 404, message: 'Prediction not found.' }, status: :not_found
  end

  def prediction_params
    params.require(:prediction).permit(:topic, :category, :expires_at)
  end
end