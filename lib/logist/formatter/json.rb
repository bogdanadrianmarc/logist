# frozen_string_literal: true

require 'json'
require 'logger'
require 'rails'

module Logist
  module Formatter
    class Json < ::Logger::Formatter
      attr_accessor :flat_json

      def call(severity, timestamp, _progname, raw_msg)
        sev = process_severity(severity)
        tstamp = process_timestamp(timestamp)

        payload = { level: sev, timestamp: tstamp, environment: ::Rails.env }

        msg = process_message(raw_msg)
        payload.merge!(msg)

        payload.to_json << "\n"
      end

      private

      def normalize_message(raw_msg)
        return raw_msg unless raw_msg.is_a?(String)

        JSON.parse(raw_msg)
      rescue JSON::ParserError
        raw_msg
      end

      def process_severity(severity)
        severity.is_a?(String) && severity.match('FATAL') ? 'ERROR' : severity
      end

      def process_timestamp(timestamp)
        format_datetime(timestamp).strip
      end

      def process_message(raw_msg)
        msg = normalize_message(raw_msg)

        if flat_json && msg.is_a?(Hash)
          msg
        elsif msg.is_a?(String) && msg.match(/Status [0-9]+/)
          status = msg.split(' ')[1]
          { message: { status: status } }
        else
          { message: msg }
        end
      end
    end
  end
end
