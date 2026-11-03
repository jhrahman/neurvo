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

RSpec.describe OpenProject::Menu::MenuGroup do
  let(:hide) { true }
  let(:premium) { OpenProject::Menu::MenuItem.new(title: "Premium", href: "/a", selected: false, show_enterprise_icon: true) }
  let(:free) { OpenProject::Menu::MenuItem.new(title: "Free", href: "/b", selected: false) }

  before do
    allow(Setting).to receive(:hide_enterprise_features?).and_return(hide)
  end

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
