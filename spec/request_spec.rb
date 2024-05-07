require_relative './spec_helper'

describe 'a normal request' do
  it 'returns right status code' do
    get '/'

    _(last_response.status).must_equal 200
  end
end
