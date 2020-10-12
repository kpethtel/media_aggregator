class MediaGatherer

  # the number five was chosen by running the media_fetch_time_test.rb
  # script (which is only useful if you remove instagram from the SERVICES
  # below because instagram is currently not responding). locally, nearly
  # all requests came back in 3 seconds so i padded that number by 2. those
  # two seconds should seldom be used. before deploying, it would be wise
  # to run that script at various times of day in order to determine real
  # world behavior and then fine tune these values for maximum performance
  MAX_RUNTIME = ((Rails.env == 'test') ? 0 : 5).freeze
  SLEEP_INTERVAL = 0.1.freeze
  CONNECTION_TIMEOUT = 0.5.freeze
  TAKEHOME_BASE_URL = 'https://takehome.io'.freeze
  SERVICES = %i[facebook instagram twitter].freeze

  attr_reader :aggregate

  def initialize(runtime: MAX_RUNTIME)
    @aggregate = {}
    @runtime = runtime.to_i
  end

  def call
    fetch_all
    sleep_time.times do
      sleep SLEEP_INTERVAL unless complete?
    end
    fill_gaps
  end

  def complete?
    @aggregate.keys.sort == SERVICES.sort
  end

  private
    def fetch_all
      SERVICES.each do |service|
        fetch_service(service)
      end
    end

    def fetch_service(service)
      uri = URI.join(TAKEHOME_BASE_URL, service.to_s)

      Thread.new do
        # can't use faraday retry because it stops on non-200 responses
        connection_tries.times do
          response = response_from(uri)
          if successful_response?(response)
            @aggregate[service] = response.body
            break
          end
        end
      end
    end

    def fill_gaps
      SERVICES.each do |service|
        next if service_responded?(service)
        @aggregate[service] = 'Service unavailable'
      end
    end

    def response_from(uri)
      conn = Faraday.new(uri.to_s)
      conn.get do |req|
        conn.options.timeout = CONNECTION_TIMEOUT
      end
    end

    def successful_response?(response)
      return false unless response.status == 200
      begin
        JSON.parse response.body
      rescue JSON::ParserError => e
        return false
      end
      true
    end

    def service_responded?(service)
      @aggregate[service].present?
    end

    def sleep_time
      times = (@runtime/SLEEP_INTERVAL).to_i
      # even in tests, we need 1 sleep to allow threads to work
      times == 0 ? 1 : times
    end

    def connection_tries
      tries = (@runtime/CONNECTION_TIMEOUT).to_i
      tries == 0 ? 1 : tries
    end
end