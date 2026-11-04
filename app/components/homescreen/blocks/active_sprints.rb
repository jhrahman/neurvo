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
    class ActiveSprints < Grids::WidgetComponent
      Progress = Data.define(:done, :total, :points) do
        def percent = total.zero? ? 0 : (done * 100.0 / total).round
      end

      LIMIT = 6

      def title
        I18n.t("neurvo.home.sprints.title")
      end

      def sprints
        @sprints ||= Sprint.active
                           .where(project_id: Project.allowed_to(current_user, :view_sprints).select(:id))
                           .includes(:project, :goals)
                           .order(:finish_date)
                           .limit(LIMIT)
                           .to_a
      end

      def progress_for(sprint)
        progress[sprint.id] || Progress.new(0, 0, 0)
      end

      def goal_for(sprint)
        sprint.goal_text_for(sprint.project).presence || I18n.t("neurvo.home.sprints.no_goal")
      end

      def dates_for(sprint)
        "#{helpers.format_date(sprint.start_date)} – #{helpers.format_date(sprint.finish_date)}"
      end

      def days_left(sprint)
        I18n.t("neurvo.home.sprints.days_left", count: [(sprint.finish_date - Time.zone.today).to_i, 0].max)
      end

      def backlog_path(sprint)
        helpers.project_backlogs_backlog_path(sprint.project)
      end

      private

      def progress
        @progress ||= totals_by_sprint.transform_values do |rows|
          Progress.new(rows.sum { |closed, count, _| closed ? count : 0 },
                       rows.sum { |_, count, _| count },
                       rows.sum { |_, _, points| points })
        end
      end

      def totals_by_sprint
        WorkPackage.where(sprint_id: sprints.map(&:id))
                   .joins(:status)
                   .group(:sprint_id, "statuses.is_closed")
                   .pluck(:sprint_id, "statuses.is_closed", Arel.sql("COUNT(*)"),
                          Arel.sql("COALESCE(SUM(work_packages.story_points), 0)"))
                   .group_by(&:first)
                   .transform_values { |rows| rows.map { |_, closed, count, points| [closed, count, points] } }
      end
    end
  end
end
