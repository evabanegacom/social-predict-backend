require 'fcm'

firebase_config = Rails.application.credentials.firebase
FCM_CLIENT = FCM.new(firebase_config[:server_key]) if firebase_config
