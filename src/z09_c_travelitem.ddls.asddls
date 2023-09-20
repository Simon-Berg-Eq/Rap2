@EndUserText.label: 'Travel Item Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@Metadata.allowExtensions: true

define view entity Z09_C_TRAVELITEM 
    as projection on Z09_I_TRAVELITEM 
{
  key Itguid,
      AgencyID,
      TravelId,
      ItemID,
      TrGuid,

       @Consumption.valueHelpDefinition: 
               [ { entity: { name:    'D437_I_Carrier',
                             element: 'CarrierID'
                           }
                 }
               ]
      CarrierId,
      
      @Consumption.valueHelpDefinition: 
               [ { entity: { name:    'D437_I_Connection',
                             element: 'ConnectionID'
                           },
                   additionalBinding: 
                        [ { localElement: 'CarrierID',
                                 element: 'CarrierID',
                                   usage: #FILTER_AND_RESULT
                          }
                        ],
                   label: 'Value Help by Connection' 
                 },
                 { entity: { name:    'D437_I_FlightVH',
                             element: 'ConnectionID'
                           },
                   additionalBinding: 
                        [ { localElement: 'CarrierID',
                            element:      'CarrierID',
                            usage:        #FILTER_AND_RESULT
                          },
                          { localElement: 'FlightDate',
                            element:      'FlightDate',
                            usage:         #RESULT
                         }
                       ],
                   label: 'Value Help by Flight',
                   qualifier: 'Secondary Value help'
                 }
               ]
      ConnectionId,
      @Consumption.valueHelpDefinition: 
               [ { entity: { name:    'D437_I_FlightVH',
                             element: 'FlightDate'
                           },
                   additionalBinding: 
                        [ { localElement: 'CarrierID',
                            element:      'CarrierID',
                            usage:         #FILTER_AND_RESULT
                          },
                          { localElement: 'ConnectionID',
                            element:      'ConnectionID',
                            usage:        #RESULT
                          }
                        ]
                 }
               ]
      FlightDate,
      BookingId,
      @Consumption.valueHelpDefinition: 
               [ { entity: { name:    'D437_I_FlightClassVH',
                             element: 'FlightClass'
                           }
                 }
               ]

      FlightClass,
      PassengerName,
      CreatedAt,
      CreatedBy,
      ChangedAt,
      ChangedBy,
      LocalChangedAt,
      _Travel : redirected to parent Z09_C_Travel2

}
