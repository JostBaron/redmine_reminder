class NoMailConfiguration < RuntimeError;
end


class ReminderMailer < Mailer
  include Redmine::I18n

  prepend_view_path "#{Redmine::Plugin.find("redmine_reminder").directory}/app/views"

  def self.reminder_notifications
    unless ActionMailer::Base.perform_deliveries
      raise NoMailConfiguration.new(l(:text_email_delivery_not_configured))
    end
    data = {}
    issues = self.find_issues
    issues.each { |issue| self.insert(data, issue) }
    data.each do |user, projects|
      reminder_notification(user, projects).deliver
    end
  end

  def reminder_notification(user, projects)

    # Only send notifications if the user has requested them or they are
    # activated by default.
    #if !user.reminder_notification_array.any? then
    #  return
    #end
    set_language_if_valid user.language
    puts "User: #{user.name}. Setting for notification: #{user.reminder_notification}"
    puts "Issues:"
    projects.each { |project, issues| puts "Project: #{project.name}"; puts "Issues: #{issues.map(&:id)}"}
    @projects = projects
    @issues_url = url_for(:controller => 'issues', :action => 'index',
                          :set_filter => 1, :assigned_to_id => user.id,
                          :sort => 'due_date:asc')

    mail :to => user.mail, :subject => l(:reminder_mail_subject)
  end


  def self.find_issues
    scope = Issue.open.where("#{Issue.table_name}.assigned_to_id IS NOT NULL" +
                                 " AND #{Project.table_name}.status = #{Project::STATUS_ACTIVE}" +
                                 " AND ( #{Issue.table_name}.due_date IS NOT NULL OR #{Issue.table_name}.start_date IS NOT NULL )" +
                                 " AND #{User.table_name}.status = #{User::STATUS_ACTIVE}"
    )
    issues = scope.includes([:status, :assigned_to, :project, :tracker]).all
    issues = issues.reject { |issue| not (issue.remind_due_date? or ( issue.overdue? and issue.project.module_enabled?(:reminder_notifications) ) or issue.remind_start_date?) }
    issues = issues.reject { |issue| issue.done_ratio >= 100 or not Setting.plugin_redmine_reminder["reminder_notification_ignore_status_#{issue.status.id.to_s}"].nil? }
    #issues = issues.reject { |issue| issue.assigned_to_id != 3 }
    issues = issues.sort { |first, second| 
		first.start_date <=> second.start_date if     (first.remind_start_date? and second.remind_start_date?)
		first.due_date   <=> second.due_date   if not (first.remind_start_date? and second.remind_start_date?)
		-1 if first.remind_start_date?
		1
	}

    return issues
  end

  private

  def self.insert(data, issue)
    data[issue.assigned_to] ||= {}
    data[issue.assigned_to][issue.project] ||= []
    data[issue.assigned_to][issue.project] << issue
  end

end
