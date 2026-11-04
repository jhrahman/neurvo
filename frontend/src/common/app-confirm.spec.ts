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

import { appConfirm } from './app-confirm';

describe('appConfirm', () => {
  const options = {
    title: 'Title',
    message: 'Really?',
    confirmLabel: 'Yes',
    cancelLabel: 'No',
  };

  const dialog = () => document.querySelector<HTMLDialogElement>('[data-test-selector="neurvo-confirm-dialog"]');
  const click = (selector:string) => document.querySelector<HTMLButtonElement>(`[data-test-selector="${selector}"]`)!.click();

  afterEach(() => {
    dialog()?.close();
  });

  it('resolves true when confirmed and removes the dialog', async () => {
    const answer = appConfirm(options);
    expect(dialog()?.open).toBeTrue();

    click('neurvo-confirm-accept');

    expect(await answer).toBeTrue();
    expect(dialog()).toBeNull();
  });

  it('resolves false when cancelled', async () => {
    const answer = appConfirm(options);

    click('neurvo-confirm-cancel');

    expect(await answer).toBeFalse();
  });

  it('resolves false when closed with Escape', async () => {
    const answer = appConfirm(options);

    dialog()!.close();

    expect(await answer).toBeFalse();
  });

  it('shares the open dialog between concurrent calls', async () => {
    const first = appConfirm(options);
    const second = appConfirm(options);

    expect(document.querySelectorAll('[data-test-selector="neurvo-confirm-dialog"]').length).toBe(1);

    click('neurvo-confirm-accept');

    expect(await first).toBeTrue();
    expect(await second).toBeTrue();
  });

  it('renders the message as text, not HTML', () => {
    void appConfirm({ ...options, message: '<img src=x onerror=alert(1)>' });

    expect(dialog()!.querySelector('img')).toBeNull();
    expect(dialog()!.textContent).toContain('<img src=x');
  });
});
