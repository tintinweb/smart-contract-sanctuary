pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}





contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;

    function MultiOwners() public {
        owners[msg.sender] = true;
    }

    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }

    function isOwner() public view returns (bool) {
        return owners[msg.sender] ? true : false;
    }

    function grant(address _newOwner) external onlyOwner {
        owners[_newOwner] = true;
        AccessGrant(_newOwner);
    }

    function revoke(address _oldOwner) external onlyOwner {
        require(msg.sender != _oldOwner);
        owners[_oldOwner] = false;
        AccessRevoke(_oldOwner);
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
  uint256 internal totalTokens;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping (uint256 => uint256) private ownedTokensIndex;

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
  * @dev Burns a specific token for a user.
  * @param _tokenId uint256 ID of the token being burned by the msg.sender
  */
  function _burnFor(address _owner, uint256 _tokenId) internal {
    if (isApprovedFor(_owner, _tokenId)) {
      clearApproval(_owner, _tokenId);
    }
    removeToken(_owner, _tokenId);
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

contract Base is ERC721Token, MultiOwners {

  event NewCRLToken(address indexed owner, uint256 indexed tokenId, uint256 traits);
  event UpdatedCRLToken(uint256 indexed UUID, uint256 indexed tokenId, uint256 traits);

  uint256 TOKEN_UUID;
  uint256 UPGRADE_UUID;

  function _createToken(address _owner, uint256 _traits) internal {
    // emit the creaton event
    NewCRLToken(
      _owner,
      TOKEN_UUID,
      _traits
    );

    // This will assign ownership, and also emit the Transfer event
    _mint(_owner, TOKEN_UUID);

    TOKEN_UUID++;
  }

  function _updateToken(uint256 _tokenId, uint256 _traits) internal {
    // emit the creaton event
    UpdatedCRLToken(
      UPGRADE_UUID,
      _tokenId,
      _traits
    );

    UPGRADE_UUID++;
  }

  // Eth balance controls

  // We can withdraw eth balance of contract.
  function withdrawBalance() onlyOwner external {
    require(this.balance > 0);

    msg.sender.transfer(this.balance);
  }
}

contract LootboxStore is Base {
  // mapping between specific Lootbox contract address to price in wei
  mapping(address => uint256) ethPricedLootboxes;

  // mapping between specific Lootbox contract address to price in NOS tokens
  mapping(uint256 => uint256) NOSPackages;

  uint256 UUID;

  event NOSPurchased(uint256 indexed UUID, address indexed owner, uint256 indexed NOSAmtPurchased);

  function addLootbox(address _lootboxAddress, uint256 _price) external onlyOwner {
    ethPricedLootboxes[_lootboxAddress] = _price;
  }

  function removeLootbox(address _lootboxAddress) external onlyOwner {
    delete ethPricedLootboxes[_lootboxAddress];
  }

  function buyEthLootbox(address _lootboxAddress) payable external {
    // Verify the given lootbox contract exists and they&#39;ve paid enough
    require(ethPricedLootboxes[_lootboxAddress] != 0);
    require(msg.value >= ethPricedLootboxes[_lootboxAddress]);

    LootboxInterface(_lootboxAddress).buy(msg.sender);
  }

  function addNOSPackage(uint256 _NOSAmt, uint256 _ethPrice) external onlyOwner {
    NOSPackages[_NOSAmt] = _ethPrice;
  }
  
  function removeNOSPackage(uint256 _NOSAmt) external onlyOwner {
    delete NOSPackages[_NOSAmt];
  }

  function buyNOS(uint256 _NOSAmt) payable external {
    require(NOSPackages[_NOSAmt] != 0);
    require(msg.value >= NOSPackages[_NOSAmt]);
    
    NOSPurchased(UUID, msg.sender, _NOSAmt);
    UUID++;
  }
}

contract ExternalInterface {
  function giveItem(address _recipient, uint256 _traits) external;

  function giveMultipleItems(address _recipient, uint256[] _traits) external;

  function giveMultipleItemsToMultipleRecipients(address[] _recipients, uint256[] _traits) external;

  function giveMultipleItemsAndDestroyMultipleItems(address _recipient, uint256[] _traits, uint256[] _tokenIds) external;
  
  function destroyItem(uint256 _tokenId) external;

  function destroyMultipleItems(uint256[] _tokenIds) external;

  function updateItemTraits(uint256 _tokenId, uint256 _traits) external;
}


contract Core is LootboxStore, ExternalInterface {
  mapping(address => uint256) authorizedExternal;

  function addAuthorizedExternal(address _address) external onlyOwner {
    authorizedExternal[_address] = 1;
  }

  function removeAuthorizedExternal(address _address) external onlyOwner {
    delete authorizedExternal[_address];
  }

  // Verify the caller of this function is a Lootbox contract or race, or crafting, or upgrade
  modifier onlyAuthorized() { 
    require(ethPricedLootboxes[msg.sender] != 0 ||
            authorizedExternal[msg.sender] != 0);
      _; 
  }

  function giveItem(address _recipient, uint256 _traits) onlyAuthorized external {
    _createToken(_recipient, _traits);
  }

  function giveMultipleItems(address _recipient, uint256[] _traits) onlyAuthorized external {
    for (uint i = 0; i < _traits.length; ++i) {
      _createToken(_recipient, _traits[i]);
    }
  }

  function giveMultipleItemsToMultipleRecipients(address[] _recipients, uint256[] _traits) onlyAuthorized external {
    require(_recipients.length == _traits.length);

    for (uint i = 0; i < _traits.length; ++i) {
      _createToken(_recipients[i], _traits[i]);
    }
  }

  function giveMultipleItemsAndDestroyMultipleItems(address _recipient, uint256[] _traits, uint256[] _tokenIds) onlyAuthorized external {
    for (uint i = 0; i < _traits.length; ++i) {
      _createToken(_recipient, _traits[i]);
    }

    for (i = 0; i < _tokenIds.length; ++i) {
      _burnFor(ownerOf(_tokenIds[i]), _tokenIds[i]);
    }
  }

  function destroyItem(uint256 _tokenId) onlyAuthorized external {
    _burnFor(ownerOf(_tokenId), _tokenId);
  }

  function destroyMultipleItems(uint256[] _tokenIds) onlyAuthorized external {
    for (uint i = 0; i < _tokenIds.length; ++i) {
      _burnFor(ownerOf(_tokenIds[i]), _tokenIds[i]);
    }
  }

  function updateItemTraits(uint256 _tokenId, uint256 _traits) onlyAuthorized external {
    _updateToken(_tokenId, _traits);
  }
}


contract LootboxInterface {
  event LootboxPurchased(address indexed owner, uint16 displayValue);
  
  function buy(address _buyer) external;
}