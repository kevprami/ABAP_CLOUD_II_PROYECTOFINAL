@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Ayuda de Búsqueda - Prioridad'
@ObjectModel.resultSet.sizeCategory: #XS
@Metadata.ignorePropagatedAnnotations: true
define view entity ZVH_PRIO_KPM
  as select from I_Language
{
      @EndUserText.label: 'Código'
      @ObjectModel.text.element: ['Description']
  key cast( 'H' as abap.char(1) ) as Priority,
      @EndUserText.label: 'Descripción'
      cast( 'High' as abap.char(20) ) as Description
}
where Language = $session.system_language

union all
  select from I_Language
{
  key cast( 'M' as abap.char(1) ) as Priority,
  cast( 'Medium' as abap.char(20) ) as Description
}
where Language = $session.system_language

union all
  select from I_Language
{
  key cast( 'L' as abap.char(1) ) as Priority,
  cast( 'Low' as abap.char(20) ) as Description
}
where Language = $session.system_language
