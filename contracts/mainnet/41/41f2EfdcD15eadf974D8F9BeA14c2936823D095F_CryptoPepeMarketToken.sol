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


contract CryptoPepeMarketToken is ERC721 {

  // Modified CryptoCelebs contract
  // Note: "Item" refers to a SocialMedia asset.
  
  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new item comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoSocialMedia"; // solhint-disable-line
  string public constant SYMBOL = "CryptoPepeMarketToken"; // solhint-disable-line

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 5000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

  mapping (uint256 => TopOwner) private topOwner;
  mapping (uint256 => address) public lastBuyer;

  /*** STORAGE ***/

  /// @dev A mapping from item IDs to the address that owns them. All items have
  ///  some valid owner address.
  mapping (uint256 => address) public itemIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from ItemIDs to an address that has been approved to call
  ///  transferFrom(). Each item can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public itemIndexToApproved;

  // @dev A mapping from ItemIDs to the price of the token.
  mapping (uint256 => uint256) private itemIndexToPrice;

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  struct TopOwner {
    address addr;
    uint256 price;
  }

  /*** DATATYPES ***/
  struct Item {
    string name;
	bytes32 message;
	address creatoraddress;		// Creators get the dev fee for item sales.
  }

  Item[] private items;

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
  function CryptoPepeMarketToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;

	// Restored bag holders
	 _createItem("Feelsgood", 0x7d9450A4E85136f46BA3F519e20Fea52f5BEd063,359808729788989630,"",address(this));
	_createItem("Ree",0x2C3756c4cB4Ff488F666a3856516ba981197f3f3,184801761494400960,"",address(this));
	_createItem("TwoGender",0xb16948C62425ed389454186139cC94178D0eFbAF,359808729788989630,"",address(this));
	_createItem("Gains",0xA69E065734f57B73F17b38436f8a6259cCD090Fd,359808729788989630,"",address(this));
	_createItem("Trump",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,94916238056430340,"",address(this));
	_createItem("Brain",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,94916238056430340,"",address(this));
	_createItem("Illuminati",0xbd6A9D2C44b571F33Ee2192BD2d46aBA2866405a,94916238056430340,"",address(this));
	_createItem("Hang",0x2C659bf56012deeEc69Aea6e87b6587664B99550,94916238056430340,"",address(this));
	_createItem("Pepesaur",0x7d9450A4E85136f46BA3F519e20Fea52f5BEd063,184801761494400960,"",address(this));
	_createItem("BlockChain",0x2C3756c4cB4Ff488F666a3856516ba981197f3f3,184801761494400960,"",address(this));
	_createItem("Wanderer",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,184801761494400960,"",address(this));
	_createItem("Link",0xBcce2CE773bE0250bdDDD4487d927aCCd748414F,184801761494400960,"",address(this));

	// Set top owners.
	topOwner[1] = TopOwner(0x7d9450A4E85136f46BA3F519e20Fea52f5BEd063,350000000000000000); 
    topOwner[2] = TopOwner(0xb16948C62425ed389454186139cC94178D0eFbAF, 350000000000000000); 
    topOwner[3] = TopOwner(0xA69E065734f57B73F17b38436f8a6259cCD090Fd, 350000000000000000); 
	lastBuyer[1] = ceoAddress;
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

    itemIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new Item with the given name.
  function createContractItem(string _name, bytes32 _message, address _creatoraddress) public onlyCOO {
    _createItem(_name, address(this), startingPrice, _message, _creatoraddress);
  }

  /// @notice Returns all the relevant information about a specific item.
  /// @param _tokenId The tokenId of the item of interest.
  function getItem(uint256 _tokenId) public view returns (
    string itemName,
    uint256 sellingPrice,
    address owner,
	bytes32 itemMessage,
	address creator
  ) {
    Item storage item = items[_tokenId];

    itemName = item.name;
	itemMessage = item.message;
    sellingPrice = itemIndexToPrice[_tokenId];
    owner = itemIndexToOwner[_tokenId];
	creator = item.creatoraddress;
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
    owner = itemIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId, bytes32 _message) public payable {
    address oldOwner = itemIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = itemIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    uint256 msgPrice = msg.value;
    require(msgPrice >= sellingPrice);

	// Onwer of the item gets 86%
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 86), 100));

	// Top 3 owners get 6% (2% each)
	uint256 twoPercentFee = uint256(SafeMath.mul(SafeMath.div(sellingPrice, 100), 2));
	topOwner[1].addr.transfer(twoPercentFee); 
    topOwner[2].addr.transfer(twoPercentFee); 
    topOwner[3].addr.transfer(twoPercentFee);

	uint256 fourPercentFee = uint256(SafeMath.mul(SafeMath.div(sellingPrice, 100), 4));

	// Transfer 4% to the last buyer
	lastBuyer[1].transfer(fourPercentFee);

	// Transfer 4% to the item creator. (Don&#39;t transfer if creator is the contract owner)
	if(items[_tokenId].creatoraddress != address(this)){
		items[_tokenId].creatoraddress.transfer(fourPercentFee);
	}


    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 86);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 86);
    } else {
      // third stage
      itemIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 86);
    }

    _transfer(oldOwner, newOwner, _tokenId);
	
    // ## Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

	// Update the message of the item 
	items[_tokenId].message = _message;

    TokenSold(_tokenId, sellingPrice, itemIndexToPrice[_tokenId], oldOwner, newOwner);

	// Set last buyer
	lastBuyer[1] = msg.sender;

	// Set next top owner (If applicable)
	if(sellingPrice > topOwner[3].price){
        for(uint8 i = 3; i >= 1; i--){
            if(sellingPrice > topOwner[i].price){
                if(i <= 2){ topOwner[3] = topOwner[2]; }
                if(i <= 1){ topOwner[2] = topOwner[1]; }
                topOwner[i] = TopOwner(msg.sender, sellingPrice);
                break;
            }
        }
    }

	// refund any excess eth to buyer
	uint256 excess = SafeMath.sub(msg.value, sellingPrice);
	msg.sender.transfer(excess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return itemIndexToPrice[_tokenId];
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
    address oldOwner = itemIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose social media tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Items array looking for items belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalItems = totalSupply();
      uint256 resultIndex = 0;

      uint256 itemId;
      for (itemId = 0; itemId <= totalItems; itemId++) {
        if (itemIndexToOwner[itemId] == _owner) {
          result[resultIndex] = itemId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return items.length;
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
    return itemIndexToApproved[_tokenId] == _to;
  }

  /// For creating Item
  function _createItem(string _name, address _owner, uint256 _price, bytes32 _message, address _creatoraddress) private {
    Item memory _item = Item({
      name: _name,
	  message: _message,
	  creatoraddress: _creatoraddress
    });
    uint256 newItemId = items.push(_item) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newItemId == uint256(uint32(newItemId)));

    Birth(newItemId, _name, _owner);

    itemIndexToPrice[newItemId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newItemId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == itemIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific Item to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of items is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    itemIndexToOwner[_tokenId] = _to;

    // When creating new items _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete itemIndexToApproved[_tokenId];
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