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

RSpec.describe Homescreen::CardCatalog do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  def user_with_role(name, in_projects: [project])
    role = ProjectRole.find_by(name:) || create(:project_role, name:, permissions: %i[view_work_packages])
    create(:user, member_with_roles: in_projects.index_with { role })
  end

  def keys_for(user)
    described_class.new(user).tiles.map(&:key)
  end

  describe "#default_keys" do
    it "gives people without a recognised role the general cards" do
      expect(described_class.new(create(:user)).default_keys).to eq %i[assigned overdue due_this_week watching]
    end

    it "gives a QA engineer the QA cards" do
      expect(described_class.new(user_with_role("QA Engineer")).default_keys)
        .to eq %i[assigned overdue ready_for_qa in_qa open_bugs reopened_bugs]
    end

    it "gives a DevOps engineer the infrastructure cards" do
      expect(described_class.new(user_with_role("DevOps Engineer")).default_keys)
        .to include(:infra_work, :change_requests)
    end

    it "gives a designer the design cards" do
      expect(described_class.new(user_with_role("Designer")).default_keys).to include(:ui_work, :ui_in_review)
    end

    it "gives administrators the project management cards" do
      expect(described_class.new(create(:admin)).default_keys).to include(:team_overdue, :active_sprints)
    end

    it "never offers more than the card limit, even for people with several roles" do
      user = create(:user, member_with_roles: {
                      project => [ProjectRole.find_by(name: "QA Engineer") || create(:project_role, name: "QA Engineer"),
                                  ProjectRole.find_by(name: "Developer") || create(:project_role, name: "Developer")]
                    })

      expect(described_class.new(user).default_keys.size).to be <= described_class::MAX_CARDS
    end
  end

  describe "#selected_keys" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "prefers the cards the user saved" do
      user.pref.home_cards = %w[unassigned assigned]
      user.pref.save!

      expect(described_class.new(user).selected_keys).to eq %i[assigned unassigned]
    end

    it "ignores unknown cards and keeps at most the card limit" do
      user.pref.home_cards = %w[nope] + described_class.keys.first(8).map(&:to_s)

      expect(user.pref.home_cards.size).to eq described_class::MAX_CARDS
      expect(user.pref.home_cards).not_to include(:nope)
    end

    it "falls back to the role defaults when the saved list is cleared" do
      user.pref.home_cards = %w[unassigned]
      user.pref.home_cards = []

      expect(described_class.new(user).selected_keys).to eq described_class.new(user).default_keys
    end
  end

  describe "counting" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages], other_project => %i[view_work_packages] }) }

    before { User.current = user }

    it "counts infrastructure work across every project the user can see" do
      create(:work_package, project:, category: create(:category, project:, name: "Kubernetes"))
      create(:work_package, project: other_project, category: create(:category, project: other_project, name: "Database"))
      create(:work_package, project:, category: create(:category, project:, name: "Unrelated"))

      expect(described_class.new(user).count_for(:infra_work)).to eq 2
    end

    it "omits a card whose status does not exist" do
      user.pref.home_cards = %w[ready_for_qa assigned]

      expect(keys_for(user)).to eq %i[assigned]
    end
  end
end
