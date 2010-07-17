# encoding: UTF-8
# Source Code Modifications (c) 2010 Laurence A. Lee, 
# See /RUBYJEDI.txt for Licensing and Distribution Terms
# Load the normal Rails helper. This ensures the environment is loaded.
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Load the schema - if migrations have been performed, this will be up to date.
#load(File.dirname(__FILE__) + "/../db/schema.rb")
#Rake::Task['db:test:prepare']

# Set up the fixtures location manually, we don't want to move them to a
# temporary path using Engines::Testing.set_fixture_path.
# This works with unit and functional tests.
ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(ActiveSupport::TestCase.fixture_path)
# This is needed for integration tests.
ActionController::IntegrationTest.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(ActionController::IntegrationTest.fixture_path)

# The only drawback to using transactional fixtures is when you actually 
# need to test transactions.  Since your test is bracketed by a transaction,
# any transactions started in your code will be automatically rolled back.
ActiveSupport::TestCase.use_transactional_fixtures = false

# Instantiated fixtures are slow, but give you @david where otherwise you
# would need people(:david).  If you don't want to migrate your existing
# test cases which use the @david style and don't mind the speed hit (each
# instantiated fixtures translates to a database query per test method),
# then set this back to true.
ActiveSupport::TestCase.use_instantiated_fixtures  = false

# We don't want our tests with images messing with "public/system" used in
# development and production, and creating images with ids that only exists in
# the test database or overwriting things.

## FIXME: This was something for Attachment-Fu, may want to replace with a Paperclip Equivalent. 
##Image.options[:path] = "public/test/"

### Helper methods for test cases ###

def login_as(user)
  @request.session[:user] = users(user).id
end

def login_as_customer(customer)
  order_user = order_users(customer)
  post "/customers/login", :login=>order_user.email_address, :password=>order_user.password
end

def substruct_fixture_file(filename, mode='rb')
  File.open(File.expand_path(File.dirname(__FILE__) + "/fixtures/files/#{filename}"), mode)
end

# Unfortunately url_for doesn't work as is inside tests, so, a fix.
def url_for(options)
  url = ActionController::UrlRewriter.new(@request, nil)
  url.rewrite(options)
end

### Custom assertions for test cases ####

# Assert that two arrays have the same elements independent of the order.
def assert_same_elements(an_array, another_array)
  assert_equal an_array - another_array, another_array - an_array
end

# The assert_working_associations method simply walks through all of the 
# associations on the class and sends the model the name of the association.
# This catch-all ensures that with a single line of code per model, 
# I can invoke all relationships on all of our model tests.
def assert_working_associations(m=nil)
  m ||= self.class.to_s.sub(/Test$/, '').constantize
  @m = m.new
  m.reflect_on_all_associations.each do |assoc|
    assert_nothing_raised("#{assoc.name} caused an error") do
      @m.send(assoc.name, true)
    end
  end
  true
end
