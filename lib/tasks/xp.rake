namespace :xp do
    desc "Update all users' XP totals"
    task update_all: :environment do
      XpUpdater.update_all!
      puts "Users' XP updated successfully."
    end
  end
  