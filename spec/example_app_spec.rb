# frozen_string_literal: true

require 'rack/test'
require_relative 'spec_helper'
require_relative '../examples/app'

RSpec.describe 'Example App' do
  include Rack::Test::Methods

  def app
    App
  end

  it 'does not explode' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(json_load(last_response.body)).to eq('hello' => 'world')
  end

  it 'returns 404' do
    get '/unknown'
    expect(last_response.status).to eq 404
  end
end
