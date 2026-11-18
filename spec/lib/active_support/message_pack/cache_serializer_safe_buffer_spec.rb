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

# Rails before 8.1.4 reconstructed cached SafeBuffers as ASCII-8BIT (rails/rails#57429).
# The fix ships with Rails now, so this guards against a regression.
RSpec.describe ActiveSupport::MessagePack::CacheSerializer, "SafeBuffer round-trip" do
  # Use the same serializer the cache store uses to cover the real path.
  let(:serializer) { described_class }
  let(:html) { "<p>Héllo &amp; wörld — «quoted»</p>" }

  def round_trip(value)
    serializer.load(serializer.dump(value))
  end

  context "with a UTF-8 SafeBuffer (normal render output)" do
    subject { ActiveSupport::SafeBuffer.new(html) }

    it "roundtrips as a UTF-8 html_safe SafeBuffer and concatenates without error", :aggregate_failures do
      result = round_trip(subject)
      expect(result).to be_a(ActiveSupport::SafeBuffer)
      expect(result).to be_html_safe
      expect(result.encoding).to eq(Encoding::UTF_8)
      expect(result.to_s).to eq(html)
      expect("prefix " + result).to eq("prefix #{html}")
    end
  end

  context "with a BINARY-encoded SafeBuffer" do
    subject { ActiveSupport::SafeBuffer.new(html.b) }

    it "preserves BINARY encoding across the round-trip", :aggregate_failures do
      result = round_trip(subject)
      expect(result).to be_a(ActiveSupport::SafeBuffer)
      expect(result).to be_html_safe
      expect(result.encoding).to eq(Encoding::BINARY)
      expect(result.to_str).to eq(html.b)
    end
  end
end
