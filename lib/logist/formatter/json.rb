# frozen_string_literal: true

require 'json'
require 'logger'
require 'rails'

module Logist
  module Formatter
    class Json < ::Logger::Formatter
      attr_accessor :flat_json

      def call(severity, timestamp, _progname, raw_msg)
        msg = normalize_message(raw_msg)
        payload = { level: severity, timestamp: format_datetime(timestamp), environment: ::Rails.env }

        if msg.is_a?(String) && msg.match(/Status [0-9]+/)
          status = msg.split(' ')[1]
          payload.merge!(status: status)
        elsif flat_json && msg.is_a?(Hash)
          payload.merge!(msg)
        else
          payload.merge!(message: msg)
        end

        payload.to_json << "\n"
      end

      private

      def normalize_message(raw_msg)
        return raw_msg unless raw_msg.is_a?(String)

        JSON.parse(raw_msg)
      rescue JSON::ParserError
        raw_msg
      end
    end
  end
end
