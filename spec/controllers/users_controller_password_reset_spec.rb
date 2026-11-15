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

RSpec.describe UsersController, "#send_password_reset" do
  render_views

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  before { login_as(admin) }

  it "creates a recovery token and mails the user" do
    expect { post :send_password_reset, params: { id: user.id } }
      .to change { Token::Recovery.where(user_id: user.id).count }.by(1)

    expect(flash[:notice]).to include(user.mail)
    expect(response).to have_http_status(:see_other)
  end

  it "refuses locked users" do
    user.lock!

    expect { post :send_password_reset, params: { id: user.id } }
      .not_to(change(Token::Recovery, :count))
    expect(flash[:error]).to be_present
  end

  it "is denied for users without the manage permission" do
    login_as(create(:user))
    post :send_password_reset, params: { id: user.id }

    expect(response).not_to be_successful
    expect(Token::Recovery.where(user_id: user.id)).to be_empty
  end

  it "shows the actions menu and an open search on the list" do
    user
    get :index

    expect(response.body).to include("user-actions-#{user.id}")
    expect(response.body).to include(I18n.t(:label_send_password_reset))
  end
end
