class Prediction < ApplicationRecord
  belongs_to :user
  has_many :votes, dependent: :destroy
  validates :topic, presence: true
  validates :category, presence: true, inclusion: { in: %w[Music Politics Sports Other] }
  validates :vote_options, presence: true
  validates :expires_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :user_id, presence: true
  validates :result, inclusion: { in: %w[Yes No], allow_nil: true }

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
      maybe: vote_options[:maybe] || 0
    })
    award_xp if votes.count >= 10 # 50 XP per 10 votes for creator
  end

  private

  def award_xp
    xp_increment = votes.count / 10 * 50
    user.update(xp: user.xp + xp_increment)
  end

  def process_points
    return unless result.present? && status == 'approved'
    votes.each do |vote|
      user = vote.user
      if vote.choice == result
        user.update(xp: user.xp + 100) # 100 points for correct vote
      else
        user.update(xp: [user.xp - 10, 0].max) # Deduct 10 points, minimum 0
      end
    end
  end
end