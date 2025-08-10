class Prediction < ApplicationRecord
  belongs_to :user
  has_many :votes, dependent: :destroy
  has_many :points, dependent: :destroy
  validates :topic, presence: true
  validates :category, presence: true, inclusion: { in: %w[Music Politics Sports Other] }
  validates :vote_options, presence: true
  validates :expires_at, presence: true
  validates :user_id, presence: true
  validates :status, inclusion: { in: %w[pending approved resolved rejected], message: "%{value} is not a valid status" }
  validates :result, inclusion: { in: %w[Yes No], allow_nil: true }
  validate :expires_at_in_future
  validate :expires_at_within_range

  after_update :process_points, if: :result_changed?

  def time_left
    return "Expired" if expires_at < Time.now.utc
    seconds_left = (expires_at - Time.now.utc).to_i
    days = seconds_left / (24 * 3600)
    hours = (seconds_left % (24 * 3600)) / 3600
    minutes = (seconds_left % 3600) / 60
    "#{days}d #{hours}h #{minutes}m"
  end

  def update_vote_counts
    vote_counts = votes.group(:choice).count
    update(vote_options: {
      yes: vote_counts["Yes"] || 0,
      no: vote_counts["No"] || 0,
      maybe: vote_counts["Maybe"] || 0
    })
    award_xp if votes.count >= 10 # 50 XP per 10 votes for creator
  end

  private

  def award_xp
    xp_increment = (votes.count / 10) * 50
    user.update(xp: user.xp + xp_increment)
  end

  def expires_at_in_future
    if expires_at && expires_at <= Time.now.utc
      errors.add(:expires_at, "must be in the future")
    end
  end

  def expires_at_within_range
    if expires_at
      min_time = Time.now.utc + 1.minute
      max_time = Time.now.utc + 7.days
      unless expires_at.between?(min_time, max_time)
        errors.add(:expires_at, "must be between 1 minute and 7 days from now")
      end
    end
  end

  def process_points
    return unless result.present? && status == 'resolved'
    votes.each do |vote|
      user = vote.user
      points = vote.choice == result ? 10 : -2
      user.update(points: [user.points + points, 0].max) # Update points, minimum 0
      Point.find_or_create_by(user: user, prediction: self) do |point|
        point.points = points
        point.choice = vote.choice
        point.result = result
        point.awarded_at = Time.now.utc
      end
    end
  end
end
