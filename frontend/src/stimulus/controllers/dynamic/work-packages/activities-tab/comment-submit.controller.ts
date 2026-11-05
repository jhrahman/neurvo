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

const MIN_VISIBLE_MS = 400;

export default class CommentSubmitController extends Controller<HTMLFormElement> {
  private bar:HTMLElement|null = null;
  private startedAt = 0;

  start() {
    this.startedAt = Date.now();
    this.element.classList.add('op-comment-form--sending');
    this.element.setAttribute('aria-busy', 'true');

    this.bar = document.createElement('div');
    this.bar.className = 'op-comment-progress';
    this.bar.setAttribute('role', 'progressbar');
    this.bar.setAttribute('aria-label', I18n.t('js.label_posting_comment'));
    this.bar.innerHTML = '<span class="op-comment-progress--bar"></span>';
    this.element.prepend(this.bar);
  }

  finish() {
    const remaining = Math.max(0, MIN_VISIBLE_MS - (Date.now() - this.startedAt));
    window.setTimeout(() => this.clear(), remaining);
  }

  disconnect() {
    this.clear();
  }

  private clear() {
    this.bar?.remove();
    this.bar = null;
    this.element.classList.remove('op-comment-form--sending');
    this.element.removeAttribute('aria-busy');
  }
}
