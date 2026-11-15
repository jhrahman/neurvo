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

RSpec.describe WorkPackageTypes::TicketFields::ApplyService do
  let(:admin) { create(:admin) }
  let(:type) { create(:type) }
  let!(:custom_field) { create(:work_package_custom_field) }
  let(:cf_key) { custom_field.attribute_name }

  def active_keys
    type.reload.default_variant.attribute_groups.flat_map(&:members)
  end

  it "enables a custom field and an inactive default field" do
    result = described_class.new(user: admin, type:).call(enabled: %w[assignee] + [cf_key])

    expect(result).to be_success
    expect(active_keys).to contain_exactly("assignee", cf_key)
    expect(type.reload.default_variant.custom_field_ids).to include(custom_field.id)
  end

  it "disables fields that are not listed" do
    described_class.new(user: admin, type:).call(enabled: %w[assignee priority])
    described_class.new(user: admin, type:).call(enabled: %w[priority])

    expect(active_keys).to contain_exactly("priority")
  end

  it "ignores unknown attribute keys" do
    described_class.new(user: admin, type:).call(enabled: %w[nonsense priority])

    expect(active_keys).to contain_exactly("priority")
  end
end
