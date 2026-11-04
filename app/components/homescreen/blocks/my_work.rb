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
    class MyWork < Grids::WidgetComponent
      include Homescreen::ListLinks

      LIMIT = 8
      ORDER = Arel.sql("enumerations.position DESC, work_packages.due_date ASC NULLS LAST, work_packages.updated_at DESC")

      def title
        I18n.t("neurvo.home.my_work.title")
      end

      def work_packages
        @work_packages ||= WorkPackage.visible(current_user)
                                      .with_status_open
                                      .where(assigned_to_id: current_user.id)
                                      .eager_load(:type, :project, :priority)
                                      .order(ORDER)
                                      .limit(LIMIT)
                                      .to_a
      end

      def view_all_path
        list_path([{ n: "assignee", o: "=", v: ["me"] }, { n: "status", o: "o", v: [] }])
      end

      def due_label(work_package)
        return unless work_package.due_date

        key = overdue?(work_package) ? "overdue" : "due"
        I18n.t("neurvo.home.my_work.#{key}", date: helpers.format_date(work_package.due_date))
      end

      def overdue?(work_package)
        work_package.due_date.present? && work_package.due_date < Time.zone.today
      end
    end
  end
end
