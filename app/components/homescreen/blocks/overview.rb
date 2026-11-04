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
      include Homescreen::ListLinks

      Tile = Data.define(:key, :label, :count, :href, :icon, :tone)

      OPEN_STATUS = { n: "status", o: "o", v: [] }.freeze
      QA_STATUS_NAMES = ["Ready for QA", "In QA"].freeze

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
        @tiles ||= [assigned_tile, overdue_tile, qa_tile, bugs_tile].compact
      end

      private

      def tile_count(key)
        tiles.find { it.key == key }&.count.to_i
      end

      def open_work_packages
        WorkPackage.visible(current_user).with_status_open
      end

      def mine
        open_work_packages.where(assigned_to_id: current_user.id)
      end

      def assigned_tile
        build_tile(:assigned, mine, [assignee_filter, OPEN_STATUS], :person, :neutral)
      end

      def overdue_tile
        scope = mine.where(work_packages: { due_date: ...Time.zone.today })
        build_tile(:overdue, scope, [assignee_filter, OPEN_STATUS, { n: "dueDate", o: "<t-", v: ["1"] }], :clock, :danger)
      end

      def qa_tile
        statuses = Status.where(name: QA_STATUS_NAMES)
        return if statuses.empty?

        scope = open_work_packages.where(status_id: statuses.ids)
        build_tile(:ready_for_qa, scope, [{ n: "status", o: "=", v: statuses.ids.map(&:to_s) }], :checklist, :attention,
                   label_key: "ready_for_qa")
      end

      def bugs_tile
        bug = Type.find_by(name: "Bug")
        return unless bug

        scope = open_work_packages.where(type_id: bug.id)
        build_tile(:open_bugs, scope, [OPEN_STATUS, { n: "type", o: "=", v: [bug.id.to_s] }], :bug, :danger)
      end

      def build_tile(key, scope, filters, icon, tone, label_key: key.to_s)
        count = scope.count
        Tile.new(key:, label: I18n.t("neurvo.home.tiles.#{label_key}"), count:, href: list_path(filters), icon:,
                 tone: count.zero? || tone == :neutral ? :neutral : tone)
      end

      def assignee_filter
        { n: "assignee", o: "=", v: ["me"] }
      end
    end
  end
end
