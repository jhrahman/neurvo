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

import {
  dueState,
  isBlockedStatus,
  lozengeTone,
  parseCalendarDate,
  priorityLevel,
  typeGlyph,
} from './board-card.presenter';

describe('board card presenter', () => {
  describe('priorityLevel', () => {
    it('maps common priority names to five levels', () => {
      expect(priorityLevel('Critical')).toBe('highest');
      expect(priorityLevel('Immediate')).toBe('highest');
      expect(priorityLevel('High')).toBe('high');
      expect(priorityLevel('Medium')).toBe('medium');
      expect(priorityLevel('Normal')).toBe('medium');
      expect(priorityLevel('Low')).toBe('low');
      expect(priorityLevel('Lowest')).toBe('lowest');
    });

    it('returns null for unknown or missing names', () => {
      expect(priorityLevel('Whenever')).toBeNull();
      expect(priorityLevel(undefined)).toBeNull();
      expect(priorityLevel('')).toBeNull();
    });
  });

  describe('typeGlyph', () => {
    it('recognises the standard types', () => {
      expect(typeGlyph('Bug')).toBe('bug');
      expect(typeGlyph('Epic')).toBe('epic');
      expect(typeGlyph('Story')).toBe('story');
      expect(typeGlyph('Task')).toBe('task');
      expect(typeGlyph('Sub-task')).toBe('subtask');
      expect(typeGlyph('Feature Request')).toBe('request');
      expect(typeGlyph('Change Request')).toBe('request');
    });

    it('prefers support over request for support requests', () => {
      expect(typeGlyph('Support Request')).toBe('support');
    });

    it('uses the milestone glyph for milestone types and a generic one otherwise', () => {
      expect(typeGlyph('Release', true)).toBe('milestone');
      expect(typeGlyph('Whatever')).toBe('generic');
      expect(typeGlyph(undefined)).toBe('generic');
    });
  });

  describe('lozengeTone', () => {
    it('is stable and within range', () => {
      const tone = lozengeTone('Live vehicle tracking');

      expect(lozengeTone('Live vehicle tracking')).toBe(tone);
      expect(tone).toBeGreaterThanOrEqual(0);
      expect(tone).toBeLessThan(8);
    });
  });

  describe('dueState', () => {
    const today = new Date(2026, 10, 4, 15, 30);

    it('flags past dates as overdue', () => {
      expect(dueState('2026-11-03', false, today)).toBe('overdue');
    });

    it('treats today and the next two days as soon', () => {
      expect(dueState('2026-11-04', false, today)).toBe('soon');
      expect(dueState('2026-11-06', false, today)).toBe('soon');
    });

    it('treats later dates as later', () => {
      expect(dueState('2026-11-07', false, today)).toBe('later');
    });

    it('ignores closed work and missing dates', () => {
      expect(dueState('2026-11-03', true, today)).toBeNull();
      expect(dueState(null, false, today)).toBeNull();
      expect(dueState('not a date', false, today)).toBeNull();
    });
  });

  describe('parseCalendarDate', () => {
    it('reads a date as a local calendar day', () => {
      const date = parseCalendarDate('2026-11-06')!;

      expect([date.getFullYear(), date.getMonth(), date.getDate()]).toEqual([2026, 10, 6]);
    });
  });

  describe('isBlockedStatus', () => {
    it('detects impediment statuses', () => {
      expect(isBlockedStatus('Blocked')).toBeTrue();
      expect(isBlockedStatus('On hold')).toBeTrue();
      expect(isBlockedStatus('In Progress')).toBeFalse();
      expect(isBlockedStatus(undefined)).toBeFalse();
    });
  });
});
