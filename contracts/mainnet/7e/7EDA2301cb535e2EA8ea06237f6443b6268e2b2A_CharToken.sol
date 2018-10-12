//EA 0x7EDA2301cb535e2EA8ea06237f6443b6268e2b2A  ETH Main net


pragma solidity ^0.4.25; // solhint-disable-line
/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public view returns (bool);
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


//********************************************************************


contract CharToken is ERC721 {
  /*** EVENTS ***/
  /// @dev The Birth event is fired whenever a new char comes into existence.
  event Birth(uint256 tokenId, string wikiID_Name, address owner);
  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, string wikiID_Name);
  /// @dev Transfer event as defined in current draft of ERC721.
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);
  /// @dev Emitted when a bug is found int the contract and the contract is upgraded at a new address.
  /// In the event this happens, the current contract is paused indefinitely
  event ContractUpgrade(address newContract);
  ///bonus issuance    
  event Bonus(address to, uint256 bonus);

  /*** CONSTANTS ***/
  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoChars"; // solhint-disable-line
  string public constant SYMBOL = "CHARS"; // solhint-disable-line
  bool private erc721Enabled = false;
  uint256 private startingPrice = 0.005 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 50000;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.20 ether;
  uint256 private thirdStepLimit = 0.5 ether;

  /*** STORAGE ***/
  /// @dev A mapping from char IDs to the address that owns them. All chars have
  ///  some valid owner address.
  mapping (uint256 => address) public charIndexToOwner;
 // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;
  /// @dev A mapping from CharIDs to an address that has been approved to call
  ///  transferFrom(). Each Char can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public charIndexToApproved;
  // @dev A mapping from CharIDs to the price of the token.
  mapping (uint256 => uint256) private charIndexToPrice;
  // @dev A mapping from owner address to its total number of transactions
  mapping (address => uint256) private addressToTrxCount;
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;
  address public cfoAddress;
  uint256 public promoCreatedCount;
  //***pack below into a struct for gas optimization    
  //promo per each N trx is effective until date, and its frequency (every nth buy)
  uint256 public bonusUntilDate;   
  uint256 bonusFrequency;
  /*** DATATYPES ***/
  struct Char {
    //name of the char
    //string name;
    //wiki pageid of char
    string wikiID_Name; //save gas
  }
  Char[] private chars; 

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
  /// @dev Access modifier for CFO-only functionality
  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }
  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }
  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress ||
      msg.sender == cfoAddress 
    );
    _;
  }
  /*** CONSTRUCTOR ***/
  constructor() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    bonusUntilDate = now; //Bonus after Nth buy is valid until this date
    bonusFrequency = 3; //Bonus distributed after every Nth buy
    
    //create genesis chars
    createContractChar("42268616_Captain Ahab",0);
    createContractChar("455401_Frankenstein",0);
    createContractChar("8670724_Dracula",0);
    createContractChar("27159_Sherlock Holmes",0);
    createContractChar("160108_Snow White",0);
    createContractChar("73453_Cinderella",0);
    createContractChar("14966133_Pinocchio",0);
    createContractChar("369427_Lemuel Gulliver",0);
    createContractChar("26171_Robin Hood",0);
    createContractChar("197889_Felix the Cat",0);
    createContractChar("382164_Wizard of Oz",0);
    createContractChar("62446_Alice",0);
    createContractChar("8237_Don Quixote",0);
    createContractChar("16808_King Arthur",0);
    createContractChar("194085_Sleeping Beauty",0);
    createContractChar("299250_Little Red Riding Hood",0);
    createContractChar("166604_Aladdin",0);
    createContractChar("7640956_Peter Pan",0);
    createContractChar("927344_Ali Baba",0);
    createContractChar("153957_Lancelot",0);
    createContractChar("235918_Dr._Jekyll_and_Mr._Hyde",0);
    createContractChar("157787_Captain_Nemo",0);
    createContractChar("933085_Moby_Dick",0);
    createContractChar("54246379_Dorian_Gray",0);
    createContractChar("55483_Robinson_Crusoe",0);
    createContractChar("380143_Black_Beauty",0);
    createContractChar("6364074_Phantom_of_the_Opera",0); 
    createContractChar("15055_Ivanhoe",0);
    createContractChar("21491685_Tarzan",0);
    /* */    
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
  ) public onlyERC721 {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    charIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }


  /// @dev Creates a new Char with the given name
  function createContractChar(string _wikiID_Name, uint256 _price) public onlyCLevel {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);
    if (_price <= 0) {
      _price = startingPrice;
    }
    promoCreatedCount++;
    _createChar(_wikiID_Name, address(this), _price);
  }
  /// @notice Returns all the relevant information about a specific char.
  /// @param _tokenId The tokenId of the char of interest.
  function getChar(uint256 _tokenId) public view returns (
    string wikiID_Name,
    uint256 sellingPrice,
    address owner
  ) {
    Char storage char = chars[_tokenId];
    wikiID_Name = char.wikiID_Name;
    sellingPrice = charIndexToPrice[_tokenId];
    owner = charIndexToOwner[_tokenId];
  }
  function changeWikiID_Name(uint256 _tokenId, string _wikiID_Name) public onlyCLevel {
    require(_tokenId < chars.length);
    chars[_tokenId].wikiID_Name = _wikiID_Name;
  }
  function changeBonusUntilDate(uint32 _days) public onlyCLevel {
       bonusUntilDate = now + (_days * 1 days);
  }
  function changeBonusFrequency(uint32 _n) public onlyCLevel {
       bonusFrequency = _n;
  }
  function overrideCharPrice(uint256 _tokenId, uint256 _price) public onlyCLevel {
    require(_price != charIndexToPrice[_tokenId]);
    require(_tokenId < chars.length);
    //C level can override price for only own and contract tokens
    require((_owns(address(this), _tokenId)) || (  _owns(msg.sender, _tokenId)) ); 
    charIndexToPrice[_tokenId] = _price;
  }
  function changeCharPrice(uint256 _tokenId, uint256 _price) public {
    require(_owns(msg.sender, _tokenId));
    require(_tokenId < chars.length);
    require(_price != charIndexToPrice[_tokenId]);
    //require(_price > charIndexToPrice[_tokenId]);  //EA>should we enforce this?
    uint256 maxPrice = SafeMath.div(SafeMath.mul(charIndexToPrice[_tokenId], 1000),100); //10x 
    uint256 minPrice = SafeMath.div(SafeMath.mul(charIndexToPrice[_tokenId], 50),100); //half price
    require(_price >= minPrice); 
    require(_price <= maxPrice); 
    charIndexToPrice[_tokenId] = _price; 
  }
  /* ERC721 */
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }
  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }
  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }
  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = charIndexToOwner[_tokenId];
    require(owner != address(0));
  }
//  function payout(address _to) public onlyCLevel {
//    _payout(_to);
//  }
  function withdrawFunds(address _to, uint256 amount) public onlyCLevel {
    _withdrawFunds(_to, amount);
  }
  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId, uint256 newPrice) public payable {
    address oldOwner = charIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    uint256 sellingPrice = charIndexToPrice[_tokenId];
    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);
    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));
    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    // Update prices
    if (newPrice >= sellingPrice) charIndexToPrice[_tokenId] = newPrice;
    else {
            if (sellingPrice < firstStepLimit) {
              // first stage
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
            } else if (sellingPrice < secondStepLimit) {
              // second stage
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
            } else if (sellingPrice < thirdStepLimit) {
              // second stage
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 100);
            } else {
              // third stage
              charIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 100);
            }
    }
    _transfer(oldOwner, newOwner, _tokenId);
    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.06)
    }
    emit TokenSold(_tokenId, sellingPrice, charIndexToPrice[_tokenId], oldOwner, newOwner,
      chars[_tokenId].wikiID_Name);
    msg.sender.transfer(purchaseExcess);
    //distribute bonus if earned and promo is ongoing and every nth buy trx
      if( (now < bonusUntilDate && (addressToTrxCount[newOwner] % bonusFrequency) == 0) ) 
      {
          //bonus operation here
          uint rand = uint (keccak256(now)) % 50 ; //***earn up to 50% of 6% commissions
          rand = rand * (sellingPrice-payment);  //***replace later. this is for test
          _withdrawFunds(newOwner,rand);
          emit Bonus(newOwner,rand);
      }
  }
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return charIndexToPrice[_tokenId];
  }
  // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
  function enableERC721() public onlyCEO {
    erc721Enabled = true;
  }
  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }
  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCOO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }
/// @dev Assigns a new address to act as the CFO. Only available to the current CFO.
  /// @param _newCFO The address of the new CFO
  function setCFO(address _newCFO) public onlyCFO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }
  
  
  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = charIndexToOwner[_tokenId];
     // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));
    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));
    _transfer(oldOwner, newOwner, _tokenId);
  }
  /// @param _owner The owner whose char tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Chars array looking for chars belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalChars = chars.length;
      uint256 resultIndex = 0;
      uint256 t;
      for (t = 0; t <= totalChars; t++) {
        if (charIndexToOwner[t] == _owner) {
          result[resultIndex] = t;
          resultIndex++;
        }
      }
      return result;
    }
  }
  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return chars.length;
  }
  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public onlyERC721 {
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
  ) public onlyERC721 {
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
    return charIndexToApproved[_tokenId] == _to;
  }
  /// For creating Char
  function _createChar(string _wikiID_Name, address _owner, uint256 _price) private {
    Char memory _char = Char({
      wikiID_Name: _wikiID_Name
    });
    uint256 newCharId = chars.push(_char) - 1;
    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newCharId == uint256(uint32(newCharId)));
    emit Birth(newCharId, _wikiID_Name, _owner);
    charIndexToPrice[newCharId] = _price;
    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newCharId);
  }
  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == charIndexToOwner[_tokenId];
  }
  /// For paying out balance on contract
//  function _payout(address _to) private {
//    if (_to == address(0)) {
//      ceoAddress.transfer(address(this).balance);
//    } else {
//      _to.transfer(address(this).balance);
//    }
//  }
 function _withdrawFunds(address _to, uint256 amount) private {
    require(address(this).balance >= amount);
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }
  /// @dev Assigns ownership of a specific Char to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of chars is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    charIndexToOwner[_tokenId] = _to;
    // When creating new chars _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete charIndexToApproved[_tokenId];
    }
    // Emit the transfer event.
    emit Transfer(_from, _to, _tokenId);
  //update trx count  
  addressToTrxCount[_to]++;
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