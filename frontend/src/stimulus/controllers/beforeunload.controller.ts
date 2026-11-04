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

import { ApplicationController } from 'stimulus-use';
import * as Turbo from '@hotwired/turbo';
import { TurboBeforeVisitEvent } from '@hotwired/turbo';
import { confirmDiscardChanges } from 'core-common/app-confirm';

export class BeforeunloadController extends ApplicationController {
  private abortController = new AbortController();
  private approvedVisit = false;
  private replayingClick = false;

  connect() {
    super.connect();

    const { signal } = this.abortController;

    window.addEventListener('beforeunload', this, { signal });
    document.addEventListener('turbo:before-visit', this, { signal });
    document.addEventListener('turbo:submit-end', this, { signal });
    document.addEventListener('turbo:load', this, { signal });
    document.addEventListener('turbo:render', this, { signal });
    document.addEventListener('submit', this, { signal });
    document.addEventListener('click', this, { signal, capture: true });
  }

  disconnect() {
    this.abortController.abort();
  }

  handleEvent(evt:Event) {
    switch (evt.type) {
      case 'beforeunload':
      case 'turbo:before-visit':
        this.beforeunloadHandler(evt);
        break;
      case 'turbo:submit-end':
      case 'turbo:load':
      case 'turbo:render':
        window.OpenProject.pageState = 'pristine';
        break;
      case 'submit':
        window.OpenProject.pageState = 'submitted';
        break;
      case 'click':
        this.confirmLinkClick(evt as MouseEvent);
        break;
      default:
        break;
    }
  }

  private beforeunloadHandler(evt:BeforeUnloadEvent|TurboBeforeVisitEvent) {
    const hasUnsavedChanges = evt.type === 'turbo:before-visit'
      ? window.OpenProject.pageHasUnsavedChanges
      : window.OpenProject.pageWasEdited;

    if (!hasUnsavedChanges) {
      return;
    }

    if (evt.type === 'turbo:before-visit') {
      this.confirmVisit(evt as TurboBeforeVisitEvent);
      return;
    }

    // Browsers only allow their own dialog when the tab is closed or reloaded
    evt.preventDefault();
    evt.returnValue = '';
  }

  // Not every link goes through Turbo (target="_top" links and the work package side menu load a new
  // page), which would show the browser's own leave-page prompt.
  private confirmLinkClick(evt:MouseEvent) {
    const link = (evt.target as Element|null)?.closest<HTMLAnchorElement>('a[href]');

    if (this.replayingClick || !link || !this.leavesPage(link, evt) || !window.OpenProject.pageHasUnsavedChanges) {
      return;
    }

    evt.preventDefault();
    evt.stopImmediatePropagation();

    void confirmDiscardChanges().then((discard) => {
      if (!discard) {
        return;
      }

      this.approve(() => {
        this.replayingClick = true;
        link.click();
        this.replayingClick = false;
      });
    });
  }

  private leavesPage(link:HTMLAnchorElement, evt:MouseEvent):boolean {
    const plainClick = evt.button === 0 && !evt.metaKey && !evt.ctrlKey && !evt.shiftKey && !evt.altKey;
    const url = new URL(link.href, window.location.href);
    const samePage = url.pathname === window.location.pathname && url.search === window.location.search;
    const opensTab = link.target !== '' && link.target !== '_top' && link.target !== '_self';
    const hasOwnBehavior = link.hasAttribute('download')
      || ['turboMethod', 'turboStream', 'method', 'turboConfirm', 'remote'].some((name) => name in link.dataset)
      || (link.dataset.controller ?? '').includes('dialog')
      || (!!link.dataset.turboFrame && link.dataset.turboFrame !== '_top');

    return plainClick
      && !evt.defaultPrevented
      && url.origin === window.location.origin
      && !samePage
      && !opensTab
      && !hasOwnBehavior;
  }

  private approve(navigate:() => void) {
    window.OpenProject.pageState = 'submitted';
    this.approvedVisit = true;
    try {
      navigate();
    } finally {
      this.approvedVisit = false;
    }
  }

  private confirmVisit(evt:TurboBeforeVisitEvent) {
    if (this.approvedVisit) {
      return;
    }

    evt.preventDefault();
    const { url } = evt.detail;

    void confirmDiscardChanges().then((discard) => {
      if (!discard) {
        return;
      }

      this.approve(() => Turbo.visit(url));
    });
  }
}
