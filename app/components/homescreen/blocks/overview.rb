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
  module Blocks
    class Overview < Grids::WidgetComponent
      def title
        I18n.t("neurvo.home.title")
      end

      def organization
        Setting.organization_name
      end

      def date
        I18n.l(Time.zone.today, format: "%A, %-d %B")
      end

      def greeting
        part = case Time.zone.now.hour
               when 5..11 then "morning"
               when 12..17 then "afternoon"
               else "evening"
               end

        I18n.t("neurvo.home.greeting.#{part}", name: current_user.firstname)
      end

      def summary
        overdue = tile_count(:overdue)
        assigned = tile_count(:assigned)

        if overdue.positive?
          I18n.t("neurvo.home.summary.overdue", count: overdue)
        elsif assigned.positive?
          I18n.t("neurvo.home.summary.open", count: assigned)
        else
          I18n.t("neurvo.home.summary.none")
        end
      end

      def tiles
        @tiles ||= catalog.tiles
      end

      private

      def catalog
        @catalog ||= Homescreen::CardCatalog.new(current_user)
      end

      def tile_count(key)
        key == :overdue ? overdue_count : assigned_count
      end

      def assigned_count
        @assigned_count ||= mine.count
      end

      def overdue_count
        @overdue_count ||= mine.where(work_packages: { due_date: ...Time.zone.today }).count
      end

      def open_work_packages
        WorkPackage.visible(current_user).with_status_open
      end

      def mine
        open_work_packages.where(assigned_to_id: current_user.id)
      end
    end
  end
end
