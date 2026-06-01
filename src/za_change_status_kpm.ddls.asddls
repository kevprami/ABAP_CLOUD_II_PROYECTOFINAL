@EndUserText.label: 'Parámetros Cambio de Estado - KPM'
define abstract entity ZA_CHANGE_STATUS_KPM 
{
  @EndUserText.label: 'Nuevo Estado (Ej: IP, PE, CO)'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZVH_STATUS_KPM', element: 'Status' } }]
  NewStatus : abap.char(2);
  
  @EndUserText.label: 'Observación'
  Observation : abap.char(255);
}
