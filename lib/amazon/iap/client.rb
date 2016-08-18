class Amazon::Iap::Client
  require 'net/http'
  require 'uri'

  PRODUCTION_HOST = 'https://appstore-sdk.amazon.com'

  def initialize(developer_secret, host=nil)
    @developer_secret = developer_secret
    @host = host || PRODUCTION_HOST
  end

  def verify_v1(user_id, purchase_token, renew_on_failure=true)
    begin
      process_v1 :verify, user_id, purchase_token
    rescue Amazon::Iap::Exceptions::ExpiredCredentials => e
      raise e unless renew_on_failure

      renewal = renew(user_id, purchase_token)
      verify(user_id, renewal.purchase_token, false)
    end
  end
  alias_method :verify, :verify_v1

  def renew_v1(user_id, purchase_token)
    process_v1 :renew, user_id, purchase_token
  end
  alias_method :renew, :renew_v1

  def verify_v2(user_id, receipt_id)
    uri = URI.parse "#{@host}/version/1.0/verifyReceiptId/developer/#{@developer_secret}/user/#{user_id}/receiptId/#{receipt_id}"
    req = Net::HTTP::Get.new uri.request_uri
    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') { |http| http.request req }
    Amazon::Iap::Result.new res
  end

  protected

  def process_v1(path, user_id, purchase_token)
    path = "/version/2.0/#{path}/developer/#{@developer_secret}/user/#{user_id}/purchaseToken/#{purchase_token}"
    uri = URI.parse "#{@host}#{path}"
    req = Net::HTTP::Get.new uri.request_uri
    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') { |http| http.request req }
    Amazon::Iap::Result.new res
  end
end
