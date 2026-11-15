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

export default class FieldFilterController extends Controller<HTMLElement> {
  static targets = ['input', 'item', 'group', 'empty'];

  declare readonly inputTarget:HTMLInputElement;
  declare readonly itemTargets:HTMLElement[];
  declare readonly groupTargets:HTMLElement[];
  declare readonly emptyTarget:HTMLElement;

  filter() {
    const term = this.inputTarget.value.trim().toLowerCase();

    this.itemTargets.forEach((item) => {
      item.hidden = term.length > 0 && !(item.textContent ?? '').toLowerCase().includes(term);
    });

    this.groupTargets.forEach((group) => {
      group.hidden = !this.visibleItems(group).length;
    });

    this.emptyTarget.hidden = this.groupTargets.some((group) => !group.hidden);
  }

  checkVisible(event:Event & { params:{ group:string } }) {
    this.setVisible(event, true);
  }

  uncheckVisible(event:Event & { params:{ group:string } }) {
    this.setVisible(event, false);
  }

  private setVisible(event:Event & { params:{ group:string } }, checked:boolean) {
    const group = this.groupTargets.find((g) => g.dataset.group === event.params.group);
    if (!group) { return; }

    this.visibleItems(group).forEach((item) => {
      const box = item.querySelector<HTMLInputElement>('input[type=checkbox]');
      if (box) { box.checked = checked; }
    });
  }

  private visibleItems(group:HTMLElement):HTMLElement[] {
    return this.itemTargets.filter((item) => group.contains(item) && !item.hidden);
  }
}
