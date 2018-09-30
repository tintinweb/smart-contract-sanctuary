pragma solidity ^0.4.23;


contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}


contract ContractReceiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */


library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract IERC721Receiver {
  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safeTransfer`. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

interface IERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public {
    minters.remove(msg.sender);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal _supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(_InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) public view returns (string);
}

contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) private _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
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

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_InterfaceId_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
    // solium-disable-next-line arg-overflow
    require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param owner owner of the token
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallSafeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

  /**
   * @dev Constructor function
   */
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return _name;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return _symbol;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 tokenId) public view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param tokenId uint256 ID of the token to set its URI
   * @param uri string URI to assign
   */
  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  /**
   * @dev Constructor function
   */
  constructor() public {
    // register the supported interface to conform to ERC721 via ERC165
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    _ownedTokens[from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to address the beneficiary that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Reorg all tokens array
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

contract ERC721Mintable is ERC721Full, MinterRole {
  event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

  /**
   * @return true if the minting is finished.
   */
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param tokenId The token id to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 tokenId
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, tokenId);
    return true;
  }

  function mintWithTokenURI(
    address to,
    uint256 tokenId,
    string tokenURI
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    mint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
}

contract Secondary {
  address private _primary;

  /**
   * @dev Sets the primary account to the one that is creating the Secondary contract.
   */
  constructor() public {
    _primary = msg.sender;
  }

  /**
   * @dev Reverts if called from any account other than the primary.
   */
  modifier onlyPrimary() {
    require(msg.sender == _primary);
    _;
  }

  function primary() public view returns (address) {
    return _primary;
  }

  function transferPrimary(address recipient) public onlyPrimary {
    require(recipient != address(0));

    _primary = recipient;
  }
}






// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fb9f9a8d9ebb9a909496999ad5989496">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract IBidRegistry {
  enum AuctionStatus {
    Undetermined,
    Lost,
    Won
  }

  enum BidState {
    Created,
    Submitted,
    Lost,
    Won,
    Refunded,
    Allocated,
    Redeemed
  }

  event BidCreated(
    bytes32 indexed hash,
    address creator,
    uint256 indexed auction,
    address indexed bidder,
    address schema,
    address license,
    uint256 durationSec,
    uint256 bidPrice,
    uint256 updatedAt
  );

  event BidAuctionStatusChange(bytes32 indexed hash, uint8 indexed auctionStatus, uint256 updatedAt);
  event BidStateChange(bytes32 indexed hash, uint8 indexed bidState, uint256 updatedAt);
  event BidClearingPriceChange(bytes32 indexed hash, uint256 clearingPrice, uint256 updatedAt);

  function hashBid(
    address _creator,
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public constant returns(bytes32);

  function verifyStoredData(bytes32 hash) public view returns(bool);

  function creator(bytes32 hash) public view returns(address);
  function auction(bytes32 hash) public view returns(uint256);
  function bidder(bytes32 hash) public view returns(address);
  function schema(bytes32 hash) public view returns(address);
  function license(bytes32 hash) public view returns(address);
  function durationSec(bytes32 hash) public view returns(uint256);
  function bidPrice(bytes32 hash) public view returns(uint256);

  function clearingPrice(bytes32 hash) public view returns(uint256);
  function auctionStatus(bytes32 hash) public view returns(uint8);
  function bidState(bytes32 hash) public view returns(uint8);
  function allocationFee(bytes32 hash) public view returns(uint256);

  function createBid(
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public;

  function setAllocationFee(bytes32 hash, uint256 fee) public;
  function setAuctionStatus(bytes32 hash, uint8 _auctionStatus) public;
  function setBidState(bytes32 hash, uint8 _bidState) public;
  function setClearingPrice(bytes32 hash, uint256 _clearingPrice) public;
}

contract IAuctionHouseClearingPriceComponent {
  event ClearingPriceSubmitted(
    address indexed submitter,
    uint256 indexed auctionId,
    bytes32 bidHash,
    uint256 clearingPrice
  );

  event ClearingPriceRejected(
    address indexed rejector,
    address indexed submitter,
    uint256 indexed auctionId,
    bytes32 bidHash,
    uint256 correctedClearingPrice
  );

  event ClearingPriceSubmitterRejected(
    address indexed rejector,
    address indexed submitter,
    uint256 indexed auctionId,
    bytes32 bidHash,
    uint256 correctedClearingPrice
  );

  function bidRegistry() public view returns(address);
  function clearingPriceCode() public view returns(bytes);
  function submissionDeposit() public view returns(uint256);
  function percentAllocationFeeNumerator() public returns(uint256);
  function percentAllocationFeeDenominator() public returns(uint256);

  function setBidRegistry(address registry) public;
  function setClearingPriceCode(bytes reference) public;
  function setSubmissionDeposit(uint256 deposit) public;
  function setPercentAllocationFee(uint256 numerator, uint256 denominator) public;

  function setSubmissionOpen(uint256 auctionId) public;
  function setSubmissionClosed(uint256 auctionId) public;

  function payDeposit(uint256 auctionId, address submitter, uint256 value) public;
  function submitClearingPrice(address submitter, bytes32 bidHash, uint256 clearingPrice) public;

  function setValidationOpen(uint256 auctionId) public;
  function setValidationClosed(uint256 auctionId) public;

  function rejectClearingPriceSubmission(
    address validator,
    address submitter,
    bytes32 bidHash,
    uint256 correctedClearingPrice
  ) public;

  function isSubmitterAccepted(uint256 auctionId, address submitter) public view returns(bool);
  function isValidSubmitter(address submitter, bytes32 bidHash) public view returns(bool);
  function hasClearingPrice(address anyValidSubmitter, bytes32 bidHash) public view returns(bool);
  function clearingPrice(address anyValidSubmitter, bytes32 bidHash) public view returns(uint256);

  function paidBidAllocationFee(bytes32 bidHash) public view returns(bool);
  function calcBidAllocationFee(bytes32 bidHash) public view returns(uint256);
  function payBidAllocationFee(bytes32 bidHash, uint256 fee) public;

  function setRewardOpen(uint256 auctionId) public;
  function setRewardClosed(uint256 auctionId) public;

  function rewarded(uint256 auctionId, address clearingPriceSubmitter) public view returns(bool);
  function calcReward(uint256 auctionId, address clearingPriceSubmitter) public view returns(uint256);
  function payReward(uint256 auctionId, address clearingPriceSubmitter, uint256 reward) public;
}

contract IAuctionHouseBiddingComponent {
  event BidRegistered(address registeree, bytes32 bidHash, uint256 updatedAt);

  function bidRegistry() public view returns(address);
  function licenseNFT() public view returns(address);
  function bidDeposit(bytes32 bidHash) public view returns(uint256);

  function submissionOpen(uint256 auctionId) public view returns(bool);
  function revealOpen(uint256 auctionId) public view returns(bool);
  function allocationOpen(uint256 auctionId) public view returns(bool);

  function setBidRegistry(address registry) public;
  function setLicenseNFT(address licenseNFTContract) public;

  function setSubmissionOpen(uint256 auctionId) public;
  function setSubmissionClosed(uint256 auctionId) public;

  function payBid(bytes32 bidHash, uint256 value) public;
  function submitBid(address registeree, bytes32 bidHash) public;

  function setRevealOpen(uint256 auctionId) public;
  function setRevealClosed(uint256 auctionId) public;

  function revealBid(bytes32 bidHash) public;

  function setAllocationOpen(uint256 auctionId) public;
  function setAllocationClosed(uint256 auctionId) public;

  function allocateBid(bytes32 bidHash, uint clearingPrice) public;
  function doNotAllocateBid(bytes32 bidHash) public;

  function payBidAllocationFee(bytes32 bidHash, uint256 fee) public;

  function calcRefund(bytes32 bidHash) public view returns(uint256);
  function payRefund(bytes32 bidHash, uint256 refund) public;

  function issueLicenseNFT(bytes32 bidHash) public;
}

contract IAuctionHouseStateTransition {
  enum AuctionState {
    Undetermined,

    AuctionCreated,

    BiddingSubmissionOpen,
    BiddingSubmissionClosed,

    BiddingRevealOpen,
    BiddingRevealClosed,

    ClearingPriceSubmissionOpen,
    ClearingPriceSubmissionClosed,

    ClearingPriceValidationOpen,
    ClearingPriceValidationClosed,

    BidAllocationOpen,
    BidAllocationClosed,

    RewardAllocationOpen,
    RewardAllocationClosed
  }

  event AuctionStateChange(
    uint256 indexed auctionId,
    AuctionState indexed state,
    uint256 updatedAt
  );

  function auctionState(uint256 auctionId) public view returns(AuctionState);
  function transition(uint256 auctionId, AuctionState state) public;
}

contract IBlindBidRegistry is IBidRegistry {
  event BlindBidCreated(
    bytes32 indexed hash,
    address creator,
    uint256 indexed auction,
    uint256 updatedAt
  );

  event BlindBidRevealed(
    bytes32 indexed hash,
    address creator,
    uint256 indexed auction,
    address indexed bidder,
    address schema,
    address license,
    uint256 durationSec,
    uint256 bidPrice,
    uint256 updatedAt
  );

  enum BlindBidState {
    // must match IBidRegistry.BidState
    Created,
    Submitted,
    Lost,
    Won,
    Refunded,
    Allocated,
    Redeemed,

    // new states
    Revealed
  }

  function createBid(bytes32 hash, uint256 _auction) public;

  function revealBid(
    bytes32 hash,
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public;
}

contract AuctionManagerRole {
  using Roles for Roles.Role;

  event AuctionManagerAdded(address indexed account);
  event AuctionManagerRemoved(address indexed account);

  Roles.Role private proxyManagers;

  constructor() public {
    proxyManagers.add(msg.sender);
  }

  modifier onlyAuctionManager() {
    require(isAuctionManager(msg.sender));
    _;
  }

  function isAuctionManager(address account) public view returns (bool) {
    return proxyManagers.has(account);
  }

  function addAuctionManager(address account) public onlyAuctionManager {
    proxyManagers.add(account);
    emit AuctionManagerAdded(account);
  }

  function renounceAuctionManager() public {
    proxyManagers.remove(msg.sender);
  }

  function _removeAuctionManager(address account) internal {
    proxyManagers.remove(account);
    emit AuctionManagerRemoved(account);
  }
}

contract ProxyManagerRole {
  using Roles for Roles.Role;

  event ProxyManagerAdded(address indexed account);
  event ProxyManagerRemoved(address indexed account);

  Roles.Role private proxyManagers;

  constructor() public {
    proxyManagers.add(msg.sender);
  }

  modifier onlyProxyManager() {
    require(isProxyManager(msg.sender));
    _;
  }

  function isProxyManager(address account) public view returns (bool) {
    return proxyManagers.has(account);
  }

  function addProxyManager(address account) public onlyProxyManager {
    proxyManagers.add(account);
    emit ProxyManagerAdded(account);
  }

  function renounceProxyManager() public {
    proxyManagers.remove(msg.sender);
  }

  function _removeProxyManager(address account) internal {
    proxyManagers.remove(account);
    emit ProxyManagerRemoved(account);
  }
}

contract BidRegistry is Secondary, IBidRegistry {
  uint256 public constant INIT_CLEARING_PRICE = 0;
  AuctionStatus public constant INIT_AUCTION_STATUS = AuctionStatus.Undetermined;
  BidState public constant INIT_BID_STATE = BidState.Created;
  uint256 public constant INIT_ALLOCATION_FEE = 0;

  struct Bid {
    // read-only after init
    address creator;

    uint256 auction;
    address bidder;
    address schema;
    address license;
    uint256 durationSec;
    uint256 bidPrice;

    // changes through state transitions
    uint256 clearingPrice;
    uint8 auctionStatus;
    uint8 bidState;
    uint256 allocationFee;
  }

  mapping(bytes32 => Bid) public registry;

  function hashBid(
    address _creator,
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public constant returns(bytes32) {
    return keccak256(abi.encodePacked(
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice
    ));
  }

  function verifyStoredData(bytes32 hash) public view returns(bool) {
    Bid memory bid = registry[hash];
    bytes32 storedBidHash = hashBid(
      bid.creator,
      bid.auction,
      bid.bidder,
      bid.schema,
      bid.license,
      bid.durationSec,
      bid.bidPrice
    );
    return storedBidHash == hash;
  }

  function creator(bytes32 hash) public view returns(address) {
    return registry[hash].creator;
  }

  function auction(bytes32 hash) public view returns(uint256) {
    return registry[hash].auction;
  }

  function bidder(bytes32 hash) public view returns(address) {
    return registry[hash].bidder;
  }

  function schema(bytes32 hash) public view returns(address) {
    return registry[hash].schema;
  }

  function license(bytes32 hash) public view returns(address) {
    return registry[hash].license;
  }

  function durationSec(bytes32 hash) public view returns(uint256) {
    return registry[hash].durationSec;
  }

  function bidPrice(bytes32 hash) public view returns(uint256) {
    return registry[hash].bidPrice;
  }

  function clearingPrice(bytes32 hash) public view returns(uint) {
    return registry[hash].clearingPrice;
  }

  function auctionStatus(bytes32 hash) public view returns(uint8) {
    return registry[hash].auctionStatus;
  }

  function bidState(bytes32 hash) public view returns(uint8) {
    return registry[hash].bidState;
  }

  function allocationFee(bytes32 hash) public view returns(uint256) {
    return registry[hash].allocationFee;
  }

  function createBid(
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint _durationSec,
    uint _bidPrice
  ) public {
    _createBid(
      msg.sender,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice
    );
  }

  function setAllocationFee(bytes32 hash, uint256 fee) public onlyPrimary {
    _setAllocationFee(hash, fee);
  }

  function setAuctionStatus(bytes32 hash, uint8 _auctionStatus) public onlyPrimary {
    _setAuctionStatus(hash, _auctionStatus);
  }

  function setBidState(bytes32 hash, uint8 _bidState) public onlyPrimary {
    _setBidState(hash, _bidState);
  }

  function setClearingPrice(bytes32 hash, uint256 _clearingPrice) public onlyPrimary {
    _setClearingPrice(hash, _clearingPrice);
  }

  function _createBid(
    address _creator,
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint _durationSec,
    uint _bidPrice
  ) internal {
    bytes32 hash = hashBid(
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice
    );

    registry[hash] = Bid(
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice,
      INIT_CLEARING_PRICE,
      uint8(INIT_AUCTION_STATUS),
      uint8(INIT_BID_STATE),
      INIT_ALLOCATION_FEE
    );

    emit BidCreated(
      hash,
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice,
      now // solhint-disable-line not-rely-on-time
    );
  }

  function _setAllocationFee(bytes32 hash, uint256 fee) internal {
    registry[hash].allocationFee = fee;
  }

  function _setAuctionStatus(bytes32 hash, uint8 _auctionStatus) internal {
    registry[hash].auctionStatus = _auctionStatus;
    emit BidAuctionStatusChange(hash, _auctionStatus, now); // solhint-disable-line
  }

  function _setBidState(bytes32 hash, uint8 _bidState) internal {
    registry[hash].bidState = _bidState;
    emit BidStateChange(hash, _bidState, now); // solhint-disable-line
  }

  function _setClearingPrice(bytes32 hash, uint256 _clearingPrice) internal {
    registry[hash].clearingPrice = _clearingPrice;
    emit BidClearingPriceChange(hash, _clearingPrice, now); // solhint-disable-line
  }
}

contract IOCPTokenReceiver is ContractReceiver {
  modifier onlyOcpToken() {
    require(msg.sender == ocpTokenContract());
    _;
  }

  function ocpTokenContract() public view returns(address);
  function setOCPTokenContract(address ocpToken) public;

  // solhint-disable-next-line
  function tokenFallback(address, uint256, bytes) public onlyOcpToken {}
}

contract BlindBidRegistry is BidRegistry, IBlindBidRegistry {
  address public constant BLIND_BIDDER = 0;
  address public constant BLIND_SCHEMA = 0;
  address public constant BLIND_LICENSE = 0;
  uint256 public constant BLIND_DURATION = 0;
  uint256 public constant BLIND_PRICE = 0;

  function createBid(bytes32 hash, uint256 _auction) public {
    _createBid(hash, msg.sender, _auction);
  }

  function revealBid(
    bytes32 hash,
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public {
    _revealBid(
      hash,
      msg.sender,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice
    );
  }

  function _createBid(bytes32 hash, address _creator, uint256 _auction) internal {
    registry[hash] = Bid(
      _creator,
      _auction,
      BLIND_BIDDER,
      BLIND_SCHEMA,
      BLIND_LICENSE,
      BLIND_DURATION,
      BLIND_PRICE,
      INIT_CLEARING_PRICE,
      uint8(INIT_AUCTION_STATUS),
      uint8(INIT_BID_STATE),
      INIT_ALLOCATION_FEE
    );

    emit BlindBidCreated(
      hash,
      _creator,
      _auction,
      now // solhint-disable-line not-rely-on-time
    );
  }

  function _revealBid(
    bytes32 hash,
    address _creator,
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint256 _durationSec,
    uint256 _bidPrice
  ) internal {
    require(!verifyStoredData(hash));
    require(registry[hash].creator == _creator);
    require(registry[hash].auction == _auction);

    bytes32 revealedHash = hashBid(
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice
    );
    require(revealedHash == hash);

    registry[hash] = Bid(
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice,
      INIT_CLEARING_PRICE,
      uint8(INIT_AUCTION_STATUS),
      bidState(hash),
      INIT_ALLOCATION_FEE
    );

    emit BlindBidRevealed(
      hash,
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice,
      now // solhint-disable-line not-rely-on-time
    );
  }
}

contract Proxiable is ProxyManagerRole {
  mapping(address => bool) private _globalProxies; // proxy -> valid
  mapping(address => mapping(address => bool)) private _senderProxies; // sender -> proxy -> valid

  event ProxyAdded(address indexed proxy, uint256 updatedAt);
  event ProxyRemoved(address indexed proxy, uint256 updatedAt);
  event ProxyForSenderAdded(address indexed proxy, address indexed sender, uint256 updatedAt);
  event ProxyForSenderRemoved(address indexed proxy, address indexed sender, uint256 updatedAt);

  modifier proxyOrSender(address claimedSender) {
    require(isProxyOrSender(claimedSender));
    _;
  }

  function isProxyOrSender(address claimedSender) public view returns (bool) {
    return msg.sender == claimedSender ||
    _globalProxies[msg.sender] ||
    _senderProxies[claimedSender][msg.sender];
  }

  function isProxy(address proxy) public view returns (bool) {
    return _globalProxies[proxy];
  }

  function isProxyForSender(address proxy, address sender) public view returns (bool) {
    return _senderProxies[sender][proxy];
  }

  function addProxy(address proxy) public onlyProxyManager {
    require(!_globalProxies[proxy]);
    _globalProxies[proxy] = true;
    emit ProxyAdded(proxy, now); // solhint-disable-line
  }

  function removeProxy(address proxy) public onlyProxyManager {
    require(_globalProxies[proxy]);
    delete _globalProxies[proxy];
    emit ProxyRemoved(proxy, now); // solhint-disable-line
  }

  function addProxyForSender(address proxy, address sender) public proxyOrSender(sender) {
    require(!_senderProxies[sender][proxy]);
    _senderProxies[sender][proxy] = true;
    emit ProxyForSenderAdded(proxy, sender, now); // solhint-disable-line
  }

  function removeProxyForSender(address proxy, address sender) public proxyOrSender(sender) {
    require(_senderProxies[sender][proxy]);
    delete _senderProxies[sender][proxy];
    emit ProxyForSenderRemoved(proxy, sender, now); // solhint-disable-line
  }
}

contract IAuctionHouse is IOCPTokenReceiver {
  event AuctionHouseCreated(uint256 updatedAt);
  
  function currentAuctionId() public view returns(uint256);
  function biddingComponent() public view returns(address);
  function clearingPriceComponent() public view returns(address);

  function setCurrentAuctionId(uint256 auctionId) public;
  function setBiddingComponent(address component) public;
  function setClearingPriceComponent(address component) public;

  function setOCPTokenContract(address ocpTokenContract) public;
  function setBidRegistry(address bidRegistry) public;
  function setLicenseNFT(address licenseNFTContract) public;

  function setClearingPriceSubmissionDeposit(uint256 deposit) public;
  function setPercentAllocationFee(uint256 numerator, uint256 denominator) public;

  function payBid(address from, uint256 value, bytes data) public;
  function payDeposit(address submitter, uint256 value, bytes data) public;
  function allocateBid(address anyValidPriceClearingSubmitter, bytes32 bidHash) public;
  function claimReward(uint256 auctionId, address clearingPriceSubmitter) public;

  // solhint-disable-next-line
  function tokenFallback(address, uint256, bytes) public onlyOcpToken {
    revert();
  }
}

contract OCPTokenReceiver is Secondary, IOCPTokenReceiver {
  address private _ocpTokenContract;

  function ocpTokenContract() public view returns(address) {
    return _ocpTokenContract;
  }

  function setOCPTokenContract(address ocpToken) public onlyPrimary {
    _setOCPTokenContract(ocpToken);
  }

  function _setOCPTokenContract(address ocpToken) internal {
    _ocpTokenContract = ocpToken;
  }
}

contract BlindBidRegistryProxiable is BlindBidRegistry, Proxiable {
  function createBid(bytes32 hash, address _creator, uint256 _auction) public proxyOrSender(_creator) {
    super._createBid(hash, _creator, _auction);
  }

  function revealBid(
    bytes32 hash,
    address _creator,
    uint256 _auction,
    address _bidder,
    address _schema,
    address _license,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public proxyOrSender(_creator) {
    super._revealBid(
      hash,
      _creator,
      _auction,
      _bidder,
      _schema,
      _license,
      _durationSec,
      _bidPrice
    );
  }
}

contract AuctionHouseBidRegistry is BlindBidRegistryProxiable {
  constructor(address auctionBiddingComponent) public {
    transferPrimary(auctionBiddingComponent);
  }
}

contract AuctionHouse is AuctionManagerRole, IAuctionHouse, IAuctionHouseStateTransition, OCPTokenReceiver {
  AuctionHouseBidRegistry private _bidRegistry;
  IAuctionHouseBiddingComponent private _biddingComponent;
  IAuctionHouseClearingPriceComponent private _clearingPriceComponent;

  uint256 private _currentAuctionId;
  mapping(uint256 => AuctionState) private _state;

  constructor() public {
    setCurrentAuctionId(1);
    emit AuctionHouseCreated(now); // solhint-disable-line not-rely-on-time
  }

  function currentAuctionId() public view returns(uint256) {
    return _currentAuctionId;
  }

  function biddingComponent() public view returns(address) {
    return address(_biddingComponent);
  }

  function clearingPriceComponent() public view returns(address) {
    return address(_clearingPriceComponent);
  }

  function setCurrentAuctionId(uint256 auctionId) public onlyAuctionManager {
    _currentAuctionId = auctionId;
    if (_state[auctionId] == AuctionState.Undetermined) {
      transition(_currentAuctionId, AuctionState.AuctionCreated);
    }
  }

  function setBiddingComponent(address component) public onlyAuctionManager {
    _biddingComponent = IAuctionHouseBiddingComponent(component);
  }

  function setClearingPriceComponent(address component) public onlyAuctionManager {
    _clearingPriceComponent = IAuctionHouseClearingPriceComponent(component);
  }

  function setOCPTokenContract(address ocpToken) public onlyAuctionManager {
    _setOCPTokenContract(ocpToken);
  }

  function setBidRegistry(address bidRegistry) public onlyAuctionManager {
    _bidRegistry = AuctionHouseBidRegistry(bidRegistry);
    _biddingComponent.setBidRegistry(bidRegistry);
    _clearingPriceComponent.setBidRegistry(bidRegistry);
  }

  function setLicenseNFT(address licenseNFTContract) public onlyAuctionManager {
    _biddingComponent.setLicenseNFT(licenseNFTContract);
  }

  function setClearingPriceSubmissionDeposit(uint256 deposit) public onlyAuctionManager {
    _clearingPriceComponent.setSubmissionDeposit(deposit);
  }

  function setPercentAllocationFee(uint256 numerator, uint256 denominator) public onlyAuctionManager {
    _clearingPriceComponent.setPercentAllocationFee(numerator, denominator);
  }

  function payBid(address, uint256 value, bytes data) public onlyOcpToken {
    require(data.length == 32);
    bytes32 bidHash;
    assembly { // solhint-disable-line
      bidHash := mload(add(data, 32))
    }
    _biddingComponent.payBid(bidHash, value);
  }

  function payDeposit(address submitter, uint256 value, bytes data) public onlyOcpToken {
    require(data.length == 32);
    uint256 auctionId;
    assembly { // solhint-disable-line
      auctionId := mload(add(data, 32))
    }
    _clearingPriceComponent.payDeposit(auctionId, submitter, value);
  }

  function allocateBid(address anyValidPriceClearingSubmitter, bytes32 bidHash) public {
    uint256 auctionId = _bidRegistry.auction(bidHash);
    require(_state[auctionId] == AuctionState.BidAllocationOpen);
    require(_clearingPriceComponent.isValidSubmitter(anyValidPriceClearingSubmitter, bidHash));

    if (_clearingPriceComponent.hasClearingPrice(anyValidPriceClearingSubmitter, bidHash)) {
      uint256 clearingPrice = _clearingPriceComponent.clearingPrice(
        anyValidPriceClearingSubmitter,
        bidHash
      );
      _biddingComponent.allocateBid(bidHash, clearingPrice);
    } else {
      _biddingComponent.doNotAllocateBid(bidHash);
    }

    _payBidAllocationFee(bidHash);
    _payRefund(bidHash);

    _biddingComponent.issueLicenseNFT(bidHash);
  }

  function claimReward(uint256 auctionId, address clearingPriceSubmitter) public {
    uint reward = _clearingPriceComponent.calcReward(auctionId, clearingPriceSubmitter);
    _clearingPriceComponent.payReward(auctionId, clearingPriceSubmitter, reward);

    ERC223 oct = ERC223(ocpTokenContract());
    oct.transfer(clearingPriceSubmitter, reward);
  }

  function auctionState(uint256 auctionId) public view returns(AuctionState) {
    return _state[auctionId];
  }

  function transition(uint256 auctionId, AuctionState state) public onlyAuctionManager {
    require(_state[auctionId] != state);
    _state[auctionId] = state;

    _transitionBiddingComponent(auctionId, state);
    _transitionClearingPriceComponent(auctionId, state);

    emit AuctionStateChange(auctionId, state, now); // solhint-disable-line not-rely-on-time
  }

  function _payBidAllocationFee(bytes32 bidHash) internal {
    uint256 fee = _clearingPriceComponent.calcBidAllocationFee(bidHash);
    _biddingComponent.payBidAllocationFee(bidHash, fee);
    _clearingPriceComponent.payBidAllocationFee(bidHash, fee);
  }

  function _payRefund(bytes32 bidHash) internal {
    uint256 refund = _biddingComponent.calcRefund(bidHash);
    _biddingComponent.payRefund(bidHash, refund);

    address bidder = _bidRegistry.bidder(bidHash);
    ERC223 oct = ERC223(ocpTokenContract());
    oct.transfer(bidder, refund);
  }

  function _transitionBiddingComponent(uint256 auctionId, AuctionState state) internal {
    if (state == AuctionState.BiddingSubmissionOpen) {
      _biddingComponent.setSubmissionOpen(auctionId);
    } else if (state == AuctionState.BiddingSubmissionClosed) {
      _biddingComponent.setSubmissionClosed(auctionId);
    } else if (state == AuctionState.BiddingRevealOpen) {
      _biddingComponent.setRevealOpen(auctionId);
    } else if (state == AuctionState.BiddingRevealClosed) {
      _biddingComponent.setRevealClosed(auctionId);
    } else if (state == AuctionState.BidAllocationOpen) {
      _biddingComponent.setAllocationOpen(auctionId);
    } else if (state == AuctionState.BidAllocationClosed) {
      _biddingComponent.setAllocationClosed(auctionId);
    }
  }

  function _transitionClearingPriceComponent(uint256 auctionId, AuctionState state) internal {
    if (state == AuctionState.ClearingPriceSubmissionOpen) {
      _clearingPriceComponent.setSubmissionOpen(auctionId);
    } else if (state == AuctionState.ClearingPriceSubmissionClosed) {
      _clearingPriceComponent.setSubmissionClosed(auctionId);
    } else if (state == AuctionState.ClearingPriceValidationOpen) {
      _clearingPriceComponent.setValidationOpen(auctionId);
    } else if (state == AuctionState.ClearingPriceValidationClosed) {
      _clearingPriceComponent.setValidationClosed(auctionId);
    } else if (state == AuctionState.RewardAllocationOpen) {
      _clearingPriceComponent.setRewardOpen(auctionId);
    } else if (state == AuctionState.RewardAllocationClosed) {
      _clearingPriceComponent.setRewardClosed(auctionId);
    }
  }
}