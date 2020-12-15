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
        elsif msg.is_a?(String) && msg.split(' ').length == 2 && msg.split(' ')[0].match('GET')
          splitted_msg = msg.split(' ')
          method = splitted_msg[0]
          path = splitted_msg[1]
          { message: { method: method, path: path } }
        elsif msg.is_a?(String) && msg.split(' ')[0].match('User-Agent:') && msg.split("\n")[1].split(' ')[0].match('Accept:')
          splitted_msg = msg.split("\n")
          user_agent = splitted_msg[0].split(' ')[1]
          accept = splitted_msg[1].split(' ')[1]
          { message: { user_agent: user_agent, accept: accept } }
        else
          { message: msg }
        end
      end
    end
  end
end
