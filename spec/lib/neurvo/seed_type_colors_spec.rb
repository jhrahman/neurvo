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

# Type names are rendered in their type color, adjusted by ColorsHelper: darkened by 22% in light mode,
# lightened towards a perceived lightness of 0.6 in dark mode. Every seeded type must stay readable
# (WCAG AA, 4.5:1) on the lightest background of every Neurvo palette.
RSpec.describe "Neurvo seed data type colors" do # rubocop:disable RSpec/DescribeClass
  let(:types) { YAML.safe_load_file(Rails.root.join("lib/neurvo/seed_data.yml"))["types"] }
  let(:light_backgrounds) { %w[#FFFFFF #F6F8FA #FBF7F0 #F4EEE3 #F5F6F8 #ECEEF2 #FDF6E3 #EEE8D5] }
  let(:dark_backgrounds) { %w[#0D1117 #151B23 #313338 #2B2D31 #000000 #282C34 #21252B #282A36 #1A1B26] }

  def rgb(hex) = hex.delete("#").scan(/../).map { |c| c.to_i(16) }

  def hsl_to_rgb(hue, sat, light)
    sat /= 100.0
    light /= 100.0
    a = sat * [light, 1 - light].min
    [0, 8, 4].map do |n|
      k = (n + (hue / 30.0)) % 12
      ((light - (a * [-1, [k - 3, 9 - k, 1].min].max)) * 255).round
    end
  end

  def to_hsl(hex)
    color = ColorConversion::Color.new(hex).hsl
    [color[:h], color[:s], color[:l]]
  end

  def light_variant(hex)
    hue, sat, light = to_hsl(hex)
    hsl_to_rgb(hue, sat, light - (light * 0.22))
  end

  def dark_variant(hex)
    hue, sat, light = to_hsl(hex)
    red, green, blue = rgb(hex)
    perceived = ((red * 0.2126) + (green * 0.7152) + (blue * 0.0722)) / 255
    switch = (1 / (0.6 - perceived)).clamp(0, 1)
    hsl_to_rgb(hue, sat, [light + ((0.6 - perceived) * 100 * switch), 100].min)
  end

  def luminance(color)
    linear = color.map do |channel|
      value = channel / 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    (0.2126 * linear[0]) + (0.7152 * linear[1]) + (0.0722 * linear[2])
  end

  def contrast(foreground, background)
    high, low = [luminance(foreground), luminance(rgb(background))].sort.reverse
    (high + 0.05) / (low + 0.05)
  end

  it "keeps every type name readable in light and dark palettes", :aggregate_failures do
    types.each do |type|
      light_backgrounds.each do |background|
        expect(contrast(light_variant(type["color"]), background))
          .to be >= 4.5, "#{type['name']} (#{type['color']}) on #{background}"
      end
      dark_backgrounds.each do |background|
        expect(contrast(dark_variant(type["color"]), background))
          .to be >= 4.5, "#{type['name']} (#{type['color']}) on #{background}"
      end
    end
  end
end
