/**
 *Submitted for verification at snowtrace.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Warzone {
    address private owner;
    event PlaceTroop(address _user, uint _planetNo, uint _ap);
    event WarResult(uint indexed warId, address indexed _user, uint _planetNo, uint _ap1, uint _ap2, bool _won, uint256 _s, uint256 _m, uint256 _c);
    mapping(address => uint) private defAttackPowerMap;
    uint private warId = 0;

    constructor() {
        owner = msg.sender;
    }
    
    function warStat() view public returns(uint){
        return warId;
    }

    function  totalAttackPower(uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) view  public returns (uint){
            
        Troop troop = Troop(0x7C347AF74c8DfAf629E4E4D3343d6E6A6ecACe80);
        uint attackPower = 0;
        for(uint i=0; i < soldierIds.length; i++){
            uint soldierId = soldierIds[i];
            uint troopType =  troop.typeOfItem(soldierId);
            require ((troopType >= 5) &&  (troopType <= 12) , "wrong troop type for soldiers");
            require(troop.ownerOf(soldierId) == owner, "wrong owner");
            attackPower += attackPowerOf(troopType);
        }
        for(uint i=0; i < spaceshipIds.length; i++){
            uint spaceshipId = spaceshipIds[i];
            uint troopType =  troop.typeOfItem(spaceshipId);
            require ((troopType >= 0) &&  (troopType <= 4) , "wrong troop type for spaceships");
            require(troop.ownerOf(spaceshipId) == owner, "wrong owner2");
            attackPower += attackPowerOf(troopType);
        }
        return attackPower;
    }

    function  totalResourceNeeded(uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) view  public returns (uint256[] memory){
        uint ap = totalAttackPower(soldierIds, spaceshipIds,  owner);
        uint256 solarNeeded = (100 ether) * ap;
        uint256 metalNeeded = (200 ether) * ap;
        uint256 crystalNeeded = (10 ether) * ap;
        uint256[] memory resources = new uint[](3);
        resources[0] = solarNeeded ; resources[1] = metalNeeded ; resources[2] = crystalNeeded ;
        return resources;
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
    
    function placeTroop(uint planetNo, uint [] memory soldierIds, uint [] memory spaceshipIds, address owner) payable onlyNovaxGame  public{
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        require(owner == planet.ownerOf(planetNo), "you are not the owner of this planet.");
        
        uint ap = totalAttackPower(soldierIds, spaceshipIds,  owner);

        
        MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));

        uint256 warzoneSolar = planet.getParam1(planetNo, "warzoneSolar");
        uint256 warzoneMetal = planet.getParam1(planetNo, "warzoneMetal");
        uint256 warzoneCrystal = planet.getParam1(planetNo, "warzoneCrystal");
        uint256 warzoneAP = planet.getParam1(planetNo, "warzoneAP");

        setter.setParam1(planetNo, "warzoneSolar", warzoneSolar + ((100 ether) * ap));
        setter.setParam1(planetNo, "warzoneMetal", warzoneMetal + ((200 ether) * ap));
        setter.setParam1(planetNo, "warzoneCrystal", warzoneCrystal + ((10 ether) * ap));
        setter.setParam1(planetNo, "warzoneAP", warzoneAP + ap);      
        defAttackPowerMap[owner] = defAttackPowerMap[owner] + ap;
        emit PlaceTroop(owner, planetNo, ap);
  
    }

    function attackPlanet(uint defender, uint [] memory soldierIds, uint [] memory spaceshipIds) payable public returns(uint){
        MetadataSetter setter = MetadataSetter(getNovaxAddress("metadataSetter"));
        Troop troop = Troop(0x7C347AF74c8DfAf629E4E4D3343d6E6A6ecACe80);
        Planet planet = Planet(0x0C3b29321611736341609022C23E981AC56E7f96);
        NovaxGame game = NovaxGame(getNovaxAddress("game"));
        uint placedDefAP = defAttackPowerMap[msg.sender];
        uint attackerAP = totalAttackPower(soldierIds, spaceshipIds,  msg.sender);

        require(attackerAP <= placedDefAP, "Your total attack power should be lesser than the total defense attack power on your planets warzones.");

        uint256 warzoneSolar = planet.getParam1(defender, "warzoneSolar");
        uint256 warzoneMetal = planet.getParam1(defender, "warzoneMetal");
        uint256 warzoneCrystal = planet.getParam1(defender, "warzoneCrystal");
        uint256 warzoneAP = planet.getParam1(defender, "warzoneAP");

        require(((warzoneSolar > 0) || (warzoneMetal > 0) || (warzoneCrystal > 0) || (warzoneAP > 0) ), "Planet is not attackable");
        uint defendedPlanetNo = defender;
        uint[] memory soldierList = soldierIds;
        uint[] memory spaceshipList = spaceshipIds;
        if(attackerAP > warzoneAP){
            //Attacker wins
            setter.setParam1(defendedPlanetNo, "warzoneSolar", warzoneSolar / 2);
            setter.setParam1(defendedPlanetNo, "warzoneMetal", warzoneMetal / 2);
            setter.setParam1(defendedPlanetNo, "warzoneCrystal", warzoneCrystal / 2);
            setter.setParam1(defendedPlanetNo, "warzoneAP", warzoneAP / 2);      
            if(defAttackPowerMap[planet.ownerOf(defendedPlanetNo)] > (warzoneAP / 2)){
                defAttackPowerMap[planet.ownerOf(defendedPlanetNo)] = defAttackPowerMap[planet.ownerOf(defendedPlanetNo)] - (warzoneAP / 2);
            }

            game.mintToken(0, warzoneSolar / 2, msg.sender);
            game.mintToken(1, warzoneMetal / 2, msg.sender);
            game.mintToken(2, warzoneCrystal / 2, msg.sender);
            
            uint256 destroyedAP = 0;
            for(uint i=0; i < soldierList.length; i++){
                uint soldierId = soldierList[i];
                if(destroyedAP < warzoneAP){
                    uint troopType =  troop.typeOfItem(soldierId);
                    destroyedAP += attackPowerOf(troopType);
                    burnTroop(soldierId);
                }
            }
            for(uint i=0; i < spaceshipList.length; i++){
                uint spaceshipId = spaceshipList[i];
                if(destroyedAP < warzoneAP){
                    uint troopType =  troop.typeOfItem(spaceshipId);
                    destroyedAP += attackPowerOf(troopType);
                    burnTroop(spaceshipId);
                }
            }
            warId = warId + 1;
            emit WarResult(warId, msg.sender, defendedPlanetNo, destroyedAP, warzoneAP / 2, true, warzoneSolar / 2, warzoneMetal / 2, warzoneCrystal / 2);   
        }else{
            //Defender wins
            setter.setParam1(defendedPlanetNo, "warzoneAP", warzoneAP - attackerAP);      
            uint256 destroyedAP = 0;
            for(uint i=0; i < soldierList.length; i++){
                uint soldierId = soldierList[i];
                if(destroyedAP * 2 < attackerAP){
                    uint troopType =  troop.typeOfItem(soldierId);
                    destroyedAP += attackPowerOf(troopType);
                    burnTroop(soldierId);
                }
            }
            for(uint i=0; i < spaceshipList.length; i++){
                uint spaceshipId = spaceshipList[i];
                if(destroyedAP * 2 < attackerAP){
                    uint troopType =  troop.typeOfItem(spaceshipId);
                    destroyedAP += attackPowerOf(troopType);
                    burnTroop(spaceshipId);
                }
            }
            uint256 winnedSolar = (warzoneSolar * attackerAP) / warzoneAP;
            uint256 winnedMetal = (warzoneMetal * attackerAP) / warzoneAP;
            uint256 winnedCrystal = (warzoneCrystal * attackerAP) / warzoneAP;
            game.mintToken(0, winnedSolar / 2, msg.sender);
            game.mintToken(1, winnedMetal / 2, msg.sender);
            game.mintToken(2, winnedCrystal / 2, msg.sender);
            warId = warId + 1;
            uint attackerAttackPower = attackerAP;
            emit WarResult(warId, msg.sender, defendedPlanetNo, destroyedAP, attackerAttackPower, false, winnedSolar, winnedMetal, winnedCrystal);   

        }
        return warId;
    }

    function burnTroop(uint troopId) private {
        NovaxGame game = NovaxGame(getNovaxAddress("game"));
        uint[] memory troops = new uint[](1);
        troops[0] = troopId;
        game.burnTroops(troops);
    }
    function getNovaxAddress(string memory key) private view returns (address){
        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address add = novax.getParam3(key);
        return add;
    }
    
    
    function resourceAddress(uint rIndex) private view returns (address){
        if (rIndex == 0) {
            return address(0xE6eE049183B474ecf7704da3F6F555a1dCAF240F);
        }else if(rIndex == 1){
            return address(0x4C1057455747e3eE5871D374FdD77A304cE10989);
        }else if(rIndex == 2){
            return address(0x70b4aE8eb7bd572Fc0eb244Cd8021066b3Ce7EE4);
        }
        return address(0);
    }
   
    function hasEnoughResource(address userAddress, address rAddress, uint256 amount) private view returns (bool){
        IERC20 token = IERC20(rAddress);
        return (amount <= token.balanceOf(userAddress));
    }
    
    //setters
    function setOwner(address user) onlyOwner public{
        owner = user;
    }
    
    function getOwner() public view returns (address)  {
        return owner;
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
   
    function withdraw(uint amount) onlyOwner public returns(bool) {
        require(amount <= address(this).balance);
        payable(owner).transfer(amount);
        return true;

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
    
    modifier onlyNovaxGame() {

        Novax novax = Novax(0x7273A2B25B506cED8b60Eb3aA1eAE661a888b412);
        address gameAddress = novax.getParam3("game");

        require (gameAddress != address(0));
        require (msg.sender == gameAddress );
        _;
    }
   
}


contract Novax {
   
    function getParam3(string memory key) public view returns (address)  {}
   
}

contract Troop {
    function createItem(address  _to, uint _troopId) payable public returns (uint){}
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


contract MetadataSetter {
   function setParam1(uint planetNo, string memory key, uint256 value)  public{  }
   function setParam2(uint planetNo, string memory key, string memory value)  public{}

}

contract NovaxGame {
    function burnTroops(uint [] memory troopIds) payable public {  }
    function burnToken(address user, uint256[] memory tResources) payable  public {    }
    function mintToken(uint resourceIndex, uint256 amount , address user) payable  public { }
}


interface IERC20 {
    function mint(address account, uint256 amount) external payable  returns(bool);
    function burn(address account, uint256 amount) external payable returns(bool);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}