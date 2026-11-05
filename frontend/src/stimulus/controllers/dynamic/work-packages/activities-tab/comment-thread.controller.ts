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
import type { TurboSubmitEndEvent } from '@hotwired/turbo';
import type PollingController from './polling.controller';

const POLLING_IDENTIFIER = 'work-packages--activities-tab--polling';

export default class CommentThreadController extends Controller<HTMLElement> {
  static targets = ['trigger', 'panel', 'form', 'input', 'timestamp'];

  declare readonly triggerTarget:HTMLElement;
  declare readonly panelTarget:HTMLElement;
  declare readonly formTarget:HTMLFormElement;
  declare readonly inputTarget:HTMLTextAreaElement;
  declare readonly timestampTarget:HTMLInputElement;

  open() {
    this.panelTarget.hidden = false;
    this.triggerTarget.hidden = true;
    this.inputTarget.focus();
  }

  close() {
    this.formTarget.reset();
    this.panelTarget.hidden = true;
    this.triggerTarget.hidden = false;
    this.triggerTarget.focus();
  }

  submit() {
    if (this.formTarget.checkValidity()) {
      this.formTarget.requestSubmit();
    } else {
      this.formTarget.reportValidity();
    }
  }

  prepare() {
    this.timestampTarget.value = this.pollingController?.lastServerTimestampValue ?? '';
  }

  done(event:TurboSubmitEndEvent) {
    const response = event.detail.fetchResponse;
    if (!response?.succeeded) { return; }

    this.pollingController?.setLastServerTimestampViaHeaders(response.response.headers);
    this.close();
  }

  private get pollingController():PollingController|undefined {
    const element = document.getElementById('work-packages--activities-tab--index');
    if (!element) { return undefined; }

    return this.application.getControllerForElementAndIdentifier(element, POLLING_IDENTIFIER) as PollingController|undefined;
  }
}
