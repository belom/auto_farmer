# auto_farmer
a Minetest auto farming mod

Auto_Farmer will plant seeds and harvest the full grown crop.
If the tiers demand is met, the machine will start to plow the field and plant seeds from the seed box.

*Be aware that the machine will not clean the necessary space for the field
and that there is a water source to water the soil*

After the crop is fully grown, the machine will harvest the crop and place it in the inventory or push it through an attached tube.

Power connector is at the bottom and tube connectors (except tier 1) is on the top of the machine.

The working direction is marked by the hoe on the front of the machine. 

**Tier 1**
Demand: **500 LV**
Field size: 3 x 3
Output: Machine inventory only
Example setup:
S = Soil
F = Farmer
W = Water
C = Cable
T = Tube
TOP VIEW:     SIDE VIEW:		
  F              
 SSS          SSSF
 SWS             C
 SSS
 
**Tier 2**
Demand: **1,500 MV**
Field size: 5x5
Output: Tubes and machine inventory
Example setup:
S = Soil
F = Farmer
W = Water
C = Cable
T = Tube
TOP VIEW:     SIDE VIEW:		
   F                 T
 SSSSS          SSSSSF
 SSWSS               C
 SSSSS

**Tier 3**
Demand: **5000 HV**
Field size: 7x7
Output: Tubes and machine inventory
Example setup:
S = Soil
F = Farmer
W = Water
C = Cable
T = Tube
TOP VIEW:     SIDE VIEW:		
    F                    T
 SSSSSSS          SSSSSSSF
 SSSWSSS                 C
 SSSSSSS
