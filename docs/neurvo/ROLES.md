# Roles and permissions (sample workspace)

Role-based access for the sample team, following least privilege: people get what their job needs and nothing more.
Roles are defined in `lib/neurvo/seed_data.yml` (`permission_sets`, `roles`, `quality_gate`) and created by
`bin/compose exec backend bundle exec rake neurvo:seed`. Roles apply **per project**: a user's role is whatever
they hold as a member of that project.

**Development credentials** (change them before any real use): every account below uses the password
`Neurvo-Dev-2026!`. The login is `firstname.lastname`. Sign in at <http://localhost:3000>.

| Role | Account to try | Login | Also holds this role |
|---|---|---|---|
| Project Manager | Imran Chowdhury (GoFleet) | `imran.chowdhury` | `ayesha.karim` (QuickCart, Neurvo), `daniel.brooks` (tech lead) |
| Developer | Sofia Martins (GoFleet) | `sofia.martins` | `rafi.hasan`, `arif.rahman`, `kenji.watanabe`, `priya.nair` |
| QA Engineer | Lena Fischer (GoFleet) | `lena.fischer` | `nusrat.jahan` (QA lead), `marco.rossi` |
| DevOps Engineer | Tanvir Ahmed (all projects) | `tanvir.ahmed` | |
| Designer | Maya Patel (GoFleet, QuickCart) | `maya.patel` | |
| System administrator | Administrator | `admin` / `admin` (change it) | |

None of the team accounts is a system administrator. Only `admin` can change types, workflows, statuses, roles,
users and system settings.

## What each role can do

| Capability | Project Manager | Developer | QA Engineer | DevOps Engineer | Designer |
|---|:-:|:-:|:-:|:-:|:-:|
| View everything in the project (issues, boards, sprints, wiki, docs, meetings, members) | yes | yes | yes | yes | yes |
| Create and edit work packages, comment, attach files, watch, link and split into sub-tasks | yes | yes | yes | yes | yes |
| Save personal views | yes | yes | yes | yes | yes |
| Edit wiki pages | yes | yes | yes | yes | yes |
| Move cards between sprints/boards, copy and move issues, set versions, export | yes | yes | yes | yes | no |
| Create and edit meetings and agendas | yes | yes | yes | yes | no |
| Manage wiki structure | yes | no | yes | yes | no |
| Manage documents | yes | no | yes | no | yes |
| Share (public) saved views | yes | no | yes | yes | no |
| Manage releases (versions) | yes | no | no | yes | no |
| Create and edit boards | yes | no | no | yes | no |
| Create and start/complete sprints | yes | no | no | no | no |
| Delete work packages | yes | no | no | no | no |
| Manage project members, categories and project settings | yes | no | no | no | no |
| Set status **In QA** and **Done** on Story, Bug, Feature Request and Change Request | yes | no | yes | no | no |

## What nobody except `admin` can do

Change types and workflows, enable or disable project modules, archive or copy a project, add sub-projects, manage
users and roles, change system settings, reach the administration pages (they answer 403).

## Quality gate

Developers, DevOps engineers and Designers cannot move a Story, Bug, Feature Request or Change Request into
**In QA** or **Done**. They hand work over by setting **Ready for QA**; the QA Engineer verifies it (In QA), then
sets Done, or Reopened with the failure. Project Managers can do any transition. Tasks, Sub-tasks, Epics, Support
Requests and Milestones are not gated, so DevOps and design tasks can be closed by their owners. This is enforced by
the workflow on the server, so boards, the API and the ticket page all behave the same; the status menu only shows
the transitions you may make.

## Tested behaviour

Checked against the running app with Playwright and the permission API after seeding (GoFleet project):

- The permission matrix above matches `allowed_in_project?` for one user of each role.
- Ticket page: the status menu of a *Ready for QA* bug lists In QA and Done for Project Manager and QA only; the
  Delete and Move actions appear for the Project Manager only (Move also for Developer, QA, DevOps).
- Server enforcement: Developer to Done, DevOps to In QA and Designer to Done are rejected ("no valid transition
  exists from old to new status for the current user's roles"); QA and Project Manager to In QA succeed; a
  Developer cannot delete, a Project Manager can.
- Pages: `/projects/GOFLEET/settings/general` is 200 for the Project Manager and 403 for the others; project
  versions settings are 200 for Project Manager and DevOps, 403 for the rest; `/admin`, `/types` and `/users` are 403
  for everyone but `admin`.

Time tracking, news and repository permissions exist in the roles but those modules are switched off in the sample
projects, so they have no effect until an administrator enables the module.

## Changing roles

Edit `permission_sets`/`roles` in `lib/neurvo/seed_data.yml` and re-run the seed, or adjust a role in the UI at
Administration > Users and permissions > Roles and permissions (the seed overwrites role permissions when re-run).
