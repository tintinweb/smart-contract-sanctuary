/**
 *Submitted for verification at snowtrace.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract NovaxGame {
    address private owner;
    mapping(string => string []) private structureNeeds;
    uint structureStat = 108431;
    bool private pvpFlag = false;

    constructor() {
        owner = msg.sender;
    }
    
    function getStats() view public  returns (uint [] memory) {
        uint[] memory stats = new uint[](3);
        stats[0] = 8888;
        stats[1] = structureStat;
        return stats;
    }
    
    function resourceInfoForKey(uint resourceIndex, string memory resourceKey) view public returns (uint256){
        address rAddress = getNovaxAddress("resourceInfo");
        Resource rInfo = Resource(rAddress);
        return rInfo.resourceInfoForKey(resourceIndex,resourceKey) ;
    }
   
    function resourceAddress(uint rIndex) private view returns (address){
        if (rIndex == 0) {
            return address(0xE6eE049183B474ecf7704da3F6F555a1dCAF240F);
        }else if(rIndex == 1){
            return address(0x4C1057455747e3eE5871D374FdD77A304cE10989);
        }else {
            return address(0x70b4aE8eb7bd572Fc0eb244Cd8021066b3Ce7EE4);
        }
    }
   
    function hasEnoughResource(address userAddress, address rAddress, uint256 amount) private view returns (bool){
        IERC20 token = IERC20(rAddress);
        return (amount <= token.balanceOf(userAddress));
    }
   
    function transferResource(uint planetNo, uint resourceIndex, address userAddress, address rAddress, uint256 amount) private returns (bool){
        if(amount > 0){
            
            MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));

            IERC20 token = IERC20(rAddress);
            require(amount <= token.balanceOf(userAddress));
            token.burn(userAddress, amount);
            
            if(resourceIndex == 0) {
                uint256 currentAmount = getResourceAmount(0, planetNo);
                setter.setParam1(planetNo, "s-cache", currentAmount);
                setter.setParam1(planetNo, "s-timestamp", block.timestamp);
            }else if(resourceIndex == 1) {
                uint256 currentAmount = getResourceAmount(1, planetNo);
                setter.setParam1(planetNo, "m-cache", currentAmount);
                setter.setParam1(planetNo, "m-timestamp", block.timestamp);
            }else if(resourceIndex == 2) {
                uint256 currentAmount = getResourceAmount(2, planetNo);
                setter.setParam1(planetNo, "c-cache", currentAmount);
                setter.setParam1(planetNo, "c-timestamp", block.timestamp);
            }
        }
        return true;
    }

    function totalResourceOfPlanets(uint256[] memory ids) public view returns (uint256[] memory){
        uint256[] memory resources = new uint[](3);

        resources[0] = 0;
        resources[1] = 0;
        resources[2] = 0;
        
        for (uint i=0; i < ids.length; i++) {
            uint256 planetNo = ids[i];
            
            uint256 resource1v = getResourceAmount(0, planetNo);
            uint256 resource2v = getResourceAmount(1, planetNo);
            uint256 resource3v = getResourceAmount(2, planetNo);
            
            resources[0] = resources[0] + resource1v;
            resources[1] = resources[1] + resource2v;
            resources[2] = resources[2] + resource3v;
        }
        return resources;
    }

    
    function harvestAll(uint256[] memory ids) public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        
        MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));
        
        for (uint i=0; i < ids.length; i++) {
            uint256 planetNo = ids[i];
            require(msg.sender == planet.ownerOf(planetNo), "User is not the owner of the planet.");
        }
        
        uint256[] memory resources = totalResourceOfPlanets(ids);
        
        for (uint i=0; i < ids.length; i++) {
            uint256 planetNo = ids[i];
            
            uint256 structureTimestamp = planet.getParam1(planetNo, "s-timestamp");
            if(structureTimestamp < block.timestamp){
                setter.setParam1(planetNo,"s-timestamp", block.timestamp);
                setter.setParam1(planetNo,"s-cache", 0);
                setter.setParam1(planetNo,"m-timestamp", block.timestamp);
                setter.setParam1(planetNo,"m-cache", 0);
                setter.setParam1(planetNo,"c-timestamp", block.timestamp);
                setter.setParam1(planetNo,"c-cache", 0);
            }
        }
        IERC20 sToken = IERC20(resourceAddress(0));
        IERC20 mToken = IERC20(resourceAddress(1));
        IERC20 cToken = IERC20(resourceAddress(2));
        sToken.mint(msg.sender, resources[0]);
        mToken.mint(msg.sender, resources[1]);
        cToken.mint(msg.sender, resources[2]);
    }
    
    function totalCostOfLevelup( string[] memory structureIds,  uint256[] memory planetIds) public view returns (uint256[] memory){
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        for (uint i=0; i < planetIds.length; i++) {
            uint256 planetNo1 = planetIds[i];
            string memory structureId1 = structureIds[i];
            for (uint y=i; y < planetIds.length; y++) {
                uint256 planetNo2 = planetIds[y];
                string memory structureId2 = structureIds[y];
                if(i != y){
                    require(!((planetNo1 == planetNo2) && compareStrings(structureId1,structureId2)));
                }
            }
        }

        uint256[] memory resources = new uint[](3);
        resources[0] = 0;
        resources[1] = 0;
        resources[2] = 0;
        require((structureIds.length == planetIds.length), "Wrong params");
        if(structureIds.length == planetIds.length){
            for (uint i=0; i < planetIds.length; i++) {
                uint256 planetNo = planetIds[i];
                string memory structureId = structureIds[i];

                string memory key = string(abi.encodePacked(structureId, "-level"));
                uint currentLevel = planet.getParam1(planetNo, key);
                require(currentLevel < 15);
                
                string memory resourceKey = string(abi.encodePacked(structureId,  uintToString(currentLevel+1)));
                resources[0] += resourceInfoForKey(0, resourceKey);
                resources[1] += resourceInfoForKey(1, resourceKey);
                resources[2] += resourceInfoForKey(2, resourceKey);
            }
        }
        return resources;
    }
    
    function levelUpAll( string[] memory structureIds,  uint256[] memory planetIds) public{
        require((structureIds.length == planetIds.length), "Wrong params");

        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        
        for (uint i=0; i < planetIds.length; i++) {
            uint256 planetNo = planetIds[i];
            require(msg.sender == planet.ownerOf(planetNo), "User is not the owner of the planet.");
        }
        
        uint256[] memory totalResources = totalCostOfLevelup(structureIds, planetIds);
        require(validateEnoughResource(msg.sender, totalResources), "not enough resources");

        MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));
        
        for (uint i=0; i < planetIds.length; i++) {
            uint256 planetNo = planetIds[i];
            string memory structureId = structureIds[i];
            string memory key = string(abi.encodePacked(structureId, "-level"));
            uint currentLevel = planet.getParam1(planetNo, key);
            require(currentLevel < 15);
            string memory resourceKey = string(abi.encodePacked(structureId,  uintToString(currentLevel+1)));
            
            if(compareStrings(structureId,"i") || compareStrings(structureId,"a") || compareStrings(structureId,"f") || compareStrings(structureId,"r")){
                require(currentLevel == 0, "you already built it. ");
                setter.setParam1(planetNo, key, 1);
                setter.setParam1(planetNo, resourceKey, 1);
            }else{
                setter.setParam1(planetNo, key, currentLevel + 1);
                setter.setParam1(planetNo, resourceKey, 1);
                setter.setParam1(planetNo, "s-cache", getResourceAmount(0, planetNo));
                setter.setParam1(planetNo, "s-timestamp", block.timestamp);
                setter.setParam1(planetNo, "m-cache", getResourceAmount(1, planetNo));
                setter.setParam1(planetNo, "m-timestamp", block.timestamp);
                setter.setParam1(planetNo, "c-cache", getResourceAmount(2, planetNo));
                setter.setParam1(planetNo, "c-timestamp", block.timestamp);
            }
            
            
            structureStat += 1;
        }
        burnTokens(msg.sender, totalResources);
    }
    
    function burnTokens(address user, uint256[] memory tResources) private {
        IERC20 token0 = IERC20(resourceAddress(0));
        IERC20 token1 = IERC20(resourceAddress(1));
        IERC20 token2 = IERC20(resourceAddress(2));
        
        token0.burn(user, tResources[0]);
        token1.burn(user, tResources[1]);
        token2.burn(user, tResources[2]);
    }
    
    function  generateTroop(uint troopId, uint planetNo) payable public{
        address factoryAddress = getNovaxAddress("factory");
        Factory factory = Factory(factoryAddress);
        
        uint256[] memory totalResources = factory.totalCostOfTroop(troopId);
        require(validateEnoughResource(msg.sender, totalResources), "not enough resources");
        
        factory.generateTroop(troopId, planetNo, msg.sender);
        burnTokens(msg.sender, totalResources);
    }
    
    function placeTroop(uint planetNo, uint [] memory soldierIds, uint [] memory spaceshipIds) payable  public{
        require(getPvPFlag() == true);
        address warzoneAddress = getNovaxAddress("warzone");
        Warzone warzone = Warzone(warzoneAddress);

        uint256[] memory totalResources = warzone.totalResourceNeeded(soldierIds, spaceshipIds, msg.sender);
        require(validateEnoughResource(msg.sender, totalResources), "not enough resources");

        warzone.placeTroop(planetNo, soldierIds, spaceshipIds, msg.sender);
        //burn resources
        burnTokens(msg.sender, totalResources);
        //burn troops
        burnTroopsPr(soldierIds);
        burnTroopsPr(spaceshipIds);
    }
    
    function burnTroops(uint [] memory troopIds)  payable onlyWarzone public {
        burnTroopsPr(troopIds);
    }

    function burnTroopsPr(uint [] memory troopIds)  private {
        Troop troop = Troop(0x7C347AF74c8DfAf629E4E4D3343d6E6A6ecACe80);
        for(uint i=0; i < troopIds.length; i++){
            troop.burnItem(troopIds[i]);
        }
    }

    function burnToken(address user, uint256[] memory tResources) payable onlyWarzone public {
        burnTokens(user, tResources);
    }

    function mintToken(uint resourceIndex, uint256 amount , address user) payable onlyWarzone public {
        address rAddress = resourceAddress(resourceIndex);
        IERC20 token = IERC20(rAddress);
        token.mint(user, amount);
    }
    
    function  completeMission(uint mIndex, uint [] memory soldierIds, uint [] memory spaceshipIds, uint planetNo) payable public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        uint256 iLevel  = planet.getParam1(planetNo, "i-level"); 
        require(iLevel >= 1, "Need to build intelligence agency on your planet.");
        require(msg.sender == planet.ownerOf(planetNo), "you are not the owner of this planet.");
        
        uint256 lastMissionTime = planet.getParam1(planetNo, "mission-time");
        require((lastMissionTime == 0 || (block.timestamp - lastMissionTime) > 86400), "24 hours should pass after the last mission.");
        
        address missionAddress = getNovaxAddress("mission");
        Mission mission = Mission(missionAddress);
        
        uint256[] memory totalResources = mission.totalCostOfMission(mIndex);
        require(validateEnoughResource(msg.sender, totalResources), "not enough resources");
        
        mission.completeMission(mIndex, soldierIds, spaceshipIds, msg.sender);
        burnTokens(msg.sender, totalResources);
        MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));
        setter.setParam1(planetNo,"mission-time", block.timestamp);
    }

    function validateEnoughResource(address userAddress, uint256[] memory resourceInfo) private view returns(bool){
        if(hasEnoughResource(userAddress, resourceAddress(0), resourceInfo[0]) &&
            hasEnoughResource(userAddress, resourceAddress(0), resourceInfo[0]) &&
            hasEnoughResource(userAddress, resourceAddress(0), resourceInfo[0])){
            return true;
        }
        return false;
    }
    function  completeBossFight(uint mIndex, uint [] memory soldierIds, uint [] memory spaceshipIds, uint planetNo) payable public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        uint256 iLevel  = planet.getParam1(planetNo, "i-level"); 
        require(iLevel >= 1, "Need to build intelligence agency on your planet.");
        require(msg.sender == planet.ownerOf(planetNo), "you are not the owner of this planet.");
        
        uint256 lastMissionTime = planet.getParam1(planetNo, "boss-time");
        require((lastMissionTime == 0 || (block.timestamp - lastMissionTime) > 604800), "7 days should pass after the last boss fight.");
        
        address missionAddress = getNovaxAddress("mission");
        Mission mission = Mission(missionAddress);
        
        uint256[] memory totalResources = mission.totalCostOfBoss();
        require(validateEnoughResource(msg.sender, totalResources), "not enough resources");
        mission.completeBossFight(mIndex, soldierIds, spaceshipIds, msg.sender, planetNo);

        burnTokens(msg.sender, totalResources);
        
        MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));
        setter.setParam1(planetNo,"boss-time", block.timestamp);
    }
    

    function getResourceAmount(uint resourceIndex, uint planetNo) public view returns (uint256)  {
        address rAddress = getNovaxAddress("resourceInfo");
        Resource rInfo = Resource(rAddress);
        return rInfo.getResourceAmount(resourceIndex,planetNo) ;
    }
   
    function withdrawResource(uint resourceIndex, uint256 amount , uint planetNo)  public returns(bool) {
        uint256 currentAmount = getResourceAmount(resourceIndex, planetNo);
        require(currentAmount >= amount);
                
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        require(msg.sender == planet.ownerOf(planetNo));
        
        MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));
       
        address rAddress = resourceAddress(resourceIndex);
            IERC20 token = IERC20(rAddress);
            
        if (resourceIndex == 0){
            setter.setParam1(planetNo,"s-timestamp", block.timestamp);
            setter.setParam1(planetNo,"s-cache", (currentAmount - amount));
            token.mint(planet.ownerOf(planetNo), amount);
            return true;
        }else if (resourceIndex == 1){
            setter.setParam1(planetNo,"m-timestamp", block.timestamp);
            setter.setParam1(planetNo,"m-cache", (currentAmount - amount));
            token.mint(planet.ownerOf(planetNo), amount);
            return true;
        }else if (resourceIndex == 2){
            setter.setParam1(planetNo,"c-timestamp", block.timestamp);
            setter.setParam1(planetNo,"c-cache", (currentAmount - amount));
            token.mint(planet.ownerOf(planetNo), amount);
            return true;
        }
        return true;
    }
   
    function getNovaxAddress(string memory key) private view returns (address){
        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address add = novax.getParam3(key);
        return add;
    }
    
    
    function uintToString(uint v) private view returns (string memory str) {
        if(v == 0){ return "0";  }
        if(v == 1){ return "1";  }
        if(v == 2){ return "2";  }
        if(v == 3){ return "3";  }
        if(v == 4){ return "4";  }
        if(v == 5){ return "5";  }
        if(v == 6){ return "6";  }
        if(v == 7){ return "7";  }
        if(v == 8){ return "8";  }
        if(v == 9){ return "9";  }
        if(v == 10){ return "10";  }
        if(v == 11){ return "11";  }
        if(v == 12){ return "12";  }
        if(v == 13){ return "13";  }
        if(v == 14){ return "14";  }
        if(v == 15){ return "15";  }
        if(v == 16){ return "16";  }
        return "0";
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier onlyWarzone() {
        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address warzoneAddress = novax.getParam3("warzone");
        address gameAddress = novax.getParam3("game");
        require (warzoneAddress != address(0));
        require ((msg.sender == warzoneAddress ) || (msg.sender == gameAddress ));
        _;
    }

    function getPvPFlag() public view returns(bool){
        return pvpFlag;
    }

    function setPvPFlag(bool flag) onlyOwner public {
        pvpFlag = flag;
    }
   
    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}


contract Novax {
    function getParam3(string memory key) public view returns (address)  {}
}

contract Factory {
    function generateTroop(uint troopId, uint planetNo, address owner) payable  public{}
    function totalCostOfTroop( uint troopId) public view returns (uint256[] memory){}
}

contract Planet {
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function createItem(address  _to) payable public returns (uint){}
    function ownerOf(uint256 tokenId) public view  returns (address) {}
    function getParam1(uint planetId, string memory key) public view returns (uint256)  { }
    function getParam2(uint planetId, string memory key) public view returns (string memory)  {  }
}

contract MetadataSetter {
   function setParam1(uint planetNo, string memory key, uint256 value)  public{  }
   function setParam2(uint planetNo, string memory key, string memory value)  public{}
}

contract Resource {
    function resourceInfoForKey(uint resourceIndex, string memory resourceKey) view public returns (uint256){}
    function getResourceAmount(uint resourceIndex, uint planetNo) public view returns (uint256)  {}
}

contract Mission {
    function completeBossFight(uint mIndex, uint [] memory soldierIds, uint [] memory spaceshipIds, address owner, uint planetNo) payable  public{}
    function totalCostOfBoss() public view returns (uint256[] memory){}
    function completeMission(uint mIndex, uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) payable   public{}
    function totalCostOfMission( uint mIndex) public view returns (uint256[] memory){}
}

contract Warzone {
    function placeTroop(uint planetNo, uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) payable public{}
    function totalResourceNeeded(uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) view  public returns (uint256[] memory){}
    function totalAttackPower(uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) view  public returns (uint){}
}

contract Troop {
    function burnItem(uint256 tokenId) payable public {}
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function typeOfItem(uint _itemNo) view public returns(uint) {} 
    function ownerOf(uint256 tokenId) public view  returns (address) {}
}

interface IERC20 {
    function mint(address account, uint256 amount) external payable  returns(bool);
    function burn(address account, uint256 amount) external payable returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}