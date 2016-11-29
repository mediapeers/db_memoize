require 'spec_helper'

describe DbMemoize::Value do
  it 'returns value object' do
    expect(create(:value)).to be_a(DbMemoize::Value)
  end
end
