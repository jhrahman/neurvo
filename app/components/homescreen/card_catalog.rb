# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module Homescreen
  # Every card that can appear at the top of the Home page, grouped by department.
  # Which cards a user sees is a per-user preference (UserPreference#home_cards);
  # without one, the defaults for the departments of the user's project roles apply.
  class CardCatalog
    include Homescreen::ListLinks

    Card = Data.define(:key, :group, :icon, :tone)
    Tile = Data.define(:key, :label, :count, :href, :icon, :tone)

    GROUPS = %i[everyone dev devops qa design pm].freeze
    GROUP_PRIORITY = %i[pm qa dev devops design].freeze
    INFRA_CATEGORIES = ["CI/CD", "Kubernetes", "Database", "Monitoring", "Security", "Cost"].freeze
    DESIGN_CATEGORIES = %w[UI UX Design].freeze
    MAX_CARDS = 6
    OPEN_STATUS = { n: "status", o: "o", v: [] }.freeze

    CARDS = [
      Card.new(:assigned, :everyone, :person, :neutral),
      Card.new(:overdue, :everyone, :clock, :danger),
      Card.new(:due_this_week, :everyone, :calendar, :attention),
      Card.new(:watching, :everyone, :eye, :neutral),
      Card.new(:created_by_me, :everyone, :pencil, :neutral),
      Card.new(:unread_notifications, :everyone, :bell, :attention),
      Card.new(:due_today, :everyone, :hourglass, :attention),
      Card.new(:high_priority, :everyone, :"arrow-up", :danger),
      Card.new(:done_this_week, :everyone, :"check-circle", :neutral),
      Card.new(:stale, :everyone, :history, :attention),
      Card.new(:in_progress, :dev, :play, :neutral),
      Card.new(:awaiting_review, :dev, :"git-pull-request", :attention),
      Card.new(:my_bugs, :dev, :bug, :danger),
      Card.new(:my_blocked, :dev, :stop, :danger),
      Card.new(:sent_back, :dev, :"issue-reopened", :danger),
      Card.new(:infra_work, :devops, :server, :neutral),
      Card.new(:my_infra, :devops, :tools, :neutral),
      Card.new(:change_requests, :devops, :"git-merge", :attention),
      Card.new(:support_queue, :devops, :"comment-discussion", :attention),
      Card.new(:monitoring_alerts, :devops, :pulse, :attention),
      Card.new(:security_work, :devops, :"shield-lock", :danger),
      Card.new(:production_bugs, :devops, :flame, :danger),
      Card.new(:ready_for_qa, :qa, :checklist, :attention),
      Card.new(:in_qa, :qa, :beaker, :neutral),
      Card.new(:open_bugs, :qa, :bug, :danger),
      Card.new(:reopened_bugs, :qa, :"issue-reopened", :danger),
      Card.new(:critical_bugs, :qa, :alert, :danger),
      Card.new(:reported_by_me, :qa, :report, :neutral),
      Card.new(:ui_work, :design, :paintbrush, :neutral),
      Card.new(:my_design_tasks, :design, :person, :neutral),
      Card.new(:ui_in_review, :design, :comment, :attention),
      Card.new(:ui_bugs, :design, :bug, :danger),
      Card.new(:ui_ready_to_test, :design, :"device-desktop", :attention),
      Card.new(:feature_requests, :design, :"light-bulb", :neutral),
      Card.new(:team_overdue, :pm, :clock, :danger),
      Card.new(:team_due_this_week, :pm, :calendar, :attention),
      Card.new(:unassigned, :pm, :unlink, :attention),
      Card.new(:blocked, :pm, :stop, :danger),
      Card.new(:critical_open, :pm, :alert, :danger),
      Card.new(:waiting_on_customer, :pm, :"comment-discussion", :attention),
      Card.new(:team_done_this_week, :pm, :"check-circle", :neutral),
      Card.new(:active_sprints, :pm, :rocket, :neutral)
    ].freeze

    DEFAULTS = {
      pm: %i[team_overdue active_sprints blocked unassigned open_bugs ready_for_qa],
      qa: %i[assigned overdue ready_for_qa in_qa open_bugs reopened_bugs],
      dev: %i[assigned overdue in_progress my_bugs awaiting_review],
      devops: %i[assigned overdue infra_work change_requests production_bugs support_queue],
      design: %i[assigned overdue ui_work ui_in_review ui_bugs feature_requests],
      everyone: %i[assigned overdue due_this_week watching]
    }.freeze

    ROLE_GROUPS = {
      "Project Manager" => :pm, "Project admin" => :pm,
      "QA Engineer" => :qa, "SQA Engineer" => :qa,
      "Developer" => :dev, "DevOps Engineer" => :devops, "Designer" => :design
    }.freeze

    def self.keys = CARDS.map(&:key)

    def self.cards_in(group) = CARDS.select { it.group == group }

    def initialize(user)
      @user = user
    end

    def selected_keys
      user.pref.home_cards.presence || default_keys
    end

    def default_keys
      keys = user_groups.flat_map { DEFAULTS.fetch(it) }.uniq
      (keys.presence || DEFAULTS.fetch(:everyone)).first(MAX_CARDS)
    end

    def recommended_groups
      user_groups.presence || %i[everyone]
    end

    def ordered_groups
      first = recommended_groups.sort_by { GROUPS.index(it) }
      (first + GROUPS).uniq
    end

    def tiles
      selected_keys.filter_map { tile_for(it) }
    end

    def count_for(key)
      tile_for(key)&.count
    end

    private

    attr_reader :user

    def user_groups
      @user_groups ||= begin
        names = user.admin? ? ["Project Manager"] : role_names
        found = names.filter_map { ROLE_GROUPS[it] }
        GROUP_PRIORITY.select { found.include?(it) }
      end
    end

    def role_names
      member_ids = Member.where(user_id: user.id).select(:id)
      Role.joins(:member_roles).where(member_roles: { member_id: member_ids }).distinct.pluck(:name)
    end

    def tile_for(key)
      card = CARDS.find { it.key == key }
      scope, filters, href = card && definition(key)
      return if scope.nil?

      count = scope.count
      Tile.new(key:, label: I18n.t("neurvo.home.cards.#{key}.label"), count:, href: href || list_path(filters),
               icon: card.icon, tone: count.zero? ? :neutral : card.tone)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    def definition(key)
      case key
      when :assigned then [mine, [assignee_me, OPEN_STATUS]]
      when :overdue then [mine.where(due_date: ...today), [assignee_me, OPEN_STATUS, overdue_filter]]
      when :due_this_week then [mine.where(due_date: today..week_end), [assignee_me, OPEN_STATUS, week_filter]]
      when :watching then [open_work.where(id: watched_ids), [{ n: "watcher", o: "=", v: ["me"] }, OPEN_STATUS]]
      when :created_by_me then [open_work.where(author_id: user.id), [{ n: "author", o: "=", v: ["me"] }, OPEN_STATUS]]
      when :unread_notifications
        [Notification.where(recipient_id: user.id, read_ian: false), nil, helpers.notifications_path]
      when :in_progress then status_card("In Progress", mine: true)
      when :awaiting_review then status_card("In Review")
      when :my_bugs then bug_card(mine: true)
      when :my_blocked then status_card("Blocked", mine: true)
      when :sent_back then status_card("Reopened", mine: true)
      when :ready_for_qa then status_card("Ready for QA")
      when :in_qa then status_card("In QA")
      when :open_bugs then bug_card
      when :reopened_bugs then bug_card(status: "Reopened")
      when :critical_bugs then critical_bugs_card
      when :reported_by_me then bug_card(author: true)
      when :team_overdue then [open_work.where(due_date: ...today), [OPEN_STATUS, overdue_filter]]
      when :team_due_this_week then [open_work.where(due_date: today..week_end), [OPEN_STATUS, week_filter]]
      when :unassigned then [open_work.where(assigned_to_id: nil), [OPEN_STATUS, { n: "assignee", o: "!*", v: [] }]]
      when :blocked then status_card("Blocked")
      when :active_sprints then sprints_card
      when :due_today then [mine.where(due_date: today), [assignee_me, OPEN_STATUS, { n: "dueDate", o: "=d", v: [today.iso8601] }]]
      when :high_priority then priority_card
      when :done_this_week then done_card(mine: true)
      when :stale then stale_card
      when :infra_work then category_card(INFRA_CATEGORIES)
      when :my_infra then category_card(INFRA_CATEGORIES, mine: true)
      when :monitoring_alerts then category_card(["Monitoring"])
      when :security_work then category_card(["Security"])
      when :change_requests then type_card("Change Request")
      when :support_queue then type_card("Support Request")
      when :feature_requests then type_card("Feature Request")
      when :production_bugs then production_bugs_card
      when :ui_work then category_card(DESIGN_CATEGORIES)
      when :my_design_tasks then category_card(DESIGN_CATEGORIES, mine: true)
      when :ui_in_review then category_card(DESIGN_CATEGORIES, status: "In Review")
      when :ui_bugs then category_card(DESIGN_CATEGORIES, type: "Bug")
      when :ui_ready_to_test then category_card(DESIGN_CATEGORIES, status: "Ready for QA")
      when :critical_open then priority_card(team: true)
      when :waiting_on_customer then status_card("Waiting on Customer")
      when :team_done_this_week then done_card
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

    def category_card(names, mine: false, status: nil, type: nil)
      ids = Category.where(name: names).pluck(:id)
      return if ids.empty?

      scope = open_work.where(category_id: ids)
      category_filter = { n: "category", o: "=", v: ids.map(&:to_s) }
      filters = [OPEN_STATUS, category_filter]
      if mine
        scope = scope.where(assigned_to_id: user.id)
        filters << assignee_me
      end
      if status
        found = Status.where(name: status)
        scope = scope.where(status_id: found.ids)
        filters = [{ n: "status", o: "=", v: found.ids.map(&:to_s) }, category_filter]
      end
      if type
        found = Type.find_by(name: type)
        return unless found

        scope = scope.where(type_id: found.id)
        filters << { n: "type", o: "=", v: [found.id.to_s] }
      end
      [scope, filters]
    end

    def type_card(name)
      found = Type.find_by(name:)
      return unless found

      [open_work.where(type_id: found.id), [OPEN_STATUS, { n: "type", o: "=", v: [found.id.to_s] }]]
    end

    def priority_card(team: false)
      levels = IssuePriority.where(name: team ? ["Critical"] : %w[High Critical])
      return if levels.empty?

      scope = open_work.where(priority_id: levels.ids)
      filters = [OPEN_STATUS, { n: "priority", o: "=", v: levels.ids.map(&:to_s) }]
      unless team
        scope = scope.where(assigned_to_id: user.id)
        filters << assignee_me
      end
      [scope, filters]
    end

    def done_card(mine: false)
      closed = Status.where(is_closed: true, name: "Done")
      return if closed.empty?

      scope = WorkPackage.visible(user).where(status_id: closed.ids, updated_at: 7.days.ago..)
      filters = [{ n: "status", o: "=", v: closed.ids.map(&:to_s) }, { n: "updatedAt", o: ">t-", v: ["7"] }]
      if mine
        scope = scope.where(assigned_to_id: user.id)
        filters << assignee_me
      end
      [scope, filters]
    end

    def stale_card
      [mine.where(updated_at: ...14.days.ago), [assignee_me, OPEN_STATUS, { n: "updatedAt", o: "<t-", v: ["14"] }]]
    end

    def production_bugs_card
      field = WorkPackageCustomField.find_by(name: "Environment")
      option = field&.custom_options&.find_by(value: "Production")
      scope, filters = bug_card
      return unless scope && option

      with_value = CustomValue.where(customized_type: "WorkPackage", custom_field_id: field.id, value: option.id.to_s)
      [scope.where(id: with_value.select(:customized_id)), filters + [{ n: "cf_#{field.id}", o: "=", v: [option.id.to_s] }]]
    end

    def status_card(name, mine: false)
      statuses = Status.where(name:)
      return if statuses.empty?

      scope = open_work.where(status_id: statuses.ids)
      filters = [{ n: "status", o: "=", v: statuses.ids.map(&:to_s) }]
      if mine
        scope = scope.where(assigned_to_id: user.id)
        filters << assignee_me
      end
      [scope, filters]
    end

    def bug_card(mine: false, status: nil, author: false)
      bug = Type.find_by(name: "Bug")
      return unless bug

      scope = open_work.where(type_id: bug.id)
      filters = [OPEN_STATUS, { n: "type", o: "=", v: [bug.id.to_s] }]
      if mine
        scope = scope.where(assigned_to_id: user.id)
        filters << assignee_me
      end
      if author
        scope = scope.where(author_id: user.id)
        filters << { n: "author", o: "=", v: ["me"] }
      end
      if status
        reopened = Status.find_by(name: status)
        return unless reopened

        scope = scope.where(status_id: reopened.id)
        filters = [{ n: "status", o: "=", v: [reopened.id.to_s] }, { n: "type", o: "=", v: [bug.id.to_s] }]
      end
      [scope, filters]
    end

    def critical_bugs_card
      field = WorkPackageCustomField.find_by(name: "Severity")
      option = field&.custom_options&.find_by(value: "Critical")
      scope, filters = bug_card
      return unless scope && option

      with_value = CustomValue.where(customized_type: "WorkPackage", custom_field_id: field.id, value: option.id.to_s)
      [scope.where(id: with_value.select(:customized_id)), filters + [{ n: "cf_#{field.id}", o: "=", v: [option.id.to_s] }]]
    end

    def sprints_card
      sprints = Sprint.active.where(project_id: Project.allowed_to(user, :view_sprints).select(:id))
      href = sprints.one? ? helpers.project_backlogs_backlog_path(sprints.first.project) : helpers.projects_path
      [sprints, nil, href]
    end

    def open_work = WorkPackage.visible(user).with_status_open

    def mine = open_work.where(assigned_to_id: user.id)

    def watched_ids = Watcher.where(watchable_type: "WorkPackage", user_id: user.id).select(:watchable_id)

    def assignee_me = { n: "assignee", o: "=", v: ["me"] }

    def overdue_filter = { n: "dueDate", o: "<t-", v: ["1"] }

    def week_filter = { n: "dueDate", o: "<>d", v: [today.iso8601, week_end.iso8601] }

    def today = Time.zone.today

    def week_end = today + 7.days

    def helpers = ApplicationController.helpers
  end
end
