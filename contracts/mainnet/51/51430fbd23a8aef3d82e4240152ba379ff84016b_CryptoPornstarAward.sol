pragma solidity ^0.4.18; // solhint-disable-line

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="620607160722031a0b0d0f18070c4c010d">[email&#160;protected]</a>> (https://github.com/dete)
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

contract PornstarsInterface {
    function ownerOf(uint256 _id) public view returns (
        address owner
    );
    
    function totalSupply() public view returns (
        uint256 total
    );
}

contract PornSceneToken is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new scene comes into existence.
  event Birth(uint256 tokenId, string name, uint[] stars, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name, uint[] stars);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoPornScenes"; // solhint-disable-line
  string public constant SYMBOL = "PornSceneToken"; // solhint-disable-line

  uint256 private startingPrice = 0.001 ether;
  uint256 private constant PROMO_CREATION_LIMIT = 10000;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

  /*** STORAGE ***/

  /// @dev A mapping from scene IDs to the address that owns them. All scenes have
  ///  some valid owner address.
  mapping (uint256 => address) public sceneIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from SceneIDs to an address that has been approved to call
  ///  transferFrom(). Each Scene can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public sceneIndexToApproved;

  // @dev A mapping from SceneIDs to the price of the token.
  mapping (uint256 => uint256) private sceneIndexToPrice;

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  PornstarsInterface pornstarsContract;
  uint currentAwardWinner;

  uint256 public promoCreatedCount;

  /*** DATATYPES ***/
  struct Scene {
    string name;
    uint[] stars;
  }

  Scene[] private scenes;

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
  function PornSceneToken() public {
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

    sceneIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }
  
  function setPornstarsContractAddress(address _address) public onlyCOO {
      pornstarsContract = PornstarsInterface(_address);
  }
  
  /// @dev Creates a new promo Scene with the given name, with given _price and assignes it to an address.
  function createPromoScene(address _owner, string _name, uint[] _stars, uint256 _price) public onlyCOO {
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address sceneOwner = _owner;
    if (sceneOwner == address(0)) {
      sceneOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    promoCreatedCount++;
    _createScene(_name, _stars, sceneOwner, _price);
  }

  /// @dev Creates a new Scene with the given name.
  function createContractScene(string _name, uint[] _stars) public onlyCOO {
    _createScene(_name, _stars, address(this), startingPrice);
  }

  /// @notice Returns all the relevant information about a specific scene.
  /// @param _tokenId The tokenId of the scene of interest.
  function getScene(uint256 _tokenId) public view returns (
    string sceneName,
    uint[] stars,
    uint256 sellingPrice,
    address owner
  ) {
    Scene storage scene = scenes[_tokenId];
    sceneName = scene.name;
    stars = scene.stars;
    sellingPrice = sceneIndexToPrice[_tokenId];
    owner = sceneIndexToOwner[_tokenId];
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
    owner = sceneIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = sceneIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = sceneIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 80), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    
    // Pornstar Holder Fees
    // Get Scene Star Length
    Scene memory _scene = scenes[_tokenId];
    
    require(_scene.stars.length > 0); //Make sure have stars in the scene

    uint256 holderFee = uint256(SafeMath.div(SafeMath.div(SafeMath.mul(sellingPrice, 10), 100), _scene.stars.length));
    uint256 awardOwnerFee = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 4), 100));

    // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      sceneIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      sceneIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
    } else {
      // third stage
      sceneIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
    }

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.06)
    }
    
    _paySceneStarOwners(_scene, holderFee);
    _payAwardOwner(awardOwnerFee);
    
    TokenSold(_tokenId, sellingPrice, sceneIndexToPrice[_tokenId], oldOwner, newOwner, _scene.name, _scene.stars);

    msg.sender.transfer(purchaseExcess);
  }
  
  function _paySceneStarOwners(Scene _scene, uint256 fee) private {
    for (uint i = 0; i < _scene.stars.length; i++) {
        address _pornstarOwner;
        (_pornstarOwner) = pornstarsContract.ownerOf(_scene.stars[i]);
        
        if(_isGoodAddress(_pornstarOwner)) {
            _pornstarOwner.transfer(fee);
        }
    }
  }
  
  function _payAwardOwner(uint256 fee) private {
    address _awardOwner;
    (_awardOwner) = pornstarsContract.ownerOf(currentAwardWinner);
    
    if(_isGoodAddress(_awardOwner)) {
        _awardOwner.transfer(fee);
    }
  }
  
  function _isGoodAddress(address _addy) private view returns (bool) {
      if(_addy == address(pornstarsContract)) {
          return false;
      }
      
      if(_addy == address(0) || _addy == address(0x0)) {
          return false;
      }
      
      return true;
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return sceneIndexToPrice[_tokenId];
  }
  
  function starsOf(uint256 _tokenId) public view returns (uint[]) {
      return scenes[_tokenId].stars;
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
    address oldOwner = sceneIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire scenes array looking for scenes belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalscenes = totalSupply();
      uint256 resultIndex = 0;

      uint256 sceneId;
      for (sceneId = 0; sceneId <= totalscenes; sceneId++) {
        if (sceneIndexToOwner[sceneId] == _owner) {
          result[resultIndex] = sceneId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return scenes.length;
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
    return sceneIndexToApproved[_tokenId] == _to;
  }

  /// For creating Scene
  function _createScene(string _name, uint[] _stars,address _owner, uint256 _price) private {
    // Require Stars Exists
    require(_stars.length > 0);
    
    for (uint i = 0; i < _stars.length; i++) {
        address _pornstarOwner;
        (_pornstarOwner) = pornstarsContract.ownerOf(_stars[i]);
        require(_pornstarOwner != address(0) || _pornstarOwner != address(0x0));
    }
      
    Scene memory _scene = Scene({
      name: _name,
      stars: _stars
    });
    uint256 newSceneId = scenes.push(_scene) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newSceneId == uint256(uint32(newSceneId)));

    Birth(newSceneId, _name, _stars, _owner);

    sceneIndexToPrice[newSceneId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newSceneId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == sceneIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific Scene to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of scenes is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    sceneIndexToOwner[_tokenId] = _to;

    // When creating new scenes _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete sceneIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}

contract CryptoPornstarAward is PornSceneToken{
    event Award(uint256 currentAwardWinner, uint32 awardTime);
    
    uint nonce = 0;
    uint cooldownTime = 60;
    uint32 awardTime = uint32(now);
    
    function _triggerCooldown() internal {
        awardTime = uint32(now + cooldownTime);
    }
    
    function _isTime() internal view returns (bool) {
        return (awardTime <= now);
    }
    
    function rand(uint min, uint max) internal returns (uint) {
        nonce++;
        return uint(keccak256(nonce))%(min+max)-min;
    }

    function setCooldown(uint _newCooldown) public onlyCOO {
        require (_newCooldown > 0);
        cooldownTime = _newCooldown;
        _triggerCooldown();
    } 
    
    function getAwardTime () public view returns (uint32) {
        return awardTime;
    }
    
    function getCooldown () public view returns (uint) {
        return cooldownTime;
    }
    
    function newAward() public onlyCOO {        
        uint256 _totalPornstars;
        (_totalPornstars) = pornstarsContract.totalSupply();
        
        require(_totalPornstars > 0);
        require(_isTime());
        
        currentAwardWinner = rand(0, _totalPornstars);
        _triggerCooldown();
        
        Award(currentAwardWinner, awardTime);
    }
    
    function getCurrentAward() public view returns (uint){
        return currentAwardWinner;
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