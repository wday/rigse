
Given /^the following investigation exists:$/ do |investigation_table|
  investigation_table.hashes.each do |hash|
    user = User.first(:conditions => { :login => hash.delete('user') })
    hash[:user_id] = user.id
    investigation = Investigation.create(hash)
    activity =Activity.create(hash)
    section = Section.create(hash)
    page = Page.create(hash)
    section.pages << page
    activity.sections << section
    investigation.activities << activity
    investigation.save
  end
end

When /add a multiple choice question$/ do
  # pending # express the regexp above with the code you wish you had
end

When /^(?:|I )follow xpath "([^\"]*)"$/ do |xpath|
  find(:xpath, xpath).click
end

When /show the first page of the "(.*)" investigation$/ do |investigation_name|
  investigation = Investigation.find_by_name(investigation_name)
  page = investigation.pages.first
  visit page_path(page)
end

Given /a mock gse/ do
  domain = mock_model(RiGse::Domain,
    :id => 1,
    :name => "physics"
  )
  gse = mock_model(RiGse::GradeSpanExpectation,
    :domain => domain,
    :id => 1,
    :grade_span => '9-11',
    :print_summary_data => "summary data",
    :gse_key => 'PHY-9-11',
    :expectations => [] # not very ambitious
  )
  domain.stub(:grade_span_expectations).and_return([gse])

  RiGse::GradeSpanExpectation.stub!(:default).and_return(gse)
  RiGse::Domain.stub!(:find).and_return([domain])
  RiGse::Domain.stub!(:find).with(1).and_return(domain)
end


#Table: | investigation | activity | section   | page   | multiple_choices |
Given /^The following investigation exists:$/ do |investigation_table|
  investigation_table.hashes.each do |hash|
    investigation = Investigation.find_or_create_by_name(hash['investigation'])
    activity = Activity.find_or_create_by_name(hash['activity'])
    section = Section.find_or_create_by_name(hash['section'])
    page = Page.find_or_create_by_name(hash['page'])
    mcs = hash['multiple_choices'].split(",").map{ |mc| Embeddable::MultipleChoice.find_by_prompt(mc.strip) }
    mcs.each do |mc|
      mc.pages << page
    end
    page.save
    section.pages << page
    activity.sections << section
    investigation.activities << activity
  end
end

#Table: | prompt | answers | correct_answer |
Given /^the following multiple choice questions exists:$/ do |mult_table|
  mult_table.hashes.each do |hash|
    prompt = hash['prompt']
    choices = hash['answers'].split(",")
    choices.map!{|c| c.strip}
    correct = hash['correct_answer']
    multi = Embeddable::MultipleChoice.find_or_create_by_prompt(prompt)
    choices.map! { |c| Embeddable::MultipleChoiceChoice.create(
      :choice => c, 
      :multiple_choice => multi, 
      :is_correct => (c == correct)
    )}
    multi.choices = choices
  end
end
