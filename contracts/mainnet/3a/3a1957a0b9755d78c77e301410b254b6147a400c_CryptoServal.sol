pragma solidity 0.4.24;

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

// File: contracts/IMarketplace.sol

contract IMarketplace {
    function createAuction(
        uint256 _tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    )
        external;
}

// File: contracts/GameData.sol

contract GameData {
    struct Country {       
        bytes2 isoCode;
        uint8 animalsCount;
        uint256[3] animalIds;
    }

    struct Animal {
        bool isSold;
        uint256 currentValue;
        uint8 rarity; // 0-4, rarity = stat range, higher rarity = better stats

        bytes32 name;         
        uint256 countryId; // country of origin

    }

    struct Dna {
        uint256 animalId; 
        uint8 effectiveness; //  1 - 100, 100 = same stats as a wild card
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

// File: contracts/Restricted.sol

contract Restricted is Ownable {
    mapping(address => bool) private addressIsAdmin;
    bool private isActive = true;

    modifier onlyAdmin() {
        require(addressIsAdmin[msg.sender] || msg.sender == owner);
        _;
    }

    modifier contractIsActive() {
        require(isActive);
        _;
    }

    function addAdmin(address adminAddress) public onlyOwner {
        addressIsAdmin[adminAddress] = true;
    }

    function removeAdmin(address adminAddress) public onlyOwner {
        addressIsAdmin[adminAddress] = false;
    }

    function pauseContract() public onlyOwner {
        isActive = false;
    }

    function activateContract() public onlyOwner {
        isActive = true;
    }
}

// File: contracts/CryptoServal.sol

contract CryptoServal is ERC721Token("CryptoServal", "CS"), GameData, Restricted {

    using AddressUtils for address;

    uint8 internal developersFee = 5;
    uint256[3] internal rarityTargetValue = [0.5 ether, 1 ether, 2 ether];

    Country[] internal countries;
    Animal[] internal animals;
    Dna[] internal dnas;

    using SafeMath for uint256;

    event AnimalBoughtEvent(
        uint256 animalId,
        address previousOwner,
        address newOwner,
        uint256 pricePaid,
        bool isSold
    );

    mapping (address => uint256) private addressToDnaCount;

    mapping (uint => address) private dnaIdToOwnerAddress;

    uint256 private startingAnimalPrice = 0.001 ether;

    IMarketplace private marketplaceContract;

    bool private shouldGenerateDna = true;

    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId < animals.length);
        _;
    }

    modifier soldOnly(uint256 _tokenId) {
        require(animals[_tokenId].isSold);
        _;
    }

    modifier isNotFromContract() {
        require(!msg.sender.isContract());
        _;
    }

    function () public payable {
    }

    function createAuction(
        uint256 _tokenId,
        uint128 startPrice,
        uint128 endPrice,
        uint128 duration
    )
        external
        isNotFromContract
    {
        // approve, not a transfer, let marketplace confirm the original owner and take ownership
        approve(address(marketplaceContract), _tokenId);
        marketplaceContract.createAuction(_tokenId, startPrice, endPrice, duration);
    }

    function setMarketplaceContract(address marketplaceAddress) external onlyOwner {
        marketplaceContract = IMarketplace(marketplaceAddress);
    }

    function getPlayerAnimals(address playerAddress)
        external
        view
        returns(uint256[])
    {
        uint256 animalsOwned = ownedTokensCount[playerAddress];
        uint256[] memory playersAnimals = new uint256[](animalsOwned);

        if (animalsOwned == 0) {
            return playersAnimals;
        }

        uint256 animalsLength = animals.length;
        uint256 playersAnimalsIndex = 0;
        uint256 animalId = 0;
        while (playersAnimalsIndex < animalsOwned && animalId < animalsLength) {
            if (tokenOwner[animalId] == playerAddress) {
                playersAnimals[playersAnimalsIndex] = animalId;
                playersAnimalsIndex++;
            }
            animalId++;
        }

        return playersAnimals;
    }

    function getPlayerDnas(address playerAddress) external view returns(uint256[]) {
        uint256 dnasOwned = addressToDnaCount[playerAddress];
        uint256[] memory playersDnas = new uint256[](dnasOwned);

        if (dnasOwned == 0) {
            return playersDnas;
        }

        uint256 dnasLength = dnas.length;
        uint256 playersDnasIndex = 0;
        uint256 dnaId = 0;
        while (playersDnasIndex < dnasOwned && dnaId < dnasLength) {
            if (dnaIdToOwnerAddress[dnaId] == playerAddress) {
                playersDnas[playersDnasIndex] = dnaId;
                playersDnasIndex++;
            }
            dnaId++;
        }

        return playersDnas;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId)
        public
        validTokenId(_tokenId)
        soldOnly(_tokenId)
    {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
        public
        validTokenId(_tokenId)
        soldOnly(_tokenId)
    {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        public
        validTokenId(_tokenId)
        soldOnly(_tokenId)
    {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function buyAnimal(uint256 id) public payable isNotFromContract contractIsActive {
        uint256 etherSent = msg.value;
        address sender = msg.sender;

        Animal storage animalToBuy = animals[id];

        require(etherSent >= animalToBuy.currentValue);
        require(tokenOwner[id] != sender);
        require(!animalToBuy.isSold);
        uint256 etherToPay = animalToBuy.currentValue;
        uint256 etherToRefund = etherSent.sub(etherToPay);
        address previousOwner = tokenOwner[id];

        // Inlined transferFrom
        clearApproval(previousOwner, id);
        removeTokenFrom(previousOwner, id);
        addTokenTo(sender, id);

        emit Transfer(previousOwner, sender, id);
        //

        // subtract developers fee
        uint256 ownersShare = etherToPay.sub(etherToPay * developersFee / 100);
        // pay previous owner
        previousOwner.transfer(ownersShare);
        // refund overpaid ether
        refundSender(sender, etherToRefund);

        // If the bid is above the target price, lock the buying via this contract and enable ERC721
        if (etherToPay >= rarityTargetValue[animalToBuy.rarity]) {
            animalToBuy.isSold = true;
            animalToBuy.currentValue = 0;
        } else {
            // calculate new value, multiplier depends on current amount of ether
            animalToBuy.currentValue = calculateNextEtherValue(animalToBuy.currentValue);
        }

        if (shouldGenerateDna) {
            generateDna(sender, id, etherToPay, animalToBuy);
        }
        emit AnimalBoughtEvent(id, previousOwner, sender, etherToPay, animalToBuy.isSold);
    }

    function getAnimal(uint256 _animalId)
        public
        view
        returns(
            uint256 countryId,
            bytes32 name,
            uint8 rarity,
            uint256 currentValue,
            uint256 targetValue,
            address owner,
            uint256 id
        )
    {
        Animal storage animal = animals[_animalId];
        return (
            animal.countryId,
            animal.name,
            animal.rarity,
            animal.currentValue,
            rarityTargetValue[animal.rarity],
            tokenOwner[_animalId],
            _animalId
        );
    }

    function getAnimalsCount() public view returns(uint256 animalsCount) {
        return animals.length;
    }

    function getDna(uint256 _dnaId)
        public
        view
        returns(
            uint animalId,
            address owner,
            uint16 effectiveness,
            uint256 id
        )
    {
        Dna storage dna = dnas[_dnaId];
        return (dna.animalId, dnaIdToOwnerAddress[_dnaId], dna.effectiveness, _dnaId);
    }

    function getDnasCount() public view returns(uint256) {
        return dnas.length;
    }

    function getCountry(uint256 _countryId)
        public
        view
        returns(
            bytes2 isoCode,
            uint8 animalsCount,
            uint256[3] animalIds,
            uint256 id
        )
    {
        Country storage country = countries[_countryId];
        return(country.isoCode, country.animalsCount, country.animalIds, _countryId);
    }

    function getCountriesCount() public view returns(uint256 countriesCount) {
        return countries.length;
    }

    function getDevelopersFee() public view returns(uint8) {
        return developersFee;
    }

    function getMarketplaceContract() public view returns(address) {
        return marketplaceContract;
    }

    function getShouldGenerateDna() public view returns(bool) {
        return shouldGenerateDna;
    }

    function withdrawContract() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setDevelopersFee(uint8 _developersFee) public onlyOwner {
        require((_developersFee >= 0) && (_developersFee <= 8));
        developersFee = _developersFee;
    }

    function setShouldGenerateDna(bool _shouldGenerateDna) public onlyAdmin {
        shouldGenerateDna = _shouldGenerateDna;
    }

    function addCountry(bytes2 isoCode) public onlyAdmin {
        Country memory country;
        country.isoCode = isoCode;
        countries.push(country);
    }

    function addAnimal(uint256 countryId, bytes32 animalName, uint8 rarity) public onlyAdmin {
        require((rarity >= 0) && (rarity < 3));
        Country storage country = countries[countryId];

        uint256 id = animals.length; // id is assigned before push

        Animal memory animal = Animal(
            false, // new animal is not sold yet
            startingAnimalPrice,
            rarity,
            animalName,
            countryId
        );

        animals.push(animal);
        addAnimalIdToCountry(id, country);
        _mint(address(this), id);
    }

    function changeCountry(uint256 id, bytes2 isoCode) public onlyAdmin {
        Country storage country = countries[id];
        country.isoCode = isoCode;
    }

    function changeAnimal(uint256 animalId, uint256 countryId, bytes32 name, uint8 rarity)
        public
        onlyAdmin
    {
        require(countryId < countries.length);
        Animal storage animal = animals[animalId];
        if (animal.name != name) {
            animal.name = name;
        }
        if (animal.rarity != rarity) {
            require((rarity >= 0) && (rarity < 3));
            animal.rarity = rarity;
        }
        if (animal.countryId != countryId) {
            Country storage country = countries[countryId];

            uint256 oldCountryId = animal.countryId;

            addAnimalIdToCountry(animalId, country);
            removeAnimalIdFromCountry(animalId, oldCountryId);

            animal.countryId = countryId;
        }
    }

    function setRarityTargetValue(uint8 index, uint256 targetValue) public onlyAdmin {
        rarityTargetValue[index] = targetValue;
    }

    function calculateNextEtherValue(uint256 currentEtherValue) public pure returns(uint256) {
        if (currentEtherValue < 0.1 ether) {
            return currentEtherValue.mul(2);
        } else if (currentEtherValue < 0.5 ether) {
            return currentEtherValue.mul(3).div(2); // x1.5
        } else if (currentEtherValue < 1 ether) {
            return currentEtherValue.mul(4).div(3); // x1.33
        } else if (currentEtherValue < 5 ether) {
            return currentEtherValue.mul(5).div(4); // x1.25
        } else if (currentEtherValue < 10 ether) {
            return currentEtherValue.mul(6).div(5); // x1.2
        } else {
            return currentEtherValue.mul(7).div(6); // 1.16
        }
    }

    function refundSender(address sender, uint256 etherToRefund) private {
        if (etherToRefund > 0) {
            sender.transfer(etherToRefund);
        }
    }

    function generateDna(
        address sender,
        uint256 animalId,
        uint256 pricePaid,
        Animal animal
    )
        private
    {
        uint256 id = dnas.length; // id is assigned before push
        Dna memory dna = Dna(
            animalId,
            calculateAnimalEffectiveness(pricePaid, animal)
        );

        dnas.push(dna);

        dnaIdToOwnerAddress[id] = sender;
        addressToDnaCount[sender] = addressToDnaCount[sender].add(1);
    }

    function calculateAnimalEffectiveness(
        uint256 pricePaid,
        Animal animal
    )
        private
        view
        returns(uint8)
    {
        if (animal.isSold) {
            return 100;
        }

        uint256 effectiveness = 10; // 10-90;
        // more common the animal = cheaper effectiveness
        uint256 effectivenessPerEther = 10**18 * 80 / rarityTargetValue[animal.rarity];
        effectiveness = effectiveness.add(pricePaid * effectivenessPerEther / 10**18);

        if (effectiveness > 90) {
            effectiveness = 90;
        }

        return uint8(effectiveness);
    }

    function addAnimalIdToCountry(
        uint256 animalId,
        Country storage country
    )
        private
    {
        uint8 animalSlotIndex = country.animalsCount;
        require(animalSlotIndex < 3);
        country.animalIds[animalSlotIndex] = animalId;
        country.animalsCount += 1;
    }

    function removeAnimalIdFromCountry(uint256 animalId, uint256 countryId) private {
        Country storage country = countries[countryId];
        for (uint8 i = 0; i < country.animalsCount; i++) {
            if (country.animalIds[i] == animalId) {
                if (i != country.animalsCount - 1) {
                    country.animalIds[i] = country.animalIds[country.animalsCount - 1];
                }
                country.animalsCount -= 1;
                return;
            }
        }
    }
}