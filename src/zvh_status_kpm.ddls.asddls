@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Ayuda de Búsqueda - Estado'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS 
define view entity ZVH_STATUS_KPM
  as select from I_Language
{
      @EndUserText.label: 'Código'
      @ObjectModel.text.element: ['Description']
  key cast( 'OP' as abap.char(2) ) as Status,
      @EndUserText.label: 'Descripción'
      cast( 'Open' as abap.char(20) ) as Description
}
where Language = $session.system_language

union all
  select from I_Language
{
  key cast( 'IP' as abap.char(2) ) as Status,
  cast( 'In Progress' as abap.char(20) ) as Description
}
where Language = $session.system_language

union all
  select from I_Language
{
  key cast( 'PE' as abap.char(2) ) as Status,
  cast( 'Pending' as abap.char(20) ) as Description
}
where Language = $session.system_language

union all
  select from I_Language
{
  key cast( 'CO' as abap.char(2) ) as Status,
  cast( 'Completed' as abap.char(20) ) as Description
}
where Language = $session.system_language

union all
  select from I_Language
{
  key cast( 'CN' as abap.char(2) ) as Status,
  cast( 'Canceled' as abap.char(20) ) as Description
}
where Language = $session.system_language

union all
  select from I_Language
{
  key cast( 'CL' as abap.char(2) ) as Status,
  cast( 'Closed' as abap.char(20) ) as Description
}
where Language = $session.system_language
