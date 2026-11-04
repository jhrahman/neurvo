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

export type PriorityLevel = 'highest'|'high'|'medium'|'low'|'lowest';

export type TypeGlyph = 'bug'|'story'|'epic'|'task'|'subtask'|'request'|'support'|'milestone'|'generic';

export type DueState = 'overdue'|'soon'|'later';

const PRIORITY_PATTERNS:[PriorityLevel, RegExp][] = [
  ['highest', /\b(critical|immediate|urgent|highest|blocker|emergency)\b/i],
  ['lowest', /\b(lowest|trivial)\b/i],
  ['high', /\b(high|major|important)\b/i],
  ['low', /\b(low|minor)\b/i],
  ['medium', /\b(medium|normal|default|moderate|standard)\b/i],
];

const TYPE_PATTERNS:[TypeGlyph, RegExp][] = [
  ['bug', /\b(bugs?|defects?|incidents?|errors?)\b/i],
  ['epic', /\bepics?\b/i],
  ['subtask', /\bsub-?tasks?\b/i],
  ['support', /\b(support|help ?desk|customer)\b/i],
  ['request', /\b(feature|change|improvement|enhancement|request)\b/i],
  ['story', /\b(stor(y|ies)|user stor(y|ies))\b/i],
  ['task', /\b(tasks?|spikes?|chores?|todo)\b/i],
];

const SOON_DAYS = 2;
const DAY_MS = 24 * 60 * 60 * 1000;
export const LOZENGE_TONES = 8;

/** Maps a priority name to one of five levels so cards can show a Jira-like chevron. */
export function priorityLevel(name?:string|null):PriorityLevel|null {
  if (!name) {
    return null;
  }

  return PRIORITY_PATTERNS.find(([, pattern]) => pattern.test(name))?.[0] ?? null;
}

/** Chooses the glyph drawn inside the coloured type badge. */
export function typeGlyph(name?:string|null, isMilestone = false):TypeGlyph {
  if (isMilestone) {
    return 'milestone';
  }

  if (!name) {
    return 'generic';
  }

  return TYPE_PATTERNS.find(([, pattern]) => pattern.test(name))?.[0] ?? 'generic';
}

/** A stable colour slot (0 to 7) for a label, so the same epic always has the same colour. */
export function lozengeTone(label:string):number {
  let hash = 0;
  for (const char of label) {
    hash = ((hash * 31) + char.charCodeAt(0)) | 0;
  }

  return Math.abs(hash) % LOZENGE_TONES;
}

function startOfDay(date:Date):number {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

/** Parses an API date (YYYY-MM-DD) as a local calendar day, free of time zone shifts. */
export function parseCalendarDate(value:string):Date|null {
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(value);
  if (!match) {
    return null;
  }

  return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
}

/** Returns whether a due date is overdue, due within two days or later; null without a date or when done. */
export function dueState(dueDate:string|null|undefined, closed:boolean, today:Date = new Date()):DueState|null {
  const due = dueDate ? parseCalendarDate(dueDate) : null;
  if (!due || closed) {
    return null;
  }

  const days = Math.round((startOfDay(due) - startOfDay(today)) / DAY_MS);
  if (days < 0) {
    return 'overdue';
  }

  return days <= SOON_DAYS ? 'soon' : 'later';
}

/** A status that signals an impediment; the card is highlighted like a flagged Jira issue. */
export function isBlockedStatus(name?:string|null):boolean {
  return !!name && /\bblocked\b|\bimpeded\b|\bon hold\b/i.test(name);
}
