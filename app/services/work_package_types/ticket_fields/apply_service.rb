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

module WorkPackageTypes
  module TicketFields
    # Switches fields on or off for one type's base variant, reusing the form configuration rules.
    class ApplyService < ::BaseServices::BaseCallable
      include ::WorkPackageTypes::FormConfiguration::Concern

      def initialize(user:, type:)
        variant = type.default_variant
        super(user:, variant:)
      end

      # params[:enabled] is the full list of attribute keys that should be active.
      def perform
        wanted = Array(params[:enabled]).map(&:to_s) & variant.work_package_attributes.keys
        groups = active_groups.select { |group| group.group_type == :attribute }

        keep_only(groups, wanted)
        add_missing(groups, wanted)

        persist_groups(active_groups)
      end

      private

      def keep_only(groups, wanted)
        groups.each { |group| group.attributes = group.members.select { |key| wanted.include?(key) } }
      end

      def add_missing(groups, wanted)
        (wanted - groups.flat_map(&:members)).each { |key| group_for(groups, key).attributes += [key] }
      end

      def group_for(groups, key)
        wanted_key = variant.send(:default_group_key, key)
        groups.find { |group| group.key.to_sym == wanted_key } ||
          groups.find { |group| group.key.to_s == "other" } ||
          groups.first || build_group(groups, wanted_key)
      end

      def build_group(groups, key)
        ::Type::AttributeGroup.new(variant, key, []).tap { |group| groups << group }
      end
    end
  end
end
