@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data Model for Incident History - KPM'
define view entity ZR_DT_INCT_H_KPM
  as select from zdt_inct_h_kpm
  association to parent ZR_DT_INCT_KPM as _Incident on $projection.IncUuid = _Incident.IncUuid
  association [0..1] to zdt_status_kpm as _OldStatus on $projection.PreviousStatus = _OldStatus.status_code
  association [0..1] to zdt_status_kpm as _NewStatus on $projection.NewStatus = _NewStatus.status_code
{
  key his_uuid as HisUuid,
  inc_uuid as IncUuid,
  his_id as HisId,
  previous_status as PreviousStatus,
  new_status as NewStatus,
  observation as Observation,
  
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
  
  _Incident,
  _OldStatus,
  _NewStatus
}
