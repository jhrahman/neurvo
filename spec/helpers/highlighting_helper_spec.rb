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

RSpec.describe HighlightingHelper do
  let(:user) { build_stubbed(:user) }

  before { login_as(user) }

  def tag_for(theme, increase_contrast: false)
    allow(user.pref).to receive_messages(theme:, increase_theme_contrast?: increase_contrast)
    helper.highlight_css_version_tag("2026-11-04T00:00:00Z")
  end

  it "differs between light and dark mode so cached stylesheets never mix" do
    expect(tag_for("light")).not_to eq tag_for("dark")
  end

  it "differs when contrast is increased" do
    expect(tag_for("dark")).not_to eq tag_for("dark", increase_contrast: true)
  end

  it "is stable for the same mode" do
    first = tag_for("dark")

    expect(tag_for("dark")).to eq first
  end
end
