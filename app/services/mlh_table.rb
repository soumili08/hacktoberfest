# frozen_string_literal: true

class MlhTable
  attr_accessor :api_url

  def initialize
    @api_url = 'https://organize.mlh.io/api/v2/events?type=hacktoberfest-2020'
  end

  def faraday_connection
    @faraday_connection ||= Faraday.new(
      url: @api_url,
      request: {
        open_timeout: 3,
        timeout: 10
      }
    ) do |faraday|
      faraday.use Faraday::Response::RaiseError
      faraday.adapter Faraday.default_adapter
      faraday.response :caching do
        unless Rails.configuration.cache_store == :null_store
          ActiveSupport::Cache.lookup_store(
            *Rails.configuration.cache_store,
            namespace: 'mlh',
            expires_in: 3.hours
          )
        end
      end
    end
    response = @faraday_connection.get
    if response.success?
      response.body
    else
      AirtablePlaceholderService.call('Meetups')
    end
  end

  def records
    if faraday_connection.is_a? String
      JSON.parse(faraday_connection)
    else
      faraday_connection
    end
  end
end
