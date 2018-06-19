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
contract IAccessoryData is AccessControl, Enums {
    uint8 public totalAccessorySeries;    
    uint32 public totalAccessories;
    
 
    /*** FUNCTIONS ***/
    //*** Write Access ***//
    function createAccessorySeries(uint8 _AccessorySeriesId, uint32 _maxTotal, uint _price) onlyCREATOR public returns(uint8) ;
	function setAccessory(uint8 _AccessorySeriesId, address _owner) onlySERAPHIM external returns(uint64);
   function addAccessoryIdMapping(address _owner, uint64 _accessoryId) private;
	function transferAccessory(address _from, address _to, uint64 __accessoryId) onlySERAPHIM public returns(ResultCode);
    function ownerAccessoryTransfer (address _to, uint64 __accessoryId)  public;
    function updateAccessoryLock (uint64 _accessoryId, bool newValue) public;
    function removeCreator() onlyCREATOR external;
    
    //*** Read Access ***//
    function getAccessorySeries(uint8 _accessorySeriesId) constant public returns(uint8 accessorySeriesId, uint32 currentTotal, uint32 maxTotal, uint price) ;
	function getAccessory(uint _accessoryId) constant public returns(uint accessoryID, uint8 AccessorySeriesID, address owner);
	function getOwnerAccessoryCount(address _owner) constant public returns(uint);
	function getAccessoryByIndex(address _owner, uint _index) constant public returns(uint) ;
    function getTotalAccessorySeries() constant public returns (uint8) ;
    function getTotalAccessories() constant public returns (uint);
    function getAccessoryLockStatus(uint64 _acessoryId) constant public returns (bool);
}


contract ILeaderboardData is AccessControl, SafeMath {

    /*** DATA TYPES ***/

    uint8 public maxRankingSpots;
    uint8 public teamsOnLeaderboard;

    // write functions
 
      
    function setMaxRankingSpots(uint8 spots)  onlyCREATOR external ;
        function startLeaderboard (uint64 angelId, uint64 petId, uint64 accessoryId)  onlyCREATOR external;
        function addtoLeaderboard(uint64 angelId, uint64 petId, uint64 accessoryId)  onlySERAPHIM external ;
        function newTeamOnEnd(uint64 angelId, uint64 petId, uint64 accessoryId)  onlySERAPHIM external ;
        function switchRankings (uint8 spot,uint64 angel1ID, uint64 pet1ID, uint64 accessory1ID,uint64 angel2ID,uint64 pet2ID,uint64 accessory2ID ) onlySERAPHIM external ;
        function verifyPosition(uint8 spot, uint64 angelID, uint64 petID, uint64 accessoryID) external constant onlySERAPHIM returns (bool) ;
        function angelOnLeaderboard(uint64 angelID) external onlySERAPHIM constant returns (bool);
        function petOnLeaderboard(uint64 petID) external onlySERAPHIM constant returns (bool);
        

    /// Read access
    
    function getMaxRankingSpots () public constant returns (uint16) ;
    function getTeamByPosition (uint8 position) external constant returns (uint64 angelId, uint64 petId, uint64 accessoryId);
    function getTeamsOnLeaderboard() public constant returns (uint16);
      
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
//You can also access this contract directly by sending a transaction the the medal you wish to claim
//Variable names are self explanatory, but contact us if you have any questions. 

contract MedalClaim is AccessControl, SafeMath  {
    // Addresses for other contracts MedalClaim interacts with. 
    address public angelCardDataContract = 0x6D2E76213615925c5fc436565B5ee788Ee0E86DC;
    address public petCardDataContract = 0xB340686da996b8B3d486b4D27E38E38500A9E926;
    address public accessoryDataContract = 0x466c44812835f57b736ef9F63582b8a6693A14D0;
    address public leaderboardDataContract = 0x9A1C755305c6fbf361B4856c9b6b6Bbfe3aCE738;
    address public medalDataContract =  0x33A104dCBEd81961701900c06fD14587C908EAa3;
    
    // events
     event EventMedalSuccessful(address owner,uint64 Medal);
  

    /*** DATA TYPES ***/

    struct Angel {
        uint64 angelId;
        uint8 angelCardSeriesId;
        address owner;
        uint16 battlePower;
        uint8 aura;
        uint16 experience;
      
    }

    struct Pet {
        uint64 petId;
        uint8 petCardSeriesId;
        address owner;
        string name;
        uint8 luck;
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
     
    }
    
     struct Accessory {
        uint accessoryId;
        uint8 accessorySeriesId;
        address owner;
    }
    
         // Stores which address have claimed which tokens, to avoid one address claiming the same token twice.
         //Note - this does NOT affect medals won on the sponsored leaderboards;
  mapping (address => bool[12]) public claimedbyAddress;
  
  //Stores which cards have been used to claim medals, to avoid transfering a key card to another account and claiming another medal. 
  mapping (uint64 => bool) public angelsClaimedCardboard;
  mapping (uint64 => bool) public petsClaimedGold;


    // write functions
    function DataContacts(address _angelCardDataContract, address _petCardDataContract, address _accessoryDataContract, address _leaderboardDataContract, address _medalDataContract) onlyCREATOR external {
        angelCardDataContract = _angelCardDataContract;
        petCardDataContract = _petCardDataContract;
        accessoryDataContract = _accessoryDataContract;
        leaderboardDataContract = _leaderboardDataContract;
        medalDataContract = _medalDataContract;
    }
       
    function checkExistsOwnedAngel (uint64 angelId) private constant returns (bool) {
        IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
       
        if ((angelId <= 0) || (angelId > angelCardData.getTotalAngels())) {return false;}
        address angelowner;
        (,,,,,,,,,,angelowner) = angelCardData.getAngel(angelId);
        if (angelowner == msg.sender) {return true;}
        
       else  return false;
}

    function checkExistsOwnedPet (uint64 petId) private constant returns (bool) {
          IPetCardData petCardData = IPetCardData(petCardDataContract);
       
        if ((petId <= 0) || (petId > petCardData.getTotalPets())) {return false;}
        address petowner;
         (,,,,,,,petowner) = petCardData.getPet(petId);
        if (petowner == msg.sender) {return true;}
        
       else  return false;
}


    function getPetCardSeries (uint64 petId) public constant returns (uint8) {
          IPetCardData petCardData = IPetCardData(petCardDataContract);
       
        if ((petId <= 0) || (petId > petCardData.getTotalPets())) {revert();}
        uint8 seriesId;
         (,seriesId,,,,,,,,) = petCardData.getPet(petId);
        return uint8(seriesId);
        }

     function claim1Ply(uint64 angel1Id, uint64 angel2Id, uint64 angel3Id, uint64 angel4Id, uint64 angel5Id) public {
         
         //can only claim each medal once per address. 
         if (claimedbyAddress[msg.sender][0] == true) {revert();}
         
         //angelIds must be called in ORDER. This prevents computationally expensive checks to avoid duplicates. 
         if ((angel1Id < angel2Id) && (angel2Id < angel3Id) && (angel3Id < angel4Id) && (angel4Id <angel5Id)) {
             if ((checkExistsOwnedAngel(angel1Id) == true) && (checkExistsOwnedAngel(angel2Id) == true) && (checkExistsOwnedAngel(angel3Id) == true) && (checkExistsOwnedAngel(angel4Id) == true)  && (checkExistsOwnedAngel(angel5Id) == true)) {
             IMedalData medalData = IMedalData(medalDataContract);   
             medalData._createMedal(msg.sender, 0);
             EventMedalSuccessful(msg.sender,0);
             claimedbyAddress[msg.sender][0] = true;
             }
             
         }
     }
        
         function claim2Ply(uint64 geckoId, uint64 parakeetId, uint64 catId, uint64 horseId) public {
        
          //can only claim each medal once per address. 
         if (claimedbyAddress[msg.sender][1] == true) {revert();}
         if ((getPetCardSeries(geckoId) == 1) && (getPetCardSeries(parakeetId) == 2) && (getPetCardSeries(catId) == 3) && (getPetCardSeries(horseId) == 4)) {
             if ((checkExistsOwnedPet(geckoId) == true) && (checkExistsOwnedPet(parakeetId) == true) && (checkExistsOwnedPet(catId) == true) && (checkExistsOwnedPet(horseId) == true)) {
             IMedalData medalData = IMedalData(medalDataContract);   
             claimedbyAddress[msg.sender][1] = true;
             medalData._createMedal(msg.sender, 1);
             EventMedalSuccessful(msg.sender,1);
             }
             
         }
     }
        function claimCardboard(uint64 angelId) public {
            
              //can only claim each medal once per address. 
         if (claimedbyAddress[msg.sender][2] == true) {revert();}
        
            if  (checkExistsOwnedAngel(angelId) == true) {
                    IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
                    uint16 experience;
                    (,,,,experience,,,,,,) = angelCardData.getAngel(angelId);
                    if (experience >= 100) {
                         claimedbyAddress[msg.sender][2] = true;
                         IMedalData medalData = IMedalData(medalDataContract);   
                         medalData._createMedal(msg.sender, 2);
                         EventMedalSuccessful(msg.sender,2);
                    }
            }
         }
             
  
             
         function claimSilver(uint64 blueAngel, uint64 redAngel, uint64 greenAngel, uint64 purpleAngel, uint64 yellowAngel, uint64 orangeAngel) public {
             
                 //can only claim each medal once per address. 
            if (claimedbyAddress[msg.sender][4] == true) {revert();}
                uint8[6] memory Auras;
                IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
            if  ((checkExistsOwnedAngel(blueAngel) == true) && (checkExistsOwnedAngel(redAngel) == true) && (checkExistsOwnedAngel(greenAngel) == true) && (checkExistsOwnedAngel(purpleAngel) == true) && (checkExistsOwnedAngel(yellowAngel) == true) && (checkExistsOwnedAngel(orangeAngel) == true)) {
                   //read all Aura colors       
                    (,,,Auras[0],,,,,,,) = angelCardData.getAngel(blueAngel);
                    (,,,Auras[1],,,,,,,) = angelCardData.getAngel(yellowAngel);
                    (,,,Auras[2],,,,,,,) = angelCardData.getAngel(purpleAngel);
                    (,,,Auras[3],,,,,,,) = angelCardData.getAngel(orangeAngel);
                    (,,,Auras[4],,,,,,,) = angelCardData.getAngel(redAngel);
                    (,,,Auras[5],,,,,,,) = angelCardData.getAngel(greenAngel);
                    //make sure each angel is of appropriate aura color
                    for (uint i=0;i<6;i++) {
                        if (Auras[i] != i) {revert();}
                    }
                        claimedbyAddress[msg.sender][4] == true;
                        IMedalData medalData = IMedalData(medalDataContract);   
                        medalData._createMedal(msg.sender, 4);
                        EventMedalSuccessful(msg.sender,4);
                    }
        
         }
        
        function claimGold(uint64 direDragonId, uint64 phoenixId, uint64 ligerId, uint64 alicornId) public  {
           //can only claim each medal once per address
         if (claimedbyAddress[msg.sender][5] == true) {revert();}
         
         //pets can each only be used once for this medal
         if ((petsClaimedGold[direDragonId] == true) || (petsClaimedGold[phoenixId] == true) || (petsClaimedGold[ligerId] == true) || (petsClaimedGold[alicornId]== true)) {revert();}
         
         if ((getPetCardSeries(direDragonId) == 13) && (getPetCardSeries(phoenixId) == 14) && (getPetCardSeries(ligerId) == 15) && (getPetCardSeries(alicornId) == 16)) {
             if ((checkExistsOwnedPet(direDragonId) == true) && (checkExistsOwnedPet(phoenixId) == true) && (checkExistsOwnedPet(ligerId) == true) && (checkExistsOwnedPet(alicornId) == true)) {
             petsClaimedGold[direDragonId] = true;
             petsClaimedGold[phoenixId] = true;
             petsClaimedGold[ligerId] = true;
             petsClaimedGold[alicornId] = true;
             claimedbyAddress[msg.sender][5] = true;
             IMedalData medalData = IMedalData(medalDataContract);   
             medalData._createMedal(msg.sender, 5);
             EventMedalSuccessful(msg.sender,5);
             }
             
         }
     }
          
        
           function claimPlatinum(uint64 angelId) public {
        
         //can only claim each medal once per address
         if (claimedbyAddress[msg.sender][6] == true) {revert();}
            if  (checkExistsOwnedAngel(angelId) == true) {
                     ILeaderboardData leaderboardData = ILeaderboardData(leaderboardDataContract);   
            if ((leaderboardData.verifyPosition(0, angelId, 0, 0) == true) || (leaderboardData.verifyPosition(1, angelId, 0, 0) == true)  || (leaderboardData.verifyPosition(2, angelId, 0, 0) == true)) {
                         claimedbyAddress[msg.sender][6] = true;
                         IMedalData medalData = IMedalData(medalDataContract);   
                        medalData._createMedal(msg.sender, 6);
                         EventMedalSuccessful(msg.sender,6);
                    }
            }
         }
         
              
        function claimStupidFluffyPink(uint64 petId) public {
         //can only claim each medal once per address
         if (claimedbyAddress[msg.sender][7] == true) {revert();}
         
         if ((getPetCardSeries(petId) == 13) || (getPetCardSeries(petId) == 14) || (getPetCardSeries(petId) == 15) || (getPetCardSeries(petId) == 16)) {
             if ((checkExistsOwnedPet(petId) == true) ) {
             IMedalData medalData = IMedalData(medalDataContract); 
             claimedbyAddress[msg.sender][7] = true;
             medalData._createMedal(msg.sender, 7);
             EventMedalSuccessful(msg.sender,7);
             }
             
         }
     }
     
     function ClaimOrichalcum() public {
         
            //can only claim each medal once per address
         if (claimedbyAddress[msg.sender][8] == true) {revert();}
              IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
              IPetCardData petCardData = IPetCardData(petCardDataContract);
              IAccessoryData accessoryData = IAccessoryData(accessoryDataContract);
              
              if ((angelCardData.getOwnerAngelCount(msg.sender) >= 15) && (petCardData.getOwnerPetCount(msg.sender) >= 25) && (accessoryData.getOwnerAccessoryCount(msg.sender) >= 10) ) {
             IMedalData medalData = IMedalData(medalDataContract);
             claimedbyAddress[msg.sender][8] = true;
             medalData._createMedal(msg.sender, 8);
             EventMedalSuccessful(msg.sender,8);    
              }
     }
     
     
      
      function getAngelClaims (uint64 angelId) public constant returns (bool claimedCardboard) {
          //before purchasing an angel card, anyone can verify if that card has already been used to claim medals
          if (angelId < 0) {revert();}
          claimedCardboard = angelsClaimedCardboard[angelId];

      }
      
          function getPetClaims (uint64 petId) public constant returns (bool claimedGold) {
          //before purchasing a pet card, anyone can verify if that card has already been used to claim medals
          if (petId < 0) {revert();}

          claimedGold = petsClaimedGold[petId];
      }
      
     
     
     function getAddressClaims(address _address, uint8 _medal) public constant returns (bool) {
         return claimedbyAddress[_address][_medal];
     }
     
     
      
      function kill() onlyCREATOR external {
        selfdestruct(creatorAddress);
    }
}