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
contract BattleboardsSupport is AccessControl, SafeMath  {

    /*** DATA TYPES ***/

    address public medalDataContract =  0x33A104dCBEd81961701900c06fD14587C908EAa3;
    address public battleboardDataContract =0xE60fC4632bD6713E923FE93F8c244635E6d5009e;

    
    
    uint8 public medalBoost = 50;
    uint8 public numBarriersPerBoard = 6;
    uint public barrierPrice = 1000000000000000;
    uint8 public maxMedalsBurned = 3;
    uint8 public barrierStrength = 75;
    
      
          // Utility Functions
    function DataContacts(address _medalDataContract, address _battleboardDataContract) onlyCREATOR external {
      
        medalDataContract = _medalDataContract;
        battleboardDataContract = _battleboardDataContract;
    }
    
    function setVariables( uint8 _medalBoost, uint8 _numBarriersPerBoard, uint8 _maxMedalsBurned, uint8 _barrierStrength, uint _barrierPrice) onlyCREATOR external {
        medalBoost = _medalBoost;
        numBarriersPerBoard = _numBarriersPerBoard;
        maxMedalsBurned = _maxMedalsBurned;
        barrierStrength = _barrierStrength;
        barrierPrice = _barrierPrice;
        
    }
    
      
      
        //Can be called by anyone at anytime,    
       function erectBarrier(uint16 battleboardId, uint8 _barrierType, uint8 _position) external payable {
           IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
           uint8 numBarriers = battleboardData.getBarrierNum(battleboardId);
           if (battleboardData.getTileIDbyPosition(battleboardId, _position) != 0 ) {revert();}  //Can&#39;t put a barrier on top of another tile
           if (numBarriers >= numBarriersPerBoard) {revert();} //can&#39;t put too many barriers on one board. 
           if (msg.value < barrierPrice) {revert();}
           if ((_barrierType <2) || (_barrierType >4)) {revert();} //can&#39;t create another tile instead of a barrier. 
          battleboardData.createTile(battleboardId,_barrierType, barrierStrength, _position, 0, 0, 0, 0, address(this),0);
       }
       
       
                
          function checkExistsOwnedMedal (uint64 medalId) public constant returns (bool) {
          IMedalData medalData = IMedalData(medalDataContract);
       
        if ((medalId < 0) || (medalId > medalData.totalSupply())) {return false;}
        if (medalData.ownerOf(medalId) == msg.sender) {return true;}
        
       else  return false;
}
       
             function medalBoostAndBurn(uint16 battleboardId, uint64 medalId) public  {
               
               //IMPORTANT: Before burning a medal in this function, you must APPROVE this address
               //in the medal data contract to unlock it. 
               
                IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);

                uint8 tileId = battleboardData.getTileIDByOwner(battleboardId,msg.sender);
                //can&#39;t resurrect yourself. 
                if (battleboardData.isTileLive(battleboardId,tileId) == false) {revert();}
                
               if  (checkExistsOwnedMedal(medalId)== false) {revert();}
               
               //make sure the max number of medals haven&#39;t already been burned. 
               if (battleboardData.getMedalsBurned(battleboardId) >= maxMedalsBurned) {revert();}
              battleboardData.addMedalBurned(battleboardId);
                 //this first takes and then burns the medal. 
               IMedalData medalData = IMedalData(medalDataContract);
               uint8 medalType = medalData.getMedalType(medalId);
               medalData.takeOwnership(medalId);
               medalData._burn(medalId);
            uint32 hp = battleboardData.getTileHp(battleboardId, tileId);
           
          battleboardData.setTileHp(battleboardId, tileId, hp + (medalType * medalBoost));
       }
       
         
           function kill() onlyCREATOR external {
        selfdestruct(creatorAddress);
    }
 
        
function withdrawEther()  onlyCREATOR external {
    creatorAddress.transfer(this.balance);
}
       
       
}