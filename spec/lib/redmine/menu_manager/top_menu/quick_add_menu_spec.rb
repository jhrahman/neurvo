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

RSpec.describe Redmine::MenuManager::TopMenu::QuickAddMenu do
  let(:menu_class) do
    Class.new do
      include Redmine::MenuManager::TopMenu::QuickAddMenu

      def initialize(project) = @project = project
      def defaults = send(:default_project_by_type)
    end
  end

  shared_let(:bug) { create(:type_bug) }
  shared_let(:task) { create(:type_task) }
  shared_let(:alpha) { create(:project, name: "Alpha", types: [bug, task]) }
  shared_let(:beta) { create(:project, name: "Beta", types: [bug]) }
  shared_let(:hidden) { create(:project, name: "Hidden", types: [bug, task]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { alpha => %i[view_work_packages add_work_packages],
                                             beta => %i[view_work_packages add_work_packages],
                                             hidden => %i[view_work_packages] })
  end

  current_user { user }

  it "prefers the current project for the types it has" do
    defaults = menu_class.new(beta).defaults

    expect(defaults).to eq(bug.id => beta.identifier, task.id => alpha.identifier)
  end

  it "falls back to the project the user created a work package in most recently" do
    create(:work_package, project: alpha, type: bug, author: user, created_at: 2.days.ago)
    create(:work_package, project: beta, type: bug, author: user, created_at: 1.day.ago)

    expect(menu_class.new(nil).defaults[bug.id]).to eq(beta.identifier)
  end

  it "never suggests a project the user cannot create work packages in" do
    expect(menu_class.new(hidden).defaults.values).not_to include(hidden.identifier)
  end
end
