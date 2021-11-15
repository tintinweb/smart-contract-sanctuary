/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

contract Resource {
    mapping(string => uint256) private resource1;
    mapping(string => uint256) private resource2;
    mapping(string => uint256) private resource3;
    mapping(string => string []) private structureNeeds;

    constructor() {

        //Solar plant
        resource1["s2"]  = 4 ether;     resource2["s2"] = 7 ether;       
        resource1["s3"]  = 151 ether;   resource2["s3"] = 272 ether;  
        resource1["s4"]  = 756 ether;   resource2["s4"] = 1360 ether;
        resource1["s5"]  = 2102 ether;  resource2["s5"] = 3784 ether; 
        resource1["s6"]  = 3888 ether;  resource2["s6"] = 7384 ether;  
        resource1["s7"]  = 7732 ether;  resource2["s7"] = 14692 ether; 
        resource1["s8"]  = 12650 ether; resource2["s8"] = 24035 ether;   
        resource1["s9"]  = 24134 ether; resource2["s9"] = 45855 ether;
        resource1["s10"] = 32659 ether; resource2["s10"] = 62052 ether; 
        resource1["s11"] = 44064 ether; resource2["s11"] = 96940 ether;  
        resource1["s12"] = 60825 ether; resource2["s12"] = 133816 ether;  
        resource1["s13"] = 78795 ether; resource2["s13"] = 173352 ether; 
        resource1["s14"] = 95378 ether; resource2["s14"] = 209832 ether; 
        resource1["s15"] = 117331 ether; resource2["s15"] = 258128 ether; 
        
        //Metal mine
        resource1["m2"] = 3 ether;          resource2["m2"] = 8 ether;          
        resource1["m3"] = 141 ether;        resource2["m3"] = 291 ether;        
        resource1["m4"] = 712 ether;        resource2["m4"] = 1471 ether;       
        resource1["m5"] = 2041 ether;       resource2["m5"] = 3912 ether;       
        resource1["m6"] = 3712 ether;       resource2["m6"] = 7521 ether;       
        resource1["m7"] = 7612 ether;       resource2["m7"] = 16211 ether;      
        resource1["m8"] = 11650 ether;      resource2["m8"] = 26035 ether;      
        resource1["m9"] = 23134 ether;      resource2["m9"] = 49855 ether;      
        resource1["m10"] = 31659 ether;     resource2["m10"] = 65052 ether;     
        resource1["m11"] = 43014 ether;     resource2["m11"] = 99940 ether;     
        resource1["m12"] = 59825 ether;     resource2["m12"] = 143816 ether;    
        resource1["m13"] = 76795 ether;     resource2["m13"] = 183352 ether;    
        resource1["m14"] = 93378 ether;     resource2["m14"] = 219832 ether;    
        resource1["m15"] = 113331 ether;    resource2["m15"] = 278128 ether;    
        
        //Crystal mine
        resource1["c1"] = 1 ether;          resource2["c1"] = 5 ether;          resource3["c1"] = 0 ether;
        resource1["c2"] = 3 ether;          resource2["c2"] = 8 ether;          resource3["c2"] = 1 ether;
        resource1["c3"] = 141 ether;        resource2["c3"] = 291 ether;        resource3["c3"] = 15 ether;
        resource1["c4"] = 712 ether;        resource2["c4"] = 1471 ether;       resource3["c4"] = 75 ether;
        resource1["c5"] = 2041 ether;       resource2["c5"] = 3912 ether;       resource3["c5"] = 210 ether;
        resource1["c6"] = 3712 ether;       resource2["c6"] = 7521 ether;       resource3["c6"] = 387 ether;
        resource1["c7"] = 7612 ether;       resource2["c7"] = 16211 ether;      resource3["c7"] = 761 ether;
        resource1["c8"] = 11650 ether;      resource2["c8"] = 26035 ether;      resource3["c8"] = 1365 ether;
        resource1["c9"] = 23134 ether;      resource2["c9"] = 49855 ether;      resource3["c9"] = 2414 ether;
        resource1["c10"] = 31659 ether;     resource2["c10"] = 65052 ether;     resource3["c10"] = 3266 ether;
        resource1["c11"] = 43014 ether;     resource2["c11"] = 99940 ether;     resource3["c11"] = 4408 ether;
        resource1["c12"] = 59825 ether;     resource2["c12"] = 143816 ether;    resource3["c12"] = 6086 ether;
        resource1["c13"] = 76795 ether;     resource2["c13"] = 183352 ether;    resource3["c13"] = 7882 ether;
        resource1["c14"] = 93378 ether;     resource2["c14"] = 219832 ether;    resource3["c14"] = 9539 ether;
        resource1["c15"] = 113331 ether;    resource2["c15"] = 278128 ether;    resource3["c15"] = 11751 ether;
        
        
        //research center
        resource1["r1"]  = 9050 ether;     resource2["r1"] = 17010 ether;        resource3["r1"] = 1200 ether;
        //factory
        resource1["f1"]  = 8010 ether;     resource2["f1"] = 15080 ether;        resource3["f1"] = 850 ether;
        //academy
        resource1["a1"]  = 8040 ether;     resource2["a1"] = 15120 ether;        resource3["a1"] = 0 ether;
        //intelligence agency
        resource1["i1"]  = 7800 ether;     resource2["i1"] = 14010 ether;        resource3["i1"] = 0 ether;

    }
    
    
    function resourceInfoForKey(uint resourceIndex, string memory resourceKey) view public returns (uint256){

        if (resourceIndex == 0) {
            return resource1[resourceKey];
        }else if(resourceIndex == 1){
            return resource2[resourceKey];
        }else if(resourceIndex == 2){
            return resource3[resourceKey];
        }
    }
    
    function getResourceAmount(uint resourceIndex, uint planetNo) public view returns (uint256)  {
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        if (resourceIndex == 0){
            uint256 structureLevel = planet.getParam1(planetNo, "s-level");
            uint256 structureTimestamp = planet.getParam1(planetNo, "s-timestamp");
            if(structureTimestamp == 0){
                structureTimestamp = block.timestamp;
            }
            uint256 structureCache = planet.getParam1(planetNo, "s-cache");
            
            return structureCache + ((block.timestamp - structureTimestamp) * structureLevel * (0.001 ether));
        }else if (resourceIndex == 1){
            uint256 structureLevel = planet.getParam1(planetNo, "m-level");
            uint256 structureTimestamp = planet.getParam1(planetNo, "m-timestamp");
            if(structureTimestamp == 0){
                structureTimestamp = block.timestamp;
            }
            uint256 structureCache = planet.getParam1(planetNo, "m-cache");
            
            return structureCache + ((block.timestamp - structureTimestamp) * structureLevel * (0.002 ether));
        }else if (resourceIndex == 2){
            uint256 structureLevel = planet.getParam1(planetNo, "c-level");
            uint256 structureTimestamp = planet.getParam1(planetNo, "c-timestamp");
            if(structureTimestamp == 0){
                structureTimestamp = block.timestamp;
            }
            uint256 structureCache = planet.getParam1(planetNo, "c-cache");
            
            return structureCache + ((block.timestamp - structureTimestamp) * structureLevel * (0.0001 ether));
        }
        return 0;
    }
}

contract Planet {
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function createItem(address  _to) payable public returns (uint){}
    function ownerOf(uint256 tokenId) public view  returns (address) {}
    function getParam1(uint planetId, string memory key) public view returns (uint256)  { }
    function getParam2(uint planetId, string memory key) public view returns (string memory)  {  }
}