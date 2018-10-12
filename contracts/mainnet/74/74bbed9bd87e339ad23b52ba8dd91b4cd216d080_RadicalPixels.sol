pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol

/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
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
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
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
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
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
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
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
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
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
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
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
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
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
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

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
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
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
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
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

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    ownedTokens[_from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
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
   * Reverts if the token does not exist
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
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/HarbergerTaxable.sol

contract HarbergerTaxable is Ownable {
  using SafeMath for uint256;

  uint256 public taxPercentage;
  address public taxCollector;
  address public ethFoundation;
  uint256 public currentFoundationContribution;
  uint256 public ethFoundationPercentage;
  uint256 public taxCollectorPercentage;

  event UpdateCollector(address indexed newCollector);
  event UpdateTaxPercentages(uint256 indexed newEFPercentage, uint256 indexed newTaxCollectorPercentage);

  constructor(uint256 _taxPercentage, address _taxCollector) public {
    taxPercentage = _taxPercentage;
    taxCollector = _taxCollector;
    ethFoundation = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;
    ethFoundationPercentage = 20;
    taxCollectorPercentage = 80;
  }

  // The total self-assessed value of user&#39;s assets
  mapping(address => uint256) public valueHeld;

  // Timestamp for the last time taxes were deducted from a user&#39;s account
  mapping(address => uint256) public lastPaidTaxes;

  // The amount of ETH a user can withdraw at the last time taxes were deducted from their account
  mapping(address => uint256) public userBalanceAtLastPaid;

  /**
   * Modifiers
   */

  modifier hasPositveBalance(address user) {
    require(userHasPositveBalance(user) == true, "User has a negative balance");
    _;
  }

  /**
   * Public functions
   */

  function updateCollector(address _newCollector)
    public
    onlyOwner
  {
    require(_newCollector != address(0));
    taxCollector == _newCollector;
    emit UpdateCollector(_newCollector);
  }

  function updateTaxPercentages(uint256 _newEFPercentage, uint256 _newTaxCollectorPercentage)
    public
    onlyOwner
  {
    require(_newEFPercentage < 100);
    require(_newTaxCollectorPercentage < 100);
    require(_newEFPercentage.add(_newTaxCollectorPercentage) == 100);

    ethFoundationPercentage = _newEFPercentage;
    taxCollectorPercentage = _newTaxCollectorPercentage;
    emit UpdateTaxPercentages(_newEFPercentage, _newTaxCollectorPercentage);
  }

  function addFunds()
    public
    payable
  {
    userBalanceAtLastPaid[msg.sender] = userBalanceAtLastPaid[msg.sender].add(msg.value);
  }

  function withdraw(uint256 value) public onlyOwner {
    // Settle latest taxes
    require(transferTaxes(msg.sender, false), "User has a negative balance");

    // Subtract the withdrawn value from the user&#39;s account
    userBalanceAtLastPaid[msg.sender] = userBalanceAtLastPaid[msg.sender].sub(value);

    // Transfer remaining balance to msg.sender
    msg.sender.transfer(value);
  }

  function userHasPositveBalance(address user) public view returns (bool) {
    return userBalanceAtLastPaid[user] >= _taxesDue(user);
  }

  function userBalance(address user) public view returns (uint256) {
    return userBalanceAtLastPaid[user].sub(_taxesDue(user));
  }

  // Transfers the taxes a user owes from their account to the taxCollector and resets lastPaidTaxes to now
  function transferTaxes(address user, bool isInAuction) public returns (bool) {

    if (isInAuction) {
      return true;
    }

    uint256 taxesDue = _taxesDue(user);

    // Make sure the user has enough funds to pay the taxesDue
    if (userBalanceAtLastPaid[user] < taxesDue) {
        return false;
    }

    // Transfer taxes due from this contract to the tax collector
    _payoutTaxes(taxesDue);
    // Update the user&#39;s lastPaidTaxes
    lastPaidTaxes[user] = now;
    // subtract the taxes paid from the user&#39;s balance
    userBalanceAtLastPaid[user] = userBalanceAtLastPaid[user].sub(taxesDue);

    return true;
  }

  function payoutEF()
    public
  {
    uint256 uincornsRequirement = 2.014 ether;
    require(currentFoundationContribution >= uincornsRequirement);

    currentFoundationContribution = currentFoundationContribution.sub(uincornsRequirement);
    ethFoundation.transfer(uincornsRequirement);
  }

  /**
   * Internal functions
   */

  function _payoutTaxes(uint256 _taxesDue)
    internal
  {
    uint256 foundationContribution = _taxesDue.mul(ethFoundationPercentage).div(100);
    uint256 taxCollectorContribution = _taxesDue.mul(taxCollectorPercentage).div(100);

    currentFoundationContribution += foundationContribution;

    taxCollector.transfer(taxCollectorContribution);
  }

  // Calculate taxes due since the last time they had taxes deducted
  // from their account or since they bought their first token.
  function _taxesDue(address user) internal view returns (uint256) {
    // Make sure user owns tokens
    if (lastPaidTaxes[user] == 0) {
      return 0;
    }

    uint256 timeElapsed = now.sub(lastPaidTaxes[user]);
    return (valueHeld[user].mul(timeElapsed).div(365 days)).mul(taxPercentage).div(100);
  }

  function _addToValueHeld(address user, uint256 value) internal {
    require(transferTaxes(user, false), "User has a negative balance");
    require(userBalanceAtLastPaid[user] > 0);
    valueHeld[user] = valueHeld[user].add(value);
  }

  function _subFromValueHeld(address user, uint256 value, bool isInAuction) internal {
    require(transferTaxes(user, isInAuction), "User has a negative balance");
    valueHeld[user] = valueHeld[user].sub(value);
  }
}

// File: contracts/RadicalPixels.sol

/**
 * @title RadicalPixels
 */
contract RadicalPixels is HarbergerTaxable, ERC721Token {
  using SafeMath for uint256;

  uint256 public   xMax;
  uint256 public   yMax;
  uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
  uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
  uint256 constant factor = 0x100000000000000000000000000000000;

  struct Pixel {
    // Id of the pixel block
    bytes32 id;
    // Owner of the pixel block
    address seller;
    // Pixel block x coordinate
    uint256 x;
    // Pixel block y coordinate
    uint256 y;
    // Pixel block price
    uint256 price;
    // Auction Id
    bytes32 auctionId;
    // Content data
    bytes32 contentData;
  }

  struct Auction {
    // Id of the auction
    bytes32 auctionId;
    // Id of the pixel block
    bytes32 blockId;
    // Pixel block x coordinate
    uint256 x;
    // Pixel block y coordinate
    uint256 y;
    // Current price
    uint256 currentPrice;
    // Current Leader
    address currentLeader;
    // End Time
    uint256 endTime;
  }

  mapping(uint256 => mapping(uint256 => Pixel)) public pixelByCoordinate;
  mapping(bytes32 => Auction) public auctionById;

  /**
   * Modifiers
   */
   modifier validRange(uint256 _x, uint256 _y)
  {
    require(_x < xMax, "X coordinate is out of range");
    require(_y < yMax, "Y coordinate is out of range");
    _;
  }

  modifier auctionNotOngoing(uint256 _x, uint256 _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    require(pixel.auctionId == 0);
    _;
  }

  /**
   * Events
   */

  event BuyPixel(
    bytes32 indexed id,
    address indexed seller,
    address indexed buyer,
    uint256 x,
    uint256 y,
    uint256 price,
    bytes32 contentData
  );

  event SetPixelPrice(
    bytes32 indexed id,
    address indexed seller,
    uint256 x,
    uint256 y,
    uint256 price
  );

  event BeginDutchAuction(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    bytes32 indexed auctionId,
    address initiator,
    uint256 x,
    uint256 y,
    uint256 startTime,
    uint256 endTime
  );

  event UpdateAuctionBid(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    bytes32 indexed auctionId,
    address bidder,
    uint256 amountBet,
    uint256 timeBet
  );

  event EndDutchAuction(
    bytes32 indexed pixelId,
    uint256 indexed tokenId,
    address indexed claimer,
    uint256 x,
    uint256 y
  );

  event UpdateContentData(
    bytes32 indexed pixelId,
    address indexed owner,
    uint256 x,
    uint256 y,
    bytes32 newContentData
  );

  constructor(uint256 _xMax, uint256 _yMax, uint256 _taxPercentage, address _taxCollector)
    public
    ERC721Token("Radical Pixels", "RPX")
    HarbergerTaxable(_taxPercentage, _taxCollector)
  {
    require(_xMax > 0, "xMax must be a valid number");
    require(_yMax > 0, "yMax must be a valid number");

    xMax = _xMax;
    yMax = _yMax;
  }

  /**
   * Public Functions
   */

  /**
   * @dev Overwrite ERC721 transferFrom with our specific needs
   * @notice This transfer has to be approved and then triggered by the _to
   * address in order to avoid sending unwanted pixels
   * @param _from Address sending token
   * @param _to Address receiving token
   * @param _tokenId ID of the transacting token
   * @param _price Price of the token being transfered
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function transferFrom(address _from, address _to, uint256 _tokenId, uint256 _price, uint256 _x, uint256 _y)
    public
    auctionNotOngoing(_x, _y)
  {
    _subFromValueHeld(msg.sender, _price, false);
    _addToValueHeld(_to, _price);
    require(_to == msg.sender);
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    super.transferFrom(_from, _to, _tokenId);
  }

   /**
   * @dev Buys pixel block
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _price New price of the pixel block
   * @param _contentData Data for the pixel
   */
   function buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
     public
   {
     require(_price > 0);
     _buyUninitializedPixelBlock(_x, _y, _price, _contentData);
   }

  /**
  * @dev Buys pixel blocks
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  * @param _contentData Data for the pixel
  */
  function buyUninitializedPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price, bytes32[] _contentData)
    public
  {
    require(_x.length == _y.length && _x.length == _price.length && _x.length == _contentData.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _buyUninitializedPixelBlock(_x[i], _y[i], _price[i], _contentData[i]);
    }
  }

  /**
  * @dev Buys pixel block
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price of the pixel block
  * @param _contentData Data for the pixel
  */
  function buyPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
    public
    payable
  {
    require(_price > 0);
    uint256 _ = _buyPixelBlock(_x, _y, _price, msg.value, _contentData);
  }

  /**
  * @dev Buys pixel block
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  * @param _contentData Data for the pixel
  */
  function buyPixelBlocks(uint256[] _x, uint256[] _y, uint256[] _price, bytes32[] _contentData)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length && _x.length == _contentData.length);
    uint256 currentValue = msg.value;
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      currentValue = _buyPixelBlock(_x[i], _y[i], _price[i], currentValue, _contentData[i]);
    }
  }

  /**
  * @dev Set prices for specific blocks
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price of the pixel block
  */
  function setPixelBlockPrice(uint256 _x, uint256 _y, uint256 _price)
    public
    payable
  {
    require(_price > 0);
    _setPixelBlockPrice(_x, _y, _price);
  }

  /**
  * @dev Set prices for specific blocks
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _price New prices of the pixel blocks
  */
  function setPixelBlockPrices(uint256[] _x, uint256[] _y, uint256[] _price)
    public
    payable
  {
    require(_x.length == _y.length && _x.length == _price.length);
    for (uint i = 0; i < _x.length; i++) {
      require(_price[i] > 0);
      _setPixelBlockPrice(_x[i], _y[i], _price[i]);
    }
  }

  /**
   * Trigger a dutch auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function beginDutchAuction(uint256 _x, uint256 _y)
    public
    auctionNotOngoing(_x, _y)
    validRange(_x, _y)
  {
    Pixel storage pixel = pixelByCoordinate[_x][_y];

    require(!userHasPositveBalance(pixel.seller));
    require(pixel.auctionId == 0);

    // Start a dutch auction
    pixel.auctionId = _generateDutchAuction(_x, _y);
    uint256 tokenId = _encodeTokenId(_x, _y);

    _updatePixelMapping(pixel.seller, _x, _y, pixel.price, pixel.auctionId, "");

    emit BeginDutchAuction(
      pixel.id,
      tokenId,
      pixel.auctionId,
      msg.sender,
      _x,
      _y,
      block.timestamp,
      block.timestamp.add(1 days)
    );
  }

  /**
   * @dev Allow a user to bid in an auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _bid Desired bid of the user
   */
  function bidInAuction(uint256 _x, uint256 _y, uint256 _bid)
    public
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction storage auction = auctionById[pixel.auctionId];

    uint256 _tokenId = _encodeTokenId(_x, _y);
    require(pixel.auctionId != 0);
    require(auction.currentPrice < _bid);
    require(block.timestamp < auction.endTime);

    auction.currentPrice = _bid;
    auction.currentLeader = msg.sender;

    emit UpdateAuctionBid(
      pixel.id,
      _tokenId,
      auction.auctionId,
      msg.sender,
      _bid,
      block.timestamp
    );
  }

  /**
   * End the auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function endDutchAuction(uint256 _x, uint256 _y)
    public
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction memory auction = auctionById[pixel.auctionId];

    require(pixel.auctionId != 0);
    require(auction.endTime < block.timestamp);

    // End dutch auction
    address winner = _endDutchAuction(_x, _y);
    _updatePixelMapping(winner, _x, _y, auction.currentPrice, 0, "");

    // Update user values
    _subFromValueHeld(pixel.seller, pixel.price, true);
    _addToValueHeld(winner, auction.currentPrice);

    uint256 tokenId = _encodeTokenId(_x, _y);
    removeTokenFrom(pixel.seller, tokenId);
    addTokenTo(winner, tokenId);
    emit Transfer(pixel.seller, winner, tokenId);

    emit EndDutchAuction(
      pixel.id,
      tokenId,
      winner,
      _x,
      _y
    );
  }

  /**
  * @dev Change content data of a pixel
  * @param _x X coordinates of the desired blocks
  * @param _y Y coordinates of the desired blocks
  * @param _contentData Data for the pixel
  */
  function changeContentData(uint256 _x, uint256 _y, bytes32 _contentData)
    public
  {
    Pixel storage pixel = pixelByCoordinate[_x][_y];

    require(msg.sender == pixel.seller);

    pixel.contentData = _contentData;

    emit UpdateContentData(
      pixel.id,
      pixel.seller,
      _x,
      _y,
      _contentData
  );

  }

  /**
   * Encode a token ID for transferability
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function encodeTokenId(uint256 _x, uint256 _y)
    public
    view
    validRange(_x, _y)
    returns (uint256)
  {
    return _encodeTokenId(_x, _y);
  }

  /**
   * Internal Functions
   */

  /**
  * @dev Buys an uninitialized pixel block for 0 ETH
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price for the pixel
  * @param _contentData Data for the pixel
  */
  function _buyUninitializedPixelBlock(uint256 _x, uint256 _y, uint256 _price, bytes32 _contentData)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == address(0), "Pixel must not be initialized");

    uint256 tokenId = _encodeTokenId(_x, _y);
    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price, 0, _contentData);

    _addToValueHeld(msg.sender, _price);
    _mint(msg.sender, tokenId);

    emit BuyPixel(
      pixelId,
      address(0),
      msg.sender,
      _x,
      _y,
      _price,
      _contentData
    );
  }

  /**
   * @dev Buys a pixel block
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   * @param _price New price of the pixel block
   * @param _currentValue Current value of the transaction
   * @param _contentData Data for the pixel
   */
  function _buyPixelBlock(uint256 _x, uint256 _y, uint256 _price, uint256 _currentValue, bytes32 _contentData)
    internal
    validRange(_x, _y)
    hasPositveBalance(msg.sender)
    returns (uint256)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    require(pixel.auctionId == 0);  // Stack to deep if this is a modifier
    uint256 _taxOnPrice = _calculateTax(_price);

    require(pixel.seller != address(0), "Pixel must be initialized");
    require(userBalanceAtLastPaid[msg.sender] >= _taxOnPrice);
    require(pixel.price <= _currentValue, "Must have sent sufficient funds");

    uint256 tokenId = _encodeTokenId(_x, _y);

    removeTokenFrom(pixel.seller, tokenId);
    addTokenTo(msg.sender, tokenId);
    emit Transfer(pixel.seller, msg.sender, tokenId);

    _addToValueHeld(msg.sender, _price);
    _subFromValueHeld(pixel.seller, pixel.price, false);

    _updatePixelMapping(msg.sender, _x, _y, _price, 0, _contentData);
    pixel.seller.transfer(pixel.price);

    emit BuyPixel(
      pixel.id,
      pixel.seller,
      msg.sender,
      _x,
      _y,
      pixel.price,
      _contentData
    );

    return _currentValue.sub(pixel.price);
  }

  /**
  * @dev Set prices for a specific block
  * @param _x X coordinate of the desired block
  * @param _y Y coordinate of the desired block
  * @param _price New price of the pixel block
  */
  function _setPixelBlockPrice(uint256 _x, uint256 _y, uint256 _price)
    internal
    auctionNotOngoing(_x, _y)
    validRange(_x, _y)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    require(pixel.seller == msg.sender, "Sender must own the block");
    _addToValueHeld(msg.sender, _price);

    delete pixelByCoordinate[_x][_y];

    bytes32 pixelId = _updatePixelMapping(msg.sender, _x, _y, _price, 0, "");

    emit SetPixelPrice(
      pixelId,
      pixel.seller,
      _x,
      _y,
      pixel.price
    );
  }

  /**
   * Generate a dutch auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function _generateDutchAuction(uint256 _x, uint256 _y)
    internal
    returns (bytes32)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];

    bytes32 _auctionId = keccak256(
      abi.encodePacked(
        block.timestamp,
        _x,
        _y
      )
    );

    auctionById[_auctionId] = Auction({
      auctionId: _auctionId,
      blockId: pixel.id,
      x: _x,
      y: _y,
      currentPrice: 0,
      currentLeader: msg.sender,
      endTime: block.timestamp.add(1 days)
    });

    return _auctionId;
  }

  /**
   * End a finished dutch auction
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function _endDutchAuction(uint256 _x, uint256 _y)
    internal
    returns (address)
  {
    Pixel memory pixel = pixelByCoordinate[_x][_y];
    Auction memory auction = auctionById[pixel.auctionId];

    address _winner = auction.currentLeader;

    delete auctionById[auction.auctionId];

    return _winner;
  }
  /**
    * @dev Update pixel mapping every time it is purchase or the price is
    * changed
    * @param _seller Seller of the pixel block
    * @param _x X coordinate of the desired block
    * @param _y Y coordinate of the desired block
    * @param _price Price of the pixel block
    * @param _contentData Data for the pixel
    */
  function _updatePixelMapping
  (
    address _seller,
    uint256 _x,
    uint256 _y,
    uint256 _price,
    bytes32 _auctionId,
    bytes32 _contentData
  )
    internal
    returns (bytes32)
  {
    bytes32 pixelId = keccak256(
      abi.encodePacked(
        _x,
        _y
      )
    );

    pixelByCoordinate[_x][_y] = Pixel({
      id: pixelId,
      seller: _seller,
      x: _x,
      y: _y,
      price: _price,
      auctionId: _auctionId,
      contentData: _contentData
    });

    return pixelId;
  }

  function _calculateTax(uint256 _price)
    internal
    view
    returns (uint256)
  {
    return _price.mul(taxPercentage).div(100);
  }
  /**
   * Encode token ID
   * @param _x X coordinate of the desired block
   * @param _y Y coordinate of the desired block
   */
  function _encodeTokenId(uint256 _x, uint256 _y)
    internal
    pure
    returns (uint256 result)
  {
    return ((_x * factor) & clearLow) | (_y & clearHigh);
  }
}