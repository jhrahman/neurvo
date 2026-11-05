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

const COPY_CLASS = 'op-code-copy';
const SELECTOR = '.op-uc-container pre';

function codeTextOf(pre:HTMLElement):string {
  return (pre.querySelector('code') ?? pre).textContent ?? '';
}

function ensureCopyButton(pre:HTMLElement) {
  if (pre.querySelector(`:scope > .${COPY_CLASS}`)) { return; }

  const button = document.createElement('button');
  button.type = 'button';
  button.className = COPY_CLASS;
  button.textContent = I18n.t('js.clipboard.copy');
  button.setAttribute('aria-label', I18n.t('js.clipboard.copy_code'));
  pre.append(button);
}

async function copy(button:HTMLButtonElement) {
  const pre = button.closest<HTMLElement>('pre');
  if (!pre) { return; }

  await navigator.clipboard.writeText(codeTextOf(pre));
  button.textContent = I18n.t('js.clipboard.copied');
  button.classList.add(`${COPY_CLASS}--done`);
  window.setTimeout(() => {
    button.textContent = I18n.t('js.clipboard.copy');
    button.classList.remove(`${COPY_CLASS}--done`);
  }, 1500);
}

export function setupCodeBlockCopy() {
  document.addEventListener('mouseover', (event) => {
    const pre = (event.target as HTMLElement|null)?.closest<HTMLElement>(SELECTOR);
    if (pre) { ensureCopyButton(pre); }
  });

  document.addEventListener('focusin', (event) => {
    const pre = (event.target as HTMLElement|null)?.closest<HTMLElement>(SELECTOR);
    if (pre) { ensureCopyButton(pre); }
  });

  document.addEventListener('click', (event) => {
    const button = (event.target as HTMLElement|null)?.closest<HTMLButtonElement>(`.${COPY_CLASS}`);
    if (button) { void copy(button); }
  });
}

const CHECK_ICON = '<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" class="octicon"><path fill="currentColor" d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z"/></svg>';
const FEEDBACK_SELECTOR = '[data-copy-feedback]';
const FEEDBACK_MS = 1600;

export function setupCopyFeedback() {
  document.addEventListener('clipboard-copy', (event) => {
    const trigger = (event.target as HTMLElement|null)?.closest<HTMLElement>(FEEDBACK_SELECTOR);
    if (!trigger || trigger.classList.contains('op-copy-feedback--done')) { return; }

    const original = trigger.innerHTML;
    trigger.classList.add('op-copy-feedback', 'op-copy-feedback--done');
    trigger.innerHTML = CHECK_ICON;

    window.setTimeout(() => {
      trigger.innerHTML = original;
      trigger.classList.remove('op-copy-feedback--done');
    }, FEEDBACK_MS);
  });
}
