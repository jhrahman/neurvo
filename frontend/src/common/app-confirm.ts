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

export interface AppConfirmOptions {
  title?:string;
  message:string;
  confirmLabel?:string;
  cancelLabel?:string;
  danger?:boolean;
}

let openDialog:Promise<boolean>|null = null;

function button(label:string, scheme:'primary'|'danger'|'secondary', testSelector:string):HTMLButtonElement {
  const element = document.createElement('button');
  element.type = 'button';
  element.className = `Button Button--${scheme} Button--medium`;
  element.dataset.testSelector = testSelector;
  element.innerHTML = '<span class="Button-content"><span class="Button-label"></span></span>';
  element.querySelector('.Button-label')!.textContent = label;
  return element;
}

function buildDialog(options:AppConfirmOptions) {
  const dialog = document.createElement('dialog');
  dialog.className = 'neurvo-confirm';
  dialog.setAttribute('aria-labelledby', 'neurvo-confirm-title');
  dialog.setAttribute('aria-describedby', 'neurvo-confirm-message');
  dialog.dataset.testSelector = 'neurvo-confirm-dialog';

  const header = document.createElement('div');
  header.className = 'neurvo-confirm--header';
  const title = document.createElement('h1');
  title.className = 'neurvo-confirm--title';
  title.id = 'neurvo-confirm-title';
  title.textContent = options.title ?? I18n.t('js.confirm_dialog.title');
  header.append(title);

  const body = document.createElement('div');
  body.className = 'neurvo-confirm--body';
  body.id = 'neurvo-confirm-message';
  body.textContent = options.message;

  const cancel = button(options.cancelLabel ?? I18n.t('js.button_cancel'), 'secondary', 'neurvo-confirm-cancel');
  const confirm = button(
    options.confirmLabel ?? I18n.t('js.button_continue'),
    options.danger ? 'danger' : 'primary',
    'neurvo-confirm-accept',
  );
  const footer = document.createElement('div');
  footer.className = 'neurvo-confirm--footer';
  footer.append(cancel, confirm);

  dialog.append(header, body, footer);
  return { dialog, cancel, confirm };
}

/**
 * Asks the user to confirm in an in-app dialog instead of the browser's window.confirm.
 * Resolves true on confirm and false on cancel, Escape or a click on the backdrop.
 * Concurrent calls share the dialog that is already open.
 */
export function appConfirm(options:AppConfirmOptions):Promise<boolean> {
  if (openDialog) {
    return openDialog;
  }

  const { dialog, cancel, confirm } = buildDialog(options);
  const previouslyFocused = document.activeElement as HTMLElement|null;

  openDialog = new Promise<boolean>((resolve) => {
    let answer = false;

    dialog.addEventListener('close', () => {
      dialog.remove();
      openDialog = null;
      previouslyFocused?.focus?.();
      resolve(answer);
    });
    dialog.addEventListener('click', (event) => {
      if (event.target === dialog) {
        dialog.close();
      }
    });
    cancel.addEventListener('click', () => dialog.close());
    confirm.addEventListener('click', () => {
      answer = true;
      dialog.close();
    });

    document.body.append(dialog);
    dialog.showModal();
    (options.danger ? cancel : confirm).focus();
  });

  return openDialog;
}

export function confirmDiscardChanges(message?:string):Promise<boolean> {
  return appConfirm({
    title: I18n.t('js.confirm_dialog.discard_title'),
    message: message ?? I18n.t('js.confirm_dialog.discard_text'),
    confirmLabel: I18n.t('js.confirm_dialog.discard_confirm'),
    cancelLabel: I18n.t('js.confirm_dialog.keep_editing'),
    danger: true,
  });
}
