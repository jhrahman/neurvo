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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, HostBinding, Injector, Input, OnInit, ViewEncapsulation, ViewRef, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  FieldDescriptor,
  GroupDescriptor,
} from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';

@Component({
  selector: 'wp-attribute-group',
  templateUrl: './wp-attribute-group.template.html',
  styleUrls: ['./wp-attribute-group.component.sass'],
  encapsulation: ViewEncapsulation.None,
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WorkPackageFormAttributeGroupComponent extends UntilDestroyedMixin implements OnInit {
  readonly I18n = inject(I18nService);
  wpEditForm = inject(EditFormComponent);
  protected injector = inject(Injector);
  private readonly cdRef = inject(ChangeDetectorRef);
  private readonly apiV3Service = inject(ApiV3Service);
  private readonly currentUserService = inject(CurrentUserService);
  private readonly halResourceService = inject(HalResourceService);

  private currentUser:{ id:string|null, name:string|null }|null = null;

  @HostBinding('class.wp-attribute-group') className = true;
  @HostBinding('class.attributes-group--attributes') parentClassName = true;

  @Input() public workPackage:WorkPackageResource;

  @Input() public group:GroupDescriptor;

  /**
   * Hide read-only fields, but only when in the create mode
   * @param {FieldDescriptor} field
   */
  public shouldHideField(descriptor:FieldDescriptor) {
    const field = descriptor.field || descriptor.fields![0];
    return this.wpEditForm.editMode && !field.writable;
  }

  ngOnInit():void {
    this.currentUserService.user$
      .pipe(this.untilDestroyed())
      .subscribe((user) => { this.currentUser = user; });

    this.wpEditForm.change.state?.values$()
      .pipe(this.untilDestroyed())
      .subscribe(() => this.refreshView());
  }

  public refreshView():void {
    setTimeout(() => {
      if (!(this.cdRef as ViewRef).destroyed) {
        this.cdRef.detectChanges();
      }
    }, 50);
  }

  public showAssignToMe(descriptor:FieldDescriptor):boolean {
    const field = descriptor.field;
    if (descriptor.multiple || !field || !this.currentUser?.id || !field.writable || field.schema?.type !== 'User') {
      return false;
    }

    const assignable = ['assignee', 'responsible'].includes(descriptor.name) || /^customField\d+$/.test(descriptor.name);
    const current = (this.wpEditForm.change.projectedResource as unknown as Record<string, { href?:string }|null>)[descriptor.name];

    return assignable && !current?.href?.endsWith(`/users/${this.currentUser.id}`);
  }

  public async assignToMe(descriptor:FieldDescriptor, event:Event):Promise<void> {
    event.preventDefault();
    const user = this.currentUser;
    if (!user?.id) { return; }

    const href = this.apiV3Service.users.id(user.id).path;
    const resource = this.halResourceService.createHalResourceOfType('user', { id: user.id, name: user.name, href });

    this.wpEditForm.change.setValue(descriptor.name, resource);

    if (isNewResource(this.workPackage)) {
      await this.reopenField(descriptor.name);
      return;
    }

    await this.wpEditForm.submit();
  }

  private async reopenField(name:string):Promise<void> {
    const field = this.wpEditForm.fields[name];
    this.wpEditForm.closeEditFields([name], false);
    await field?.activateOnForm(true);
  }
}
