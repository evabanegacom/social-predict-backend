class Api::V1::ActivitiesController < ApplicationController
    before_action :authenticate_user

    def index
    activities = Activity.includes(:user, :target).order(created_at: :desc).limit(20)
    render json: {
        status: 200,
        message: "Activities retrieved successfully.",
        data: activities.map do |activity|
        {
            id: activity.id,
            username: activity.user.username,
            action: activity.action,
            target: activity.target_type == 'Prediction' ? activity.target&.topic : activity.target&.name,
            created_at: activity.created_at.to_i * 1000
        }
        end
    }, status: :ok
    end
end

