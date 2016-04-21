require 'spec_helper'

describe security_group('test-labs-sg') do
  it { should exist }
end
