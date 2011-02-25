Given /the following users[(?exist):\s]*$/i do |users_table|
  User.anonymous(true)
  users_table.hashes.each do |hash|
    roles = hash.delete('roles')
    if roles
      roles = roles ? roles.split(/,\s*/) : nil
    else
      roles =  []
    end
    begin
      user = Factory(:user, hash)
      roles.each do |role|
        user.add_role(role)
      end
      user.register
      user.activate
      user.save!
    rescue ActiveRecord::RecordInvalid
      # assume this user is already created...
    end
  end
end

Given /^there are (\d+) (.+)$/ do |number, model_name|
  model_name = model_name.gsub(/\s/, '_').singularize
  the_class = model_name.classify.constantize
  
  the_class.destroy_all
  number.to_i.times do |i|
    Factory.create(model_name.to_sym)
  end
end

# Then the investigation named "Test" should have "offerings_count" equal to "1"
Then /^the (.*) named "([^"]*)" should have "([^"]*)" equal to "([^"]*)"$/ do |class_name, obj_name, field, value|
  obj = class_name.gsub(/\s/, "_").classify.constantize.find_by_name(obj_name)
  obj.send(field.to_sym).to_s.should == value
end

Then /"(.*)" should appear before "(.*)"/ do |first_item, second_item|
  page.body.should =~ /#{first_item}.*#{second_item}/m
end
