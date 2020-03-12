module SimpleSlackAlerts
  class Notifier
    # TODO: 'Slack' can be only one of concrete implementations,
    # write it in the most abstract way.
    #
    # TODO: move stuff to external configs.
    URL = 'https://hooks.slack.com'.freeze
    DEFAULT_PARAMS = { username: 'default_bot', icon_emoji: ':slack:' }.freeze

    CHANNEL_URLS = { billing_alerts: '/services/T22B51L01/BEC0XQRGU/HuFZ6A9Gfrmun9ycHExV6nUS' }.freeze

    # NOTE: you can explicitely send channel here into params - to post to a specific channel, not the
    # one set in the integration settings.
    def perform(channel, text, **params)
      # TODO: move this to config too - to remove dependancy on Rails.env and 'under_test'
      return unless Rails.env.production? || (Rails.env.test? && under_test?)
      params = DEFAULT_PARAMS.merge(params)

      conn = Faraday.new(url: URL)
      conn.post do |req|
        req.url CHANNEL_URLS[channel]
        req.headers['Content-Type'] = 'application/json'
        req.body = params.merge(text: text).to_json
      end
    end

    private

    def under_test?
      false
    end
  end
end
