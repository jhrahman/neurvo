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

module WorkPackages
  module ActivitiesTab
    module Journals
      class RepliesComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(parent_id:, filter: Filters::ALL)
          super

          @parent_id = parent_id
          @filter = filter
        end

        private

        attr_reader :parent_id, :filter

        def wrapper_uniq_by
          parent_id
        end

        def replies
          @replies ||= Journal.find(parent_id).journable.journals
            .internal_visible
            .where(reply_to_id: parent_id)
            .includes(:user)
            .reorder(:created_at, :id)
            .to_a
        end

        def grouped_emoji_reactions
          @grouped_emoji_reactions ||= EmojiReactions::GroupedQueries.grouped_emoji_reactions_by_reactable(
            reactable_id: replies.map(&:id), reactable_type: "Journal"
          )
        end
      end
    end
  end
end
