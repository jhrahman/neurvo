//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';

export default class HomeCardsController extends Controller {
  static targets = ['option', 'counter', 'limit'];

  static values = { max: Number };

  declare optionTargets:HTMLInputElement[];
  declare counterTarget:HTMLElement;
  declare limitTarget:HTMLElement;
  declare maxValue:number;

  private template = '';

  connect() {
    this.template = this.counterTarget.textContent ?? '';
    this.sync();
  }

  toggle() {
    this.sync();
  }

  private sync() {
    const selected = this.optionTargets.filter((option) => option.checked).length;
    const full = selected >= this.maxValue;

    this.optionTargets.forEach((option) => {
      option.disabled = full && !option.checked;
    });

    this.counterTarget.textContent = this.template.replace(/\d+ of (\d+)/, `${selected} of $1`);
    this.limitTarget.hidden = !full;
  }
}
