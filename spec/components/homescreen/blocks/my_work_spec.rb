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

require "rails_helper"

RSpec.describe Homescreen::Blocks::MyWork, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:other_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:low) { create(:priority, name: "Low", position: 1) }
  shared_let(:high) { create(:priority, name: "High", position: 3) }

  def render_widget
    render_inline(described_class.new(current_user: user))
  end

  it "lists open work assigned to the user, most important first" do
    create(:work_package, project:, assigned_to: user, subject: "Minor chore", priority: low)
    create(:work_package, project:, assigned_to: user, subject: "Urgent fix", priority: high)

    render_widget

    expect(page.all("[data-test-selector='neurvo-wp-row']").map(&:text)).to match [
      a_string_including("Urgent fix"), a_string_including("Minor chore")
    ]
  end

  it "leaves out closed work and work assigned to others" do
    create(:work_package, project:, assigned_to: user, subject: "Finished", status: closed_status)
    create(:work_package, project:, assigned_to: other_user, subject: "Someone else's")

    render_widget

    expect(page).to have_no_text("Finished")
    expect(page).to have_no_text("Someone else's")
    expect(page).to have_test_selector("my-work-widget-empty")
  end

  it "marks work past its due date" do
    create(:work_package, project:, assigned_to: user, due_date: 2.days.ago.to_date)

    render_widget

    expect(page).to have_css(".neurvo-overdue")
  end
end
