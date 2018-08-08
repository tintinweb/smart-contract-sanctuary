pragma solidity ^0.4.18; // solhint-disable-line



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d9bdbcadbc99b8a1b0b6b4a3bcb7f7bab6">[email&#160;protected]</a>> (https://github.com/dete)
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


contract PowZoneToken is ERC721 {

  address cryptoVideoGames = 0xdEc14D8f4DA25108Fd0d32Bf2DeCD9538564D069; 
  address cryptoVideoGameItems = 0xD2606C9bC5EFE092A8925e7d6Ae2F63a84c5FDEa;

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new pow comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoKotakuPowZone"; // solhint-disable-line
  string public constant SYMBOL = "PowZone"; // solhint-disable-line

  uint256 private startingPrice = 0.005 ether;
  uint256 private firstStepLimit =  0.05 ether;
  uint256 private secondStepLimit = 0.5 ether;

  /*** STORAGE ***/

  /// @dev A mapping from pow IDs to the address that owns them. All pows have
  ///  some valid owner address.
  mapping (uint256 => address) public powIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from PowIDs to an address that has been approved to call
  ///  transferFrom(). Each Pow can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public powIndexToApproved;

  // @dev A mapping from PowIDs to the price of the token.
  mapping (uint256 => uint256) private powIndexToPrice;

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  uint256 public promoCreatedCount;

  /*** DATATYPES ***/
  struct Pow {
    string name;
    uint gameId;
    uint gameItemId;
  }

  Pow[] private pows;

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
  function PowZoneToken() public {
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

    powIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new promo Pow with the given name, with given _price and assignes it to an address.
  function createPromoPow(address _owner, string _name, uint256 _price, uint _gameId, uint _gameItemId) public onlyCOO {

    address powOwner = _owner;
    if (powOwner == address(0)) {
      powOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createPow(_name, powOwner, _price, _gameId, _gameItemId);
  }

  /// @dev Creates a new Pow with the given name.
  function createContractPow(string _name, uint _gameId, uint _gameItemId) public onlyCOO {
    _createPow(_name, address(this), startingPrice, _gameId, _gameItemId);
  }

  /// @notice Returns all the relevant information about a specific pow.
  /// @param _tokenId The tokenId of the pow of interest.
  function getPow(uint256 _tokenId) public view returns (
    uint256 Id,
    string powName,
    uint256 sellingPrice,
    address owner,
    uint gameId,
    uint gameItemId
  ) {
    Pow storage pow = pows[_tokenId];
    Id = _tokenId;
    powName = pow.name;
    sellingPrice = powIndexToPrice[_tokenId];
    owner = powIndexToOwner[_tokenId];
    gameId = pow.gameId;
    gameItemId = pow.gameItemId;
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
    owner = powIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = powIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = powIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 gameOwnerPayment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 5), 100));
    uint256 gameItemOwnerPayment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 10), 100));
    uint256 payment =  sellingPrice - gameOwnerPayment - gameOwnerPayment - gameItemOwnerPayment;
    uint256 purchaseExcess = SafeMath.sub(msg.value,sellingPrice);

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      powIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      powIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 180), 100);
    } else {
      // third stage
      powIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    }

    _transfer(oldOwner, newOwner, _tokenId);
    TokenSold(_tokenId, sellingPrice, powIndexToPrice[_tokenId], oldOwner, newOwner, pows[_tokenId].name);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.2)
    }
    
    msg.sender.transfer(purchaseExcess);
    _transferDivs(gameOwnerPayment, gameItemOwnerPayment, _tokenId);
    
  }

  /// Divident distributions
  function _transferDivs(uint256 _gameOwnerPayment, uint256 _gameItemOwnerPayment, uint256 _tokenId) private {
    CryptoVideoGames gamesContract = CryptoVideoGames(cryptoVideoGames);
    CryptoVideoGameItem gameItemContract = CryptoVideoGameItem(cryptoVideoGameItems);
    address gameOwner = gamesContract.getVideoGameOwner(pows[_tokenId].gameId);
    address gameItemOwner = gameItemContract.getVideoGameItemOwner(pows[_tokenId].gameItemId);
    gameOwner.transfer(_gameOwnerPayment);
    gameItemOwner.transfer(_gameItemOwnerPayment);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return powIndexToPrice[_tokenId];
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
    address oldOwner = powIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose pow tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire pows array looking for pows belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPows = totalSupply();
      uint256 resultIndex = 0;

      uint256 powId;
      for (powId = 0; powId <= totalPows; powId++) {
        if (powIndexToOwner[powId] == _owner) {
          result[resultIndex] = powId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return pows.length;
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
    return powIndexToApproved[_tokenId] == _to;
  }

  /// For creating Pow
  function _createPow(string _name, address _owner, uint256 _price, uint _gameId, uint _gameItemId) private {
    Pow memory _pow = Pow({
      name: _name,
      gameId: _gameId,
      gameItemId: _gameItemId
    });
    uint256 newPowId = pows.push(_pow) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newPowId == uint256(uint32(newPowId)));

    Birth(newPowId, _name, _owner);

    powIndexToPrice[newPowId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newPowId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == powIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /*
  This function can be used by the owner of a pow item to modify the price of its pow item.
  */
  function modifyPowPrice(uint _powId, uint256 _newPrice) public {
      require(_newPrice > 0);
      require(powIndexToOwner[_powId] == msg.sender);
      powIndexToPrice[_powId] = _newPrice;
  }

  /// @dev Assigns ownership of a specific Pow to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of pow is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    powIndexToOwner[_tokenId] = _to;

    // When creating new pows _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete powIndexToApproved[_tokenId];
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


contract CryptoVideoGames {
    // This function will return only the owner address of a specific Video Game
    function getVideoGameOwner(uint _videoGameId) public view returns(address) {
    }
    
}


contract CryptoVideoGameItem {
  function getVideoGameItemOwner(uint _videoGameItemId) public view returns(address) {
    }
}