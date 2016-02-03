require 'redmine'
require_dependency 'reminder/view_hook'

Rails.configuration.to_prepare do
  require_dependency 'project'
  require_dependency 'principal'
  require_dependency 'user'
  unless User.included_modules.include? Reminder::UserPatch
    User.send(:include, Reminder::UserPatch)
  end

  require_dependency 'issue_category'
  unless IssueCategory.included_modules.include? Reminder::IssueCategoryPatch
    IssueCategory.send(:include, Reminder::IssueCategoryPatch)
  end

  require_dependency 'issue'
  unless Issue.included_modules.include? Reminder::IssuePatch
    Issue.send(:include, Reminder::IssuePatch)
  end

  require_dependency 'settings_controller'
  unless SettingsController.included_modules.include? Reminder::SettingsControllerPatch
    SettingsController.send(:include, Reminder::SettingsControllerPatch)
  end

  require_dependency 'my_controller'
  unless MyController.included_modules.include? Reminder::MyControllerPatch
    MyController.send(:include, Reminder::MyControllerPatch)
  end
end

Redmine::Plugin.register :redmine_reminder do
  name 'Due Date Reminder plugin'
  author 'Oleg Kandaurov, Dmitry Yu Okunev'
  description 'Sends notifications about due date'
  version '0.5'
  url 'https://github.com/mephi-ut/redmine_reminder'
  author_url 'http://f0y.me https://github.com/xaionaro'
  requires_redmine :version_or_higher => '2.0.0'
  settings :default => {'reminder_notification' => '1,7,30', 'category_reminder_notification' => '1,7,30', 'reminder_notification_ignore_status' => {} }, :partial => 'reminder/settings'
  project_module :reminder_notifications do
		permission :reminder_notifications, {}
  end
end
