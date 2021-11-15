/**
 *Submitted for verification at snowtrace.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Mission {
    address private owner;
    
    mapping(uint => uint) private troopDateMap;
    mapping(uint => uint) private bossLootMap;
    mapping(uint => uint[]) private claimableLootsMap;
    uint private bossFightCount = 35;
    uint private missionCount = 235;
    event BossFight(address _user, uint _planetNo, uint _bossFightId);

    constructor() {
        owner = msg.sender;
    }
    
    function bossStat() view public  returns (uint) {
        return bossFightCount;
    }
    
    function missionStat() view public  returns (uint) {
        return missionCount;
    }
    
    function missionIndex() view public  returns (uint) {
        uint time = block.timestamp;
        return ((time / 86400 )+3) % 11;
    }
    
    function bossIndex() view public  returns (uint) {
        uint time = block.timestamp + 259200;
        return ((time / 604800 )) % 3;
    }
    
    function  completeMission(uint mIndex, uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) payable onlyNovaxGame  public{
        require(missionIndex() == mIndex, "wrong mission index");
       
        Troop troop = Troop(0x7C347AF74c8DfAf629E4E4D3343d6E6A6ecACe80);
        uint attackPower = 0;
        for(uint i=0; i < soldierIds.length; i++){
            uint soldierId = soldierIds[i];
            uint troopType =  troop.typeOfItem(soldierId);
            require ((troopType >= 5) &&  (troopType <= 12) , "wrong troop type for soldiers");
            require(isTroopAvailable(soldierId), "troop not available");
            require(troop.ownerOf(soldierId) == owner, "wrong owner");
            attackPower += attackPowerOf(troopType);
        }
        for(uint i=0; i < spaceshipIds.length; i++){
            uint spaceshipId = spaceshipIds[i];
            uint troopType =  troop.typeOfItem(spaceshipId);
            require ((troopType >= 0) &&  (troopType <= 4) , "wrong troop type for spaceships");
            require(isTroopAvailable(spaceshipId), "troop not available");
            require(troop.ownerOf(spaceshipId) == owner, "wrong owner2");
            attackPower += attackPowerOf(troopType);
        }
        require(soldierLimitForMission(mIndex) >= soldierIds.length, "soldier limit fail");
        require(spaceshipLimitForMission(mIndex) >= spaceshipIds.length, "spaceship limit fail");
        require(minAttackPowerNeededForMission(mIndex) <= attackPower , "attack power fail");
        
        for(uint i=0; i < soldierIds.length; i++){
            uint soldierId = soldierIds[i];
            useTroop(soldierId);
        }
        for(uint i=0; i < spaceshipIds.length; i++){
            uint spaceshipId = spaceshipIds[i];
            useTroop(spaceshipId);
        }
        
        Loot loot = Loot(0x9ab7f0203cb23f7a6a33eD7AFA518B4a34e5E7C7);
        uint lootNo = loot.createItem(owner, lootTypeForMission(mIndex));
        missionCount++;
    }
    
    function attackPowerOf(uint troopId) public view returns(uint){
        //0: Light fighter
        //1: Heavy fighter
        //2: battleship
        //3: cruiser
        //4: destroyer
        //5: space soldier
        //6: space dog
        //7: heavy space soldier
        //8: plasma powered soldier
        //9: bomber
        //10: alien leader
        //11: samurai
        //12: doom warrior
        if(troopId == 0){  return 50; }
        else if(troopId == 1){  return 80; }
        else if(troopId == 2){  return 140; }
        else if(troopId == 3){  return 320; }
        else if(troopId == 4){  return 680; }
        else if(troopId == 5){  return 50; }
        else if(troopId == 6){  return 80; }
        else if(troopId == 7){  return 140; }
        else if(troopId == 8){  return 210; }
        else if(troopId == 9){  return 384; }
        else if(troopId == 10){  return 978; }
        else if(troopId == 11){  return 1078; }
        else if(troopId == 12){  return 1278; }
        return 0;
        
        
    }
    function isTroopAvailable(uint troopId) public view returns (bool){
        return (troopDateMap[troopId] == 0 || (block.timestamp - troopDateMap[troopId]) > 86400);
    }
    
    
    function useTroop(uint troopId) private {
        troopDateMap[troopId] = block.timestamp;
    }
    
    function lootTypeForMission( uint mIndex) public view returns (uint){
        
        require((mIndex >= 0) && mIndex < 11, "Wrong mission id");
        if(mIndex == 0){  return 0; }
        else if(mIndex == 1){  return 4; }
        else if(mIndex == 2){  return 5; }
        else if(mIndex == 3){  return 1; }
        else if(mIndex == 4){  return 6; }
        else if(mIndex == 5){  return 4; }
        else if(mIndex == 6){  return 2; }
        else if(mIndex == 7){  return 5; }
        else if(mIndex == 8){  return 7; }
        else if(mIndex == 9){  return 6; }
        else if(mIndex == 10){  return 3; }
        return 0;
    }
    
    function minAttackPowerNeededForMission( uint mIndex) public view returns (uint){
        
        require((mIndex >= 0) && mIndex < 11, "Wrong mission id");
        if(mIndex == 0){  return 100; }
        else if(mIndex == 1){  return 120; }
        else if(mIndex == 2){  return 340; }
        else if(mIndex == 3){  return 490; }
        else if(mIndex == 4){  return 650; }
        else if(mIndex == 5){  return 120; }
        else if(mIndex == 6){  return 1100; }
        else if(mIndex == 7){  return 340; }
        else if(mIndex == 8){  return 1400; }
        else if(mIndex == 9){  return 650; }
        else if(mIndex == 10){  return 1850; }
        return 0;
    }
    
    function soldierLimitForMission( uint mIndex) public view returns (uint){
        
        require((mIndex >= 0) && mIndex < 11, "Wrong mission id");
        if(mIndex == 0){  return 2; }
        else if(mIndex == 1){  return 2; }
        else if(mIndex == 2){  return 3; }
        else if(mIndex == 3){  return 3; }
        else if(mIndex == 4){  return 3; }
        else if(mIndex == 5){  return 2; }
        else if(mIndex == 6){  return 4; }
        else if(mIndex == 7){  return 3; }
        else if(mIndex == 8){  return 4; }
        else if(mIndex == 9){  return 3; }
        else if(mIndex == 10){  return 5; }
        return 0;
    }
    function spaceshipLimitForMission( uint mIndex) public view returns (uint){
        
        require((mIndex >= 0) && mIndex < 11, "Wrong mission id");
        if(mIndex == 0){        return 1; }
        else if(mIndex == 1){   return 1; }
        else if(mIndex == 2){   return 2; }
        else if(mIndex == 3){   return 2; }
        else if(mIndex == 4){   return 2; }
        else if(mIndex == 5){   return 1; }
        else if(mIndex == 6){   return 3; }
        else if(mIndex == 7){   return 2; }
        else if(mIndex == 8){   return 3; }
        else if(mIndex == 9){   return 2; }
        else if(mIndex == 10){  return 2; }
        return 0;
    }
    
    function totalCostOfMission( uint mIndex) public view returns (uint256[] memory){
        
        uint256[] memory resources = new uint[](3);
        
        require((mIndex >= 0) && mIndex < 11, "Wrong mission id");
        if(mIndex == 0){
            resources[0] = 412 ether;   resources[1] = 832 ether; resources[2] = 47 ether;
        }
        else if(mIndex == 1){
            resources[0] = 481 ether;   resources[1] = 910 ether;   resources[2] = 52 ether;
        }
        else if(mIndex == 2){
            resources[0] = 551 ether;   resources[1] = 980 ether;   resources[2] = 65 ether;
        }
        else if(mIndex == 3){
            resources[0] = 712 ether;   resources[1] = 1232 ether;  resources[2] = 92 ether;
        }
        else if(mIndex == 4){
            resources[0] = 1121 ether;  resources[1] = 1823 ether;  resources[2] = 141 ether;
        }
        else if(mIndex == 5){
            resources[0] = 475 ether;   resources[1] = 892 ether;   resources[2] = 49 ether;
        }
        else if(mIndex == 6){
            resources[0] = 1512 ether;  resources[1] = 2883 ether;  resources[2] = 295 ether;
        }
        else if(mIndex == 7){
            resources[0] = 541 ether;   resources[1] = 943 ether;   resources[2] = 68 ether;
        }
        else if(mIndex == 8){
            resources[0] = 2542 ether;  resources[1] = 5982 ether;  resources[2] = 290 ether;
        }
        else if(mIndex == 9){
            resources[0] = 1051 ether;  resources[1] = 1923 ether;  resources[2] = 149 ether;
        }
        else if(mIndex == 10){
            resources[0] = 2612 ether;  resources[1] = 6123 ether;  resources[2] = 312 ether;
        }

        return resources;
    }
    
    
    //Boss fights
    function  completeBossFight(uint mIndex, uint [] memory soldierIds, uint [] memory spaceshipIds, address owner, uint planetNo) payable onlyNovaxGame  public{
        require(bossIndex() == mIndex);
        
        Troop troop = Troop(0x7C347AF74c8DfAf629E4E4D3343d6E6A6ecACe80);
        uint attackPower = 0;
        for(uint i=0; i < soldierIds.length; i++){
            uint soldierId = soldierIds[i];
            uint troopType =  troop.typeOfItem(soldierId);
            require ((troopType >= 5) &&  (troopType <= 12) , "wrong troop type for soldiers");
            require(isTroopAvailable(soldierId), "troop not available");
            require(troop.ownerOf(soldierId) == owner, "wrong owner");
            attackPower += attackPowerOf(troopType);
        }
        for(uint i=0; i < spaceshipIds.length; i++){
            uint spaceshipId = spaceshipIds[i];
            uint troopType =  troop.typeOfItem(spaceshipId);
            require ((troopType >= 0) &&  (troopType <= 4) , "wrong troop type for spaceships");
            require(isTroopAvailable(spaceshipId), "troop not available");
            require(troop.ownerOf(spaceshipId) == owner, "wrong owner2");
            attackPower += attackPowerOf(troopType);
        }
        require(soldierLimitForBoss() >= soldierIds.length, "soldier limit fail");
        require(spaceshipLimitForBoss() >= spaceshipIds.length, "spaceship limit fail");
        require(minAttackPowerNeededForBoss(mIndex) <= attackPower, "attack power fail");
        
        for(uint i=0; i < soldierIds.length; i++){
            uint soldierId = soldierIds[i];
            useTroop(soldierId);
        }
        for(uint i=0; i < spaceshipIds.length; i++){
            uint spaceshipId = spaceshipIds[i];
            useTroop(spaceshipId);
        }
        uint[] memory list = claimableLootsMap[planetNo];
        
        claimableLootsMap[planetNo] = new uint[](list.length + 1);
        for(uint i=0; i < list.length; i++){
            claimableLootsMap[planetNo][i] = list[i];
        }
        claimableLootsMap[planetNo][list.length] = bossFightCount;

        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        emit BossFight(planet.ownerOf(planetNo), planetNo, bossFightCount);

        bossFightCount++;
    }
    
    function randomBossLoot(uint[] memory fightIds, uint randomValue) public onlyRandom payable {
        
        for(uint i=0 ; i < fightIds.length; i++){
            bossLootMap[fightIds[i]] = 1 + (uint256(keccak256(abi.encodePacked(fightIds[i], randomValue))) % 321);
        }
    }
    
    function isFightClaimable(uint fightId) public view returns (bool) {
        return (bossLootMap[fightId] != 0);
    }
    
    function claimableBossFightLootCount(uint planetNo) public view returns(uint){
        uint[] memory list = claimableLootsMap[planetNo];
        return list.length;
    }
    
    function claimBossLoot(uint planetNo) public payable {
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        require(msg.sender == planet.ownerOf(planetNo), "you are not the owner of this planet.");
        
        uint[] memory list = claimableLootsMap[planetNo];
        for(uint i=0 ; i < list.length; i++){
            uint fightNo = list[i];
            require(bossLootMap[fightNo] != 0);
        }
        
        for(uint i=0 ; i < list.length; i++){
            uint fightNo = list[i];
            uint lootId = bossLootMap[fightNo] - 1;
            uint lootType = 0;
            if(lootId >= 0 && lootId < 120){
                lootType = 0;
            }
            else if(lootId >= 120 && lootId < 180){
                lootType = 4;
            }
            else if(lootId >= 180 && lootId < 219){
                lootType = 5;
            }
            else if(lootId >= 219 && lootId < 249){
                lootType = 1;
            }
            else if(lootId >= 249 && lootId < 273){
                lootType = 6;
            }
            else if(lootId >= 273 && lootId < 291){
                lootType = 2;
            }
            else if(lootId >= 291 && lootId < 306){
                lootType = 5;
            }
            else if(lootId >= 276 && lootId < 318){
                lootType = 3;
            }
            else if(lootId >= 288 && lootId < 319){
                lootType = 8;
            }
            else if(lootId >= 289 && lootId < 320){
                lootType = 9;
            }
            else if(lootId >= 288 && lootId < 321){
                lootType = 10;
            }
            Loot loot = Loot(0x9ab7f0203cb23f7a6a33eD7AFA518B4a34e5E7C7);
            uint lootNo = loot.createItem(msg.sender, lootType);
        }
        claimableLootsMap[planetNo] = new uint[](0);
    }
    
    function minAttackPowerNeededForBoss( uint mIndex) public view returns (uint){
        require((mIndex >= 0) && mIndex < 3, "Wrong mission id");
        if(mIndex == 0){  return 1100; }
        else if(mIndex == 1){  return 1300; }
        else if(mIndex == 2){  return 1500; }
        return 0;
    }
    
    function soldierLimitForBoss() public view returns (uint){
        return 8;
    }
    function spaceshipLimitForBoss() public view returns (uint){
        return 3;
    }
    
    function totalCostOfBoss() public view returns (uint256[] memory){
        
        uint256[] memory resources = new uint[](3);
        resources[0] = 1500 ether; resources[1] = 300 ether; resources[2] = 250 ether;
        return resources;
    }
    
    
    
    modifier onlyNovaxGame() {

        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address gameAddress = novax.getParam3("game");

        require (gameAddress != address(0));
        require (msg.sender == gameAddress);
        _;
    }
    
    modifier onlyRandom() {

        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address randomAddress = novax.getParam3("random");

        require (randomAddress != address(0));
        require (msg.sender == randomAddress || msg.sender == owner);
        _;
    }
    
    modifier onlyOwner() {

        require (msg.sender == owner);
        _;
    }
   
}

contract Novax {
   
    function getParam3(string memory key) public view returns (address)  {}
   
}

contract Loot {
    function createItem(address  _to, uint _lootId)  payable public returns (uint){}
}

contract Troop {
    function typeOfItem(uint _itemNo) view public returns(uint){}
    function ownerOf(uint256 tokenId) public view  returns (address) {}
}

contract Planet {
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {}
    function createItem(address  _to) payable public returns (uint){}
    function ownerOf(uint256 tokenId) public view  returns (address) {}
    function getParam1(uint planetId, string memory key) public view returns (uint256)  { }
    function getParam2(uint planetId, string memory key) public view returns (string memory)  {  }
}