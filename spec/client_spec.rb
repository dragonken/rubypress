require_relative 'spec_helper'

describe "#client" do

  it '#initialize' do
    CLIENT.class.should == Rubypress::Client
  end

  it "#execute" do
    Rubypress::Client.any_instance.stub_chain(:connection, :call){ [{"user_id"=>"46917508", "user_login"=>"johnsmith", "display_name"=>"john"}, {"user_id"=>"33333367", "user_login"=>"johnsmith", "display_name"=>"johnsmith"}] }
    expect(CLIENT.execute("wp.getAuthors", {})).to eq( [{"user_id"=>"46917508", "user_login"=>"johnsmith", "display_name"=>"john"}, {"user_id"=>"33333367", "user_login"=>"johnsmith", "display_name"=>"johnsmith"}] )
  end

  it '#execute only sets up retries for the current instance' do
    retryable_connection = Rubypress::Client.new(CLIENT_OPTS.merge(retry_timeouts: true)).connection
    standard_connection = Rubypress::Client.new(CLIENT_OPTS).connection

    expect(retryable_connection).to respond_to(:call_with_retry)
    expect(standard_connection).to_not respond_to(:call_with_retry)
  end

  it '#execute retries timeouts when retry_timeouts option is true' do
    client = Rubypress::Client.new(CLIENT_OPTS.merge(retry_timeouts: true))
    connection = client.connection
    client.stub(:connection).and_return(connection)

    expect(connection).to receive(:call_without_retry).twice.and_raise(Timeout::Error)
    expect { client.execute('newComment', {}) }.to raise_error(Timeout::Error)
  end

  it '#execute does not retry timeouts by default' do
    client = Rubypress::Client.new(CLIENT_OPTS)
    expect(client).to_not receive(:call_with_retry)
    expect { client.execute('newComment', {}) }.to raise_error(VCR::Errors::UnhandledHTTPRequestError)
  end

  it "#httpAuth" do
    conn = HTTP_AUTH_CLIENT.connection

    expect( conn.user ).to eq HTTP_AUTH_CLIENT_OPTS[ :http_user ]
    expect( conn.password ).to eq HTTP_AUTH_CLIENT_OPTS[ :http_password ]

    expect( conn.user.nil? ).to be_false
    expect( conn.password.nil? ).to be_false

  end
end
