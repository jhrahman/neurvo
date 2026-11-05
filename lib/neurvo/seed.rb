# frozen_string_literal: true

#-- copyright
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
#++

# Seed scripts build data step by step; splitting them further would not make them clearer.
# rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
module Neurvo
  # Builds the Neurvo sample workspace described in seed_data.yml.
  # Safe to run repeatedly: configuration is upserted, sample projects are rebuilt.
  class Seed
    DATA_PATH = File.expand_path("seed_data.yml", __dir__)
    PROJECT_FILES = File.expand_path("seed_data/*.yml", __dir__)
    DEFAULT_PASSWORD = "Neurvo-Dev-2026!"
    MAIL_DOMAIN = "oceanit.example"
    UPSTREAM_DEMO_IDENTIFIERS = %w[demo-project your-scrum-project dev-empty dev-work-package-sharing
                                   dev-large dev-large-child dev-custom-fields].freeze
    RETIRED_SAMPLE_IDENTIFIERS = %w[WEB MOB SHOP].freeze
    KEPT_LOGINS = %w[admin qa].freeze
    FORM_SECTIONS = {
      details: %w[priority sprint target_versions category date],
      people: %w[assignee responsible],
      estimates_and_progress: %w[story_points estimated_time remaining_time percentage_done]
    }.freeze

    attr_reader :data, :log, :today

    def initialize(log: $stdout, remove_upstream_demo: true)
      @data = load_data
      @log = log
      @remove_upstream_demo = remove_upstream_demo
      @today = Time.zone.today
      @refs = {}
    end

    def call
      User.system.run_given do
        Journal::NotificationConfiguration.with(false) do
          remove_upstream_demo if @remove_upstream_demo
          configure_instance
          seed_statuses
          seed_types
          seed_priorities
          seed_custom_fields
          seed_roles
          seed_workflows
          seed_users
          rebuild_projects
          convert_to_semantic_identifiers
        end
        create_comments
      end
      say "Done. Log in as any team member with password #{DEFAULT_PASSWORD}"
    end

    private

    # The shared configuration lives in seed_data.yml; every file in seed_data/ describes one project with its
    # tickets, relations, comments, saved views, meetings and wiki pages.
    def load_data
      YAML.safe_load_file(DATA_PATH, aliases: false).merge(
        "projects" => [], "work_packages" => {}, "relations" => [], "comments" => {},
        "queries" => [], "meetings" => [], "wiki_pages" => []
      ).tap do |data|
        Dir[PROJECT_FILES].each do |path|
          add_project_file(data, YAML.safe_load_file(path, aliases: false))
        end
      end
    end

    def add_project_file(data, part)
      key = part.fetch("project").fetch("key")
      data["projects"] << part["project"]
      data["work_packages"][key] = part.fetch("work_packages", [])
      data["relations"].concat(part.fetch("relations", []))
      data["comments"].merge!(part.fetch("comments", {}))
      %w[queries meetings wiki_pages].each do |section|
        data[section].concat(part.fetch(section, []).map { |item| { "project" => key }.merge(item) })
      end
    end

    def say(message) = log&.puts("[neurvo:seed] #{message}")

    def admin = @admin ||= User.where(admin: true).order(:id).first

    # --- cleanup ---------------------------------------------------------

    def remove_upstream_demo
      destroy_projects(Project.where(identifier: UPSTREAM_DEMO_IDENTIFIERS), "Removing upstream demo project")

      team_logins = data["users"].map { |u| login_for(u) }
      User.user.where.not(login: KEPT_LOGINS + team_logins).where(admin: false).find_each do |user|
        say "Removing demo user #{user.name}"
        Principals::DeleteJob.perform_now(user)
      end
      Group.where.not(lastname: data["users"].pluck("group").uniq).find_each do |group|
        Principals::DeleteJob.perform_now(group)
      end
    end

    def destroy_projects(scope, message)
      scope.order(lft: :desc).to_a.each do |project|
        next unless Project.exists?(project.id)

        say "#{message} #{project.name}"
        project.reload.destroy!
      end
    end

    def configure_instance
      Setting.work_packages_identifier = Setting::WorkPackageIdentifier::SEMANTIC
      Setting.default_projects_modules = data["modules"].map(&:to_s)
      Setting.default_projects_public = false
      Setting.self_registration = Setting::SelfRegistration.disabled
      Setting.organization_name = data.dig("organization", "name")
      Setting.welcome_title = data.dig("organization", "welcome_title")
      Setting.welcome_text = data.dig("organization", "welcome_text")
      Setting.plugin_openproject_avatars = Setting.plugin_openproject_avatars.merge("enable_gravatars" => false)
    end

    # --- configuration ---------------------------------------------------

    def color(hex) = Color.find_or_create_by!(hexcode: hex) { |c| c.name = hex }

    def seed_statuses
      @statuses = data["statuses"].each_with_index.to_h do |conf, index|
        status = Status.find_by(name: conf["name"]) || Status.find_by(name: conf["renames"]) || Status.new
        status.update!(name: conf["name"], position: index + 1, is_closed: conf["closed"] || false,
                       is_default: conf["default"] || false, color: color(conf["color"]),
                       default_done_ratio: conf["done_ratio"] || 0)
        [conf["key"], status]
      end
      Status.where.not(id: @statuses.values.map(&:id)).find_each do |status|
        next if WorkPackage.exists?(status_id: status.id)

        Workflow.where(old_status_id: status.id).or(Workflow.where(new_status_id: status.id)).delete_all
        status.destroy!
      end
      say "Statuses: #{@statuses.values.map(&:name).join(', ')}"
    end

    def seed_types
      @types = data["types"].each_with_index.to_h do |conf, index|
        type = Type.find_by(name: conf["name"]) || Type.find_by(name: conf["renames"]) || Type.new
        type.update!(name: conf["name"], position: index + 1, color: color(conf["color"]),
                     is_milestone: conf["milestone"] || false, is_in_roadmap: conf.fetch("roadmap", !conf["milestone"]))
        template = data.dig("templates", conf["key"])
        type.default_variant.update!(default_work_package_description: template) if template
        [conf["key"], type]
      end
      Type.where(name: data["obsolete_types"]).find_each do |type|
        type.destroy! unless WorkPackage.exists?(type_id: type.id)
      end
      say "Types: #{@types.values.map(&:name).join(', ')}"
    end

    def seed_priorities
      @priorities = data["priorities"].each_with_index.to_h do |conf, index|
        priority = IssuePriority.find_by(name: conf["name"]) || IssuePriority.find_by(name: conf["renames"]) ||
                   IssuePriority.new
        priority.update!(name: conf["name"], position: index + 1, is_default: conf["default"] || false, active: true)
        [conf["name"], priority]
      end
    end

    def seed_custom_fields
      @custom_fields = data["custom_fields"].to_h do |conf|
        field = WorkPackageCustomField.find_or_initialize_by(name: conf["name"])
        field.field_format = conf["format"] if field.new_record?
        field.assign_attributes(is_for_all: true, is_filter: true,
                                searchable: conf["format"] == "string", is_required: false)
        Array(conf["options"]).each_with_index do |value, index|
          option = field.custom_options.detect { |o| o.value == value } || field.custom_options.build(value:)
          option.position = index + 1
        end
        field.save!
        conf["types"].each do |type_key|
          variant = @types.fetch(type_key).default_variant
          variant.custom_fields << field unless variant.custom_fields.include?(field)
        end
        [conf["key"], field]
      end
      seed_form_layouts
    end

    def seed_form_layouts
      data["types"].each do |conf|
        variant = @types.fetch(conf["key"]).default_variant.reload
        fields = data["custom_fields"].select { |f| f["types"].include?(conf["key"]) }
                                      .map { |f| @custom_fields.fetch(f["key"]).attribute_name }
        sections = FORM_SECTIONS.except(*(conf["milestone"] ? [:estimates_and_progress] : [])).to_a
        sections.unshift([conf["form_section"], fields]) if fields.any?
        variant.attribute_groups = sections
        variant.save!
      end
    end

    def seed_roles
      @roles = data["roles"].to_h do |conf|
        role = ProjectRole.find_or_initialize_by(name: conf["name"])
        role.permissions = role_permissions(conf)
        role.save!
        [conf["name"], role]
      end
    end

    def role_permissions(conf)
      return ProjectRole.find_by!(name: conf["copy_from"]).permissions - conf["without"].map(&:to_sym) if conf["copy_from"]

      (conf["sets"].flat_map { |set| data["permission_sets"].fetch(set) } + conf["permissions"].to_a).uniq.map(&:to_sym)
    end

    def gated_role?(role)
      data["roles"].any? { |conf| conf["name"] == role.name && conf["gated"] }
    end

    def quality_gated?(role, type_key, new_status_key)
      gate = data["quality_gate"]
      gated_role?(role) && gate["types"].include?(type_key) && gate["statuses"].include?(new_status_key)
    end

    def workflow_roles
      @roles.values + ProjectRole.where(name: ["Member", "Project admin"]).to_a +
        WorkPackageRole.where(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_EDITOR).to_a
    end

    def seed_workflows
      data["types"].each do |conf|
        variant = @types.fetch(conf["key"]).default_variant
        statuses = conf["statuses"].map { |key| [key, @statuses.fetch(key)] }
        Workflow.where(type_variant: variant).delete_all
        rows = workflow_roles.flat_map do |role|
          statuses.product(statuses).reject { |(a, _), (b, _)| a == b }
                  .reject { |_, (new_key, _)| quality_gated?(role, conf["key"], new_key) }
                  .map do |(_, old_status), (_, new_status)|
            { type_variant_id: variant.id, role_id: role.id, old_status_id: old_status.id,
              new_status_id: new_status.id, assignee: false, author: false }
          end
        end
        Workflow.insert_all(rows) if rows.any?
      end
      say "Workflows rebuilt for #{workflow_roles.size} roles"
    end

    # --- people ----------------------------------------------------------

    def login_for(conf) = "#{conf['first']}.#{conf['last']}".downcase

    def seed_users
      @users = data["users"].to_h do |conf|
        user = User.find_or_initialize_by(login: login_for(conf))
        user.assign_attributes(firstname: conf["first"], lastname: conf["last"],
                               mail: "#{login_for(conf)}@#{MAIL_DOMAIN}", language: "en", admin: false)
        user.password = user.password_confirmation = DEFAULT_PASSWORD if user.new_record?
        user.force_password_change = false
        user.activate
        user.save!
        assign_designation(user, conf["title"])
        user.pref.update!(time_zone: data["time_zone"])
        user.notification_settings.create! if user.notification_settings.none?
        group = Group.find_or_create_by!(lastname: conf["group"])
        group.group_users.find_or_create_by!(user_id: user.id)
        [conf["key"], user]
      end
      say "Team: #{@users.values.map(&:name).join(', ')}"
    end

    def designation_field
      @designation_field ||= UserCustomField.find_or_create_by!(name: "Designation") do |field|
        field.field_format = "string"
        field.visible_on_user_card = true
        field.custom_field_section = UserCustomFieldSection.order(:position).first
      end
    end

    def assign_designation(user, title)
      return if title.blank?

      user.custom_field_values = { designation_field.id => title }
      user.save!
    end

    def user(key) = @users.fetch(key)

    def role_for(key) = @roles.fetch(data["users"].detect { |u| u["key"] == key }["role"])

    # --- projects --------------------------------------------------------

    def rebuild_projects
      destroy_projects(Project.where(identifier: data["projects"].pluck("key") + RETIRED_SAMPLE_IDENTIFIERS),
                       "Rebuilding")

      @projects = {}
      @leads = data["projects"].to_h { |conf| [conf["key"], conf["lead"]] }
      data["projects"].each { |conf| @projects[conf["key"]] = create_project(conf) }
      @projects.each_value(&:reload)
      data["projects"].each do |conf|
        project = @projects.fetch(conf["key"])
        create_work_packages(project, data.dig("work_packages", conf["key"]) || [])
      end
      create_relations
      close_released_versions
      complete_previous_sprints
      create_boards
      create_queries
      create_meetings
      create_wiki_pages
    end

    def create_project(conf)
      project = Project.create!(name: conf["name"], identifier: conf["key"], description: conf["description"],
                                workspace_type: "project",
                                public: false, parent: conf["parent"] && @projects.fetch(conf["parent"]),
                                status_code: conf.dig("status", "code"),
                                status_explanation: conf.dig("status", "explanation"),
                                enabled_module_names: data["modules"])
      @types.each_value { |type| project.project_types.create!(type_id: type.id, variant_id: type.default_variant.id) }
      conf["members"].each do |key|
        Member.create!(project:, principal: user(key), roles: [role_for(key)])
        Favorite.create!(user: user(key), favorited: project)
      end
      conf["categories"].each { |name| project.categories.create!(name:) }
      create_versions(project, conf["versions"] || [])
      create_sprints(project, conf["sprints"]) if conf["sprints"]
      say "Project #{project.identifier} #{project.name}"
      project
    end

    def create_versions(project, versions)
      @versions ||= {}
      versions.each do |conf|
        @versions[conf["name"]] = project.versions.create!(
          name: conf["name"], description: conf["description"], status: "open", sharing: "none",
          start_date: today + conf["start"], effective_date: today + conf["due"]
        )
      end
    end

    def create_sprints(project, conf)
      @sprints ||= {}
      number = conf.fetch("number")
      current_start = current_sprint_start
      sprints = {
        "previous" => { offset: -14, status: :completed, number: number - 1 },
        "current" => { offset: 0, status: :active, number: },
        "next" => { offset: 14, status: :in_planning, number: number + 1 }
      }
      @sprints[project.identifier] = sprints.to_h do |key, sprint_conf|
        start = current_start + sprint_conf[:offset]
        sprint = Sprint.create!(project:, name: "#{conf.fetch('prefix')} Sprint #{sprint_conf[:number]}",
                                status: sprint_conf[:status] == :active ? :active : :in_planning,
                                start_date: start, finish_date: start + 11,
                                started_at: (start.to_time if sprint_conf[:status] == :active))
        sprint.goals.create!(project:, text: conf.dig("goals", key))
        [key, sprint]
      end
    end

    def current_sprint_start = today.beginning_of_week - 7.days

    # --- work packages ---------------------------------------------------

    def create_work_packages(project, items)
      items.each do |conf|
        wp = create_work_package(project, conf)
        @refs[conf["ref"]] = wp
      end
    end

    def create_work_package(project, conf)
      type = @types.fetch(conf["type"])
      sprint = conf["sprint"] && @sprints.dig(project.identifier, conf["sprint"])
      attributes = {
        project:, type:, subject: conf["subject"],
        description: conf["description"] || type.default_variant.default_work_package_description,
        status: @statuses.fetch(conf["status"]),
        priority: @priorities.fetch(conf["priority"] || "Medium"),
        assigned_to: conf["assignee"] && user(conf["assignee"]),
        responsible: user(project_lead(project)),
        parent: conf["parent"] && @refs.fetch(conf["parent"]),
        target_versions: conf["version"] && [@versions.fetch(conf["version"])],
        category: conf["category"] && project.categories.find_by!(name: conf["category"]),
        sprint:,
        story_points: conf["points"],
        start_date: conf["start"] ? today + conf["start"] : sprint&.start_date,
        due_date: conf["due"] ? today + conf["due"] : sprint&.finish_date,
        schedule_manually: true,
        custom_field_values: custom_values(conf)
      }.compact

      result = WorkPackages::CreateService.new(user: user(conf["author"])).call(**attributes)
      raise "Could not create '#{conf['subject']}': #{result.errors.full_messages.join(', ')}" if result.failure?

      result.result
    end

    def project_lead(project) = @leads.fetch(project.identifier)

    def custom_values(conf)
      {
        "severity" => conf["severity"], "environment" => conf["environment"], "platform" => conf["platform"],
        "found_in" => conf["found_in"], "fixed_in" => conf["fixed_in"],
        "requested_by" => conf["requested_by"], "impact" => conf["impact"],
        "customer" => conf["customer"], "channel" => conf["channel"]
      }.compact.to_h do |key, value|
        field = @custom_fields.fetch(key)
        stored = field.list? ? field.custom_options.find_by!(value:).id.to_s : value
        [field.id.to_s, stored]
      end
    end

    def create_relations
      data["relations"].each do |conf|
        Relation.create!(from: @refs.fetch(conf["from"]), to: @refs.fetch(conf["to"]), relation_type: conf["type"])
      end
    end

    # Comments notify assignees, watchers and mentioned people, so every inbox starts with real activity.
    def create_comments
      Journal::NotificationConfiguration.with(true) do
        data["comments"].each do |ref, comments|
          work_package = @refs.fetch(ref)
          comments.each do |comment|
            result = AddWorkPackageNoteService.new(user: user(comment["by"]), work_package: work_package.reload)
                                              .call(with_mentions(comment["text"]), send_notifications: true)
            raise "Could not comment on #{work_package.subject}: #{result.errors.full_messages.join(', ')}" if result.failure?
          end
        end
      end
    end

    def with_mentions(text)
      text.gsub(/@([A-Z][a-z]+)/) do |match|
        mentioned = @users.values.detect { |u| u.firstname == Regexp.last_match(1) }
        next match unless mentioned

        %(<mention class="mention" data-id="#{mentioned.id}" data-type="user" data-text="@#{mentioned.name}">) +
          %(@#{mentioned.name}</mention>)
      end
    end

    def complete_previous_sprints
      @sprints.each_value do |sprints|
        sprint = sprints.fetch("previous")
        sprint.update_columns(status: "completed", started_at: sprint.start_date.to_time,
                              completed_at: sprint.finish_date.to_time)
      end
    end

    def close_released_versions
      data["projects"].flat_map { |p| p["versions"] || [] }.select { |v| v["status"] == "closed" }.each do |conf|
        @versions.fetch(conf["name"]).update!(status: "closed")
      end
    end

    # --- boards and views ------------------------------------------------

    def create_boards
      data["projects"].each do |conf|
        project = @projects.fetch(conf["key"])
        Array(conf["boards"]).each { |board| create_board(project, board) }
      end
      Setting.boards_demo_data_available = "true"
    end

    def create_board(project, conf)
      kind = conf.fetch("kind", "status")
      types = conf.fetch("types").map { |key| @types.fetch(key) }
      widgets = board_columns(conf, kind).each_with_index.map do |column, index|
        query = board_column_query(project, column)
        Grids::Widget.new(start_row: 1, end_row: 2, start_column: index + 1, end_column: index + 2,
                          identifier: "work_package_query",
                          options: { query_id: query.id,
                                     filters: [{ column[:key] => { operator: "=", values: [column[:id].to_s] } }] })
      end
      Boards::Grid.create!(project:, name: conf["name"], widgets:, column_count: widgets.size, row_count: 1,
                           options: { "type" => "action", "attribute" => kind, "highlightingMode" => "priority",
                                      "filters" => [{ type: { operator: "=", values: types.map { |t| t.id.to_s } } }] })
      say "Board #{conf['name']} in #{project.identifier}"
    end

    # One column per status, version or assignee.
    def board_columns(conf, kind)
      case kind
      when "status"
        conf["statuses"].map { |key| board_column("status_id", "status", @statuses.fetch(key)) }
      when "version"
        conf["versions"].map { |name| board_column("version_id", "version", @versions.fetch(name)) }
      when "assignee"
        conf["assignees"].map { |key| board_column("assigned_to_id", "assignee", user(key)) }
      end
    end

    def board_column(field, key, record) = { field:, key:, id: record.id, name: record.try(:name) || record.to_s }

    def board_column_query(project, column)
      Query.new_default(project:, user: admin).tap do |q|
        q.public = true
        q.name = column[:name]
        q.add_filter(column[:field], "=", [column[:id]])
        q.sort_criteria = [[:manual_sorting, "asc"]]
        q.save!
      end
    end

    def create_queries
      User.execute_as(User.user.where(admin: true).order(:id).first) { build_queries }
      say "Saved views: #{data['queries'].pluck('name').uniq.join(', ')}"
    end

    def build_queries
      data["queries"].each do |conf|
        query = Query.new(project: @projects.fetch(conf["project"]), user: admin, public: true, name: conf["name"],
                          include_subprojects: conf["subprojects"] || false, show_hierarchies: false)
        query.add_filter("status_id", "o", []) if conf["open"]
        query.add_filter("type_id", "=", conf["types"].map { |k| @types.fetch(k).id }) if conf["types"]
        query.add_filter("status_id", "=", conf["statuses"].map { |k| @statuses.fetch(k).id }) if conf["statuses"]
        query.add_filter("version_id", "=", [@versions.fetch(conf["version"]).id.to_s]) if conf["version"]
        query.add_filter("assigned_to_id", "=", ["me"]) if conf["mine"]
        (conf["cf"] || {}).each do |key, value|
          field = @custom_fields.fetch(key)
          query.add_filter(field.column_name, "=", [field.custom_options.find_by!(value:).id.to_s])
        end
        query.sort_criteria = conf["sort"]
        query.column_names = conf["columns"].map { |c| column_for(c) }
        query.save!
        View.create!(query:, type: "work_packages_table")
      end
    end

    def column_for(name)
      return name.to_sym unless name.start_with?("cf_")

      @custom_fields.fetch(name.delete_prefix("cf_")).column_name.to_sym
    end

    def create_wiki_pages
      data["wiki_pages"].each do |conf|
        project = @projects.fetch(conf["project"])
        start_page = data["wiki_pages"].find { |page| page["project"] == conf["project"] }["title"]
        wiki = project.wiki || Wiki.create!(project:, start_page:)
        parent = conf["parent"] && wiki.pages.find_by!(title: conf["parent"])
        wiki.pages.create!(title: conf["title"], text: conf["text"], author: user(conf["author"]), parent:)
      end
      say "Wiki: #{data['wiki_pages'].pluck('title').join(', ')}"
    end

    # --- meetings --------------------------------------------------------

    def local_time(conf)
      date = conf["sprint_day"] ? current_sprint_start + conf["sprint_day"] : today + conf["day"]
      Time.find_zone!(data["time_zone"]).parse("#{date} #{conf['time']}")
    end

    def create_meetings
      data["meetings"].each do |conf|
        meeting = conf["recurring"] ? create_meeting_series(conf) : create_meeting(conf)
        add_participants(meeting, conf)
        add_agenda(meeting, conf)
        conf["recurring"] ? finalize_series(meeting.recurring_meeting) : meeting.open!
        say "Meeting #{conf['title']}"
      end
    end

    def meeting_attributes(conf)
      { title: conf["title"], author: user(conf["author"]), project: @projects.fetch(conf["project"]),
        start_time: local_time(conf), duration: conf["duration"] / 60.0 }
    end

    def create_meeting_series(conf)
      attributes = meeting_attributes(conf)
      series = RecurringMeeting.create!(**attributes, current_schedule_start: attributes[:start_time],
                                                      frequency: conf["recurring"], interval: 1,
                                                      time_zone: data["time_zone"])
      create_meeting(conf, template: true, recurring_meeting: series)
    end

    def create_meeting(conf, **extra)
      result = Meetings::CreateService.new(user: user(conf["author"])).call(**meeting_attributes(conf), **extra)
      raise "Could not create meeting #{conf['title']}: #{result.errors.full_messages.join(', ')}" if result.failure?

      result.result
    end

    def add_participants(meeting, conf)
      conf["attendees"].each do |key|
        meeting.participants.find_or_initialize_by(user: user(key))
               .update!(invited: true, participation_status: :accepted)
      end
    end

    def add_agenda(meeting, conf)
      conf["agenda"].each do |item|
        work_package = item["wp"] && @refs.fetch(item["wp"])
        MeetingAgendaItem.create!(meeting:, author: user(conf["author"]), duration_in_minutes: item["duration"],
                                  item_type: work_package ? :work_package : :simple,
                                  title: item["title"], work_package:)
      end
    end

    def finalize_series(series)
      call = RecurringMeetings::TemplateCompletedService.new(user: series.author, recurring_meeting: series.reload)
                                                        .call(notify: false, first_occurrence: series.first_occurrence.to_time)
      raise "Could not finalize #{series.title}: #{call.message}" if call.failure?
    end

    def convert_to_semantic_identifiers
      ProjectIdentifiers::ConvertInstanceToSemanticIdsJob.perform_now
      sample = @refs.values.first.reload
      say "Issue keys enabled, e.g. #{sample.display_id} #{sample.subject}"
    end
  end
end
