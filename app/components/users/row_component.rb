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

module Users
  class RowComponent < ::RowComponent
    property :firstname, :lastname

    def user
      model
    end

    def row_css_class
      status = user.status
      blocked = "blocked" if user.failed_too_many_recent_login_attempts?

      ["user", status, blocked].compact.join(" ")
    end

    def login
      icon = helpers.avatar user, size: :mini

      link = helpers.link_to_user(user,
                                  class: "op-principal--name",
                                  name: user.login,
                                  href: helpers.allowed_management_user_profile_path(user))

      icon + link + settings_link
    end

    def settings_link
      return "".html_safe unless current_user_allowed_to_manage_users?

      helpers.link_to(
        helpers.edit_user_path(user),
        class: "op-user-settings-link",
        title: I18n.t(:label_edit_user),
        aria: { label: "#{I18n.t(:label_edit_user)}: #{user.login}" }
      ) { render(Primer::Beta::Octicon.new(icon: :gear, color: :muted, ml: 2)) }
    end

    def mail
      mail_to user.mail
    end

    def admin
      helpers.checked_image user.admin?
    end

    def last_login_on
      helpers.format_time user.last_login_on unless user.last_login_on.nil?
    end

    def created_at
      helpers.format_time user.created_at
    end

    def consented_at
      helpers.format_time user.consented_at unless user.consented_at.nil?
    end

    def status
      helpers.full_user_status user
    end

    def department
      return if user.department.nil?

      safe_join(
        [
          render(Primer::Beta::Octicon.new(icon: :briefcase, color: :muted, mr: 1)),
          user.department.name
        ]
      )
    end

    def member_of_group
      joined_names user.regular_groups
    end

    def member_of_project
      joined_names user.projects
    end

    def button_links
      return [] unless current_user_allowed_to_manage_users?

      [actions_menu]
    end

    def actions_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(
          icon: "kebab-horizontal",
          scheme: :invisible,
          "aria-label": I18n.t(:label_actions),
          test_selector: "user-actions-#{user.id}"
        )
        menu.with_item(label: I18n.t(:label_edit_user), tag: :a, href: helpers.edit_user_path(user)) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
        add_password_reset_item(menu)
        add_status_items(menu)
      end
    end

    def add_password_reset_item(menu)
      return unless user.active? && user.change_password_allowed?
      return if user_is_admin_and_current_user_is_no_admin?

      menu.with_item(label: I18n.t(:label_send_password_reset),
                     tag: :a,
                     href: helpers.send_password_reset_user_path(user),
                     content_arguments: { data: { turbo_method: :post } }) do |item|
        item.with_leading_visual_icon(icon: :key)
      end
    end

    def add_status_items(menu)
      return if user_is_current_user? || user_is_admin_and_current_user_is_no_admin?

      helpers.iterate_user_statusses(user) do |title, name|
        menu.with_item(**status_item_options(title, name)) do |item|
          item.with_leading_visual_icon(icon: helpers.change_user_status_icons[name])
        end
      end
    end

    def status_item_options(title, name)
      {
        label: title,
        tag: :a,
        href: helpers.change_status_user_path(user, name.to_sym => "1", back_url: helpers.request.fullpath),
        content_arguments: { data: { turbo_method: :post } }
      }
    end

    def status_link
      return if user_is_current_user?
      return unless current_user_allowed_to_manage_users?
      return if user_is_admin_and_current_user_is_no_admin?

      helpers.change_user_status_links user
    end

    def user_is_current_user?
      user.id == table.current_user.id
    end

    def current_user_allowed_to_manage_users?
      table.current_user.allowed_globally?(:manage_user)
    end

    def user_is_admin_and_current_user_is_no_admin?
      user.admin? && !table.current_user.admin?
    end

    def column_value(column)
      return custom_field_column(column) if custom_field_column?(column)

      attribute = column_attribute(column)

      respond_to?(attribute) ? send(attribute) : user.public_send(attribute)
    end

    def column_css_class(column)
      attribute = column_attribute(column)
      case attribute
      when :mail then "email"
      when :login then "username"
      else attribute.to_s
      end
    end

    private

    def column_attribute(column)
      column.respond_to?(:attribute) ? column.attribute : column
    end

    def joined_names(records)
      records.map(&:name).sort.join(", ")
    end

    def custom_field_column_subject
      user
    end
  end
end
