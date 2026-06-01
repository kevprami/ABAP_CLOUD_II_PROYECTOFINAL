@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for Incident History'
@Metadata.allowExtensions: true
define view entity ZC_DT_INCT_H_KPM
  as projection on ZR_DT_INCT_H_KPM
{
  key HisUuid,
  IncUuid,
  HisId,
  PreviousStatus,
  NewStatus,
  Observation,
  LocalCreatedBy,
  LocalCreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt,
  
  _Incident : redirected to parent ZC_DT_INCT_KPM,
  _NewStatus,
  _OldStatus
}
