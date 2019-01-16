pragma solidity ^0.4.24;

// File: contracts/openzeppelin-solidity/introspection/ERC165.sol

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

// File: contracts/openzeppelin-solidity/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {
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

// File: contracts/openzeppelin-solidity/token/ERC721/ERC721.sol

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

// File: contracts/openzeppelin-solidity/token/ERC721/ERC721Receiver.sol

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
   * @param _tokenId The NFT identifier which is being transfered
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

// File: contracts/openzeppelin-solidity/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/openzeppelin-solidity/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
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
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: contracts/openzeppelin-solidity/introspection/SupportsInterfaceWithLookup.sol

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

// File: contracts/openzeppelin-solidity/token/ERC721/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
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

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

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
    canTransfer(_tokenId)
  {
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
    canTransfer(_tokenId)
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

// File: contracts/openzeppelin-solidity/token/ERC721/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

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

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
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

// File: contracts/openzeppelin-solidity/ownership/Ownable.sol

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

// File: contracts/ERC721TokenWithData.sol

// import "./ERC721SlimTokenArray.sol";



// an ERC721 token with additional data storage,
contract ERC721TokenWithData is ERC721Token("CryptoAssaultUnit", "CAU"), Ownable {

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
			approvedContractAddresses[_spender] ||
			getApproved(_tokenId) == _spender ||
			isApprovedForAll(owner, _spender)
		);
	}

	mapping (address => bool) internal approvedContractAddresses;
	bool approvedContractsFinalized = false;

	/**
	* @notice Approve a contract address for minting tokens and transferring tokens, when approved by the owner
	* @param contractAddress The address that will be approved
	*/
	function addApprovedContractAddress(address contractAddress) public onlyOwner
	{
		require(!approvedContractsFinalized);
		approvedContractAddresses[contractAddress] = true;
	}

	/**
	* @notice Unapprove a contract address for minting tokens and transferring tokens
	* @param contractAddress The address that will be unapproved
	*/
	function removeApprovedContractAddress(address contractAddress) public onlyOwner
	{
		require(!approvedContractsFinalized);
		approvedContractAddresses[contractAddress] = false;
	}

	/**
	* @notice Finalize the contract so it will be forever impossible to change the approved contracts list
	*/
	function finalizeApprovedContracts() public onlyOwner {
		approvedContractsFinalized = true;
	}

	mapping(uint256 => mapping(uint256 => uint256)) data;

	function getData(uint256 _tokenId, uint256 _index) public view returns (uint256) {
		return data[_index][_tokenId];
	}

	function getData3(uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, uint256 _index) public view returns (uint256, uint256, uint256) {
		return (
			data[_index][_tokenId1],
			data[_index][_tokenId2],
			data[_index][_tokenId3]
		);
	}
	
	function getDataAndOwner3(uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, uint256 _index) public view returns (uint256, uint256, uint256, address, address, address) {
		return (
			data[_index][_tokenId1],
			data[_index][_tokenId2],
			data[_index][_tokenId3],
			ownerOf(_tokenId1),
			ownerOf(_tokenId2),
			ownerOf(_tokenId3)
		);
	}
	
	function _setData(uint256 _tokenId, uint256 _index, uint256 _data) internal {
		
		data[_index][_tokenId] = _data;
	}

	function setData(uint256 _tokenId, uint256 _index, uint256 _data) public {
		
		require(approvedContractAddresses[msg.sender], "not an approved sender");
		data[_index][_tokenId] = _data;
	}

	/**
	* @notice Gets the list of tokens owned by a given address
	* @param _owner address to query the tokens of
	* @return uint256[] representing the list of tokens owned by the passed address
	*/
	function tokensOfWithData(address _owner, uint256 _index) public view returns (uint256[], uint256[]) {
		uint256[] memory tokensList = ownedTokens[_owner];
		uint256[] memory dataList = new uint256[](tokensList.length);
		for (uint i=0; i<tokensList.length; i++) {
			dataList[i] = data[_index][tokensList[i]];
		}
		return (tokensList, dataList);
	}

	// The tokenId of the next minted token. It auto-increments.
	uint256 nextTokenId = 1;

	function getNextTokenId() public view returns (uint256) {
		return nextTokenId;
	}

	/**
	* @notice Mint token function
	* @param _to The address that will own the minted token
	*/
	function mintAndSetData(address _to, uint256 _data) public returns (uint256) {

		require(approvedContractAddresses[msg.sender], "not an approved sender");

		uint256 tokenId = nextTokenId;
		nextTokenId++;
		_mint(_to, tokenId);
		_setData(tokenId, 0, _data);

		return tokenId;
	}

	function burn(uint256 _tokenId) public {
		require(
			approvedContractAddresses[msg.sender] ||
			msg.sender == owner, "burner not approved"
		);

		_burn(ownerOf(_tokenId), _tokenId);
	}
	
	function burn3(uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3) public {
		require(
			approvedContractAddresses[msg.sender] ||
			msg.sender == owner, "burner not approved"
		);

		_burn(ownerOf(_tokenId1), _tokenId1);
		_burn(ownerOf(_tokenId2), _tokenId2);
		_burn(ownerOf(_tokenId3), _tokenId3);
	}
}

// File: contracts/strings/Strings.sol

library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

// File: contracts/Token.sol

contract Token is ERC721TokenWithData {

	string metadataUrlPrefix = "https://api.cryptoassault.io/unit/";

	/**
	* @dev Returns an URI for a given token ID
	* Throws if the token ID does not exist. May return an empty string.
	* @param _tokenId uint256 ID of the token to query
	*/
	function tokenURI(uint256 _tokenId) public view returns (string) {
		require(exists(_tokenId));
		return Strings.strConcat(metadataUrlPrefix, Strings.uint2str(_tokenId));
	}

	function setMetadataUrlPrefix(string _metadataUrlPrefix) public onlyOwner
	{
		metadataUrlPrefix = _metadataUrlPrefix;
	}
}

// File: contracts/openzeppelin-solidity/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/GachaSale.sol

contract GachaSale is Pausable {

	event Sold(address buyer, uint256 amount, uint256 totalPrice);
	event Hatched(address buyer, uint256 amount);

	uint256 constant PRESALE_START_TIME = 1541628000; //TODO: put in a real time.
	uint256 constant NUM_UNIT_TYPES = 30;

	Token token;

	function setTokenContractAddress(address newAddress) onlyOwner public {
		token = Token(newAddress);
	}
	
	// this is a continuously rotating FIFO.
	// to delete the first item, increment firstIndex,
	// mod by MAX_WAITING_TO_HATCH_ENTRIES,
	// and decrement num.
	struct WaitingToHatch {
		address owner;
		uint32 amount;
		uint16 rarity;
		uint16 sku;
		uint32 purchasedOnBlockNumber;
	}
	uint64 constant MAX_WAITING_TO_HATCH_ENTRIES = 256;
	WaitingToHatch[MAX_WAITING_TO_HATCH_ENTRIES] waitingToHatch;

	uint64 waitingToHatchFirstIndex;
	uint64 waitingToHatchNum;
	uint64 hatchNonce = 1;

	// maps amount to a price.
	mapping(uint256 => uint256) prices;

	uint256 constant NUM_RARITIES = 4;
	
	constructor() public {
	// 	// temp, to test gas prices after some usage.
	// 	for (uint256 i=0; i<MAX_WAITING_TO_HATCH_ENTRIES; i++) {
	// 		waitingToHatch[i].amount = 1;
	// 	}
	}
	
	function withdrawBalance() onlyOwner public {
		owner.transfer(address(this).balance);
	}

	function setPrice(uint32 sku, uint64 price) public onlyOwner {
		prices[sku] = price;
	}

	function getPrice(uint32 sku) public view returns (uint256)
	{
		require(now >= PRESALE_START_TIME, "The sale hasn&#39;t started yet");

		uint256 price = prices[sku];
		require (price > 0);

		// Apply the pre-sale discount
		uint256 intervalsSinceSaleStarted = (now - PRESALE_START_TIME) / (1 hours);
		// The discount starts at 30% and goes down 1% every 2 days.
		uint256 pricePercentage = 70 + intervalsSinceSaleStarted;
		if (pricePercentage < 100) {
			price = (price * pricePercentage) / 100;
		}

		return price;
	}

	function pushHatch(address to, uint32 amount, uint16 rarity, uint16 sku) private {

		require(waitingToHatchNum < MAX_WAITING_TO_HATCH_ENTRIES, "There are too many hatching gachas. Wait a bit.");

		uint256 index = waitingToHatchFirstIndex + waitingToHatchNum;
		index = index % MAX_WAITING_TO_HATCH_ENTRIES;
		waitingToHatch[index] = WaitingToHatch(to, amount, rarity, sku, uint32(block.number));
		waitingToHatchNum = waitingToHatchNum + 1;
	}

	function popHatch() private {

		waitingToHatchNum = waitingToHatchNum - 1;
		waitingToHatchFirstIndex = (waitingToHatchFirstIndex + 1) % MAX_WAITING_TO_HATCH_ENTRIES;
	}

	function peekHatch() private view returns (WaitingToHatch) {

		return waitingToHatch[waitingToHatchFirstIndex];
	}

	function buy(uint16 sku, address referral) external payable whenNotPaused {

		uint256 price = getPrice(sku);
		require(msg.value >= price, "Amount paid is too low");

		// push the purchase onto a FIFO, to be minted in a later transaction.

		if (sku == 1) {
			pushHatch(msg.sender, 1, 0, sku); // 1 common or better
		} else if (sku == 2) {
			pushHatch(msg.sender, 5, 0, sku); // 5 common or better
		} else if (sku == 3) {
			pushHatch(msg.sender, 10, 1, sku);  // 10 rare or better
		} else if (sku == 4) {
			// 50 common or better
			pushHatch(msg.sender, 10, 0, sku);
			pushHatch(msg.sender, 10, 0, sku);
			pushHatch(msg.sender, 10, 0, sku);
			pushHatch(msg.sender, 10, 0, sku);
			pushHatch(msg.sender, 10, 0, sku);
		} else if (sku == 5) {
			// 47 rare or better
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 10, 1, sku);
			pushHatch(msg.sender, 7, 1, sku);
			// 3 epic or better
			pushHatch(msg.sender, 3, 2, sku);
		} else {
			require(false, "Invalid sku");
		}

		// Pay the referral 5%
		if (referral != address(0)) {
			referral.transfer(price / 20);
		}

		emit Sold(msg.sender, sku, price);
	}

	function giveFreeUnit(address to, uint16 minRarity) onlyOwner public
	{
		pushHatch(to, 1, minRarity, 0);
	}

	function getNumMyHatchingUnits() public view returns (uint256) {
		uint256 num = 0;
		for (uint256 i=waitingToHatchFirstIndex; i<waitingToHatchFirstIndex + waitingToHatchNum; i++) {
			uint256 indexModded = i % MAX_WAITING_TO_HATCH_ENTRIES;
			if (waitingToHatch[indexModded].owner == msg.sender) {
				num += waitingToHatch[indexModded].amount;
			}
		}
		return num;
	}

	function hatchingsNeeded() external view returns (uint256) {

		return waitingToHatchNum;
	}
	
	function getProjectedBlockHash(uint256 blockNumber) internal view returns (uint256) {

		uint256 blockToHash = blockNumber;
		uint256 blocksAgo = block.number - blockToHash;
		if (blocksAgo > 256) {
			blockToHash += (blocksAgo / 256) * 256;
		}
		return uint256(blockhash(blockToHash));
	}

	function getRandomType(uint16 rand) internal pure returns (uint8)
	{
		return uint8(rand % NUM_UNIT_TYPES);
	}
 
	function getRandomRarity(uint32 rand, uint256 minimumRarity) internal pure returns (uint256)
	{

		uint256 rarityRand;
		if (minimumRarity == 0) {
			rarityRand = rand % 100;
		} else if (minimumRarity == 1) {
			rarityRand = rand % 20 + 80;
		} else if (minimumRarity == 2) {
			rarityRand = rand % 5 + 95;
		} else if (minimumRarity == 3) {
			rarityRand = 99;
		} else {
			require(false, "Invalid minimumRarity");
		}

		if (rarityRand < 80) return 0;
		if (rarityRand < 95) return 1;
		if (rarityRand < 99) return 2;
		return 3;
	}

	function hatch() external whenNotPaused {

		require(waitingToHatchNum > 0, "nothing to hatch");

		WaitingToHatch memory w = peekHatch();
		
		// can&#39;t hatch on the same block. its block hash would be unknown.
		require (w.purchasedOnBlockNumber < block.number, "Can&#39;t hatch on the same block.");

		uint256 rand = getProjectedBlockHash(w.purchasedOnBlockNumber) + hatchNonce;

		for (uint256 i=0; i<w.amount; i++) {
			rand = uint256(keccak256(abi.encodePacked(rand)));
			uint256 thisRand = rand;
			uint8 unitType = getRandomType(uint16(thisRand));
			thisRand >>= 16;

			uint256 rarity = getRandomRarity(uint32(thisRand), w.rarity);
			thisRand >>= 32;

			// TPRDATEDARSKRANDOM__RANDOM__RANDOM__RANDOM__RAND0000000000000000

			uint256 data = unitType; // 8 bits

			data <<= 4;
			// data |= 0; // tier 0

			// birth timestamp
			data <<= 24;
			data |= now / (1 days);

			data <<= 4;
			data |= rarity;
			data <<= 8;
			data |= w.sku;
			data <<= 208;
			data |= thisRand & 0xffffffffffffffffffffffffffffffffffff0000000000000000;

			token.mintAndSetData(w.owner, data);
		}

		popHatch();

		hatchNonce++;

		emit Hatched(w.owner, w.amount);
	}

}