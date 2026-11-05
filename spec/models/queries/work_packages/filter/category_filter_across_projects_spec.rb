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

RSpec.describe Queries::WorkPackages::Filter::CategoryFilter, "without a project" do
  shared_let(:project) { create(:project) }
  shared_let(:hidden_project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:visible_category) { create(:category, project:, name: "Kubernetes") }
  shared_let(:hidden_category) { create(:category, project: hidden_project, name: "Secret") }

  let(:query) { build_stubbed(:query, project: nil) }
  let(:instance) { described_class.create!(name: :category_id, context: query, operator: "=", values: [visible_category.id.to_s]) }

  before { login_as(user) }

  it "is available when a visible project has categories" do
    expect(instance).to be_available
  end

  it "offers only categories of projects the user can see" do
    expect(instance.allowed_values).to contain_exactly(["Kubernetes", visible_category.id.to_s])
  end

  it "validates without raising on a cross-project list" do
    expect { instance.validate }.not_to raise_error
    expect(instance).to be_valid
  end
end
