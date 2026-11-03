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

RSpec.describe "my/_color_mode_menu" do
  let(:user) { build_stubbed(:user) }

  before do
    login_as(user)
    allow(user.pref).to receive(:theme).and_return(theme)
    render partial: "my/color_mode_menu"
  end

  context "when the light theme is active" do
    let(:theme) { "light" }

    it "posts the chosen theme to the settings endpoint and marks light as pressed" do
      expect(rendered).to have_selector("form[action='/my/settings']")
      expect(rendered).to have_button("Light", aria: { pressed: "true" })
      expect(rendered).to have_button("Dark", aria: { pressed: "false" })
    end
  end

  context "when the light theme is active with the warm palette" do
    let(:theme) { "light" }

    before do
      allow(user.pref).to receive(:light_palette).and_return("warm")
      render partial: "my/color_mode_menu"
    end

    it "offers the light palettes and marks the chosen one" do
      expect(rendered).to have_button("Warm (eye-friendly)", aria: { pressed: "true" })
      expect(rendered).to have_button("Paper", aria: { pressed: "false" })
      expect(rendered).to have_no_button("One Dark Pro")
    end
  end

  context "when the dark theme is active" do
    let(:theme) { "dark" }

    it "marks dark as pressed" do
      expect(rendered).to have_button("Dark", aria: { pressed: "true" })
      expect(rendered).to have_button("Light", aria: { pressed: "false" })
    end

    it "offers the dark palettes" do
      expect(rendered).to have_button("One Dark Pro")
      expect(rendered).to have_no_button("Warm (eye-friendly)")
    end
  end
end
