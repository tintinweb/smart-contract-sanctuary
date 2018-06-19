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

contract RetirePets is AccessControl, SafeMath {

  
   
    address public petCardDataContract = 0xB340686da996b8B3d486b4D27E38E38500A9E926;


   
    // events
   
    event EventNewPet(uint64 petID);

  



    // write functions
    function DataContacts( address _petCardDataContract) onlyCREATOR external {
        petCardDataContract = _petCardDataContract;
      
    }
    

       
    function checkPet (uint64  petID) private constant returns (uint8) {
              IPetCardData petCardData = IPetCardData(petCardDataContract);
              
        //check if a pet both exists and is owned by the message sender.
        // This function also returns the petcardSeriesID. 
     
        if ((petID <= 0) || (petID > petCardData.getTotalPets())) {return 0;}
        
        address petowner;
        uint8 petcardSeriesID;
     
      (,petcardSeriesID,,,,,,,,petowner) = petCardData.getPet(petID);
    
         if  (petowner != msg.sender)  {return 0;}
        
        return petcardSeriesID;
        
        
}
     function retireWildEasy(uint64 pet1, uint64 pet2, uint64 pet3, uint64 pet4, uint64 pet5, uint64 pet6) public {
            IPetCardData petCardData = IPetCardData(petCardDataContract);
         // Send this function the petIds of 6 of your Wild Easy (2 star pets) to receive 1 3 star pet. 
         
         //won&#39;t throw an error if you send a level3 pet, but will still recycle. This is to reduce gas costs for everyone. 
         if (checkPet(pet1) <5) {revert();}
         if (checkPet(pet2) <5) {revert();}
         if (checkPet(pet3) <5) {revert();}
         if (checkPet(pet4) <5) {revert();}
         if (checkPet(pet5) <5) {revert();}
         if (checkPet(pet6) <5) {revert();}
         
       petCardData.transferPet(msg.sender, address(0), pet1);
       petCardData.transferPet(msg.sender, address(0), pet2);
       petCardData.transferPet(msg.sender, address(0), pet3);
       petCardData.transferPet(msg.sender, address(0), pet4);
       petCardData.transferPet(msg.sender, address(0), pet5);
       petCardData.transferPet(msg.sender, address(0), pet6);
         uint8 _newLuck = getRandomNumber(39,30,msg.sender);
        getNewPetCard(getRandomNumber(12,9,msg.sender), _newLuck);
         
     }

    function retireWildHard(uint64 pet1, uint64 pet2, uint64 pet3, uint64 pet4, uint64 pet5, uint64 pet6) public {
            IPetCardData petCardData = IPetCardData(petCardDataContract);
         // Send this function the petIds of 6 of your Wild Hard (3 star pets) to receive 1 four star pet. 
         
        
         if (checkPet(pet1) <9) {revert();}
         if (checkPet(pet2) <9) {revert();}
         if (checkPet(pet3) <9) {revert();}
         if (checkPet(pet4) <9) {revert();}
         if (checkPet(pet5) <9) {revert();}
         if (checkPet(pet6) <9) {revert();}
         
       petCardData.transferPet(msg.sender, address(0), pet1);
       petCardData.transferPet(msg.sender, address(0), pet2);
       petCardData.transferPet(msg.sender, address(0), pet3);
       petCardData.transferPet(msg.sender, address(0), pet4);
       petCardData.transferPet(msg.sender, address(0), pet5);
       petCardData.transferPet(msg.sender, address(0), pet6);
       uint8 _newLuck = getRandomNumber(49,40,msg.sender);
        getNewPetCard(getRandomNumber(16,13,msg.sender), _newLuck);
         
     }


    
   function getNewPetCard(uint8 opponentId, uint8 _luck) private {
        uint16 _auraRed = 0;
        uint16 _auraYellow = 0;
        uint16 _auraBlue = 0;
        
        uint32 _auraColor = getRandomNumber(2,0,msg.sender);
        if (_auraColor == 0) { _auraRed = 14;}
        if (_auraColor == 1) { _auraYellow = 14;}
        if (_auraColor == 2) { _auraBlue = 14;}
        
      
        IPetCardData petCardData = IPetCardData(petCardDataContract);
        uint64 petId = petCardData.setPet(opponentId, msg.sender, &#39;Rover&#39;, _luck, _auraRed, _auraYellow, _auraBlue);
        EventNewPet(petId);
        }


 
      function kill() onlyCREATOR external {
        selfdestruct(creatorAddress);
    }
}