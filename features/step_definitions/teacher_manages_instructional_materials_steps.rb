
Then /^A report window opens of offering "(.+)"$/ do |offering|
  #offering = Portal::Offering.find_by_name(offering)
  step 'I wait 2 seconds'
  page.driver.browser.switch_to.window page.driver.browser.window_handles.last do
    page.should have_content("Report for:")
    page.should have_content("#{offering}")
  end
end

And /^(?:|I )click the tab of Instructional Materials with text "(.+)"$/ do |text|
  script_text = "
    var arrTabs = $$('#oTabcontainer div.tab');
    arrTabs = arrTabs.concat( $$('#oTabcontainer div.selected_tab') );
    var strTabText = null;
    for (var i = 0; i < arrTabs.length; i++)
    {
      strTabText = arrTabs[i].innerHTML.stripTags().strip();
      if (strTabText == '#{text}')
      {
        arrTabs[i].simulate('click');
        return true;
      }
    }
    return false;
  "
  result = page.execute_script(script_text)
  
   raise 'Tab switch failed' if result == false
  
end

And /^(?:|I )should see progress bars for the students$/ do
  step 'I wait 2 seconds'
  result = page.execute_script("
    var arrProgressBars = $$('div.progress');
    var bProgressBarWidthIncreased = false;
    var iWidth = null;
    for (var i = 0; i < arrProgressBars.length; i++)
    {
      iWidth = parseInt(arrProgressBars[i].style.width, 10);
      if (iWidth > 0)
      {
        bProgressBarWidthIncreased = true;
      }
    }
    return bProgressBarWidthIncreased;
  ")
  
   raise 'Progress bar fail' if result == false

end

When /^(?:|I )follow "(.+)" for the investigation "(.+)"$/ do |link, investigation_name|
  within(:xpath, "//tr[contains(.,'#{investigation_name}') and contains(.,'Investigation:')]") do
    step "I follow \"#{link}\""
  end
end

When /^(?:|I )follow "(.+)" for the activity "(.+)"$/ do |link, activity_name|
  within(:xpath, "//tr[contains(.,'#{activity_name}') and contains(.,'Activity')]") do
    step "I follow \"#{link}\""
  end
end

And /^(?:|I )click progress bar on the instructional materials page for the student "(.+)" and activity "(.+)"$/ do |student_login, activity_name|
  user_id = User.find_by_login(student_login).id
  activity_id = Activity.find_by_name(activity_name).id
  find(:xpath,"//div[@id = 'progressbar_#{user_id}_#{activity_id}']").click
end
