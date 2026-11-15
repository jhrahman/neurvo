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

require "spec_helper"

RSpec.describe Admin::TicketFieldsController do
  render_views

  let(:type) { create(:type) }

  context "as admin" do
    before { login_as(create(:admin)) }

    it "shows the matrix" do
      type
      get :show
      expect(response).to be_successful
    end

    it "applies the submitted fields" do
      patch :update, params: { fields: { type.id.to_s => %w[priority] } }
      expect(response).to redirect_to(admin_ticket_fields_path)
      expect(type.reload.default_variant.attribute_groups.flat_map(&:members)).to eq(%w[priority])
    end
  end

  it "denies non-admins" do
    login_as(create(:user))
    get :show
    expect(response).not_to be_successful
  end
end
