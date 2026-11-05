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
require "mini_magick"

module Avatars
  # Neurvo: ready-made avatars for people who do not want to upload a picture.
  # A preset is stored as the user's regular local avatar, so every place that
  # shows avatars (API, server-rendered and Angular views) works unchanged.
  class PresetService
    DIRECTORY = Rails.root.join("lib/neurvo/avatars")

    class << self
      def all
        @all ||= JSON.parse(DIRECTORY.join("presets.json").read, symbolize_names: true)
      end

      def keys
        all.pluck(:key)
      end

      def path(key)
        DIRECTORY.join("png", "#{key}.png") if keys.include?(key.to_s)
      end
    end

    def initialize(user)
      @user = user
    end

    def apply(key)
      file_path = self.class.path(key)
      return failure(I18n.t("avatars.error_unknown_preset")) unless file_path

      Tempfile.create(["avatar", ".png"], binmode: true) do |tempfile|
        tempfile.write(file_path.binread)
        tempfile.flush
        upload = ActionDispatch::Http::UploadedFile.new(tempfile:, filename: "#{key}.png", type: "image/png")
        @user.local_avatar_attachment = upload
      end

      ServiceResult.success(result: I18n.t(:message_avatar_uploaded))
    rescue StandardError => e
      Rails.logger.error "Failed to apply preset avatar #{key} to user##{@user.id}: #{e}"
      failure(I18n.t(:error_image_upload))
    end

    private

    def failure(message)
      ServiceResult.failure.tap { |result| result.errors.add(:base, message) }
    end
  end
end
