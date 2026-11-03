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

require "spec_helper"

RSpec.describe "Hiding Enterprise-only menu entries" do
  let(:hide) { true }
  let(:allowed) { false }

  before do
    allow(Setting).to receive(:hide_enterprise_features?).and_return(hide)
    allow(EnterpriseToken).to receive(:allows_to?).and_return(allowed)
  end

  describe Redmine::MenuManager::MenuItem do
    def build_item(feature)
      described_class.new(:feature, { controller: "/homescreen", action: "index" }, enterprise_feature: feature)
    end

    it "hides an item whose Enterprise feature is missing" do
      expect(build_item("team_planner_view")).to be_enterprise_feature_hidden
    end

    it "keeps the item when hiding is switched off" do
      allow(Setting).to receive(:hide_enterprise_features?).and_return(false)

      expect(build_item("team_planner_view")).not_to be_enterprise_feature_hidden
      expect(build_item("team_planner_view")).to be_enterprise_feature_missing
    end

    context "when the feature is available" do
      let(:allowed) { true }

      it "keeps the item" do
        expect(build_item("team_planner_view")).not_to be_enterprise_feature_hidden
      end
    end

    it "keeps items without an Enterprise feature" do
      expect(build_item(nil)).not_to be_enterprise_feature_hidden
    end

    it "keeps the Design entry reachable without an upsell marker" do
      item = build_item("define_custom_style")

      expect(item).not_to be_enterprise_feature_hidden
      expect(item).not_to be_enterprise_feature_missing
    end
  end

  describe OpenProject::Menu::MenuGroup do
    let(:premium) { OpenProject::Menu::MenuItem.new(title: "Premium", href: "/a", selected: false, show_enterprise_icon: true) }
    let(:free) { OpenProject::Menu::MenuItem.new(title: "Free", href: "/b", selected: false) }

    it "drops submenu items flagged with the Enterprise icon" do
      group = described_class.new(header: "Group", children: [free, premium])

      expect(group.children).to eq [free]
    end

    context "when hiding is switched off" do
      let(:hide) { false }

      it "keeps every item" do
        group = described_class.new(header: "Group", children: [free, premium])

        expect(group.children).to eq [free, premium]
      end
    end
  end
end
