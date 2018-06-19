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

contract BattleboardData is IBattleboardData  {

    /*** DATA TYPES ***/
       
  
  //Most main pieces on the board are tiles.   
      struct Tile {
        uint8 tileType;
        uint8 value; //speed for angels, otherwise value of other types. 
        uint8 id;
        uint8 position;
        uint32 hp;
        uint16 petPower;
        uint8 team; //which team they are on. 
        uint64 angelId;
        uint64 petId;
        bool isLive;
        address owner;
        
    }
    
      struct Battleboard {
        uint8 turn; //turn number - turn 0 is the first player who enters the board. 
        address[] players;
        bool isLive;
        uint prize;
        uint16 id;
        uint8 numTeams; //number of angel/pet teams on the board, different than TEAM1 vs TEAM2
        uint8 numTiles;
        uint8 createdBarriers;
        uint8 restrictions; //number of which angels can be added. 
        uint lastMoveTime;
        address[] team1;
        address[] team2; //addresses of the owners of teams 1 and 2
        uint8 numTeams1;
        uint8 numTeams2;
        uint8 monster1; //tile number of the monster locations. 
        uint8 monster2;
        uint8 medalsBurned;
    }

    //main storage
    Battleboard []  Battleboards;
    
    uint16 public totalBattleboards;
    
    uint8 maxFreeTeams = 6;
    uint8 maxPaidTeams = 4;
    
    //Each angel can only be on one board at a time. 
    mapping (uint64 => bool) angelsOnBattleboards; 

    //Map the battleboard ID to an array of all tiles on that board. 
    mapping (uint32 => Tile[]) TilesonBoard;
    
    //for each battleboardId(uint16) there is a number with the tileId of the tile. TileId 0 means blank. 
    mapping (uint16 => uint8 [64]) positionsTiles;
    
    
    
      // write functions
  
       function createBattleboard(uint prize, uint8 restrictions) onlySERAPHIM external returns (uint16) {
           Battleboard memory battleboard;
           battleboard.restrictions = restrictions;
           battleboard.isLive = false; //will be live once ALL teams are added. 
           battleboard.prize = prize;
           battleboard.id = totalBattleboards;
           battleboard.numTeams = 0;
           battleboard.lastMoveTime = now;
           totalBattleboards += 1;
           battleboard.numTiles = 0;
          //set the monster positions
           battleboard.monster1 = getRandomNumber(30,17,1);
           battleboard.monster2 = getRandomNumber(48,31,2); 
           Battleboards.push(battleboard);
          createNullTile(totalBattleboards-1);
           return (totalBattleboards - 1);
       }
       
         
      
      function killMonster(uint16 battleboardId, uint8 monsterId)  onlySERAPHIM external{
          if (monsterId == 1) {
              Battleboards[battleboardId].monster1 = 0;
          }
          if (monsterId ==2) {
               Battleboards[battleboardId].monster2 = 0;
          }
      }
        
        function createNullTile(uint16 _battleboardId) private    {
      //We need to create a tile with ID 0 that won&#39;t be on the board. This lets us know if any other tile is ID 0 then that means it&#39;s a blank tile. 
        if ((_battleboardId <0) || (_battleboardId > totalBattleboards)) {revert();}
        Tile memory tile ;
        tile.tileType = 0; 
        tile.id = 0;
        tile.isLive = true;
        TilesonBoard[_battleboardId].push(tile);
     
    }
        
        function createTile(uint16 _battleboardId, uint8 _tileType, uint8 _value, uint8 _position, uint32 _hp, uint16 _petPower, uint64 _angelId, uint64 _petId, address _owner, uint8 _team) onlySERAPHIM external  returns (uint8)   {
      //main function to create a tile and add it to the board. 
        if ((_battleboardId <0) || (_battleboardId > totalBattleboards)) {revert();}
        if ((angelsOnBattleboards[_angelId] == true) && (_angelId != 0)) {revert();}
        angelsOnBattleboards[_angelId] = true;
        Tile memory tile ;
        tile.tileType = _tileType; 
        tile.value = _value;
        tile.position= _position;
        tile.hp = _hp;
        Battleboards[_battleboardId].numTiles +=1;
        tile.id = Battleboards[_battleboardId].numTiles;
        positionsTiles[_battleboardId][_position+1] = tile.id;
        tile.petPower = _petPower;
        tile.angelId = _angelId;
        tile.petId = _petId;
        tile.owner = _owner;
        tile.team = _team;
        tile.isLive = true;
        TilesonBoard[_battleboardId].push(tile);
        return (Battleboards[_battleboardId].numTiles);
    }
     
     function killTile(uint16 battleboardId, uint8 tileId) onlySERAPHIM external {
     
      TilesonBoard[battleboardId][tileId].isLive= false;
      TilesonBoard[battleboardId][tileId].tileType= 0;
      for (uint i =0; i< Battleboards[battleboardId].team1.length; i++) {
          if (Battleboards[battleboardId].team1[i] == TilesonBoard[battleboardId][tileId].owner) {
             //should be safe because a team can&#39;t be killed if there are 0 teams to kill. 
             Battleboards[battleboardId].numTeams1 -= 1; 
          }
      }
      for (i =0; i< Battleboards[battleboardId].team2.length; i++) {
          if (Battleboards[battleboardId].team2[i] == TilesonBoard[battleboardId][tileId].owner) {
             //should be safe because a team can&#39;t be killed if there are 0 teams to kill. 
             Battleboards[battleboardId].numTeams2 -= 1; 
          }
      }
    }
     
     function addTeamtoBoard(uint16 battleboardId, address owner, uint8 team) onlySERAPHIM external {
        
        //Can&#39;t add a team if the board is live, or if the board is already full of teams. 
         if (Battleboards[battleboardId].isLive == true) {revert();}
         if ((Battleboards[battleboardId].prize == 0) &&(Battleboards[battleboardId].numTeams == maxFreeTeams)) {revert();}
         if ((Battleboards[battleboardId].prize != 0) &&(Battleboards[battleboardId].numTeams == maxPaidTeams)) {revert();}
         
         //only one team per address can be on the board. 
         for (uint i =0; i<Battleboards[battleboardId].numTeams; i++) {
             if (Battleboards[battleboardId].players[i] == owner) {revert();}
         }
         Battleboards[battleboardId].numTeams += 1;
         Battleboards[battleboardId].players.push(owner);
         
         if (team == 1) {
         Battleboards[battleboardId].numTeams1 += 1;
         Battleboards[battleboardId].team1.push(owner);
         }
         if (team == 2) {
         Battleboards[battleboardId].numTeams2 += 1;
         Battleboards[battleboardId].team2.push(owner);
         
         //if the board is now full, then go ahead and make it live. 
         if ((Battleboards[battleboardId].numTeams1 == 3) && (Battleboards[battleboardId].numTeams2 ==3)) {Battleboards[battleboardId].isLive = true;}
        if ((Battleboards[battleboardId].prize != 0) &&(Battleboards[battleboardId].numTeams == maxPaidTeams)) {Battleboards[battleboardId].isLive = true;}
         }
          
     }
       
        function setTilePosition (uint16 battleboardId, uint8 tileId, uint8 _positionTo) onlySERAPHIM public  {
            uint8 oldPos = TilesonBoard[battleboardId][tileId].position;
            positionsTiles[battleboardId][oldPos+1] = 0;
            TilesonBoard[battleboardId][tileId].position = _positionTo;
            positionsTiles[battleboardId][_positionTo+1] = tileId;
            
        }
        
        function setTileHp(uint16 battleboardId, uint8 tileId, uint32 _hp) onlySERAPHIM external {
            TilesonBoard[battleboardId][tileId].hp = _hp;
        }
        
          function addMedalBurned(uint16 battleboardId) onlySERAPHIM external {
            Battleboards[battleboardId].medalsBurned += 1;
        }
        
        function withdrawEther()  onlyCREATOR external {
   //shouldn&#39;t have any eth here but just in case. 
    creatorAddress.transfer(this.balance);
}

function setLastMoveTime(uint16 battleboardId) onlySERAPHIM external {
        Battleboards[battleboardId].lastMoveTime = now;
        
        
    }
    
      function iterateTurn(uint16 battleboardId) onlySERAPHIM external {
            if (Battleboards[battleboardId].turn  == (Battleboards[battleboardId].players.length-1)) {
                Battleboards[battleboardId].turn = 0;
            } 
            else {Battleboards[battleboardId].turn += 1;}
        }
        
         function killBoard(uint16 battleboardId) onlySERAPHIM external {
           Battleboards[battleboardId].isLive = false;
           clearAngelsFromBoard(battleboardId);
       }
    
    
        function clearAngelsFromBoard(uint16 battleboardId) private {
         //Free up angels to be used on other boards. 
         for (uint i = 0; i < Battleboards[battleboardId].numTiles; i++) {
            if (TilesonBoard[battleboardId][i].angelId != 0) {
                angelsOnBattleboards[TilesonBoard[battleboardId][i].angelId] = false;
              }
         } 
  
    }

//Read functions
     
        function getTileHp(uint16 battleboardId, uint8 tileId) constant external returns (uint32) {
            return TilesonBoard[battleboardId][tileId].hp;
        }
        
      
        function getMedalsBurned(uint16 battleboardId) constant external returns (uint8) {
            return Battleboards[battleboardId].medalsBurned;
        }
  
 
 function getTeam(uint16 battleboardId, uint8 tileId) constant external returns (uint8) {
     return TilesonBoard[battleboardId][tileId].team;
 }
        


function getRandomNumber(uint16 maxRandom, uint8 min, address privateAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(privateAddress);
        return uint8(genNum % (maxRandom - min + 1)+min);
        }

       
       function getMaxFreeTeams() constant public returns (uint8) {
          return maxFreeTeams;
       }
  
        function getBarrierNum(uint16 battleboardId) public constant returns (uint8) {
            return Battleboards[battleboardId].createdBarriers;
        }

    // Call to get the specified tile at a certain position of a certain board. 
   function getTileFromBattleboard(uint16 battleboardId, uint8 tileId) public constant returns (uint8 tileType, uint8 value, uint8 id, uint8 position, uint32 hp, uint16 petPower, uint64 angelId, uint64 petId, bool isLive, address owner)   {
      
        if ((battleboardId <0) ||  (battleboardId > totalBattleboards)) {revert();}
        Battleboard memory battleboard = Battleboards[battleboardId];
        Tile memory tile;
        if ((tileId <0) || (tileId> battleboard.numTiles)) {revert();}
        tile = TilesonBoard[battleboardId][tileId];
        tileType = tile.tileType; 
        value = tile.value;
        id= tile.id;
        position = tile.position;
        hp = tile.hp;
        petPower = tile.petPower;
        angelId = tile.angelId;
        petId = tile.petId;
        owner = tile.owner;
        isLive = tile.isLive;
        
    }
    
    //Each player (address) can only have one tile on each board. 
    function getTileIDByOwner(uint16 battleboardId, address _owner) constant public returns (uint8) {
        for (uint8 i = 0; i < Battleboards[battleboardId].numTiles+1; i++) {
            if (TilesonBoard[battleboardId][i].owner == _owner) {
                return TilesonBoard[battleboardId][i].id;
        }
    }
       return 0;
    }
    
    
    
    function getPetbyTileId( uint16 battleboardId, uint8 tileId) constant public returns (uint64) {
       return TilesonBoard[battleboardId][tileId].petId;
    }
    
    function getOwner (uint16 battleboardId, uint8 team,  uint8 ownerNumber) constant external returns (address) {
        
       if (team == 0) {return Battleboards[battleboardId].players[ownerNumber];}
       if (team == 1) {return Battleboards[battleboardId].team1[ownerNumber];}
       if (team == 2) {return Battleboards[battleboardId].team2[ownerNumber];}
       
       
    }
    

    
      function getTileIDbyPosition(uint16 battleboardId, uint8 position) public constant returns (uint8) {
        return positionsTiles[battleboardId][position+1];
    }
    //If tile is empty, this returns 0
     
        // Call to get the specified tile at a certain position of a certain board. 
   function getPositionFromBattleboard(uint16 battleboardId, uint8 _position) public constant returns (uint8 tileType, uint8 value, uint8 id, uint8 position, uint32 hp, uint32 petPower, uint64 angelId, uint64 petId, bool isLive)   {
      
        if ((battleboardId <0) ||  (battleboardId > totalBattleboards)) {revert();}
    
        Tile memory tile;
        uint8 tileId = positionsTiles[battleboardId][_position+1];
        tile = TilesonBoard[battleboardId][tileId];
        tileType = tile.tileType; 
        value = tile.value;
        id= tile.id;
        position = tile.position;
        hp = tile.hp;
        petPower = tile.petPower;
        angelId = tile.angelId;
        petId = tile.petId;
        isLive = tile.isLive;
        
    } 
     
 
    function getBattleboard(uint16 id) public constant returns (uint8 turn, bool isLive, uint prize, uint8 numTeams, uint8 numTiles, uint8 createdBarriers, uint8 restrictions, uint lastMoveTime, uint8 numTeams1, uint8 numTeams2, uint8 monster1, uint8 monster2) {
            
            Battleboard memory battleboard = Battleboards[id];
    
        turn = battleboard.turn;
        isLive = battleboard.isLive;
        prize = battleboard.prize;
        numTeams = battleboard.numTeams;
        numTiles = battleboard.numTiles;
        createdBarriers = battleboard.createdBarriers;
        restrictions = battleboard.restrictions;
        lastMoveTime = battleboard.lastMoveTime;
        numTeams1 = battleboard.numTeams1;
        numTeams2 = battleboard.numTeams2;
        monster1 = battleboard.monster1;
        monster2 = battleboard.monster2;
    }

    
    

     
     function isBattleboardLive(uint16 battleboardId) constant public returns (bool) {
         return Battleboards[battleboardId].isLive;
     }


     function isTileLive(uint16 battleboardId, uint8 tileId) constant  external returns (bool) {
     
      return TilesonBoard[battleboardId][tileId].isLive;
    }
    
    function getLastMoveTime(uint16 battleboardId) constant public returns (uint) {
        return Battleboards[battleboardId].lastMoveTime;
    }
     
  
        function getNumTilesFromBoard (uint16 _battleboardId) constant public returns (uint8) {
            return Battleboards[_battleboardId].numTiles;
        }
   
        
        //each angel can only be on ONE sponsored battleboard at a time. 
        function angelOnBattleboards(uint64 angelID) external constant returns (bool) {
           
            return angelsOnBattleboards[angelID]; 
        }
   
        
        function getTurn(uint16 battleboardId) constant public returns (address) {
            return Battleboards[battleboardId].players[Battleboards[battleboardId].turn];
        }
        
      
     
     function getNumTeams(uint16 battleboardId, uint8 team) public constant returns (uint8) {
         if (team == 1) {return Battleboards[battleboardId].numTeams1;}
         if (team == 2) {return Battleboards[battleboardId].numTeams2;}
     }
        
      
    
    function getMonsters(uint16 BattleboardId) external constant returns (uint8 monster1, uint8 monster2) {
        
        monster1 = Battleboards[BattleboardId].monster1;
        monster2 = Battleboards[BattleboardId].monster2;
   
    }
    
    
    function safeMult(uint x, uint y) pure internal returns(uint) {
      uint z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    
     function SafeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
    /// Read access
     }
   
   
    function getTotalBattleboards() public constant returns (uint16) {
        return totalBattleboards;
    }
      
  
        
   
        
        
        
   
      
        
   
}