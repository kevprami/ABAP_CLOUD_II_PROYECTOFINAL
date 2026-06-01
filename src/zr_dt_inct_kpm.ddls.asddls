@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data Model for Incident - KPM'
define root view entity ZR_DT_INCT_KPM
  as select from zdt_inct_kpm
  composition [0..*] of ZR_DT_INCT_H_KPM as _History
  association [0..1] to zdt_status_kpm as _Status on $projection.Status = _Status.status_code
  association [0..1] to zdt_prior_kpm as _Priority on $projection.Priority = _Priority.prior_code
{
  key inc_uuid as IncUuid,
  incident_id as IncidentId,
  title as Title,
  description as Description,
  status as Status,
  priority as Priority,
  responsible as Responsible,
  creation_date as CreationDate,
  changed_date as ChangedDate,
  
  @Semantics.user.createdBy: true
  local_created_by as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  local_created_at as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  
  _History,
  _Status,
  _Priority
}
