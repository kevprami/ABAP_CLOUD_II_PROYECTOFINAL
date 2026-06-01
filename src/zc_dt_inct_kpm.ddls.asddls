@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for Incident - KPM'
@Metadata.allowExtensions: true
define root view entity ZC_DT_INCT_KPM
  provider contract transactional_query
  as projection on ZR_DT_INCT_KPM
{
  key IncUuid,
  IncidentId,
  Title,
  Description,
  Status,
  Priority,
  Responsible,
  CreationDate,
  ChangedDate,
  LocalCreatedBy,
  LocalCreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt,
  
  _History : redirected to composition child ZC_DT_INCT_H_KPM,
  _Status,
  _Priority
}
