pragma solidity ^0.4.19; // solhint-disable-line


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Srini Vasan 
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

contract CryptonToken is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new crypton comes into existence.
  event Birth(uint256 tokenId, string name, address owner, bool isProtected, uint8 category);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /// @dev the PaymentTransferredToPreviousOwner event is fired when the previous owner of the Crypton is paid after a purchase.
  event PaymentTransferredToPreviousOwner(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  // @dev CryptonIsProtected is fired when the Crypton is protected from snatching - i.e. owner is allowed to set the selling price for the crypton
  event CryptonIsProtected(uint256 tokenId);

    // @dev The markup was changed
    event MarkupChanged(string name, uint256 newMarkup);
    
    //@dev Selling price of protected Crypton changed
    event ProtectedCryptonSellingPriceChanged(uint256 tokenId, uint256 newSellingPrice);
    
    // Owner protected their Crypton
    event OwnerProtectedCrypton(uint256 _tokenId, uint256 newSellingPrice);

    //Contract paused event
    event ContractIsPaused(bool paused);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "Cryptons"; // solhint-disable-line
  string public constant SYMBOL = "CRYPTON"; // solhint-disable-line

  uint256 private startingPrice = 0.1 ether;
  uint256 private defaultMarkup = 2 ether;
  uint256 private FIRST_STEP_LIMIT =  1.0 ether;
  uint16 private FIRST_STEP_MULTIPLIER = 200; // double the value
  uint16 private SECOND_STEP_MULTIPLIER = 120; // increment value by 20%
  uint16 private XPROMO_MULTIPLIER = 500; // 5 times the value
  uint16 private CRYPTON_CUT = 6; // our cut
  uint16 private NET_PRICE_PERCENT = 100 - CRYPTON_CUT; // Net price paid out after cut

  // I could have used enums - but preferered the more specific uint8 
  uint8 private constant PROMO = 1;
  uint8 private constant STANDARD = 2;
  uint8 private constant RESERVED = 7;
  uint8 private constant XPROMO = 10; // First transaction, contract sets sell price to 5x
  
  /*** STORAGE ***/

  /// @dev A mapping from crypton IDs to the address that owns them. All cryptons have
  ///  some valid owner address.
  mapping (uint256 => address) public cryptonIndexToOwner;

  mapping (uint256 => bool) public cryptonIndexToProtected;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from CryptonIDs to an address that has been approved to call
  ///  transferFrom(). Each Crypton can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public cryptonIndexToApproved;

  // @dev A mapping from CryptonIDs to the price of the token.
  mapping (uint256 => uint256) private cryptonIndexToPrice;


  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  /*** DATATYPES ***/
  struct Crypton {
    string name;
    uint8  category;
    uint256 markup;
  }

  Crypton[] private cryptons;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked.
    bool public paused = false;

  /*** ACCESS MODIFIERS ***/
  /// @dev Access modifier for COO-only functionality
  /// @dev Access modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }
  
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

    /*** Pausable functionality adapted from OpenZeppelin ***/
    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause()
        external
        onlyCLevel
        whenNotPaused
    {
        paused = true;
        emit ContractIsPaused(paused);
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause()
        public
        onlyCEO
        whenPaused
    {
        // can&#39;t unpause if contract was forked
        paused = false;
        emit ContractIsPaused(paused);
    }
  /*** CONSTRUCTOR ***/
  constructor() public {
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
  ) public whenNotPaused {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    cryptonIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new Crypton with the given name, startingPrice, category and an (optional) owner wallet address
  function createCrypton(
    string _name,                           //Required
    uint8 _category,                        //Required
    uint256 _startingPrice,                 // Optional - defaults to startingPrice
    uint256 _markup,                        // Optional - defaults to defaultMarkup
    address _owner                          // Optional - deafults to contract
    ) public onlyCLevel {
      address cryptonOwner = _owner;
      if (cryptonOwner == address(0)) {
        cryptonOwner = address(this);
      }
      
      if (_category == XPROMO) {    // XPROMO Cryptons - force ownership to contract
          cryptonOwner = address(this);
      }

      if (_markup <= 0) {
          _markup = defaultMarkup;
      }
        
      if (_category == PROMO) { // PROMO Cryptons - force markup to zero
        _markup = 0;  
      }

      if (_startingPrice <= 0) {
        _startingPrice = startingPrice;
      }


      bool isProtected = (_category == PROMO)?true:false; // PROMO cryptons are protected, others are not - at creation
      
      _createCrypton(_name, cryptonOwner, _startingPrice, _markup, isProtected, _category);
  }

  /// @notice Returns all the relevant information about a specific crypton.
  /// @param _tokenId The tokenId of the crypton of interest.
  function getCrypton(uint256 _tokenId) public view returns (
    string cryptonName,
    uint8 category,
    uint256 markup,
    uint256 sellingPrice,
    address owner,
    bool isProtected
  ) {
    Crypton storage crypton = cryptons[_tokenId];
    cryptonName = crypton.name;
    sellingPrice = cryptonIndexToPrice[_tokenId];
    owner = cryptonIndexToOwner[_tokenId];
    isProtected = cryptonIndexToProtected[_tokenId];
    category = crypton.category;
    markup = crypton.markup;
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
    owner = cryptonIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  /// @dev This function withdraws the contract owner&#39;s cut.
  /// Any amount may be withdrawn as there is no user funds.
  /// User funds are immediately sent to the old owner in `purchase`
  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  /// @dev This function allows the contract owner to adjust the selling price of a protected Crypton
  function setPriceForProtectedCrypton(uint256 _tokenId, uint256 newSellingPrice) public whenNotPaused {
    address oldOwner = cryptonIndexToOwner[_tokenId]; // owner in blockchain
    address newOwner = msg.sender;                    // person requesting change
    require(oldOwner == newOwner); // Only current owner can update the price
    require(cryptonIndexToProtected[_tokenId]); // Make sure Crypton is protected
    require(newSellingPrice > 0);  // Make sure the price is not zero
    cryptonIndexToPrice[_tokenId] = newSellingPrice;
    emit ProtectedCryptonSellingPriceChanged(_tokenId, newSellingPrice);
 }

  /// @dev This function allows the contract owner to buy protection for an unprotected that they already own
  function setProtectionForMyUnprotectedCrypton(uint256 _tokenId, uint256 newSellingPrice) public payable whenNotPaused {
    address oldOwner = cryptonIndexToOwner[_tokenId]; // owner in blockchain
    address newOwner = msg.sender;                    // person requesting change
    uint256 markup = cryptons[_tokenId].markup;
    if (cryptons[_tokenId].category != PROMO) {
      require(markup > 0); // if this is NOT a promotional crypton, the markup should be > zero
    }
    
    require(oldOwner == newOwner); // Only current owner can buy protection for existing crypton
    require(! cryptonIndexToProtected[_tokenId]); // Make sure Crypton is NOT already protected
    require(newSellingPrice > 0);  // Make sure the sellingPrice is more than zero
    require(msg.value >= markup);   // Make sure to collect the markup
    
    cryptonIndexToPrice[_tokenId] = newSellingPrice;
    cryptonIndexToProtected[_tokenId] = true;
    
    emit OwnerProtectedCrypton(_tokenId, newSellingPrice);
 }
 
  function getMarkup(uint256 _tokenId) public view returns (uint256 markup) {
    return cryptons[_tokenId].markup;
  }

  /// @dev This function allows the contract owner to adjust the markup value
  function setMarkup(uint256 _tokenId, uint256 newMarkup) public onlyCLevel {
    require(newMarkup >= 0);
    cryptons[_tokenId].markup = newMarkup;
    emit MarkupChanged(cryptons[_tokenId].name, newMarkup);
  }
    
  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId, uint256 newSellingPrice) public payable whenNotPaused {
    address oldOwner = cryptonIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    bool isAlreadyProtected = cryptonIndexToProtected[_tokenId];
    
    uint256 sellingPrice = cryptonIndexToPrice[_tokenId];
    uint256 markup = cryptons[_tokenId].markup;
    
    if (cryptons[_tokenId].category != PROMO) {
      require(markup > 0); // if this is NOT a promotional crypton, the markup should be > zero
    }

    // Make sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Make sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice); // this is redundant - as we are checking this below

    if (newSellingPrice > 0) { // if we are called with a new selling price, then the buyer is paying the markup or purchasing a protected crypton
        uint256 purchasePrice = sellingPrice; //assume it is protected
        if (! cryptonIndexToProtected[_tokenId] ) { // Crypton is not protected,
            purchasePrice = sellingPrice + markup;  // apply markup
        }

        // If the Crypton is not already protected, make sure that the buyer is paying markup more than the current selling price
        // If the buyer is not paying the markup - then he cannot set the new selling price- bailout
        require(msg.value >= purchasePrice); 

        // Ok - the buyer paid the markup or the crypton was already protected.
        cryptonIndexToPrice[_tokenId] = newSellingPrice;  // Set the selling price that the buyer wants
        cryptonIndexToProtected[_tokenId] = true;         // Set the Crypton to protected
        emit CryptonIsProtected(_tokenId);                // Let the world know

    } else {
        // Compute next listing price.
        // Handle XPROMO case first...
        if (
          (oldOwner == address(this)) &&                // first transaction only`
          (cryptons[_tokenId].category == XPROMO)      // Only for XPROMO category
          ) 
        {
          cryptonIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, XPROMO_MULTIPLIER), NET_PRICE_PERCENT);            
        } else {
          if (sellingPrice < FIRST_STEP_LIMIT) {
            // first stage
            cryptonIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, FIRST_STEP_MULTIPLIER), NET_PRICE_PERCENT);
          } else {
            // second stage
            cryptonIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, SECOND_STEP_MULTIPLIER), NET_PRICE_PERCENT);
          }
        }

    }
       
    _transfer(oldOwner, newOwner, _tokenId);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, NET_PRICE_PERCENT), 100));
    string storage cname = cryptons[_tokenId].name;

    bool isReservedToken = (cryptons[_tokenId].category == RESERVED);
  
    if (isReservedToken && isAlreadyProtected) {
      oldOwner.transfer(payment); //(1-CRYPTON_CUT/100)
      emit PaymentTransferredToPreviousOwner(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);
      emit TokenSold(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);
      return;
    }

    // Pay seller of the Crypton if they are not this contract or if this is a Reserved token
    if ((oldOwner != address(this)) && !isReservedToken ) // Not a Reserved token and not owned by the contract
    {
      oldOwner.transfer(payment); //(1-CRYPTON_CUT/100)
      emit PaymentTransferredToPreviousOwner(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);
    }

    emit TokenSold(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return cryptonIndexToPrice[_tokenId];
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
  function takeOwnership(uint256 _tokenId) public whenNotPaused {
    address newOwner = msg.sender;
    address oldOwner = cryptonIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose Cryptons we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Cryptons array looking for cryptons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalCryptons = totalSupply();
      uint256 resultIndex = 0;

      uint256 cryptonId;
      for (cryptonId = 0; cryptonId <= totalCryptons; cryptonId++) {
        if (cryptonIndexToOwner[cryptonId] == _owner) {
          result[resultIndex] = cryptonId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return cryptons.length;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public whenNotPaused {
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
  ) public whenNotPaused {
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
    return cryptonIndexToApproved[_tokenId] == _to;
  }

  /// For creating Crypton
  function _createCrypton(string _name, address _owner, uint256 _price, uint256 _markup, bool _isProtected, uint8 _category) private {
    Crypton memory _crypton = Crypton({
      name: _name,
      category: _category,
      markup: _markup
    });
    uint256 newCryptonId = cryptons.push(_crypton) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newCryptonId == uint256(uint32(newCryptonId)));

    emit Birth(newCryptonId, _name, _owner, _isProtected, _category);

    cryptonIndexToPrice[newCryptonId] = _price;
    
    cryptonIndexToProtected[newCryptonId] = _isProtected; // _isProtected is true for promo cryptons - false for others.

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newCryptonId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == cryptonIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    address myAddress = this;
    if (_to == address(0)) {
      ceoAddress.transfer(myAddress.balance);
    } else {
      _to.transfer(myAddress.balance);
    }
  }

  /// @dev Assigns ownership of a specific Crypton to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of cryptons is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    cryptonIndexToOwner[_tokenId] = _to;

    // When creating new cryptons _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete cryptonIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _tokenId);
  }

//various getter/setter methods

  function setFIRST_STEP_LIMIT(uint256 newLimit) public onlyCLevel {
    require(newLimit > 0 && newLimit < 100 ether);
    FIRST_STEP_LIMIT = newLimit;
  }
  function getFIRST_STEP_LIMIT() public view returns (uint256 value) {
    return FIRST_STEP_LIMIT;
  }

  function setFIRST_STEP_MULTIPLIER(uint16 newValue) public onlyCLevel {
    require(newValue >= 110 && newValue <= 200);
    FIRST_STEP_MULTIPLIER = newValue;
  }
  function getFIRST_STEP_MULTIPLIER() public view returns (uint16 value) {
    return FIRST_STEP_MULTIPLIER;
  }

  function setSECOND_STEP_MULTIPLIER(uint16 newValue) public onlyCLevel {
    require(newValue >= 110 && newValue <= 200);
    SECOND_STEP_MULTIPLIER = newValue;
  }
  function getSECOND_STEP_MULTIPLIER() public view returns (uint16 value) {
    return SECOND_STEP_MULTIPLIER;
  }

  function setXPROMO_MULTIPLIER(uint16 newValue) public onlyCLevel {
    require(newValue >= 100 && newValue <= 10000); // between 0 and 100x
    XPROMO_MULTIPLIER = newValue;
  }
  function getXPROMO_MULTIPLIER() public view returns (uint16 value) {
    return XPROMO_MULTIPLIER;
  }

  function setCRYPTON_CUT(uint16 newValue) public onlyCLevel {
    require(newValue > 0 && newValue < 10);
    CRYPTON_CUT = newValue;
  }
  function getCRYPTON_CUT() public view returns (uint16 value) {
    return CRYPTON_CUT;
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