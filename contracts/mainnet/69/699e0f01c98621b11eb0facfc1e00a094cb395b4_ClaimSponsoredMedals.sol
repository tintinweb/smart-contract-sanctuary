pragma solidity ^0.4.17;

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

contract ISponsoredLeaderboardData is AccessControl {

  
    uint16 public totalLeaderboards;
    
    //The reserved balance is the total balance outstanding on all open leaderboards. 
    //We keep track of this figure to prevent the developers from pulling out money currently pledged
    uint public contractReservedBalance;
    

    function setMinMaxDays(uint8 _minDays, uint8 _maxDays) external ;
        function openLeaderboard(uint8 numDays, string message) external payable ;
        function closeLeaderboard(uint16 leaderboardId) onlySERAPHIM external;
        
        function setMedalsClaimed(uint16 leaderboardId) onlySERAPHIM external ;
    function withdrawEther() onlyCREATOR external;
  function getTeamFromLeaderboard(uint16 leaderboardId, uint8 rank) public constant returns (uint64 angelId, uint64 petId, uint64 accessoryId) ;
    
    function getLeaderboard(uint16 id) public constant returns (uint startTime, uint endTime, bool isLive, address sponsor, uint prize, uint8 numTeams, string message, bool medalsClaimed);
      function newTeamOnEnd(uint16 leaderboardId, uint64 angelId, uint64 petId, uint64 accessoryId) onlySERAPHIM external;
       function switchRankings (uint16 leaderboardId, uint8 spot,uint64 angel1ID, uint64 pet1ID, uint64 accessory1ID,uint64 angel2ID,uint64 pet2ID,uint64 accessory2ID) onlySERAPHIM external;
       function verifyPosition(uint16 leaderboardId, uint8 spot, uint64 angelID) external constant returns (bool); 
        function angelOnLeaderboards(uint64 angelID) external constant returns (bool);
         function petOnLeaderboards(uint64 petID) external constant returns (bool);
         function accessoryOnLeaderboards(uint64 accessoryID) external constant returns (bool) ;
    function safeMult(uint x, uint y) pure internal returns(uint) ;
     function SafeDiv(uint256 a, uint256 b) internal pure returns (uint256) ;
    function getTotalLeaderboards() public constant returns (uint16);
      
  
        
   
        
        
        
   
      
        
   
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

//INSTURCTIONS: You can access this contract through our webUI at angelbattles.com (preferred)
//You can also access this contract directly by sending a transaction the the leaderboardId you wish to claim medals for
//Variable names are self explanatory, but contact us if you have any questions. 

contract ClaimSponsoredMedals is AccessControl, SafeMath  {
    // Addresses for other contracts MedalClaim interacts with. 
    address public angelCardDataContract = 0x6D2E76213615925c5fc436565B5ee788Ee0E86DC;
    address public medalDataContract =  0x33A104dCBEd81961701900c06fD14587C908EAa3;
    address public sponsoredLeaderboardDataContract = 0xAbe64ec568AeB065D0445B9D76F511A7B5eA2d7f;
    
    // events
     event EventMedalSuccessful(address owner,uint64 Medal);
  



    // write functions
    function DataContacts(address _angelCardDataContract,  address _medalDataContract, address _sponsoredLeaderboardDataContract) onlyCREATOR external {
        angelCardDataContract = _angelCardDataContract;
        medalDataContract = _medalDataContract;
        sponsoredLeaderboardDataContract = _sponsoredLeaderboardDataContract;
    }
       



function claimMedals (uint16 leaderboardId) public  {
    
    //Function can be called by anyone, as long as the medals haven&#39;t already been claimed, the leaderboard is closed, and it&#39;s past the end time. 
    
           ISponsoredLeaderboardData sponsoredLeaderboardData = ISponsoredLeaderboardData(sponsoredLeaderboardDataContract);  
        if ((leaderboardId < 0 ) || (leaderboardId > sponsoredLeaderboardData.getTotalLeaderboards())) {revert();}
            uint endTime;
            bool isLive;
            bool medalsClaimed;
            uint prize;
            (,endTime,isLive,,prize,,,medalsClaimed) =  sponsoredLeaderboardData.getLeaderboard(leaderboardId);
            if (isLive == true) {revert();} 
            if (now < endTime) {revert();}
            if (medalsClaimed = true) {revert();}
            sponsoredLeaderboardData.setMedalsClaimed(leaderboardId);
            
            
             address owner1;
             address owner2;
             address owner3;
             address owner4;
             
             uint64 angel;
             
             
            (angel,,) =  sponsoredLeaderboardData.getTeamFromLeaderboard(leaderboardId, 0);
             (,,,,,,,,,,owner1) = angelCardData.getAngel(angel);
             (angel,,) =  sponsoredLeaderboardData.getTeamFromLeaderboard(leaderboardId, 1);
             (,,,,,,,,,,owner2) = angelCardData.getAngel(angel);
              (angel,,) =  sponsoredLeaderboardData.getTeamFromLeaderboard(leaderboardId, 2);
             (,,,,,,,,,,owner3) = angelCardData.getAngel(angel);
              (angel,,) =  sponsoredLeaderboardData.getTeamFromLeaderboard(leaderboardId, 3);
             (,,,,,,,,,,owner4) = angelCardData.getAngel(angel);
            
            IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
     
    
            
             IMedalData medalData = IMedalData(medalDataContract);  
            if (prize == 10000000000000000) {
             medalData._createMedal(owner1, 2);
             medalData._createMedal(owner2, 1);
             medalData._createMedal(owner3,0);
             medalData._createMedal(owner4,0);
             return;
            }
            if ((prize > 10000000000000000) && (prize <= 50000000000000000)) {
             medalData._createMedal(owner1, 5);
             medalData._createMedal(owner2, 4);
             medalData._createMedal(owner3,3);
             medalData._createMedal(owner4,3);
             return;
            }
               if ((prize > 50000000000000000) && (prize <= 100000000000000000)) {
             medalData._createMedal(owner1, 6);
             medalData._createMedal(owner2, 5);
             medalData._createMedal(owner3,4);
             medalData._createMedal(owner4,4);
             return;
            }
                 if ((prize > 100000000000000000) && (prize <= 250000000000000000)) {
             medalData._createMedal(owner1, 9);
             medalData._createMedal(owner2, 6);
             medalData._createMedal(owner3,5);
             medalData._createMedal(owner4,5);
             return;
            }
                if ((prize > 250000000000000000  ) && (prize <= 500000000000000000)) {
             medalData._createMedal(owner1,10);
             medalData._createMedal(owner2, 9);
             medalData._createMedal(owner3,6);
             medalData._createMedal(owner4,6);
            }
                if (prize  > 500000000000000000)   {
             medalData._createMedal(owner1, 11);
             medalData._createMedal(owner2, 10);
             medalData._createMedal(owner3,9);
             medalData._createMedal(owner4,9);
             
            }
            
}

           
            
        }