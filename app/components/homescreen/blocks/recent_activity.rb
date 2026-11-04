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
    class RecentActivity < Grids::WidgetComponent
      include Homescreen::ListLinks

      LIMIT = 8

      def title
        I18n.t("neurvo.home.recent.title")
      end

      def work_packages
        @work_packages ||= WorkPackage.visible(current_user)
                                      .eager_load(:type, :status, :project)
                                      .order(updated_at: :desc)
                                      .limit(LIMIT)
                                      .to_a
      end

      def view_all_path
        list_path([], sort: "updatedAt:desc")
      end

      def updated_label(work_package)
        journal = last_journals[work_package.id]
        return unless journal

        I18n.t("neurvo.home.recent.updated",
               user: journal.user&.name,
               time: helpers.time_ago_in_words(journal.created_at))
      end

      private

      def last_journals
        @last_journals ||= Journal.where(journable_type: "WorkPackage", journable_id: work_packages.map(&:id))
                                  .includes(:user)
                                  .order(:version)
                                  .group_by(&:journable_id)
                                  .transform_values(&:last)
      end
    end
  end
end
