pragma solidity ^0.4.19;

/**
 * @title Ownable
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title SafeMath Library
 */
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

/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

  // Total amount of tokens
  uint256 private totalTokens;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
  * @dev Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  /**
  * @dev Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

  /**
  * @dev Gets the list of tokens owned by a given address
  * @param _owner address to query the tokens of
  * @return uint256[] representing the list of tokens owned by the passed address
  */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

  /**
  * @dev Gets the owner of the specified token ID
  * @param _tokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Gets the approved address to take ownership of a given token ID
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved to take ownership of the given token ID
   */
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
  * @dev Transfers the ownership of a given token ID to another address
  * @param _to address to receive the ownership of the given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

  /**
  * @dev Approves another address to claim for the ownership of the given token ID
  * @param _to address to be approved for the given token ID
  * @param _tokenId uint256 ID of the token to be approved
  */
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

  /**
  * @dev Claims the ownership of a given token ID
  * @param _tokenId uint256 ID of the token being claimed by the msg.sender
  */
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

  /**
  * @dev Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

  /**
  * @dev Burns a specific token
  * @param _tokenId uint256 ID of the token being burned by the msg.sender
  */
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

  /**
   * @dev Tells whether the msg.sender is approved for the given token ID or not
   * This function is not private so it can be extended in further implementations like the operatable ERC721
   * @param _owner address of the owner to query the approval of
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return bool whether the msg.sender is approved for the given token ID or not
   */
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

  /**
  * @dev Internal function to clear current approval and transfer the ownership of a given token ID
  * @param _from address which you want to send tokens from
  * @param _to address which you want to transfer the token to
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  /**
  * @dev Internal function to clear current approval of a given token ID
  * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

  /**
  * @dev Internal function to remove a token ID from the list of a given address
  * @param _from address representing the previous owner of the given token ID
  * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
  */
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}

/**
 * @title CryptoThingWithDescendants
 */
contract CryptoThingWithDescendants is Ownable, ERC721Token {
  using SafeMath for uint256;

  struct Thing {
    uint256 id;
    uint256 parentId;
    uint256 purchasePrice;
    uint256 growthRate;
    uint256 dividendRate;
    uint256 dividendsPaid;
    uint256 lastAction;
    bytes32 displayName;
  }

  uint256 public gameCost = 10 ether;
  uint256 public floorPrice = 10 finney;
  uint256 public standardGrowthRate = 150;
  uint256 public numThings;
  mapping (uint256 => Thing) public things;
  mapping (uint256 => uint256[]) public descendantsOfThing;

  string constant public NAME = &#39;Star Card&#39;;
  string constant public SYMBOL = &#39;CARD&#39;;

  event DividendPaid(address indexed recipient, uint256 amount);
  event OverpaymentRefunded(uint256 amountExpected, uint256 excessFunds);
  event ThingBorn(uint256 indexed thingId, uint256 initialPrice);
  event ThingDestroyed(uint256 indexed thingId);
  event ThingSold(
    uint256 indexed thingId,
    uint256 oldPrice,
    uint256 newPrice,
    address oldOwner,
    address newOwner
  );

  function () payable public {
    // someone sent a gift! yay!
    owner.transfer(msg.value);
  }

  function name() constant public returns (string) {
    return NAME;
  }

  function symbol() constant public returns (string) {
    return SYMBOL;
  }

  function addThing(
    uint256 _parentId,
    uint256 _purchasePrice,
    uint256 _growthRate,
    uint256 _dividendRate,
    bytes32 _displayName
  ) public onlyOwner returns (uint256 thingId) {
    thingId = ++numThings;
    things[thingId] = Thing({
      id: thingId,
      parentId: _parentId,
      purchasePrice: _purchasePrice == 0 ? floorPrice : _purchasePrice,
      growthRate: _growthRate == 0 ? standardGrowthRate : _growthRate,
      dividendRate: _dividendRate,
      dividendsPaid: 0,
      lastAction: block.timestamp,
      displayName: _displayName
    });

    if (_parentId != 0) descendantsOfThing[_parentId].push(thingId);

    _mint(msg.sender, thingId);
    ThingBorn(thingId, things[thingId].purchasePrice);
  }

  function purchase(uint256 _thingId) public payable {
    require(_thingId != 0 && _thingId <= numThings);

    address previousOwner = ownerOf(_thingId);
    require(previousOwner != msg.sender);

    Thing storage thing = things[_thingId];
    uint256[] storage descendants = descendantsOfThing[_thingId];

    uint256 currentPrice = getCurrentPrice(_thingId);
    require(msg.value >= currentPrice);
    if (msg.value > currentPrice) {
      OverpaymentRefunded(currentPrice, msg.value.sub(currentPrice));
      msg.sender.transfer(msg.value.sub(currentPrice));
    }

    if (thing.dividendRate != 0 && (thing.parentId != 0 || descendants.length > 0)) {
      uint256 numDividends = thing.parentId == 0 ? descendants.length : descendants.length.add(1);
      uint256 dividendPerRecipient = getDividendPayout(
        currentPrice,
        thing.dividendRate,
        numDividends
      );

      address dividendRecipient = address(this);
      for (uint256 i = 0; i < numDividends; i++) {
        dividendRecipient = ownerOf(
          i == descendants.length ? thing.parentId : descendants[i]
        );
        dividendRecipient.transfer(dividendPerRecipient);
        DividendPaid(dividendRecipient, dividendPerRecipient);
      }

      thing.dividendsPaid = thing.dividendsPaid.add(dividendPerRecipient.mul(numDividends));
    }

    uint256 previousHolderShare = currentPrice.sub(
      dividendPerRecipient.mul(numDividends)
    );

    uint256 fee = previousHolderShare.div(20);
    owner.transfer(fee);

    previousOwner.transfer(previousHolderShare.sub(fee));
    thing.purchasePrice = thing.purchasePrice.mul(thing.growthRate).div(100);
    thing.lastAction = block.timestamp;

    clearApprovalAndTransfer(previousOwner, msg.sender, _thingId);
    ThingSold(_thingId, currentPrice, thing.purchasePrice, previousOwner, msg.sender);
  }

  function purchaseGame() public payable {
    require(msg.sender != owner);
    require(msg.value >= gameCost);
    owner.transfer(msg.value);
    owner = msg.sender;
    OwnershipTransferred(owner, msg.sender);
  }

  function setGameCost(uint256 newCost) public onlyOwner {
    gameCost = newCost;
  }

  function getDescendantsOfThing(uint256 _thingId) public view returns (uint256[]) {
    return descendantsOfThing[_thingId];
  }

  function getCurrentPrice(
    uint256 _thingId
  ) public view returns (uint256 currentPrice) {
    require(_thingId != 0 && _thingId <= numThings);
    Thing storage thing = things[_thingId];
    currentPrice = getPurchasePrice(thing.purchasePrice, thing.growthRate);
  }

  function getPurchasePrice(
    uint256 _currentPrice,
    uint256 _priceIncrease
  ) internal pure returns (uint256 currentPrice) {
    currentPrice = _currentPrice.mul(_priceIncrease).div(100);
  }

  function getDividendPayout(
    uint256 _purchasePrice,
    uint256 _dividendRate,
    uint256 _numDividends
  ) public pure returns (uint256 dividend) {
    dividend = _purchasePrice.mul(
      _dividendRate
    ).div(
      100
    ).sub(
      _purchasePrice
    ).div(
      _numDividends
    );
  }
}