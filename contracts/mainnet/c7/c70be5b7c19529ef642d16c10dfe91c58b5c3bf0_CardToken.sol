pragma solidity ^0.4.21;

/**
 * @title Maths
 * A library to make working with numbers in Solidity hurt your brain less.
 */
library Maths {
  /**
   * @dev Adds two addends together, returns the sum
   * @param addendA the first addend
   * @param addendB the second addend
   * @return sum the sum of the equation (e.g. addendA + addendB)
   */
  function plus(
    uint256 addendA,
    uint256 addendB
  ) public pure returns (uint256 sum) {
    sum = addendA + addendB;
  }

  /**
   * @dev Subtracts the minuend from the subtrahend, returns the difference
   * @param minuend the minuend
   * @param subtrahend the subtrahend
   * @return difference the difference (e.g. minuend - subtrahend)
   */
  function minus(
    uint256 minuend,
    uint256 subtrahend
  ) public pure returns (uint256 difference) {
    assert(minuend >= subtrahend);
    difference = minuend - subtrahend;
  }

  /**
   * @dev Multiplies two factors, returns the product
   * @param factorA the first factor
   * @param factorB the second factor
   * @return product the product of the equation (e.g. factorA * factorB)
   */
  function mul(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    if (factorA == 0 || factorB == 0) return 0;
    product = factorA * factorB;
    assert(product / factorA == factorB);
  }

  /**
   * @dev Multiplies two factors, returns the product
   * @param factorA the first factor
   * @param factorB the second factor
   * @return product the product of the equation (e.g. factorA * factorB)
   */
  function times(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    return mul(factorA, factorB);
  }

  /**
   * @dev Divides the dividend by divisor, returns the truncated quotient
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   */
  function div(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    quotient = dividend / divisor;
    assert(quotient * divisor == dividend);
  }

  /**
   * @dev Divides the dividend by divisor, returns the truncated quotient
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   */
  function dividedBy(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    return div(dividend, divisor);
  }

  /**
   * @dev Divides the dividend by divisor, returns the quotient and remainder
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   * @return remainder the remainder of the equation (e.g. dividend % divisor)
   */
  function divideSafely(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient, uint256 remainder) {
    quotient = div(dividend, divisor);
    remainder = dividend % divisor;
  }

  /**
   * @dev Returns the lesser of two values.
   * @param a the first value
   * @param b the second value
   * @return result the lesser of the two values
   */
  function min(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a <= b ? a : b;
  }

  /**
   * @dev Returns the greater of two values.
   * @param a the first value
   * @param b the second value
   * @return result the greater of the two values
   */
  function max(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a >= b ? a : b;
  }

  /**
   * @dev Determines whether a value is less than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than b
   */
  function isLessThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a < b;
  }

  /**
   * @dev Determines whether a value is equal to or less than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than or equal to b
   */
  function isAtMost(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a <= b;
  }

  /**
   * @dev Determines whether a value is greater than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is greater than b
   */
  function isGreaterThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a > b;
  }

  /**
   * @dev Determines whether a value is equal to or greater than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than b
   */
  function isAtLeast(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a >= b;
  }
}

/**
 * @title Manageable
 */
contract Manageable {
  address public owner;
  address public manager;

  event OwnershipChanged(address indexed previousOwner, address indexed newOwner);
  event ManagementChanged(address indexed previousManager, address indexed newManager);

  /**
   * @dev The Manageable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Manageable() public {
    owner = msg.sender;
    manager = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner or manager.
   */
  modifier onlyManagement() {
    require(msg.sender == owner || msg.sender == manager);
    _;
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
    emit OwnershipChanged(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the owner or manager to replace the current manager
   * @param newManager The address to give contract management rights.
   */
  function replaceManager(address newManager) public onlyManagement {
    require(newManager != address(0));
    emit ManagementChanged(manager, newManager);
    manager = newManager;
  }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  ) public;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. This function MUST use 50,000 gas or less. Return of other
   *  than the magic value MUST result in the transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using Maths for uint256;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address holder = tokenOwner[_tokenId];
    require(holder != address(0));
    return holder;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existance of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address holder = tokenOwner[_tokenId];
    return holder != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address holder = ownerOf(_tokenId);
    require(_to != holder);
    require(msg.sender == holder || isApprovedForAll(holder, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(holder, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address holder = ownerOf(_tokenId);
    return _spender == holder || getApproved(_tokenId) == _spender || isApprovedForAll(holder, _spender);
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].plus(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].minus(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * @dev The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!isContract(_to)) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }
}

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  function ERC721Token() public { }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets a list of token IDs owned by the requested address
   * @param _owner address owning the tokens list to be accessed
   * @return uint256[] list of token IDs owned by the requested address
   */
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.minus(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.minus(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

contract CardToken is ERC721Token, Manageable {
  string public constant name = "Mythereum Card";
  string public constant symbol = "CARD";

  mapping (uint8 => string) public className;
  mapping (uint8 => Card[]) public cardsInEdition;
  uint8 public latestEditionReleased;

  struct Card {
    string    name;
    uint8     class;
    uint8     classVariant;
    uint256   damagePoints;
    uint256   shieldPoints;
    uint256   abilityId;
  }

  struct Ability {
    string  name;
    bool    canBeBlocked;
    uint8   blackMagicCost;
    uint8   grayMagicCost;
    uint8   whiteMagicCost;
    uint256 addedDamage;
    uint256 addedShield;
  }

  Card[] public cards;
  Ability[] public abilities;

  function isEditionAvailable(uint8 _editionNumber) public view returns (bool) {
    return _editionNumber <= latestEditionReleased;
  }

  function mintRandomCards(
    address _owner,
    uint8 _editionNumber,
    uint8 _numCards
  ) public onlyManagement returns (bool) {
    require(isEditionAvailable(_editionNumber));
    for(uint8 i = 0; i < _numCards; i++) {
      Card storage card = cardsInEdition[_editionNumber][
        uint256(keccak256(now, _owner, _editionNumber, _numCards, i)) % cardsInEdition[_editionNumber].length
      ];

      _cloneCard(card, _owner);
    }
    return true;
  }

  function mintSpecificCard(
    address _owner,
    uint8   _editionNumber,
    uint256 _cardIndex
  ) public onlyManagement returns (bool) {
    require(isEditionAvailable(_editionNumber));
    require(_cardIndex < cardsInEdition[_editionNumber].length);
    _cloneCard(cardsInEdition[_editionNumber][_cardIndex], _owner);
  }

  function mintSpecificCards(
    address   _owner,
    uint8     _editionNumber,
    uint256[] _cardIndexes
  ) public onlyManagement returns (bool) {
    require(isEditionAvailable(_editionNumber));
    require(_cardIndexes.length > 0 && _cardIndexes.length <= 10);

    for(uint8 i = 0; i < _cardIndexes.length; i++) {
      require(_cardIndexes[i] < cardsInEdition[_editionNumber].length);
      _cloneCard(cardsInEdition[_editionNumber][_cardIndexes[i]], _owner);
    }
  }

  function improveCard(
    uint256 _tokenId,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public onlyManagement returns (bool) {
    require(exists(_tokenId));
    Card storage card = cards[_tokenId];
    card.damagePoints = card.damagePoints.plus(_addedDamage);
    card.shieldPoints = card.shieldPoints.plus(_addedShield);
    return true;
  }

  function destroyCard(uint256 _tokenId) public onlyManagement returns (bool) {
    require(exists(_tokenId));
    _burn(ownerOf(_tokenId), _tokenId);
    return true;
  }

  function setLatestEdition(uint8 _editionNumber) public onlyManagement {
    require(cardsInEdition[_editionNumber].length.isAtLeast(1));
    latestEditionReleased = _editionNumber;
  }

  function setTokenURI(uint256 _tokenId, string _uri) public onlyManagement {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  function addAbility(
    string  _name,
    bool    _canBeBlocked,
    uint8   _blackMagicCost,
    uint8   _grayMagicCost,
    uint8   _whiteMagicCost,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public onlyManagement {
    abilities.push(
      Ability(
        _name,
        _canBeBlocked,
        _blackMagicCost,
        _grayMagicCost,
        _whiteMagicCost,
        _addedDamage,
        _addedShield
      )
    );
  }

  function replaceAbility(
    uint256 _abilityId,
    string  _name,
    bool    _canBeBlocked,
    uint8   _blackMagicCost,
    uint8   _grayMagicCost,
    uint8   _whiteMagicCost,
    uint256 _addedDamage,
    uint256 _addedShield
  ) public onlyManagement {
    require(_abilityId.isLessThan(abilities.length));
    abilities[_abilityId].name           = _name;
    abilities[_abilityId].canBeBlocked   = _canBeBlocked;
    abilities[_abilityId].blackMagicCost = _blackMagicCost;
    abilities[_abilityId].grayMagicCost  = _grayMagicCost;
    abilities[_abilityId].whiteMagicCost = _whiteMagicCost;
    abilities[_abilityId].addedDamage    = _addedDamage;
    abilities[_abilityId].addedShield    = _addedShield;
  }

  function addCardToEdition(
    uint8   _editionNumber,
    string  _name,
    uint8   _classId,
    uint8   _classVariant,
    uint256 _damagePoints,
    uint256 _shieldPoints,
    uint256 _abilityId
  ) public onlyManagement {
    require(_abilityId.isLessThan(abilities.length));

    cardsInEdition[_editionNumber].push(
      Card({
        name:         _name,
        class:        _classId,
        classVariant: _classVariant,
        damagePoints: _damagePoints,
        shieldPoints: _shieldPoints,
        abilityId:    _abilityId
      })
    );
  }

  function setClassName(uint8 _classId, string _name) public onlyManagement {
    className[_classId] = _name;
  }

  function _cloneCard(Card storage card, address owner) internal {
    require(card.damagePoints > 0 || card.shieldPoints > 0);
    uint256 tokenId = cards.length;
    cards.push(card);
    _mint(owner, tokenId);
  }
}