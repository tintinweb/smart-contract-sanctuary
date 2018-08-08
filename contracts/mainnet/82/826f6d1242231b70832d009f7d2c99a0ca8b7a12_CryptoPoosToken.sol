pragma solidity ^0.4.18; 



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
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


contract CryptoPoosToken is ERC721 {

  // Modified CryptoCelebs contract
  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new poo comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  // Triggered on toilet flush
  event ToiletPotChange();

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoPoos"; // solhint-disable-line
  string public constant SYMBOL = "CryptoPoosToken"; // solhint-disable-line

  uint256 private startingPrice = 0.005 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  
  // Min price to flush the toilet
  uint256 private minFlushPrice = 0.002 ether;


  /*** STORAGE ***/

  /// @dev A mapping from poo IDs to the address that owns them. All poos have
  ///  some valid owner address.
  mapping (uint256 => address) public pooIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from PooIDs to an address that has been approved to call
  ///  transferFrom(). Each poo can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public pooIndexToApproved;

  // @dev A mapping from PooIDs to the price of the token.
  mapping (uint256 => uint256) private pooIndexToPrice;
  
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;
  
  uint256 roundCounter;
  address lastFlusher;   // Person that flushed
  uint256 flushedTokenId;   // Poo that got flushed
  uint256 lastPotSize; //Stores last pot size obviously
  uint256 goldenPooId; // Current golden poo id
  uint public lastPurchaseTime; // Tracks time since last purchase

  /*** DATATYPES ***/
  struct Poo {
    string name;
  }

  Poo[] private poos;

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
  function CryptoPoosToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
	
	createContractPoo("1");
	createContractPoo("2");
	createContractPoo("3");
	createContractPoo("4");
	createContractPoo("5");
	createContractPoo("6");
	roundCounter = 1;
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

    pooIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new poo with the given name.
  function createContractPoo(string _name) public onlyCOO {
    _createPoo(_name, address(this), startingPrice);
  }

  /// @notice Returns all the relevant information about a specific poo.
  /// @param _tokenId The tokenId of the poo of interest.
  function getPoo(uint256 _tokenId) public view returns (
    string pooName,
    uint256 sellingPrice,
    address owner
  ) {
    Poo storage poo = poos[_tokenId];
    pooName = poo.name;
    sellingPrice = pooIndexToPrice[_tokenId];
    owner = pooIndexToOwner[_tokenId];
  }

  function getRoundDetails() public view returns (
    uint256 currentRound,
	uint256 currentBalance,
	uint256 currentGoldenPoo,
	uint256 lastRoundReward,
    uint256 lastFlushedTokenId,
    address lastRoundFlusher,
	bool bonusWinChance,
	uint256 lowestFlushPrice
  ) {
	currentRound = roundCounter;
	currentBalance = this.balance;
	currentGoldenPoo = goldenPooId;
	lastRoundReward = lastPotSize;
	lastFlushedTokenId = flushedTokenId;
	lastRoundFlusher = lastFlusher;
	bonusWinChance = _increaseWinPotChance();
	lowestFlushPrice = minFlushPrice;
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
    owner = pooIndexToOwner[_tokenId];
    require(owner != address(0));
  }

   function donate() public payable {
	require(msg.value >= 0.001 ether);
   }


  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = pooIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = pooIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    // 62% to previous owner
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 62), 100));
  
    // 8% to the jew
    ceoAddress.transfer(uint256(SafeMath.div(SafeMath.mul(sellingPrice, 8), 100)));

	// 30% goes to the pot

    // Next token price is double
     pooIndexToPrice[_tokenId] = uint256(SafeMath.mul(sellingPrice, 2));

    _transfer(oldOwner, newOwner, _tokenId);
	
    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); 
    }

    _checkToiletFlush(false, _tokenId); 
	lastPurchaseTime = now;
	ToiletPotChange();
  }
  
  // User is trying to flush the toilet. See if they succeed
  function tryFlush() public payable {

        // Make sure they are sending min flush price
        require(msg.value >= minFlushPrice);

		// Jew takes 10% of manual flush attempt. Stops dat spam....
		ceoAddress.transfer(uint256(SafeMath.div(SafeMath.mul(msg.value, 10), 100)));

        _checkToiletFlush(true, 0);
		lastPurchaseTime = now;
		ToiletPotChange();
  }
  
  // If manual flush attempt, the user has a chance to flush their own poo
 function _checkToiletFlush(bool _manualFlush, uint256 _purchasedTokenId) private {
     
    uint256 winningChance = 25;

	// We are calling manual flush option, so the chance of winning is less
	if(_manualFlush){
		winningChance = 50;
	}else if(_purchasedTokenId == goldenPooId){
		// If buying golden poo, and is not a manual flush, increase chance of winning!
		winningChance = uint256(SafeMath.div(SafeMath.mul(winningChance, 90), 100));
	}

	// Check if we are trippling chance to win on next flush attempt/poop purchase
	if(_increaseWinPotChance()){
		winningChance = uint256(SafeMath.div(winningChance,3));
	}
     
    // Check if owner owns a poo. If not, their chance of winning is lower
    if(ownershipTokenCount[msg.sender] == 0){
        winningChance = uint256(SafeMath.mul(winningChance,2));
    }
     
    uint256 flushPooIndex = rand(winningChance);
    
    if( (flushPooIndex < 6) && (flushPooIndex != goldenPooId) &&  (msg.sender != pooIndexToOwner[flushPooIndex])  ){
      lastFlusher = msg.sender;
	  flushedTokenId = flushPooIndex;
      
      _transfer(pooIndexToOwner[flushPooIndex],address(this),flushPooIndex);
      pooIndexToPrice[flushPooIndex] = startingPrice;
      
      // Leave 5% behind for next pot
	  uint256 reward = uint256(SafeMath.div(SafeMath.mul(this.balance, 95), 100));
	  lastPotSize = reward;

      msg.sender.transfer(reward); // Send reward to purchaser
	  goldenPooId = rand(6);// There is a new golden poo in town.

	  roundCounter += 1; // Keeps track of how many flushes
    }
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return pooIndexToPrice[_tokenId];
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

  // If 2 hours elapsed since last purchase, increase chance of winning pot.
  function _increaseWinPotChance() constant private returns (bool) {
    if (now >= lastPurchaseTime + 120 minutes) {
        // 120 minutes has elapsed from last purchased time
        return true;
    }
    return false;
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
    address oldOwner = pooIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose social media tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire poos array looking for poos belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPoos = totalSupply();
      uint256 resultIndex = 0;

      uint256 pooId;
      for (pooId = 0; pooId <= totalPoos; pooId++) {
        if (pooIndexToOwner[pooId] == _owner) {
          result[resultIndex] = pooId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return poos.length;
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
    return pooIndexToApproved[_tokenId] == _to;
  }

  /// For creating Poo
  function _createPoo(string _name, address _owner, uint256 _price) private {
    Poo memory _poo = Poo({
      name: _name
    });
    uint256 newPooId = poos.push(_poo) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newPooId == uint256(uint32(newPooId)));

    Birth(newPooId, _name, _owner);

    pooIndexToPrice[newPooId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newPooId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == pooIndexToOwner[_tokenId];
  }

  /// @dev Assigns ownership of a specific Poo to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of poos is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    pooIndexToOwner[_tokenId] = _to;

    // When creating new poos _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete pooIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
  
    //Generate random number between 0 & max
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
    function rand(uint max) constant private returns (uint256 result){
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
    
        return uint256((uint256(hashVal) / factor)) % max;
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