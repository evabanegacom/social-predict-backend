class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :prediction
  validates :choice, presence: true, inclusion: { in: %w[Yes No] }
  validate :prediction_not_expired
  validate :user_has_not_voted
  validate :prediction_approved

  private

  def prediction_not_expired
    errors.add(:prediction, "has expired") if prediction.expires_at < Time.now.utc
  end

  def user_has_not_voted
    if Vote.exists?(user_id: user_id, prediction_id: prediction_id)
      errors.add(:base, "You have already voted on this prediction")
    end
  end

  def prediction_approved
    errors.add(:prediction, "is not approved") unless prediction.status == 'approved'
  end
end