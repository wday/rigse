Given /^the following resource pages exist:$/ do |table|
  table.hashes.each do |hash|
    user_name = hash.delete('user')
    user = User.first(:conditions => { :login => user_name })
    next if user.blank?
    
    hash['user'] = user
    resource_page = Factory(:resource_page, hash)
    resource_page.save!
  end
end

When /^I search for a resource page named "([^"]*)"$/ do |query|
  visit("/resource_pages?name=#{query}")
end

When /^I search for a resource page including drafts named "([^"]*)"$/ do |query|
  visit("/resource_pages?name=#{query}&include_drafts=true")
end

Given /^the teacher "([^"]*)" has (\d+) classes$/ do |teacher_login, num_classes|
  user = User.first(:conditions => { :login => teacher_login })
  teacher = user.portal_teacher
  num_classes.to_i.times do |n|
    clazz = Factory.create(:portal_clazz, :teacher => teacher)
  end
end

Given /^all resource pages are assigned to classes$/ do
  clazzes = Portal::Clazz.all
  ResourcePage.all.each do |resource_page|
    Factory.create(:portal_offering, {
      :runnable => resource_page,
      :clazz => clazzes.rand
    })
  end
end
