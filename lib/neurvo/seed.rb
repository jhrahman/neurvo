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
    DEFAULT_PASSWORD = "Neurvo-Dev-2026!"
    MAIL_DOMAIN = "shopease.example"
    UPSTREAM_DEMO_IDENTIFIERS = %w[demo-project your-scrum-project dev-empty dev-work-package-sharing
                                   dev-large dev-large-child dev-custom-fields].freeze
    KEPT_LOGINS = %w[admin qa].freeze

    attr_reader :data, :log, :today

    def initialize(log: $stdout, remove_upstream_demo: true)
      @data = YAML.safe_load_file(DATA_PATH, aliases: false)
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
      end
      say "Done. Log in as any team member with password #{DEFAULT_PASSWORD}"
    end

    private

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
                     is_milestone: conf["milestone"] || false, is_in_roadmap: !conf["milestone"])
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
      @types.each_value { |type| type.default_variant.reload.save! }
    end

    def seed_roles
      @roles = data["roles"].to_h do |conf|
        source = ProjectRole.find_by!(name: conf["copy_from"])
        role = ProjectRole.find_or_initialize_by(name: conf["name"])
        role.permissions = source.permissions
        role.save!
        [conf["name"], role]
      end
    end

    def workflow_roles
      @roles.values + ProjectRole.where(name: ["Member", "Project admin"]).to_a +
        WorkPackageRole.where(builtin: WorkPackageRole::BUILTIN_WORK_PACKAGE_EDITOR).to_a
    end

    def seed_workflows
      data["types"].each do |conf|
        variant = @types.fetch(conf["key"]).default_variant
        statuses = conf["statuses"].map { |key| @statuses.fetch(key) }
        Workflow.where(type_variant: variant).delete_all
        rows = workflow_roles.flat_map do |role|
          statuses.product(statuses).reject { |a, b| a == b }.map do |old_status, new_status|
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
        group = Group.find_or_create_by!(lastname: conf["group"])
        group.group_users.find_or_create_by!(user_id: user.id)
        [conf["key"], user]
      end
      say "Team: #{@users.values.map(&:name).join(', ')}"
    end

    def user(key) = @users.fetch(key)

    def role_for(key) = @roles.fetch(data["users"].detect { |u| u["key"] == key }["role"])

    # --- projects --------------------------------------------------------

    def rebuild_projects
      destroy_projects(Project.where(identifier: data["projects"].pluck("key")), "Rebuilding")

      @projects = {}
      data["projects"].each { |conf| @projects[conf["key"]] = create_project(conf) }
      @projects.each_value(&:reload)
      data["projects"].each do |conf|
        project = @projects.fetch(conf["key"])
        create_work_packages(project, data.dig("work_packages", conf["key"]) || [])
      end
      create_relations
      create_comments
      close_released_versions
      complete_previous_sprints
      create_boards
      create_queries
    end

    def create_project(conf)
      project = Project.create!(name: conf["name"], identifier: conf["key"], description: conf["description"],
                                workspace_type: "project",
                                public: false, parent: conf["parent"] && @projects.fetch(conf["parent"]),
                                enabled_module_names: data["modules"])
      @types.each_value { |type| project.project_types.create!(type_id: type.id, variant_id: type.default_variant.id) }
      conf["members"].each do |key|
        Member.create!(project:, principal: user(key), roles: [role_for(key)])
      end
      conf["categories"].each { |name| project.categories.create!(name:) }
      create_versions(project, conf["versions"] || [])
      create_sprints(project) if conf["sprints"]
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

    def create_sprints(project)
      @sprints ||= {}
      number = { "MOB" => 11, "OPS" => 31, "NEU" => 1 }.fetch(project.identifier, 24)
      current_start = today - 7
      sprints = {
        "previous" => { offset: -14, status: :completed, number: number - 1 },
        "current" => { offset: 0, status: :active, number: },
        "next" => { offset: 14, status: :in_planning, number: number + 1 }
      }
      @sprints[project.identifier] = sprints.to_h do |key, conf|
        start = current_start + conf[:offset]
        sprint = Sprint.create!(project:, name: "#{project.identifier} Sprint #{conf[:number]}",
                                status: conf[:status] == :active ? :active : :in_planning,
                                start_date: start, finish_date: start + 11,
                                started_at: (start.to_time if conf[:status] == :active))
        sprint.goals.create!(project:, text: data.dig("sprint_goals", key))
        [key, sprint]
      end
    end

    # --- work packages ---------------------------------------------------

    def create_work_packages(project, items)
      items.each do |conf|
        wp = create_work_package(project, conf)
        @refs[conf["ref"]] = wp
      end
    end

    def create_work_package(project, conf)
      type = @types.fetch(conf["type"])
      attributes = {
        project:, type:, subject: conf["subject"],
        description: conf["description"] || type.default_variant.default_work_package_description,
        status: @statuses.fetch(conf["status"]),
        priority: @priorities.fetch(conf["priority"] || "Medium"),
        assigned_to: conf["assignee"] && user(conf["assignee"]),
        responsible: user(project_lead(project)),
        parent: conf["parent"] && @refs.fetch(conf["parent"]),
        version: conf["version"] && @versions.fetch(conf["version"]),
        category: conf["category"] && project.categories.find_by!(name: conf["category"]),
        sprint: conf["sprint"] && @sprints.dig(project.identifier, conf["sprint"]),
        story_points: conf["points"],
        start_date: conf["start"] && (today + conf["start"]),
        due_date: conf["due"] && (today + conf["due"]),
        schedule_manually: true,
        custom_field_values: custom_values(conf)
      }.compact

      result = WorkPackages::CreateService.new(user: user(conf["author"])).call(**attributes)
      raise "Could not create '#{conf['subject']}': #{result.errors.full_messages.join(', ')}" if result.failure?

      result.result
    end

    def project_lead(project) = project.identifier == "OPS" ? "daniel" : "ayesha"

    def custom_values(conf)
      {
        "severity" => conf["severity"], "environment" => conf["environment"], "platform" => conf["platform"],
        "found_in" => conf["found_in"], "fixed_in" => conf["fixed_in"],
        "requested_by" => conf["requested_by"], "impact" => conf["impact"]
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

    def create_comments
      data["comments"].each do |ref, comments|
        work_package = @refs.fetch(ref)
        comments.each do |comment|
          result = AddWorkPackageNoteService.new(user: user(comment["by"]), work_package: work_package.reload)
                                            .call(comment["text"], send_notifications: false)
          raise "Could not comment on #{work_package.subject}: #{result.errors.full_messages.join(', ')}" if result.failure?
        end
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
      board = data["sqa_board"]
      create_status_board(@projects.fetch(board["project"]), board["name"], board["statuses"],
                          types: [@types.fetch("bug")], subprojects: true)
      data["projects"].each do |conf|
        Array(conf["boards"]).each do |board_conf|
          create_status_board(@projects.fetch(conf["key"]), board_conf["name"], board_conf["statuses"],
                              types: @types.values_at("story", "task", "subtask", "bug", "feature_request",
                                                      "change_request"))
        end
      end
      Setting.boards_demo_data_available = "true"
    end

    def create_status_board(project, name, status_keys, types:, subprojects: false)
      widgets = status_keys.each_with_index.map do |key, index|
        status = @statuses.fetch(key)
        query = Query.new_default(project:, user: admin).tap do |q|
          q.public = true
          q.name = status.name
          q.include_subprojects = subprojects
          q.add_filter("status_id", "=", [status.id])
          q.sort_criteria = [[:manual_sorting, "asc"]]
          q.save!
        end
        Grids::Widget.new(start_row: 1, end_row: 2, start_column: index + 1, end_column: index + 2,
                          identifier: "work_package_query",
                          options: { query_id: query.id, filters: [{ status: { operator: "=", values: [status.id.to_s] } }] })
      end
      Boards::Grid.create!(project:, name:, widgets:, column_count: widgets.size, row_count: 1,
                           options: { "type" => "action", "attribute" => "status", "highlightingMode" => "priority",
                                      "filters" => [{ type: { operator: "=", values: types.map { |t| t.id.to_s } } }] })
      say "Board #{name} in #{project.identifier}"
    end

    def create_queries
      data["queries"].each do |conf|
        query = Query.new(project: @projects.fetch(conf["project"]), user: admin, public: true, name: conf["name"],
                          include_subprojects: conf["subprojects"] || false, show_hierarchies: false)
        query.add_filter("status_id", "o", []) if conf["open"]
        query.add_filter("type_id", "=", conf["types"].map { |k| @types.fetch(k).id }) if conf["types"]
        query.add_filter("status_id", "=", conf["statuses"].map { |k| @statuses.fetch(k).id }) if conf["statuses"]
        (conf["cf"] || {}).each do |key, value|
          field = @custom_fields.fetch(key)
          query.add_filter(field.column_name, "=", [field.custom_options.find_by!(value:).id.to_s])
        end
        query.sort_criteria = conf["sort"]
        query.column_names = conf["columns"].map { |c| column_for(c) }
        query.save!
      end
      say "Saved views: #{data['queries'].pluck('name').join(', ')}"
    end

    def column_for(name)
      return name.to_sym unless name.start_with?("cf_")

      @custom_fields.fetch(name.delete_prefix("cf_")).column_name.to_sym
    end

    def convert_to_semantic_identifiers
      ProjectIdentifiers::ConvertInstanceToSemanticIdsJob.perform_now
      sample = @refs.fetch("bug_expiry_500").reload
      say "Issue keys enabled, e.g. #{sample.display_id} #{sample.subject}"
    end
  end
end
