pragma solidity ^0.4.18; // solhint-disable-line

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6f0b0a1b0a2f0e17060002150a01410c00">[email&#160;protected]</a>> (https://github.com/dete)
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
}


contract MemeToken is ERC721 {
  /*** EVENTS ***/
  /// @dev The Birth event is fired whenever a new meme comes into existence.
  event Birth(uint256 tokenId, uint256 metadata, string text, address owner);

  /// @dev The TokenSold event is fired whenever a meme is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, uint256 metadata, string text);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/
  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoMemes"; // solhint-disable-line
  string public constant SYMBOL = "CM"; // solhint-disable-line

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 50000;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;

  /*** STORAGE ***/
  /// @dev A mapping from meme IDs to the address that owns them. All memes have
  ///  some valid owner address.
  mapping (uint256 => address) public memeIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from memeIDs to an address that has been approved to call
  ///  transferFrom(). Each meme can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public memeIndexToApproved;

  // @dev A mapping from memeIDs to the price of the token.
  mapping (uint256 => uint256) private memeIndexToPrice;

  // The address of the account that can execute special actions.
  // Not related to Dogecoin, just a normal Doge.
  address public dogeAddress;
  // Robot9000 address for automation.
  // Not related to r9k, just a normal robot.
  address public r9kAddress;

  uint256 public promoCreatedCount;

  /*** DATATYPES ***/
  struct Meme {
    uint256 metadata;
    string text;
  }

  // All your memes are belong to us.
  Meme[] private memes;

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for Doge functionality
  modifier onlyDoge() {
    require(msg.sender == dogeAddress);
    _;
  }

  /// @dev Access modifier for Robot functionality
  modifier onlyr9k() {
    require(msg.sender == r9kAddress);
    _;
  }

  /// @dev Access modifier for Doge and Robot functionality
  modifier onlyDogeAndr9k() {
    require(
      msg.sender == dogeAddress ||
      msg.sender == r9kAddress
    );
    _;
  }

  /*** CONSTRUCTOR ***/
  function MemeToken() public {
    dogeAddress = msg.sender;
    r9kAddress = msg.sender;
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
  ) public
  {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    memeIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new promo meme with the given metadata and text, with given _price and
  ///  assignes it to an address.
  function createPromoMeme(address _owner, uint256 _metadata, string _text, uint256 _price) public onlyDogeAndr9k {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address memeOwner = _owner;
    if (memeOwner == address(0)) {
      memeOwner = dogeAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createMeme(_metadata, _text, memeOwner, _price);
  }

  /// @dev Creates a new user-generated meme with the given metadata and text, with given _price and
  ///  assignes it to an address.
  function createUserMeme(address _owner, uint256 _metadata, string _text, uint256 _price) public onlyDogeAndr9k {
    address memeOwner = _owner;
    if (memeOwner == address(0)) {
      memeOwner = dogeAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    _createMeme(_metadata, _text, memeOwner, _price);
  }

  /// @dev Creates a new meme with the given name.
  function createContractMeme(uint256 _metadata, string _text) public onlyDogeAndr9k {
    _createMeme(_metadata, _text, address(this), startingPrice);
  }

  /// @notice Returns all the relevant information about a specific meme.
  /// @param _tokenId The tokenId of the meme of interest.
  function getMeme(uint256 _tokenId) public view returns (
    uint256 metadata,
    string text,
    uint256 sellingPrice,
    address owner
  ) {
    Meme storage meme = memes[_tokenId];
    metadata = meme.metadata;
    text = meme.text;
    sellingPrice = memeIndexToPrice[_tokenId];
    owner = memeIndexToOwner[_tokenId];
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
    owner = memeIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyDoge {
    _payout(_to);
  }

  // Allows someone to send ether and obtain the meme
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = memeIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = memeIndexToPrice[_tokenId];

    // Making sure meme owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 97), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    } else {
      // third stage
      memeIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 100);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1 - 0.05)
    }

    TokenSold(_tokenId, sellingPrice, memeIndexToPrice[_tokenId], oldOwner, newOwner, memes[_tokenId].metadata, memes[_tokenId].text);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return memeIndexToPrice[_tokenId];
  }

  /// @dev Assigns a new address to act as Doge. Only available to the current Doge.
  /// @param _newDoge The address of the new Doge
  function setDoge(address _newDoge) public onlyDoge {
    require(_newDoge != address(0));

    dogeAddress = _newDoge;
  }

  /// @dev Assigns a new address to act as Robot. Only available to the current Doge.
  /// @param _newRobot The address of the new Robot
  function setRobot(address _newRobot) public onlyDoge {
    require(_newRobot != address(0));

    r9kAddress = _newRobot;
  }

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  /// @notice Allow pre-approved user to take ownership of a meme
  /// @param _tokenId The ID of the meme that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = memeIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose meme tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire memes array looking for memes belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 memeCount = totalSupply();
      uint256 resultIndex = 0;

      uint256 memeId;
      for (memeId = 0; memeId <= memeCount; memeId++) {
        if (memeIndexToOwner[memeId] == _owner) {
          result[resultIndex] = memeId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return memes.length;
  }

  /// Owner initates the transfer of the meme to another account
  /// @param _to The address for the meme to be transferred to.
  /// @param _tokenId The ID of the meme that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public
  {
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
  ) public
  {
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
    return memeIndexToApproved[_tokenId] == _to;
  }

  /// For creating a new meme
  function _createMeme(uint256 _metadata, string _text, address _owner, uint256 _price) private {
    Meme memory _meme = Meme({
      metadata: _metadata,
      text: _text
    });
    uint256 newMemeId = memes.push(_meme) - 1;

    // It&#39;s probably never going to happen, 2^64 memes are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newMemeId == uint256(uint64(newMemeId)));

    Birth(newMemeId, _metadata, _text, _owner);

    memeIndexToPrice[newMemeId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newMemeId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == memeIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      dogeAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific meme to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of memes is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    memeIndexToOwner[_tokenId] = _to;

    // When creating new memes _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete memeIndexToApproved[_tokenId];
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