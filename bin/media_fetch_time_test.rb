require_relative '../app/services/media_gatherer.rb'

# this was written to determine what a reasonable timeout would be
# for the MediaGather. Run it like:
# bundle exec rails runner bin/media_fetch_time_test.rb
class MediaFetchTimeTest

  TRIES = 100
  TIMEOUT = 3
  TIMES = []

  attr_reader :timeout
  attr_reader :gatherer
  attr_reader :start_time
  attr_reader :end_time
  attr_reader :success_count

  def initialize()
    @success_count = 0
  end

  def run_time_trials
    TRIES.times do
      new_gatherer
      set_start
      run_gatherer
      sleep 0.1 while gatherer.complete? == false
      set_end
      TIMES << time_taken
      @success_count += 1 if success?
    end
  end

  def new_gatherer
    @gatherer = MediaGatherer.new(runtime: TIMEOUT)
  end

  def run_gatherer
    gatherer.call
  end

  def set_start
    @start_time = Time.now
  end

  def set_end
    @end_time = Time.now
  end

  def time_taken
    end_time - start_time
  end

  def success?
    %i[facebook twitter].all? do |service|
      section = gatherer.aggregate[service]
      section && section != 'Service unavailable'
    end
  end

  def process_times
    TIMES.sort!
  end

  def output_results
    puts %Q{
      fastest time: #{TIMES.first}
      slowest time: #{TIMES.last}
      percent success: #{success_count.to_f/TRIES.to_f * 100}
    }
  end

end

if __FILE__ == $0
  tester = MediaFetchTimeTest.new
  tester.run_time_trials
  tester.process_times
  tester.output_results
end