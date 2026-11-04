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

RSpec.describe Homescreen::Blocks::Overview, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, firstname: "Nusrat", member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:closed_status) { create(:closed_status) }

  def render_widget
    render_inline(described_class.new(current_user: user))
  end

  def tile_count(key)
    page.find("[data-test-selector='neurvo-home-tile-#{key}'] .neurvo-home-tile--count").text.to_i
  end

  it "greets the user and names the organization" do
    render_widget

    expect(page).to have_text(/Good (morning|afternoon|evening), Nusrat/)
    expect(page).to have_text(Setting.organization_name)
  end

  it "counts open and overdue work assigned to the user" do
    create(:work_package, project:, assigned_to: user, due_date: 3.days.ago.to_date)
    create(:work_package, project:, assigned_to: user, due_date: 3.days.from_now.to_date)
    create(:work_package, project:, assigned_to: user, status: closed_status, due_date: 3.days.ago.to_date)

    render_widget

    expect(tile_count("assigned")).to eq 2
    expect(tile_count("overdue")).to eq 1
    expect(page).to have_text("1 of your items is overdue.")
  end

  it "offers the QA and bug tiles only when those statuses and types exist" do
    render_widget

    expect(page).to have_no_test_selector("neurvo-home-tile-ready_for_qa")
    expect(page).to have_no_test_selector("neurvo-home-tile-open_bugs")

    create(:status, name: "Ready for QA")
    create(:type, name: "Bug")
    render_widget

    expect(page).to have_test_selector("neurvo-home-tile-ready_for_qa")
    expect(page).to have_test_selector("neurvo-home-tile-open_bugs")
  end

  it "links each tile to the matching work package list" do
    render_widget

    expect(page.find("[data-test-selector='neurvo-home-tile-assigned']")[:href]).to start_with("/work_packages?query_props=")
  end
end
