pragma solidity ^0.4.18; // solhint-disable-line



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract CelebrityToken is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new person comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoCelebrities"; // solhint-disable-line
  string public constant SYMBOL = "CelebrityToken"; // solhint-disable-line

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

  /*** STORAGE ***/

  /// @dev A mapping from person IDs to the address that owns them. All persons have
  ///  some valid owner address.
  mapping (uint256 => address) public personIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from PersonIDs to an address that has been approved to call
  ///  transferFrom(). Each Person can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public personIndexToApproved;

  // @dev A mapping from PersonIDs to the price of the token.
  mapping (uint256 => uint256) private personIndexToPrice;

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

  /*** DATATYPES ***/
  struct Person {
    string name;
  }

  Person[] private persons;

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  /// @dev Access modifier for COO-only functionality
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

  /*** CONSTRUCTOR ***/
  function CelebrityToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    personIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new promo Person with the given name, with given _price and assignes it to an address.
  function createPromoPerson(address _owner, string _name, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address personOwner = _owner;
    if (personOwner == address(0)) {
      personOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createPerson(_name, personOwner, _price);
  }

  /// @dev Creates a new Person with the given name.
  function createContractPerson(string _name) public onlyCOO {
    _createPerson(_name, address(this), startingPrice);
  }

  /// @notice Returns all the relevant information about a specific person.
  /// @param _tokenId The tokenId of the person of interest.
  function getPerson(uint256 _tokenId) public view returns (
    string personName,
    uint256 sellingPrice,
    address owner
  ) {
    Person storage person = persons[_tokenId];
    personName = person.name;
    sellingPrice = personIndexToPrice[_tokenId];
    owner = personIndexToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }

  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = personIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = personIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = personIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
      // third stage
      personIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.06)
    }

    TokenSold(_tokenId, sellingPrice, personIndexToPrice[_tokenId], oldOwner, newOwner, persons[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return personIndexToPrice[_tokenId];
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = personIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Persons array looking for persons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPersons = totalSupply();
      uint256 resultIndex = 0;

      uint256 personId;
      for (personId = 0; personId <= totalPersons; personId++) {
        if (personIndexToOwner[personId] == _owner) {
          result[resultIndex] = personId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return persons.length;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return personIndexToApproved[_tokenId] == _to;
  }

  /// For creating Person
  function _createPerson(string _name, address _owner, uint256 _price) private {
    Person memory _person = Person({
      name: _name
    });
    uint256 newPersonId = persons.push(_person) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newPersonId == uint256(uint32(newPersonId)));

    Birth(newPersonId, _name, _owner);

    personIndexToPrice[newPersonId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newPersonId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == personIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific Person to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of persons is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    personIndexToOwner[_tokenId] = _to;

    // When creating new persons _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete personIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/// @author Artyom Harutyunyan <artyomharutyunyans@gmail.com>

contract CelebrityBreederToken is ERC721 {
  
   /// @dev The Birth event is fired whenever a new person comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);
  event Trained(address caller, uint256 tokenId, bool generation);
  event Beaten(address caller, uint256 tokenId, bool generation);
  event SiringPriceEvent(address caller, uint256 tokenId, bool generation, uint price);
  event SellingPriceEvent(address caller, uint256 tokenId, bool generation, uint price);
  event GenesInitialisedEvent(address caller, uint256 tokenId, bool generation, uint genes);
  
  CelebrityToken private CelGen0=CelebrityToken(0xbb5Ed1EdeB5149AF3ab43ea9c7a6963b3C1374F7); //@Artyom Pointing to original CC
  CelebrityBreederToken private CelBetta=CelebrityBreederToken(0xdab64dc4a02225f76fccce35ab9ba53b3735c684); //@Artyom Pointing to betta 
 
  string public constant NAME = "CryptoCelebrityBreederCards"; 
  string public constant SYMBOL = "CeleBreedCard"; 

  uint256 public breedingFee = 0.01 ether;
  uint256 public initialTraining = 0.00001 ether;
  uint256 public initialBeating = 0.00002 ether;
  uint256 private constant CreationLimitGen0 = 5000;
  uint256 private constant CreationLimitGen1 = 2500000;
  uint256 public constant MaxValue =  100000000 ether;
  
  mapping (uint256 => address) public personIndexToOwnerGen1;
  mapping (address => uint256) private ownershipTokenCountGen1;
  mapping (uint256 => address) public personIndexToApprovedGen1;
  mapping (uint256 => uint256) private personIndexToPriceGen1;
  mapping (uint256 => address) public ExternalAllowdContractGen0;
  mapping (uint256 => address) public ExternalAllowdContractGen1; 
  mapping (uint256 => uint256) public personIndexToSiringPrice0;
  mapping (uint256 => uint256) public personIndexToSiringPrice1;
  address public CeoAddress; 
  address public DevAddress;
  
   struct Person {
    string name;
    string surname; 
    uint64 genes; 
    uint64 birthTime;
    uint32 fatherId;
    uint32 motherId;
    uint32 readyToBreedWithId;
    uint32 trainedcount;
    uint32 beatencount;
    bool readyToBreedWithGen;
    bool gender;
    bool fatherGeneration;
    bool motherGeneration;
  }
  
  Person[] private PersonsGen0;
  Person[] private PersonsGen1;
  
    modifier onlyCEO() {
    require(msg.sender == CeoAddress);
    _;
  }

  modifier onlyDEV() {
    require(msg.sender == DevAddress);
    _;
  }
  
   modifier onlyPlayers() {
    require(ownershipTokenCountGen1[msg.sender]>0 || CelGen0.balanceOf(msg.sender)>0);
    _;
  }

  /// Access modifier for contract owner only functionality
 /* modifier onlyTopLevel() {
    require(
      msg.sender == CeoAddress ||
      msg.sender == DevAddress
    );
    _;
  }
  */
  function masscreate(uint256 fromindex, uint256 toindex) external onlyCEO{ 
      string memory name; string memory surname; uint64 genes;  bool gender;
      for(uint256 i=fromindex;i<=toindex;i++)
      {
          ( name, surname, genes, , ,  , , ,  gender)=CelBetta.getPerson(i,false);
         _birthPerson(name, surname ,genes, gender, false);
      }
  }
  function CelebrityBreederToken() public { 
      CeoAddress= msg.sender;
      DevAddress= msg.sender;
  }
    function setBreedingFee(uint256 newfee) external onlyCEO{
      breedingFee=newfee;
  }
  function allowexternalContract(address _to, uint256 _tokenId,bool _tokengeneration) public { 
    // Caller must own token.
    require(_owns(msg.sender, _tokenId, _tokengeneration));
    
    if(_tokengeneration) {
        if(_addressNotNull(_to)) {
            ExternalAllowdContractGen1[_tokenId]=_to;
        }
        else {
             delete ExternalAllowdContractGen1[_tokenId];
        }
    }
    else {
       if(_addressNotNull(_to)) {
            ExternalAllowdContractGen0[_tokenId]=_to;
        }
        else {
             delete ExternalAllowdContractGen0[_tokenId];
        }
    }

  }
  
  
  //@Artyom Required for ERC-721 compliance.
  function approve(address _to, uint256 _tokenId) public { //@Artyom only gen1
    // Caller must own token.
    require(_owns(msg.sender, _tokenId, true));

    personIndexToApprovedGen1[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }
  // @Artyom Required for ERC-721 compliance.
  //@Artyom only gen1
   function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCountGen1[_owner];
  }
  
    function getPerson(uint256 _tokenId,bool generation) public view returns ( string name, string surname, uint64 genes,uint64 birthTime, uint32 readyToBreedWithId, uint32 trainedcount,uint32 beatencount,bool readyToBreedWithGen, bool gender) {
    Person person;
    if(generation==false) {
        person = PersonsGen0[_tokenId];
    }
    else {
        person = PersonsGen1[_tokenId];
    }
         
    name = person.name;
    surname=person.surname;
    genes=person.genes;
    birthTime=person.birthTime;
    readyToBreedWithId=person.readyToBreedWithId;
    trainedcount=person.trainedcount;
    beatencount=person.beatencount;
    readyToBreedWithGen=person.readyToBreedWithGen;
    gender=person.gender;

  }
   function getPersonParents(uint256 _tokenId, bool generation) public view returns ( uint32 fatherId, uint32 motherId, bool fatherGeneration, bool motherGeneration) {
    Person person;
    if(generation==false) {
        person = PersonsGen0[_tokenId];
    }
    else {
        person = PersonsGen1[_tokenId];
    }
         
    fatherId=person.fatherId;
    motherId=person.motherId;
    fatherGeneration=person.fatherGeneration;
    motherGeneration=person.motherGeneration;
  }
  // @Artyom Required for ERC-721 compliance.
   function implementsERC721() public pure returns (bool) { 
    return true;
  }

  // @Artyom Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }

// @Artyom Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId) public view returns (address owner)
  {
    owner = personIndexToOwnerGen1[_tokenId];
    require(_addressNotNull(owner));
  }
  
  //@Artyom only gen1
   function purchase(uint256 _tokenId) public payable {
    address oldOwner = personIndexToOwnerGen1[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = personIndexToPriceGen1[_tokenId];
    personIndexToPriceGen1[_tokenId]=MaxValue;

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

   // uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
    //  oldOwner.transfer(payment); //(1-0.06) //old code for holding some percents
    oldOwner.transfer(sellingPrice);
    }
    blankbreedingdata(_tokenId,true);

    TokenSold(_tokenId, sellingPrice, personIndexToPriceGen1[_tokenId], oldOwner, newOwner, PersonsGen1[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }
  
   //@Artyom only gen1
   function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return personIndexToPriceGen1[_tokenId];
  }

 
  function setCEO(address _newCEO) external onlyCEO {
    require(_addressNotNull(_newCEO));

    CeoAddress = _newCEO;
  }

 //@Artyom only gen1
 function setprice(uint256 _tokenId, uint256 _price) public {
    require(_owns(msg.sender, _tokenId, true));
    if(_price<=0 || _price>=MaxValue) {
        personIndexToPriceGen1[_tokenId]=MaxValue;
    }
    else {
        personIndexToPriceGen1[_tokenId]=_price;
    }
    SellingPriceEvent(msg.sender,_tokenId,true,_price);
 }
 
  function setDEV(address _newDEV) external onlyDEV {
    require(_addressNotNull(_newDEV));

    DevAddress = _newDEV;
  }
  
    // @Artyom Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }


  // @Artyom Required for ERC-721 compliance.
   //@Artyom only gen1
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = personIndexToOwnerGen1[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approvedGen1(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }
  
  //@Artyom only gen1
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } 
    else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPersons = totalSupply();
      uint256 resultIndex = 0;

      uint256 personId;
      for (personId = 0; personId <= totalPersons; personId++) {
        if (personIndexToOwnerGen1[personId] == _owner) {
          result[resultIndex] = personId;
          resultIndex++;
        }
      }
      return result;
    }
  }
  
   // @Artyom Required for ERC-721 compliance.
   //@Artyom only gen1
   function totalSupply() public view returns (uint256 total) {
    return PersonsGen1.length;
  }

   // @Artyom Required for ERC-721 compliance.
   //@Artyom only gen1
  function transfer( address _to, uint256 _tokenId) public {
    require(_owns(msg.sender, _tokenId, true));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }
  
   // @Artyom Required for ERC-721 compliance.
   //@Artyom only gen1
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_owns(_from, _tokenId, true));
    require(_approvedGen1(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }
  
   function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approvedGen1(address _to, uint256 _tokenId) private view returns (bool) {
    return personIndexToApprovedGen1[_tokenId] == _to;
  }
  //@Artyom only gen0
   function createPersonGen0(string _name, string _surname,uint64 _genes, bool _gender) external onlyCEO returns(uint256) {
    return _birthPerson(_name, _surname ,_genes, _gender, false);
  }
  function SetGene(uint256 tokenId,bool generation, uint64 newgene) public {
     require(_owns(msg.sender, tokenId, generation) || msg.sender==CeoAddress);
     require(newgene<=9999999999 && newgene>=10);
     Person person; //@Artyom reference
    if (generation==false) { 
        person = PersonsGen0[tokenId];
    }
    else {
        person = PersonsGen1[tokenId];
    }
    require(person.genes<=90);
     
    uint64 _gene=newgene;
    uint64 _pointCount=0;
   
   
      for(uint i=0;i<10;i++) {
           _pointCount+=_gene%10;
           _gene=_gene/10;
      }
    //  log(_pointCount,person.genes);
    require(_pointCount==person.genes);
           
    person.genes=newgene;
    GenesInitialisedEvent(msg.sender,tokenId,generation,newgene);
}
 
   function breed(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool  _withpersongeneration, string _boyname, string _girlname) public payable { //@Artyom mother
       require(_owns(msg.sender, _mypersonid, _mypersongeneration));
       require(CreationLimitGen1>totalSupply()+1);
    
    //Mother
    Person person; //@Artyom reference
    if(_mypersongeneration==false) { 
        person = PersonsGen0[_mypersonid];
    }
    else {
        person = PersonsGen1[_mypersonid];
        require(person.gender==false); //@Artyom checking gender for gen1 to be mother in this case
    }

    require(person.genes>90);//@Artyom if its unlocked
    
    uint64 genes1=person.genes;
    //Father
        if(_withpersongeneration==false) { 
        person = PersonsGen0[_withpersonid];
    }
    else {
        person = PersonsGen1[_withpersonid];
       
    }
     
   
     require(readyTobreed(_mypersonid, _mypersongeneration, _withpersonid,  _withpersongeneration));
     require(breedingFee<=msg.value);
   
    
    delete person.readyToBreedWithId;
    person.readyToBreedWithGen=false;
    
   // uint64 genes2=person.genes;
    
       uint64 _generatedGen;
       bool _gender; 
       (_generatedGen,_gender)=_generateGene(genes1,person.genes,_mypersonid,_withpersonid); 
       
     if(_gender) {
       _girlname=_boyname; //@Artyom if gender is true/1 then it should take the boyname
     }
       uint newid=_birthPerson(_girlname, person.surname, _generatedGen, _gender, true);
            PersonsGen1[newid].fatherGeneration=_withpersongeneration; // @ Artyom, did here because stack too deep for function
            PersonsGen1[newid].motherGeneration=_mypersongeneration;
            PersonsGen1[newid].fatherId=uint32(_withpersonid); 
            PersonsGen1[newid].motherId=uint32(_mypersonid);
        
        
       _payout();
  }
  
    function breedOnAuction(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool  _withpersongeneration, string _boyname, string _girlname) public payable { //@Artyom mother
       require(_owns(msg.sender, _mypersonid, _mypersongeneration));
       require(CreationLimitGen1>totalSupply()+1);
       require(!(_mypersonid==_withpersonid && _mypersongeneration==_withpersongeneration));// @Artyom not to breed with self
       require(!((_mypersonid==0 && _mypersongeneration==false) || (_withpersonid==0 && _withpersongeneration==false))); //Not to touch Satoshi
    //Mother
    Person person; //@Artyom reference
    if(_mypersongeneration==false) { 
        person = PersonsGen0[_mypersonid];
    }
    else {
        person = PersonsGen1[_mypersonid];
        require(person.gender==false); //@Artyom checking gender for gen1 to be mother in this case
    }
    
    require(person.genes>90);//@Artyom if its unlocked
    
    address owneroffather;
    uint256 _siringprice;
    uint64 genes1=person.genes;
    //Father
        if(_withpersongeneration==false) { 
        person = PersonsGen0[_withpersonid];
        _siringprice=personIndexToSiringPrice0[_withpersonid];
        owneroffather=CelGen0.ownerOf(_withpersonid);
    }
    else {
        person = PersonsGen1[_withpersonid];
        _siringprice=personIndexToSiringPrice1[_withpersonid];
        owneroffather= personIndexToOwnerGen1[_withpersonid];
    }
     
   require(_siringprice>0 && _siringprice<MaxValue);
   require((breedingFee+_siringprice)<=msg.value);
    
    
//    uint64 genes2=;
    
       uint64 _generatedGen;
       bool _gender; 
       (_generatedGen,_gender)=_generateGene(genes1,person.genes,_mypersonid,_withpersonid); 
       
     if(_gender) {
       _girlname=_boyname; //@Artyom if gender is true/1 then it should take the boyname
     }
       uint newid=_birthPerson(_girlname, person.surname, _generatedGen, _gender, true);
            PersonsGen1[newid].fatherGeneration=_withpersongeneration; // @ Artyom, did here because stack too deep for function
            PersonsGen1[newid].motherGeneration=_mypersongeneration;
            PersonsGen1[newid].fatherId=uint32(_withpersonid); 
            PersonsGen1[newid].motherId=uint32(_mypersonid);
        
        
        owneroffather.transfer(_siringprice);
       _payout();
  }
 
  
  
  function prepareToBreed(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool _withpersongeneration, uint256 _siringprice) external { //@Artyom father
      require(_owns(msg.sender, _mypersonid, _mypersongeneration)); 
      
       Person person; //@Artyom reference
    if(_mypersongeneration==false) {
        person = PersonsGen0[_mypersonid];
        personIndexToSiringPrice0[_mypersonid]=_siringprice;
    }
    else {
        person = PersonsGen1[_mypersonid];
        
        require(person.gender==true);//@Artyom for gen1 checking genders to be male
        personIndexToSiringPrice1[_mypersonid]=_siringprice;
    }
      require(person.genes>90);//@Artyom if its unlocked

       person.readyToBreedWithId=uint32(_withpersonid); 
       person.readyToBreedWithGen=_withpersongeneration;
       SiringPriceEvent(msg.sender,_mypersonid,_mypersongeneration,_siringprice);
      
  }
  
  function readyTobreed(uint256 _mypersonid, bool _mypersongeneration, uint256 _withpersonid, bool _withpersongeneration) public view returns(bool) {

if (_mypersonid==_withpersonid && _mypersongeneration==_withpersongeneration) //Not to fuck Themselves 
return false;

if((_mypersonid==0 && _mypersongeneration==false) || (_withpersonid==0 && _withpersongeneration==false)) //Not to touch Satoshi
return false;

    Person withperson; //@Artyom reference
    if(_withpersongeneration==false) {
        withperson = PersonsGen0[_withpersonid];
    }
    else {
        withperson = PersonsGen1[_withpersonid];
    }
   
   
   if(withperson.readyToBreedWithGen==_mypersongeneration) {
       if(withperson.readyToBreedWithId==_mypersonid) {
       return true;
   }
   }
  
    
    return false;
    
  }
  function _birthPerson(string _name, string _surname, uint64 _genes, bool _gender, bool _generation) private returns(uint256) { // about this steps   
    Person memory _person = Person({
        name: _name,
        surname: _surname,
        genes: _genes,
        birthTime: uint64(now),
        fatherId: 0,
        motherId: 0,
        readyToBreedWithId: 0,
        trainedcount: 0,
        beatencount: 0,
        readyToBreedWithGen: false,
        gender: _gender,
        fatherGeneration: false,
        motherGeneration: false

        
    });
    
    uint256 newPersonId;
    if(_generation==false) {
         newPersonId = PersonsGen0.push(_person) - 1;
    }
    else {
         newPersonId = PersonsGen1.push(_person) - 1;
         personIndexToPriceGen1[newPersonId] = MaxValue; //@Artyom indicating not for sale
          // per ERC721 draft-This will assign ownership, and also emit the Transfer event as
        _transfer(address(0), msg.sender, newPersonId);
        

    }

    Birth(newPersonId, _name, msg.sender);
    return newPersonId;
  }
  function _generateGene(uint64 _genes1,uint64 _genes2,uint256 _mypersonid,uint256 _withpersonid) private returns(uint64,bool) {
       uint64 _gene;
       uint64 _gene1;
       uint64 _gene2;
       uint64 _rand;
       uint256 _finalGene=0;
       bool gender=false;

       for(uint i=0;i<10;i++) {
           _gene1 =_genes1%10;
           _gene2=_genes2%10;
           _genes1=_genes1/10;
           _genes2=_genes2/10;
           _rand=uint64(keccak256(block.blockhash(block.number), i, now,_mypersonid,_withpersonid))%10000;
           
          _gene=(_gene1+_gene2)/2;
           
           if(_rand<26) {
               _gene-=3;
           }
            else if(_rand<455) {
                _gene-=2;
           }
            else if(_rand<3173) {
                _gene-=1;
           }
            else if(_rand<6827) {
                
           }
            else if(_rand<9545) {
                _gene+=1;
           }
            else if(_rand<9974) {
                _gene+=2;
           }
            else if(_rand<10000) {
                _gene+=3;
           }
           
           if(_gene>12) //@Artyom to avoid negative overflow
           _gene=0;
           if(_gene>9)
           _gene=9;
           
           _finalGene+=(uint(10)**i)*_gene;
       }
      
      if(uint64(keccak256(block.blockhash(block.number), 11, now,_mypersonid,_withpersonid))%2>0)
      gender=true;
      
      return(uint64(_finalGene),gender);  
  } 
  function _owns(address claimant, uint256 _tokenId,bool _tokengeneration) private view returns (bool) {
   if(_tokengeneration) {
        return ((claimant == personIndexToOwnerGen1[_tokenId]) || (claimant==ExternalAllowdContractGen1[_tokenId]));
   }
   else {
       return ((claimant == CelGen0.personIndexToOwner(_tokenId)) || (claimant==ExternalAllowdContractGen0[_tokenId]));
   }
  }
      
  function _payout() private {
    DevAddress.transfer((this.balance/10)*3);
    CeoAddress.transfer((this.balance/10)*7); 
  }
  
   // @Artyom Required for ERC-721 compliance.
   //@Artyom only gen1
   function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of persons is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCountGen1[_to]++;
    //transfer ownership
    personIndexToOwnerGen1[_tokenId] = _to;

    // When creating new persons _from is 0x0, but we can&#39;t account that address.
    if (_addressNotNull(_from)) {
      ownershipTokenCountGen1[_from]--;
      // clear any previously approved ownership exchange
     blankbreedingdata(_tokenId,true);
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
  function blankbreedingdata(uint256 _personid, bool _persongeneration) private{
      Person person;
      if(_persongeneration==false) { 
        person = PersonsGen0[_personid];
        delete ExternalAllowdContractGen0[_personid];
        delete personIndexToSiringPrice0[_personid];
    }
    else {
        person = PersonsGen1[_personid];
        delete ExternalAllowdContractGen1[_personid];
        delete personIndexToSiringPrice1[_personid];
    	delete personIndexToApprovedGen1[_personid];
    }
     delete person.readyToBreedWithId;
     delete person.readyToBreedWithGen; 
  }
    function train(uint256 personid, bool persongeneration, uint8 gene) external payable onlyPlayers {
        
        require(gene>=0 && gene<10);
        uint256 trainingPrice=checkTrainingPrice(personid,persongeneration);
        require(msg.value >= trainingPrice);
         Person person; 
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    
     require(person.genes>90);//@Artyom if its unlocked
     uint gensolo=person.genes/(uint(10)**gene);
    gensolo=gensolo%10;
    require(gensolo<9); //@Artyom not to train after 9
    
          person.genes+=uint64(10)**gene;
          person.trainedcount++;

    uint256 purchaseExcess = SafeMath.sub(msg.value, trainingPrice);
    msg.sender.transfer(purchaseExcess);
    _payout();
    Trained(msg.sender, personid, persongeneration);
    }
    
     function beat(uint256 personid, bool persongeneration, uint8 gene) external payable onlyPlayers {
        require(gene>=0 && gene<10);
        uint256 beatingPrice=checkBeatingPrice(personid,persongeneration);
        require(msg.value >= beatingPrice);
         Person person; 
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    
    require(person.genes>90);//@Artyom if its unlocked
    uint gensolo=person.genes/(uint(10)**gene);
    gensolo=gensolo%10;
    require(gensolo>0);
          person.genes-=uint64(10)**gene;
          person.beatencount++;

    uint256 purchaseExcess = SafeMath.sub(msg.value, beatingPrice);
    msg.sender.transfer(purchaseExcess);
    _payout();
    Beaten(msg.sender, personid, persongeneration);    
    }
    
    
    function checkTrainingPrice(uint256 personid, bool persongeneration) view returns (uint256) {
         Person person;
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    
    uint256 _trainingprice= (uint(2)**person.trainedcount) * initialTraining;
    if (_trainingprice > 5 ether)
    _trainingprice=5 ether;
    
    return _trainingprice;
    }
    function checkBeatingPrice(uint256 personid, bool persongeneration) view returns (uint256) {
         Person person;
    if(persongeneration==false) {
        person = PersonsGen0[personid];
    }
    else {
        person = PersonsGen1[personid];
    }
    uint256 _beatingprice=(uint(2)**person.beatencount) * initialBeating;
     if (_beatingprice > 7 ether)
    _beatingprice=7 ether;
    return _beatingprice;
    } 
  
}