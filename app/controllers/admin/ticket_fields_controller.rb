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

module Admin
  class TicketFieldsController < ApplicationController
    layout "admin"

    before_action :require_admin

    current_menu_item do
      :ticket_fields
    end

    def show
      @types = Type.includes(:variants).order(:position).to_a
      @type = @types.find { |type| type.id == params[:type_id].to_i } || @types.first
      @attributes = TypeVariant.translated_work_package_form_attributes(merge_date: true)
      @active = active_keys(@type)
      @counts = active_counts
    end

    def update
      type = Type.find(params.expect(:type_id))
      result = WorkPackageTypes::TicketFields::ApplyService.new(user: current_user, type:).call(enabled: requested_keys)

      redirect_to admin_ticket_fields_path(type_id: type.id), **update_feedback(result)
    end

    private

    def active_counts
      @types.to_h { |type| [type.id, (active_keys(type) & @attributes.keys).size] }
    end

    def update_feedback(result)
      if result.success?
        { notice: t(:notice_successful_update) }
      else
        { flash: { error: result.errors.full_messages.to_sentence } }
      end
    end

    def requested_keys
      if params[:copy_from].present?
        active_keys(Type.find(params.expect(:copy_from)))
      else
        Array(params[:fields])
      end
    end

    def active_keys(type)
      type.default_variant.attribute_groups
          .select { |group| group.group_type == :attribute }
          .flat_map(&:members)
    end
  end
end
