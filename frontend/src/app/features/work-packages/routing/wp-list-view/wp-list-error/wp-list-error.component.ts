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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, inject, OnInit } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace, QueryLoadError } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

type ErrorKind = 'forbidden'|'not_found'|'server';

@Component({
  selector: 'wp-list-error',
  templateUrl: './wp-list-error.component.html',
  styleUrls: ['./wp-list-error.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageListErrorComponent extends UntilDestroyedMixin implements OnInit {
  readonly I18n = inject(I18nService);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly pathHelper = inject(PathHelperService);
  readonly cdRef = inject(ChangeDetectorRef);

  error:QueryLoadError|null = null;

  ngOnInit():void {
    this.querySpace.loadError
      .values$()
      .pipe(this.untilDestroyed())
      .subscribe((error) => {
        this.error = error;
        this.cdRef.markForCheck();
      });
  }

  get kind():ErrorKind {
    if (this.error?.status === 403) {
      return 'forbidden';
    }

    return this.error?.status === 404 ? 'not_found' : 'server';
  }

  text(part:'title'|'description'):string {
    return this.I18n.t(`js.work_packages.load_error.${this.kind}.${part}`);
  }

  readonly labels = {
    back: this.I18n.t('js.work_packages.load_error.back'),
    retry: this.I18n.t('js.work_packages.load_error.retry'),
    home: this.I18n.t('js.work_packages.load_error.home'),
    details: this.I18n.t('js.work_packages.load_error.details'),
  };

  goBack():void {
    if (window.history.length > 1) {
      window.history.back();
    } else {
      window.location.href = this.pathHelper.appBasePath || '/';
    }
  }

  retry():void {
    window.location.reload();
  }
}
