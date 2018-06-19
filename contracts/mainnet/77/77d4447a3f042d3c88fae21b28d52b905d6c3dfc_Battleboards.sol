pragma solidity ^0.4.17;

contract AccessControl {
    address public creatorAddress;
    uint16 public totalSeraphims = 0;
    mapping (address => bool) public seraphims;

    bool public isMaintenanceMode = true;
 
    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress);
        _;
    }

    modifier onlySERAPHIM() {
        require(seraphims[msg.sender] == true);
        _;
    }
    
    modifier isContractActive {
        require(!isMaintenanceMode);
        _;
    }
    
    // Constructor
    function AccessControl() public {
        creatorAddress = msg.sender;
    }
    

    function addSERAPHIM(address _newSeraphim) onlyCREATOR public {
        if (seraphims[_newSeraphim] == false) {
            seraphims[_newSeraphim] = true;
            totalSeraphims += 1;
        }
    }
    
    function removeSERAPHIM(address _oldSeraphim) onlyCREATOR public {
        if (seraphims[_oldSeraphim] == true) {
            seraphims[_oldSeraphim] = false;
            totalSeraphims -= 1;
        }
    }

    function updateMaintenanceMode(bool _isMaintaining) onlyCREATOR public {
        isMaintenanceMode = _isMaintaining;
    }

  
} 

contract SafeMath {
    function safeAdd(uint x, uint y) pure internal returns(uint) {
      uint z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint x, uint y) pure internal returns(uint) {
      assert(x >= y);
      uint z = x - y;
      return z;
    }

    function safeMult(uint x, uint y) pure internal returns(uint) {
      uint z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    
     function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

    function getRandomNumber(uint16 maxRandom, uint8 min, address privateAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(privateAddress);
        return uint8(genNum % (maxRandom - min + 1)+min);
    }
}

contract Enums {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_OWNER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum AngelAura { 
        Blue, 
        Yellow, 
        Purple, 
        Orange, 
        Red, 
        Green 
    }
}

contract IAngelCardData is AccessControl, Enums {
    uint8 public totalAngelCardSeries;
    uint64 public totalAngels;

    
    // write
    // angels
    function createAngelCardSeries(uint8 _angelCardSeriesId, uint _basePrice,  uint64 _maxTotal, uint8 _baseAura, uint16 _baseBattlePower, uint64 _liveTime) onlyCREATOR external returns(uint8);
    function updateAngelCardSeries(uint8 _angelCardSeriesId, uint64 _newPrice, uint64 _newMaxTotal) onlyCREATOR external;
    function setAngel(uint8 _angelCardSeriesId, address _owner, uint _price, uint16 _battlePower) onlySERAPHIM external returns(uint64);
    function addToAngelExperienceLevel(uint64 _angelId, uint _value) onlySERAPHIM external;
    function setAngelLastBattleTime(uint64 _angelId) onlySERAPHIM external;
    function setAngelLastVsBattleTime(uint64 _angelId) onlySERAPHIM external;
    function setLastBattleResult(uint64 _angelId, uint16 _value) onlySERAPHIM external;
    function addAngelIdMapping(address _owner, uint64 _angelId) private;
    function transferAngel(address _from, address _to, uint64 _angelId) onlySERAPHIM public returns(ResultCode);
    function ownerAngelTransfer (address _to, uint64 _angelId)  public;
    function updateAngelLock (uint64 _angelId, bool newValue) public;
    function removeCreator() onlyCREATOR external;

    // read
    function getAngelCardSeries(uint8 _angelCardSeriesId) constant public returns(uint8 angelCardSeriesId, uint64 currentAngelTotal, uint basePrice, uint64 maxAngelTotal, uint8 baseAura, uint baseBattlePower, uint64 lastSellTime, uint64 liveTime);
    function getAngel(uint64 _angelId) constant public returns(uint64 angelId, uint8 angelCardSeriesId, uint16 battlePower, uint8 aura, uint16 experience, uint price, uint64 createdTime, uint64 lastBattleTime, uint64 lastVsBattleTime, uint16 lastBattleResult, address owner);
    function getOwnerAngelCount(address _owner) constant public returns(uint);
    function getAngelByIndex(address _owner, uint _index) constant public returns(uint64);
    function getTotalAngelCardSeries() constant public returns (uint8);
    function getTotalAngels() constant public returns (uint64);
    function getAngelLockStatus(uint64 _angelId) constant public returns (bool);
}
contract IPetCardData is AccessControl, Enums {
    uint8 public totalPetCardSeries;    
    uint64 public totalPets;
    
    // write
    function createPetCardSeries(uint8 _petCardSeriesId, uint32 _maxTotal) onlyCREATOR public returns(uint8);
    function setPet(uint8 _petCardSeriesId, address _owner, string _name, uint8 _luck, uint16 _auraRed, uint16 _auraYellow, uint16 _auraBlue) onlySERAPHIM external returns(uint64);
    function setPetAuras(uint64 _petId, uint8 _auraRed, uint8 _auraBlue, uint8 _auraYellow) onlySERAPHIM external;
    function setPetLastTrainingTime(uint64 _petId) onlySERAPHIM external;
    function setPetLastBreedingTime(uint64 _petId) onlySERAPHIM external;
    function addPetIdMapping(address _owner, uint64 _petId) private;
    function transferPet(address _from, address _to, uint64 _petId) onlySERAPHIM public returns(ResultCode);
    function ownerPetTransfer (address _to, uint64 _petId)  public;
    function setPetName(string _name, uint64 _petId) public;

    // read
    function getPetCardSeries(uint8 _petCardSeriesId) constant public returns(uint8 petCardSeriesId, uint32 currentPetTotal, uint32 maxPetTotal);
    function getPet(uint _petId) constant public returns(uint petId, uint8 petCardSeriesId, string name, uint8 luck, uint16 auraRed, uint16 auraBlue, uint16 auraYellow, uint64 lastTrainingTime, uint64 lastBreedingTime, address owner);
    function getOwnerPetCount(address _owner) constant public returns(uint);
    function getPetByIndex(address _owner, uint _index) constant public returns(uint);
    function getTotalPetCardSeries() constant public returns (uint8);
    function getTotalPets() constant public returns (uint);
}

contract IMedalData is AccessControl {
  
    modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }
   
function totalSupply() public view returns (uint256);
function setMaxTokenNumbers()  onlyCREATOR external;
function balanceOf(address _owner) public view returns (uint256);
function tokensOf(address _owner) public view returns (uint256[]) ;
function ownerOf(uint256 _tokenId) public view returns (address);
function approvedFor(uint256 _tokenId) public view returns (address) ;
function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId);
function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId);
function takeOwnership(uint256 _tokenId) public;
function _createMedal(address _to, uint8 _seriesID) onlySERAPHIM public ;
function getCurrentTokensByType(uint32 _seriesID) public constant returns (uint32);
function getMedalType (uint256 _tokenId) public constant returns (uint8);
function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) external;
function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) ;
function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal;
function clearApproval(address _owner, uint256 _tokenId) private;
function addToken(address _to, uint256 _tokenId) private ;
function removeToken(address _from, uint256 _tokenId) private;
}

contract IBattleboardData is AccessControl  {

  

      // write functions
  
function createBattleboard(uint prize, uint8 restrictions) onlySERAPHIM external returns (uint16);
function killMonster(uint16 battleboardId, uint8 monsterId)  onlySERAPHIM external;
function createNullTile(uint16 _battleboardId) private ;
function createTile(uint16 _battleboardId, uint8 _tileType, uint8 _value, uint8 _position, uint32 _hp, uint16 _petPower, uint64 _angelId, uint64 _petId, address _owner, uint8 _team) onlySERAPHIM external  returns (uint8);
function killTile(uint16 battleboardId, uint8 tileId) onlySERAPHIM external ;
function addTeamtoBoard(uint16 battleboardId, address owner, uint8 team) onlySERAPHIM external;
function setTilePosition (uint16 battleboardId, uint8 tileId, uint8 _positionTo) onlySERAPHIM public ;
function setTileHp(uint16 battleboardId, uint8 tileId, uint32 _hp) onlySERAPHIM external ;
function addMedalBurned(uint16 battleboardId) onlySERAPHIM external ;
function setLastMoveTime(uint16 battleboardId) onlySERAPHIM external ;
function iterateTurn(uint16 battleboardId) onlySERAPHIM external ;
function killBoard(uint16 battleboardId) onlySERAPHIM external ;
function clearAngelsFromBoard(uint16 battleboardId) private;
//Read functions
     
function getTileHp(uint16 battleboardId, uint8 tileId) constant external returns (uint32) ;
function getMedalsBurned(uint16 battleboardId) constant external returns (uint8) ;
function getTeam(uint16 battleboardId, uint8 tileId) constant external returns (uint8) ;
function getMaxFreeTeams() constant public returns (uint8);
function getBarrierNum(uint16 battleboardId) public constant returns (uint8) ;
function getTileFromBattleboard(uint16 battleboardId, uint8 tileId) public constant returns (uint8 tileType, uint8 value, uint8 id, uint8 position, uint32 hp, uint16 petPower, uint64 angelId, uint64 petId, bool isLive, address owner)   ;
function getTileIDByOwner(uint16 battleboardId, address _owner) constant public returns (uint8) ;
function getPetbyTileId( uint16 battleboardId, uint8 tileId) constant public returns (uint64) ;
function getOwner (uint16 battleboardId, uint8 team,  uint8 ownerNumber) constant external returns (address);
function getTileIDbyPosition(uint16 battleboardId, uint8 position) public constant returns (uint8) ;
function getPositionFromBattleboard(uint16 battleboardId, uint8 _position) public constant returns (uint8 tileType, uint8 value, uint8 id, uint8 position, uint32 hp, uint32 petPower, uint64 angelId, uint64 petId, bool isLive)  ;
function getBattleboard(uint16 id) public constant returns (uint8 turn, bool isLive, uint prize, uint8 numTeams, uint8 numTiles, uint8 createdBarriers, uint8 restrictions, uint lastMoveTime, uint8 numTeams1, uint8 numTeams2, uint8 monster1, uint8 monster2) ;
function isBattleboardLive(uint16 battleboardId) constant public returns (bool);
function isTileLive(uint16 battleboardId, uint8 tileId) constant  external returns (bool) ;
function getLastMoveTime(uint16 battleboardId) constant public returns (uint) ;
function getNumTilesFromBoard (uint16 _battleboardId) constant public returns (uint8) ; 
function angelOnBattleboards(uint64 angelID) external constant returns (bool) ;
function getTurn(uint16 battleboardId) constant public returns (address) ;
function getNumTeams(uint16 battleboardId, uint8 team) public constant returns (uint8);
function getMonsters(uint16 BattleboardId) external constant returns (uint8 monster1, uint8 monster2) ;
function getTotalBattleboards() public constant returns (uint16) ;
  
        
 
   
}


contract Battleboards is AccessControl, SafeMath  {

    /*** DATA TYPES ***/
    address public angelCardDataContract = 0x6D2E76213615925c5fc436565B5ee788Ee0E86DC;
    address public petCardDataContract = 0xB340686da996b8B3d486b4D27E38E38500A9E926;
    address public medalDataContract =  0x33A104dCBEd81961701900c06fD14587C908EAa3;
    address public battleboardDataContract =0xE60fC4632bD6713E923FE93F8c244635E6d5009e;

     // events
     event EventMonsterStrike(uint16 battleboardId, uint64 angel, uint16 amount);
     event EventBarrier(uint16 battleboardId,uint64 angelId, uint8 color, uint8 damage);
     event EventBattleResult(uint16 battleboardId, uint8 tile1Id, uint8 tile2Id, bool angel1win);
    
    
    uint8 public delayHours = 12;
    uint16 public petHpThreshold = 250;
    uint16 public maxMonsterHit = 200;
    uint16 public minMonsterHit = 50;
         
      struct Tile {
        uint8 tileType;
        uint8 value;
        uint8 id;
        uint8 position;
        uint32 hp;
        uint32 petPower;
        uint64 angelId;
        uint64 petId;
        bool isLive;
        address owner;
        
    }
    
    
    
    
    //Aura Boosts
    // Red - Burning Strike - + 10 battle power  
    // Green - Healing Light - 20% chance to heal 75 hp each battle
    //Yellow - Guiding Path - 5 hp recovered each turn.
    //Purple - Uncontroled Fury - 10% chance for sudden kill 
    //Orange - Radiant Power - +100 max hp on joining board. 
    //Blue - Friend to all - immunity from monster attacks 
    
      
          // Utility Functions
    function DataContacts(address _angelCardDataContract, address _petCardDataContract,  address _medalDataContract, address _battleboardDataContract) onlyCREATOR external {
        angelCardDataContract = _angelCardDataContract;
        petCardDataContract = _petCardDataContract;
        medalDataContract = _medalDataContract;
        battleboardDataContract = _battleboardDataContract;
    }
    
    function setVariables(uint8 _delayHours, uint16 _petHpThreshold,  uint16 _maxMonsterHit, uint16 _minMonsterHit) onlyCREATOR external {
        delayHours = _delayHours;
        petHpThreshold = _petHpThreshold;
        maxMonsterHit = _maxMonsterHit;
        minMonsterHit = _minMonsterHit;
        
    }
      

      
    
        function removeDeadTurns(uint16 battleboardId) private {
            //This function iterates through turns of players whose tiles may already be dead 
            IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
            uint8 oldTurnTileID;
            for (uint8 i = 0; i<6; i++) {
            oldTurnTileID = battleboardData.getTileIDByOwner(battleboardId, battleboardData.getTurn(battleboardId));
            if (battleboardData.isTileLive(battleboardId, oldTurnTileID) == false) {battleboardData.iterateTurn(battleboardId);}
            else {i=9;} //break loop
            }
        }
    
       function move(uint16 battleboardId, uint8 tileId, uint8 positionTo) external {
           //Can&#39;t move off the board
           if ((positionTo <= 0) || (positionTo >64)) {revert();}
           IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
           
           //if it&#39;s not your turn. 
           if (msg.sender != battleboardData.getTurn(battleboardId)) {
               //first check to see if the team whose turn it is is dead.
              removeDeadTurns(battleboardId);
              if (msg.sender != battleboardData.getTurn(battleboardId)) {
                  //if it&#39;s still not your turn, revert if it&#39;s also not past the real turn&#39;s delay time. 
               if  (now  < battleboardData.getLastMoveTime(battleboardId) + (3600* delayHours)) {revert();}
              }
           }
           Tile memory tile;
            //get the tile to be moved. 
           (tile.tileType, tile.value ,, tile.position, tile.hp,,,, tile.isLive,tile.owner) = battleboardData.getTileFromBattleboard(battleboardId, tileId) ;
           //first see if the move is legal
           if (canMove(battleboardId, tile.position, positionTo) == false) {revert();}
           
           //Regardless of if the ower moves its tile normally or if someone else moves it, it has to move on its turn. 
           if (battleboardData.getTurn(battleboardId) != tile.owner) {revert();}
           
           //can&#39;t move if your tile isn&#39;t live. 
           if (tile.isLive == false) {revert();}
           
           
            //Tile TYPES
    // 0 - Empty Space
    // 1 - Team (Angel + Pet)
    // 3 - Red Barrier (red is hurt)
    // 4 - Yellow barrier (yellow is hurt)
    // 5 - Blue barrier (blue is hurt)
    // 6 - Exp Boost (permanent)
    // 7 - HP boost (temp)
    // 8 - Eth boost
    // 9 - Warp
    // 10 - Medal
    // 11 - Pet permanent Aura boost random color
    
           battleboardData.iterateTurn(battleboardId);
           battleboardData.setLastMoveTime(battleboardId);
           
           //Tile 2 is the tile that the angel team will interact with. 
           Tile memory tile2;
            tile2.id = battleboardData.getTileIDbyPosition(battleboardId, positionTo);
           
          (tile2.tileType, tile2.value ,,,,, tile2.angelId, tile2.petId, tile2.isLive,) = battleboardData.getTileFromBattleboard(battleboardId, tile2.id) ;
           
           if ((tile2.tileType == 0) || (tile2.isLive == false)) {
               //Empty Space
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
           }
           if (tile2.isLive == true) {
            if (tile2.tileType == 1) {
                if (battleboardData.getTeam(battleboardId, tileId) == battleboardData.getTeam(battleboardId, tile2.id)) {revert();}
               //Fight Team
               if (fightTeams(battleboardId, tileId, tile2.id) == true) {
                   //challenger won. 
                   battleboardData.setTilePosition(battleboardId,tileId, positionTo);
                   battleboardData.killTile(battleboardId, tile2.id);
                   EventBattleResult(battleboardId, tileId, tile2.id, true);
               }
               else {battleboardData.killTile(battleboardId, tileId);
                   EventBattleResult(battleboardId, tileId, tile2.id, false);
               } //challenger lost
              
           }
          
             if (tile2.tileType == 3) {
               //Red barrier
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
               if (isVulnerable (tile.angelId,1) == true) {
                    if (tile.hp > tile2.value) {battleboardData.setTileHp(battleboardId, tileId, (tile.hp - tile2.value));}
                    else {battleboardData.killTile(battleboardId, tileId);}
               }
               EventBarrier(battleboardId, tile.angelId,3, tile2.value);
               
           }
             if (tile2.tileType == 4) {
               //Yellow barrier
             battleboardData.setTilePosition(battleboardId,tileId, positionTo);
              if (isVulnerable (tile.angelId,2) == true) {
                    if (tile.hp > tile2.value) {battleboardData.setTileHp(battleboardId, tileId, (tile.hp - tile2.value));}
                    else {battleboardData.killTile(battleboardId, tileId);}
                    
               }
               EventBarrier(battleboardId, tile.angelId,4, tile2.value);
           }
             if (tile2.tileType == 5) {
               //Blue barrier
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
                if (isVulnerable (tile.angelId,3) == true) {
                    if (tile.hp > tile2.value) {battleboardData.setTileHp(battleboardId, tileId, (tile.hp - tile2.value));}
                    else {battleboardData.killTile(battleboardId, tileId);}
               }
               EventBarrier(battleboardId, tile.angelId,5, tile2.value);
           }
             if (tile2.tileType == 6) {
               //Exp boost
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
               IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
               angelCardData.addToAngelExperienceLevel(tile.angelId,tile2.value);
               battleboardData.killTile(battleboardId,tile2.id);
               
           }
             if (tile2.tileType == 7) {
               //HP boost
               battleboardData.setTileHp(battleboardId,tileId, tile.hp+ tile2.value);
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
               battleboardData.killTile(battleboardId,tile2.id);
           }
             if (tile2.tileType == 8){
               //ETH Boost - to be used only in paid boards. 
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
               battleboardData.killTile(battleboardId,tile2.id);
           }
             if (tile2.tileType ==9) {
               //Warp tile
               if  (battleboardData.getTileIDbyPosition(battleboardId, tile2.value) == 0) {battleboardData.setTilePosition(battleboardId,tileId, tile2.value);}
               //check if warping directly onto another tile
               else {battleboardData.setTilePosition(battleboardId,tileId, positionTo);}
               //if warping directly onto another tile, just stay at the warp tile position. 
           }
             if (tile2.tileType ==10){
               //Medal
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
               IMedalData medalData = IMedalData(medalDataContract);
               medalData._createMedal(tile.owner,uint8(tile2.value));
               battleboardData.killTile(battleboardId,tile2.id);
           }
            if (tile2.tileType==11) {
               //Pet Aura Boost
               battleboardData.setTilePosition(battleboardId,tileId, positionTo);
               randomPetAuraBoost(tile.petId,tile2.value);
               battleboardData.killTile(battleboardId,tile2.id);
            }
            
           }
            //check if yellow HP Boost
            if (getAuraColor(tile.angelId) == 1) {battleboardData.setTileHp(battleboardId,tileId, tile.hp+ 5);}
            
            //check if new position is vulnerable to monster attack. 
            checkMonsterAttack(battleboardId,tileId,positionTo);
            
       }
       
       function checkMonsterAttack(uint16 battleboardId, uint8 tileId, uint8 position) private  {
            IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
           //get the monster locations
           uint8 m1;
           uint8 m2;
           (m1,m2) = battleboardData.getMonsters(battleboardId);
           //If a monster is within 2 spots it will automatically attack. 
           if ((position == m1) || (position == m1 +1) || (position == m1 +2) || (position == m1 +8) || (position == m1 +16) || (position == m1 - 1) || (position == m1 -2) || (position == m1 -8) || (position == m1 -16)) {
                if (m1 != 0) {
               fightMonster(battleboardId, tileId, 1);
                }
           }
           
            if ((position == m2) || (position == m2 +1) || (position == m2 +2) || (position == m2 +8) || (position == m2 +16) || (position == m2 -1) || (position == m2 -2) || (position == m2 -8) || (position == m2 -16)) {
                 if (m2 != 0) {
               fightMonster(battleboardId, tileId, 2);
                 }
           }
           
       }
    
       function getAngelInfoByTile (uint16 battleboardId, uint8 tileId) public constant returns (uint16 bp, uint8 aura) {
             IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
             uint64 angelId;
            (, ,,,,,angelId,,,) = battleboardData.getTileFromBattleboard(battleboardId, tileId);
           IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
           (,,bp,aura,,,,,,,) = angelCardData.getAngel(angelId);
           return;
       }
       
       function getFastest(uint16 battleboardId, uint8 tile1Id, uint8 tile2Id) public constant returns (bool) {
          IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
           uint8 speed1;
           uint8 speed2;
              (, speed1,,,,,,,,) = battleboardData.getTileFromBattleboard(battleboardId, tile1Id);
            (, speed2,,,, ,,,,) = battleboardData.getTileFromBattleboard(battleboardId, tile2Id);
            if (speed1 >= speed2) return true;
            return false;
           
       }
       function fightTeams(uint16 battleboardId, uint8 tile1Id, uint8 tile2Id) private returns (bool) {
           //True return means that team 1 won, false return means team 2 won. 
           
           //First get the parameters. 
           IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
        
           uint32 hp1;
           uint32 hp2;
    
           uint16 petPower1;
           uint16 petPower2;
           (,,,,hp1, petPower1,,,,) = battleboardData.getTileFromBattleboard(battleboardId, tile1Id);
           (,,,,hp2, petPower2,,,,) = battleboardData.getTileFromBattleboard(battleboardId, tile2Id);
           
          uint16 angel1BP;
          uint16 angel2BP;
          uint8 angel1aura;
          uint8 angel2aura;
          
         (angel1BP, angel1aura) = getAngelInfoByTile(battleboardId, tile1Id);
         (angel2BP, angel2aura) = getAngelInfoByTile(battleboardId, tile2Id);
        
        
        //If red aura, boost battle power
        if (angel1aura == 4) {angel1BP += 10;}
        if (angel2aura == 4) {angel2BP += 10;}
        
        //if purple aura, 10% chance of sudden kill
        if ((angel1aura == 2) && (getRandomNumber(100,0,msg.sender) <10)) {return true;}
        if ((angel2aura == 2) && (getRandomNumber(100,0,msg.sender) <10)) {return false;}
        
        
        //if green aura, 20% chance of +75 hp
        if ((angel1aura == 5) && (getRandomNumber(100,0,msg.sender) <20)) {hp1 += 75;}
        if ((angel2aura == 5) && (getRandomNumber(100,0,msg.sender) <20)) {hp2 +=75;}
        
        
           uint16 strike;
           
           //attacker (team 1) gets the first strike.
           //see if strike will be angel and pet or just angel. 
           strike = Strike(angel1BP,hp1,petPower1,1);
           if (hp2 > strike) {hp2 = hp2 - strike;}
           else {return true;}
           
           //defender gets the second strike if still alive.  
           strike = Strike(angel2BP,hp2,petPower2,2);
           if (hp1 > strike) {hp1 = hp1 - strike;}
           else {
               battleboardData.setTileHp(battleboardId, tile2Id, hp2);
               return false;}
           
        // second round (if necessary)
        
        if (getFastest(battleboardId, tile1Id, tile2Id)==true) {
            if (getRandomNumber(100,0,2) > 30) {
                //team 1 attacks first. 
                   strike = Strike(angel1BP,hp1,petPower1,3);
                   if (hp2 > strike) {hp2 = hp2 - strike;}
                   else {
                       battleboardData.setTileHp(battleboardId, tile1Id, hp1);
                       return true;}
            }
            else {
            //team 2 attacks first    
            strike = Strike(angel2BP,hp2,petPower2,4);
           if (hp1 > strike) {hp1 = hp1 - strike;}
           else {
           battleboardData.setTileHp(battleboardId, tile2Id, hp2);
           return false;}
        }
        }
        if (getFastest(battleboardId, tile1Id, tile2Id) == false) {
               if (getRandomNumber(100,0,2) >70) {
                //team 1 attacks first. 
                   strike = Strike(angel1BP,hp1,petPower1,5);
                   if (hp2 > strike) {hp2 = hp2 - strike;}
                   else {
                       battleboardData.setTileHp(battleboardId, tile1Id, hp1);
                       return true;}
                 }
            else {
            //team 2 attacks first    
            strike = Strike(angel2BP,hp2,petPower2,6);
           if (hp1 > strike) {hp1 = hp1 - strike;}
           else {
           battleboardData.setTileHp(battleboardId, tile2Id, hp2);
           return false;}
            }
           }
           
             // third round (if necessary)
        
        if (getFastest(battleboardId, tile1Id, tile2Id)==true) {
            if (getRandomNumber(100,0,2) > 30) {
                //team 1 attacks first. 
                   strike = Strike(angel1BP,hp1,petPower1,7);
                   if (hp2 > strike) {hp2 = hp2 - strike;}
                   else {
                       battleboardData.setTileHp(battleboardId, tile1Id, hp1);
                       return true;}
            }
        }
            else {
            //team 2 attacks first    
            strike = Strike(angel2BP,hp2,petPower2,8);
           if (hp1 > strike) {hp1 = hp1 - strike;}
           else {battleboardData.setTileHp(battleboardId, tile2Id, hp2);
               return false;}
        }
        if (getFastest(battleboardId, tile1Id, tile2Id) == false) {
               if (getRandomNumber(100,0,2) >70) {
                //team 1 attacks first. 
                   strike = Strike(angel1BP,hp1,petPower1,9);
                   if (hp2 > strike) {hp2 = hp2 - strike;}
                   else {
                       battleboardData.setTileHp(battleboardId, tile1Id, hp1);
                       return true;}
                 }
            else {
            //team 2 attacks first    
            strike = Strike(angel2BP,hp2,petPower2,10);
           if (hp1 > strike) {hp1 = hp1 - strike;}
           else {
               battleboardData.setTileHp(battleboardId, tile2Id, hp2);
               return false;}
            }
           }
          
          if (hp1 > hp2) {
              battleboardData.setTileHp(battleboardId, tile1Id, hp1-hp2);
              return true;
          }
          if (hp1 < hp2) {
              battleboardData.setTileHp(battleboardId, tile2Id, hp2-hp1);
              return false;
          }
            if (hp1 == hp2) {
              battleboardData.setTileHp(battleboardId, tile1Id, 1);
              return true;
          }
        //if these titans are still left after 3 rounds, the winner is the one with the most HP. 
        //The loser&#39;s HP goes to 0 and the winner&#39;s HP is reduced by the  losers. In the unlikely event of a tie, the winner gets 1 hp. 
        
        }
        function Strike(uint16 bp, uint32 hp, uint16 petPower, uint8 seed) public constant returns (uint16) {
            if (hp > petHpThreshold) {return getRandomNumber(bp+petPower,20,seed);}
            return getRandomNumber(bp,20,seed);
            //Your strike is a return of a random from 20 to bp 
        }
        
           
       function fightMonster(uint16 battleboardId, uint8 tile1Id, uint8 monsterId) private {
             //First get the parameters. 
           IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
          
           uint32 hp;
           uint16 monsterHit= getRandomNumber(maxMonsterHit, uint8(minMonsterHit), msg.sender);
           uint64 angelId;
           (, ,,, hp, ,angelId ,,,) = battleboardData.getTileFromBattleboard(battleboardId, tile1Id);
      
           if (getAuraColor(angelId) != 0) { // blue angels are immune to monsters. 
           //see if the angel team dies or just loses hp
           if (hp > monsterHit) {
               battleboardData.setTileHp(battleboardId, tile1Id, (hp-monsterHit));
           }
           else {battleboardData.killTile(battleboardId, tile1Id);}
          battleboardData.killMonster(battleboardId, monsterId); 
           }
           EventMonsterStrike(battleboardId, angelId, monsterHit);
           
       }
       
       
       function canMove(uint16 battleboardId, uint8 position1, uint8 position2) public constant  returns (bool) {
           //returns true if a piece can move from position 1 to position 2. 
           
           //moves up and down are protected from moving off the board by the position numbers. 
           //Check if trying to move off the board to left 
           if (((position1 % 8) == 1) && ((position2 == position1-1 ) || (position2 == position1 -2))) {return false;}
           if (((position1 % 8) == 2) && (position2 == (position1-2))) {return false;}
           
           //Now check if trying to move off board to right. 
            if (((position1 % 8) == 0) && ((position2 == position1+1 ) || (position2 == position1 +2))) {return false;}
           if (((position1 % 8) == 7) && (position2 == (position1+2))) {return false;}
           
             IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
           //legal move left. Either move one space or move two spaces, with nothing blocking the first move. 
           if ((position2 == uint8(safeSubtract(position1,1))) || ((position2 == uint8(safeSubtract(position1,2)))  && (battleboardData.getTileIDbyPosition(battleboardId,position1-1) == 0))) {return true;}
           
           //legal move right
           if ((position2 == position1 +1) || ((position2 == position1 + 2) && (battleboardData.getTileIDbyPosition(battleboardId, position1+1) == 0))) {return true;}
           
           //legal move down
           if ((position2 == position1 +8) || ((position2 == position1 + 16) && (battleboardData.getTileIDbyPosition(battleboardId, position1+8) == 0))) {return true;}
           
           //legal move up
            if ((position2 == uint8(safeSubtract(position1,8))) || ((position2 == uint8(safeSubtract(position1,16)))  && (battleboardData.getTileIDbyPosition(battleboardId,position1-8) == 0))) {return true;}
          return false;
           
       }
       
       

       
    
       function randomPetAuraBoost (uint64 _petId, uint8 _boost) private  {
       IPetCardData petCardData = IPetCardData(petCardDataContract);
        uint16 auraRed;
        uint16 auraBlue;
        uint16 auraYellow;
        (,,,,auraRed,auraBlue,auraYellow,,,) = petCardData.getPet(_petId);
               uint8 chance = getRandomNumber(2,0,msg.sender);
               if (chance ==0) {petCardData.setPetAuras(_petId, uint8(auraRed + _boost), uint8(auraBlue), uint8(auraYellow));}
               if (chance ==1) {petCardData.setPetAuras(_petId, uint8(auraRed), uint8(auraBlue + _boost), uint8(auraYellow));}
               if (chance ==2) {petCardData.setPetAuras(_petId, uint8(auraRed), uint8(auraBlue), uint8(auraYellow+ _boost));}
               }
         
         



       
       
       function getAuraColor(uint64 angelId) private constant returns (uint8) {
              uint8 angelAura;
            IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
            (,,,angelAura,,,,,,,) = angelCardData.getAngel(angelId);
           return angelAura;
       }

        function isVulnerable(uint64 _angelId, int8 color) public constant returns (bool) {
            //Returns true if an angel is vulnerable to a certain color trap 
            //Red is 1, Yellow is 2, blue is 3
            uint8 angelAura;
            IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
            (,,,angelAura,,,,,,,) = angelCardData.getAngel(_angelId);
            
            if (color == 1) {
                if ((angelAura == 2) || (angelAura == 3) || (angelAura == 4)) {return true;}
            }
            
            if (color == 2) {
                if ((angelAura == 1) || (angelAura == 3) || (angelAura == 5)) {return true;}
            }
            
            if (color == 3) {
                if ((angelAura == 0) || (angelAura == 2) || (angelAura == 5)) {return true;}
            }
            
            
            
        }
  
           function kill() onlyCREATOR external {
        selfdestruct(creatorAddress);
    }
 
        
function withdrawEther()  onlyCREATOR external {
    creatorAddress.transfer(this.balance);
}

      
        
   
}