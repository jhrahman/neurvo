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

    GROUPS = %i[everyone dev qa pm].freeze
    MAX_CARDS = 6
    OPEN_STATUS = { n: "status", o: "o", v: [] }.freeze

    CARDS = [
      Card.new(:assigned, :everyone, :person, :neutral),
      Card.new(:overdue, :everyone, :clock, :danger),
      Card.new(:due_this_week, :everyone, :calendar, :attention),
      Card.new(:watching, :everyone, :eye, :neutral),
      Card.new(:created_by_me, :everyone, :pencil, :neutral),
      Card.new(:unread_notifications, :everyone, :bell, :attention),
      Card.new(:in_progress, :dev, :play, :neutral),
      Card.new(:awaiting_review, :dev, :"git-pull-request", :attention),
      Card.new(:my_bugs, :dev, :bug, :danger),
      Card.new(:my_blocked, :dev, :stop, :danger),
      Card.new(:sent_back, :dev, :"issue-reopened", :danger),
      Card.new(:ready_for_qa, :qa, :checklist, :attention),
      Card.new(:in_qa, :qa, :beaker, :neutral),
      Card.new(:open_bugs, :qa, :bug, :danger),
      Card.new(:reopened_bugs, :qa, :"issue-reopened", :danger),
      Card.new(:critical_bugs, :qa, :alert, :danger),
      Card.new(:reported_by_me, :qa, :report, :neutral),
      Card.new(:team_overdue, :pm, :clock, :danger),
      Card.new(:team_due_this_week, :pm, :calendar, :attention),
      Card.new(:unassigned, :pm, :unlink, :attention),
      Card.new(:blocked, :pm, :stop, :danger),
      Card.new(:active_sprints, :pm, :rocket, :neutral)
    ].freeze

    DEFAULTS = {
      pm: %i[team_overdue active_sprints blocked unassigned open_bugs ready_for_qa],
      qa: %i[assigned overdue ready_for_qa in_qa open_bugs reopened_bugs],
      dev: %i[assigned overdue in_progress my_bugs awaiting_review],
      everyone: %i[assigned overdue due_this_week watching]
    }.freeze

    ROLE_GROUPS = {
      "Project Manager" => :pm, "Project admin" => :pm,
      "QA Engineer" => :qa,
      "Developer" => :dev, "DevOps Engineer" => :dev, "Designer" => :dev
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
        GROUPS.select { found.include?(it) }
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
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

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
