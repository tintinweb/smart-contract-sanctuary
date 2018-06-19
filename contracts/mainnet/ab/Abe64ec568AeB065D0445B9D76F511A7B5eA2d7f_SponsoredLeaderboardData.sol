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

//Note - due to not yet implemented features we could not store teams in an array. 

contract SponsoredLeaderboardData is ISponsoredLeaderboardData {

    /*** DATA TYPES ***/
        address public angelCardDataContract = 0x6D2E76213615925c5fc436565B5ee788Ee0E86DC;
    
      struct Team {
        uint64 angelId;
        uint64 petId;
        uint64 accessoryId;
    }
    
      struct Leaderboard {
        uint startTime;
        uint endTime;
        Team rank0;
        Team rank1;
        Team rank2;
        Team rank3;
        bool isLive;
        address sponsor;
        uint prize;
        uint16 id;
        uint8 numTeams;
        string message;
        bool medalsClaimed;
        
    }

    //main storage
    Leaderboard []  Leaderboards;
    
    uint16 public totalLeaderboards;
    
    uint16 minDays= 4;
    uint16 maxDays = 10;
    
    //The reserved balance is the total balance outstanding on all open leaderboards. 
    //We keep track of this figure to prevent the developers from pulling out money currently pledged
    uint public contractReservedBalance;
    
    
    mapping (uint64 => bool) angelsOnLeaderboards;
    mapping (uint64 => bool) petsOnLeaderboards;
    mapping (uint64 => bool) accessoriesOnLeaderboards;
    
    
    
      // write functions
    function setMinMaxDays(uint8 _minDays, uint8 _maxDays) external {
        minDays = _minDays;
        maxDays = _maxDays;
       }

  
        function openLeaderboard(uint8 numDays, string message) external payable {
            // This function is called by the sponsor to create the Leaderboard by sending money. 
            
           if (msg.value < 10000000000000000) {revert();}
         
         if ((numDays < minDays) || (numDays > maxDays)) {revert();}
            Leaderboard memory leaderboard;
            leaderboard.startTime = now;
            leaderboard.endTime = (now + (numDays * 86400));
            leaderboard.isLive = true;
            leaderboard.sponsor = msg.sender;
            leaderboard.prize = msg.value;
            leaderboard.message = message;
            leaderboard.id = totalLeaderboards;
            
            leaderboard.medalsClaimed= false;
            leaderboard.numTeams = 4;
    
           Leaderboards.push(leaderboard);
           
            Team memory team;
            team.angelId = 1;
            team.petId = 1;
            team.accessoryId = 0;
            Leaderboards[totalLeaderboards].rank1 = team;
            Leaderboards[totalLeaderboards].rank2 = team;
            Leaderboards[totalLeaderboards].rank3 = team;
            Leaderboards[totalLeaderboards].rank0 = team;
            totalLeaderboards +=1;
            contractReservedBalance += msg.value;
           
            
        }
        
        function closeLeaderboard(uint16 leaderboardId) onlySERAPHIM external {
           //will be called by the SponsoredLeaderboards contract with a certain chance after the minimum battle time. 
           
            Leaderboard memory leaderboard;
            leaderboard = Leaderboards[leaderboardId];
            if (now < leaderboard.endTime) {revert();}
            if (leaderboard.isLive = false) {revert();}
            Leaderboards[leaderboardId].isLive = false;
             IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
             
             address owner1;
             address owner2;
             address owner3;
             address owner4;
             
            (,,,,,,,,,,owner1) = angelCardData.getAngel(Leaderboards[leaderboardId].rank0.angelId);
            (,,,,,,,,,,owner2) = angelCardData.getAngel(Leaderboards[leaderboardId].rank1.angelId);
            (,,,,,,,,,,owner3) = angelCardData.getAngel(Leaderboards[leaderboardId].rank2.angelId);
            (,,,,,,,,,,owner4) = angelCardData.getAngel(Leaderboards[leaderboardId].rank3.angelId);
            uint prize = Leaderboards[leaderboardId].prize;
            
            owner1.transfer(SafeDiv(safeMult(prize,45), 100));
            owner2.transfer(SafeDiv(safeMult(prize,25), 100));
            owner3.transfer(SafeDiv(safeMult(prize,15), 100));
            owner4.transfer(SafeDiv(safeMult(prize,5), 100));
    
            //Free up cards to be on other Leaderboards
            
        angelsOnLeaderboards[Leaderboards[leaderboardId].rank0.angelId] = false;
        petsOnLeaderboards[Leaderboards[leaderboardId].rank0.petId] = false;
        accessoriesOnLeaderboards[Leaderboards[leaderboardId].rank0.accessoryId] = false;
         
             
        angelsOnLeaderboards[Leaderboards[leaderboardId].rank1.angelId] = false;
        petsOnLeaderboards[Leaderboards[leaderboardId].rank1.petId] = false;
        accessoriesOnLeaderboards[Leaderboards[leaderboardId].rank1.accessoryId] = false;
        
            
        angelsOnLeaderboards[Leaderboards[leaderboardId].rank2.angelId] = false;
        petsOnLeaderboards[Leaderboards[leaderboardId].rank2.petId] = false;
        accessoriesOnLeaderboards[Leaderboards[leaderboardId].rank2.accessoryId] = false;
        
            
        angelsOnLeaderboards[Leaderboards[leaderboardId].rank3.angelId] = false;
        petsOnLeaderboards[Leaderboards[leaderboardId].rank3.petId] = false;
        accessoriesOnLeaderboards[Leaderboards[leaderboardId].rank3.accessoryId] = false;
            
            
            
            contractReservedBalance= contractReservedBalance -  SafeDiv(safeMult(prize,90), 100);
        }
  
        
        function setMedalsClaimed(uint16 leaderboardId) onlySERAPHIM external {
            Leaderboards[leaderboardId].medalsClaimed = true;
        }
        
function withdrawEther() external onlyCREATOR {
    //make sure we can&#39;t transfer out balance for leaderboards that aren&#39;t open. 
    creatorAddress.transfer(this.balance-contractReservedBalance);
}

    // Call to get the specified team at a certain position of a certain board. 
   function getTeamFromLeaderboard(uint16 leaderboardId, uint8 rank) public constant returns (uint64 angelId, uint64 petId, uint64 accessoryId)   {
      
        if ((leaderboardId <0) || (rank <0) || (rank >3) || (leaderboardId > totalLeaderboards)) {revert();}
        if (rank == 0) {
       angelId = Leaderboards[leaderboardId].rank0.angelId;
       petId = Leaderboards[leaderboardId].rank0.petId;
       accessoryId = Leaderboards[leaderboardId].rank0.accessoryId;
       return;
        }
         if (rank == 1) {
       angelId = Leaderboards[leaderboardId].rank1.angelId;
       petId = Leaderboards[leaderboardId].rank1.petId;
       accessoryId = Leaderboards[leaderboardId].rank1.accessoryId;
       return;
        }
          if (rank == 2) {
       angelId = Leaderboards[leaderboardId].rank2.angelId;
       petId = Leaderboards[leaderboardId].rank2.petId;
       accessoryId = Leaderboards[leaderboardId].rank2.accessoryId;
       return;
        }
          if (rank == 3) {
       angelId = Leaderboards[leaderboardId].rank3.angelId;
       petId = Leaderboards[leaderboardId].rank3.petId;
       accessoryId = Leaderboards[leaderboardId].rank3.accessoryId;
       return;
        }
    

   }
    function getLeaderboard(uint16 id) public constant returns (uint startTime, uint endTime, bool isLive, address sponsor, uint prize, uint8 numTeams, string message, bool medalsClaimed) {
            Leaderboard memory leaderboard;
            leaderboard = Leaderboards[id];
            startTime = leaderboard.startTime;
            endTime = leaderboard.endTime;
            isLive = leaderboard.isLive;
            sponsor = leaderboard.sponsor;
            prize = leaderboard.prize;
            numTeams = leaderboard.numTeams;
            message = leaderboard.message;
            medalsClaimed = leaderboard.medalsClaimed;
    }
    
     


        function newTeamOnEnd(uint16 leaderboardId, uint64 angelId, uint64 petId, uint64 accessoryId)  onlySERAPHIM external  {
         //to be used when a team successfully challenges the last spot and knocks the prvious team out.   
         
                Team memory team;
               //remove old team from mappings
                team = Leaderboards[leaderboardId].rank3;
                angelsOnLeaderboards[Leaderboards[leaderboardId].rank3.angelId] = false;
               petsOnLeaderboards[Leaderboards[leaderboardId].rank3.petId] = false;
               accessoriesOnLeaderboards[Leaderboards[leaderboardId].rank3.accessoryId] = false;
                
                //Add new team to end
              Leaderboards[leaderboardId].rank3.angelId = angelId;
              Leaderboards[leaderboardId].rank3.petId = petId;
              Leaderboards[leaderboardId].rank3.accessoryId = accessoryId;
              
              angelsOnLeaderboards[angelId] = true;
               petsOnLeaderboards[petId] = true;
               accessoriesOnLeaderboards[accessoryId] = true;
           
            
            
        }
        function switchRankings (uint16 leaderboardId, uint8 spot,uint64 angel1ID, uint64 pet1ID, uint64 accessory1ID,uint64 angel2ID,uint64 pet2ID,uint64 accessory2ID ) onlySERAPHIM external {
        //put team 1 from spot to spot+1 and put team 2 to spot. 
    
                Team memory team;
                team.angelId = angel1ID;
                team.petId = pet1ID;
                team.accessoryId = accessory1ID;
                if (spot == 0) {Leaderboards[leaderboardId].rank1 = team;}
                if (spot == 1) {Leaderboards[leaderboardId].rank2 = team;}
                if (spot == 2) {Leaderboards[leaderboardId].rank3 = team;}
                
                team.angelId = angel2ID;
                team.petId = pet2ID;
                team.accessoryId = accessory2ID;
            
                if (spot == 0) {Leaderboards[leaderboardId].rank0 = team;}
                if (spot == 1) {Leaderboards[leaderboardId].rank1 = team;}
                if (spot == 2) {Leaderboards[leaderboardId].rank2 = team;}
        
        }
        
        
        function verifyPosition(uint16 leaderboardId, uint8 spot, uint64 angelID) external constant returns (bool) {
          
               if (spot == 0) {
                   if (Leaderboards[leaderboardId].rank0.angelId == angelID) {return true;}
               }
               if (spot == 1) {
                   if (Leaderboards[leaderboardId].rank1.angelId == angelID) {return true;}
               }
               if (spot == 2) {
                   if (Leaderboards[leaderboardId].rank2.angelId == angelID) {return true;}
               }
                 if (spot == 3) {
                   if (Leaderboards[leaderboardId].rank3.angelId == angelID) {return true;}
               }
               
               
                return false;
                
        }
        
        //each angel can only be on ONE sponsored leaderboard at a time. 
        function angelOnLeaderboards(uint64 angelID) external constant returns (bool) {
           
            return angelsOnLeaderboards[angelID]; 
        }
        
        //each pet can only be on ONE sponsored leaderboard at a time. 
         function petOnLeaderboards(uint64 petID) external constant returns (bool) {
           
            return petsOnLeaderboards[petID]; 
        }
        
        //Each Accessory can only be on one sponsored leaderboard
         function accessoryOnLeaderboards(uint64 accessoryID) external constant returns (bool) {
           
            return accessoriesOnLeaderboards[accessoryID]; 
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
   
   
    function getTotalLeaderboards() public constant returns (uint16) {
        return totalLeaderboards;
    }
      
  
        
   
        
        
        
   
      
        
   
}