pragma solidity ^0.4.22;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;


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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner());
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
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

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
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

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) public view returns (string);
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
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

/**
 * Utility library of inline functions on addresses
 */
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

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
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

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}


/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5d3c2f3c3e353334391d33322939322973333829">[email&#160;protected]</a>>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a &#39;slice&#39;. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first &#39;.&#39;,
 *      modifying s to only contain the remainder of the string after the &#39;.&#39;.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew(&#39;.&#39;)` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice&#39;s text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = uint256(-1); // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

contract CarFactory is Ownable {
    using strings for *;

    uint256 public constant MAX_CARS = 30000 + 150000 + 1000000;
    uint256 public mintedCars = 0;
    address preOrderAddress;
    CarToken token;

    mapping(uint256 => uint256) public tankSizes;
    mapping(uint256 => uint) public savedTypes;
    mapping(uint256 => bool) public giveawayCar;
    
    mapping(uint => uint256[]) public availableIds;
    mapping(uint => uint256) public idCursor;

    event CarMinted(uint256 _tokenId, string _metadata, uint cType);
    event CarSellingBeings();



    modifier onlyPreOrder {
        require(msg.sender == preOrderAddress, "Not authorized");
        _;
    }

    modifier isInitialized {
        require(preOrderAddress != address(0), "No linked preorder");
        require(address(token) != address(0), "No linked token");
        _;
    }

    function uintToString(uint v) internal pure returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s);  // memory isn&#39;t implicitly convertible to storage
        return str; // this was missing
    }

    function mintFor(uint cType, address newOwner) public onlyPreOrder isInitialized returns (uint256) {
        require(mintedCars < MAX_CARS, "Factory has minted the max number of cars");
        
        uint256 _tokenId = nextAvailableId(cType);
        require(!token.exists(_tokenId), "Token already exists");

        string memory id = uintToString(_tokenId).toSlice().concat(".json".toSlice());

        uint256 tankSize = tankSizes[_tokenId];
        string memory _metadata = "https://vault.warriders.com/".toSlice().concat(id.toSlice());

        token.mint(_tokenId, _metadata, cType, tankSize, newOwner);
        mintedCars++;
        
        return _tokenId;
    }

    function giveaway(uint256 _tokenId, uint256 _tankSize, uint cType, bool markCar, address dst) public onlyOwner isInitialized {
        require(dst != address(0), "No destination address given");
        require(!token.exists(_tokenId), "Token already exists");
        require(dst != owner());
        require(dst != address(this));
        require(_tankSize <= token.maxTankSizes(cType));
            
        tankSizes[_tokenId] = _tankSize;
        savedTypes[_tokenId] = cType;

        string memory id = uintToString(_tokenId).toSlice().concat(".json".toSlice());
        string memory _metadata = "https://vault.warriders.com/".toSlice().concat(id.toSlice());

        token.mint(_tokenId, _metadata, cType, _tankSize, dst);
        mintedCars++;

        giveawayCar[_tokenId] = markCar;
    }

    function setTokenMeta(uint256[] _tokenIds, uint256[] ts, uint[] cTypes) public onlyOwner isInitialized {
        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint cType = cTypes[i];
            uint256 _tankSize = ts[i];

            require(_tankSize <= token.maxTankSizes(cType));
            
            tankSizes[_tokenId] = _tankSize;
            savedTypes[_tokenId] = cType;
            
            
            availableIds[cTypes[i]].push(_tokenId);
        }
    }
    
    function nextAvailableId(uint cType) private returns (uint256) {
        uint256 currentCursor = idCursor[cType];
        
        require(currentCursor < availableIds[cType].length);
        
        uint256 nextId = availableIds[cType][currentCursor];
        idCursor[cType] = currentCursor + 1;
        return nextId;
    }

    /**
    Attach the preOrder that will be receiving tokens being marked for sale by the
    sellCar function
    */
    function attachPreOrder(address dst) public onlyOwner {
        require(preOrderAddress == address(0));
        require(dst != address(0));

        //Enforce that address is indeed a preorder
        PreOrder preOrder = PreOrder(dst);

        preOrderAddress = address(preOrder);
    }

    /**
    Attach the token being used for things
    */
    function attachToken(address dst) public onlyOwner {
        require(address(token) == address(0));
        require(dst != address(0));

        //Enforce that address is indeed a preorder
        CarToken ct = CarToken(dst);

        token = ct;
    }
}

contract CarToken is ERC721Full, Ownable {
    using strings for *;
    
    address factory;

    /*
    * Car Types:
    * 0 - Unknown
    * 1 - SUV
    * 2 - Truck
    * 3 - Hovercraft
    * 4 - Tank
    * 5 - Lambo
    * 6 - Buggy
    * 7 - midgrade type 2
    * 8 - midgrade type 3
    * 9 - Hatchback
    * 10 - regular type 2
    * 11 - regular type 3
    */
    uint public constant UNKNOWN_TYPE = 0;
    uint public constant SUV_TYPE = 1;
    uint public constant TANKER_TYPE = 2;
    uint public constant HOVERCRAFT_TYPE = 3;
    uint public constant TANK_TYPE = 4;
    uint public constant LAMBO_TYPE = 5;
    uint public constant DUNE_BUGGY = 6;
    uint public constant MIDGRADE_TYPE2 = 7;
    uint public constant MIDGRADE_TYPE3 = 8;
    uint public constant HATCHBACK = 9;
    uint public constant REGULAR_TYPE2 = 10;
    uint public constant REGULAR_TYPE3 = 11;
    
    string public constant METADATA_URL = "https://vault.warriders.com/";
    
    //Number of premium type cars
    uint public PREMIUM_TYPE_COUNT = 5;
    //Number of midgrade type cars
    uint public MIDGRADE_TYPE_COUNT = 3;
    //Number of regular type cars
    uint public REGULAR_TYPE_COUNT = 3;

    mapping(uint256 => uint256) public maxBznTankSizeOfPremiumCarWithIndex;
    mapping(uint256 => uint256) public maxBznTankSizeOfMidGradeCarWithIndex;
    mapping(uint256 => uint256) public maxBznTankSizeOfRegularCarWithIndex;

    /**
     * Whether any given car (tokenId) is special
     */
    mapping(uint256 => bool) public isSpecial;
    /**
     * The type of any given car (tokenId)
     */
    mapping(uint256 => uint) public carType;
    /**
     * The total supply for any given type (int)
     */
    mapping(uint => uint256) public carTypeTotalSupply;
    /**
     * The current supply for any given type (int)
     */
    mapping(uint => uint256) public carTypeSupply;
    /**
     * Whether any given type (int) is special
     */
    mapping(uint => bool) public isTypeSpecial;

    /**
    * How much BZN any given car (tokenId) can hold
    */
    mapping(uint256 => uint256) public tankSizes;
    
    /**
     * Given any car type (uint), get the max tank size for that type (uint256)
     */
    mapping(uint => uint256) public maxTankSizes;
    
    mapping (uint => uint[]) public premiumTotalSupplyForCar;
    mapping (uint => uint[]) public midGradeTotalSupplyForCar;
    mapping (uint => uint[]) public regularTotalSupplyForCar;

    modifier onlyFactory {
        require(msg.sender == factory, "Not authorized");
        _;
    }

    constructor(address factoryAddress) public ERC721Full("WarRiders", "WR") {
        factory = factoryAddress;

        carTypeTotalSupply[UNKNOWN_TYPE] = 0; //Unknown
        carTypeTotalSupply[SUV_TYPE] = 20000; //SUV
        carTypeTotalSupply[TANKER_TYPE] = 9000; //Tanker
        carTypeTotalSupply[HOVERCRAFT_TYPE] = 600; //Hovercraft
        carTypeTotalSupply[TANK_TYPE] = 300; //Tank
        carTypeTotalSupply[LAMBO_TYPE] = 100; //Lambo
        carTypeTotalSupply[DUNE_BUGGY] = 40000; //migrade type 1
        carTypeTotalSupply[MIDGRADE_TYPE2] = 50000; //midgrade type 2
        carTypeTotalSupply[MIDGRADE_TYPE3] = 60000; //midgrade type 3
        carTypeTotalSupply[HATCHBACK] = 200000; //regular type 1
        carTypeTotalSupply[REGULAR_TYPE2] = 300000; //regular type 2
        carTypeTotalSupply[REGULAR_TYPE3] = 500000; //regular type 3
        
        maxTankSizes[SUV_TYPE] = 200; //SUV tank size
        maxTankSizes[TANKER_TYPE] = 450; //Tanker tank size
        maxTankSizes[HOVERCRAFT_TYPE] = 300; //Hovercraft tank size
        maxTankSizes[TANK_TYPE] = 200; //Tank tank size
        maxTankSizes[LAMBO_TYPE] = 250; //Lambo tank size
        maxTankSizes[DUNE_BUGGY] = 120; //migrade type 1 tank size
        maxTankSizes[MIDGRADE_TYPE2] = 110; //midgrade type 2 tank size
        maxTankSizes[MIDGRADE_TYPE3] = 100; //midgrade type 3 tank size
        maxTankSizes[HATCHBACK] = 90; //regular type 1 tank size
        maxTankSizes[REGULAR_TYPE2] = 70; //regular type 2 tank size
        maxTankSizes[REGULAR_TYPE3] = 40; //regular type 3 tank size
        
        maxBznTankSizeOfPremiumCarWithIndex[1] = 200; //SUV tank size
        maxBznTankSizeOfPremiumCarWithIndex[2] = 450; //Tanker tank size
        maxBznTankSizeOfPremiumCarWithIndex[3] = 300; //Hovercraft tank size
        maxBznTankSizeOfPremiumCarWithIndex[4] = 200; //Tank tank size
        maxBznTankSizeOfPremiumCarWithIndex[5] = 250; //Lambo tank size
        maxBznTankSizeOfMidGradeCarWithIndex[1] = 100; //migrade type 1 tank size
        maxBznTankSizeOfMidGradeCarWithIndex[2] = 110; //midgrade type 2 tank size
        maxBznTankSizeOfMidGradeCarWithIndex[3] = 120; //midgrade type 3 tank size
        maxBznTankSizeOfRegularCarWithIndex[1] = 40; //regular type 1 tank size
        maxBznTankSizeOfRegularCarWithIndex[2] = 70; //regular type 2 tank size
        maxBznTankSizeOfRegularCarWithIndex[3] = 90; //regular type 3 tank size

        isTypeSpecial[HOVERCRAFT_TYPE] = true;
        isTypeSpecial[TANK_TYPE] = true;
        isTypeSpecial[LAMBO_TYPE] = true;
    }

    function isCarSpecial(uint256 tokenId) public view returns (bool) {
        return isSpecial[tokenId];
    }

    function getCarType(uint256 tokenId) public view returns (uint) {
        return carType[tokenId];
    }

    function mint(uint256 _tokenId, string _metadata, uint cType, uint256 tankSize, address newOwner) public onlyFactory {
        //Since any invalid car type would have a total supply of 0 
        //This require will also enforce that a valid cType is given
        require(carTypeSupply[cType] < carTypeTotalSupply[cType], "This type has reached total supply");
        
        //This will enforce the tank size is less than the max
        require(tankSize <= maxTankSizes[cType], "Tank size provided bigger than max for this type");
        
        if (isPremium(cType)) {
            premiumTotalSupplyForCar[cType].push(_tokenId);
        } else if (isMidGrade(cType)) {
            midGradeTotalSupplyForCar[cType].push(_tokenId);
        } else {
            regularTotalSupplyForCar[cType].push(_tokenId);
        }

        super._mint(newOwner, _tokenId);
        super._setTokenURI(_tokenId, _metadata);

        carType[_tokenId] = cType;
        isSpecial[_tokenId] = isTypeSpecial[cType];
        carTypeSupply[cType] = carTypeSupply[cType] + 1;
        tankSizes[_tokenId] = tankSize;
    }
    
    function isPremium(uint cType) public pure returns (bool) {
        return cType == SUV_TYPE || cType == TANKER_TYPE || cType == HOVERCRAFT_TYPE || cType == TANK_TYPE || cType == LAMBO_TYPE;
    }
    
    function isMidGrade(uint cType) public pure returns (bool) {
        return cType == DUNE_BUGGY || cType == MIDGRADE_TYPE2 || cType == MIDGRADE_TYPE3;
    }
    
    function isRegular(uint cType) public pure returns (bool) {
        return cType == HATCHBACK || cType == REGULAR_TYPE2 || cType == REGULAR_TYPE3;
    }
    
    function getTotalSupplyForType(uint cType) public view returns (uint256) {
        return carTypeSupply[cType];
    }
    
    function getPremiumCarsForVariant(uint variant) public view returns (uint[]) {
        return premiumTotalSupplyForCar[variant];
    }
    
    function getMidgradeCarsForVariant(uint variant) public view returns (uint[]) {
        return midGradeTotalSupplyForCar[variant];
    }

    function getRegularCarsForVariant(uint variant) public view returns (uint[]) {
        return regularTotalSupplyForCar[variant];
    }

    function getPremiumCarSupply(uint variant) public view returns (uint) {
        return premiumTotalSupplyForCar[variant].length;
    }
    
    function getMidgradeCarSupply(uint variant) public view returns (uint) {
        return midGradeTotalSupplyForCar[variant].length;
    }

    function getRegularCarSupply(uint variant) public view returns (uint) {
        return regularTotalSupplyForCar[variant].length;
    }
    
    function exists(uint256 _tokenId) public view returns (bool) {
        return super._exists(_tokenId);
    }
}

contract PreOrder is Destructible {
    /**
     * The current price for any given type (int)
     */
    mapping(uint => uint256) public currentTypePrice;

    // Maps Premium car variants to the tokens minted for their description
    // INPUT: variant #
    // OUTPUT: list of cars
    mapping(uint => uint256[]) public premiumCarsBought;
    mapping(uint => uint256[]) public midGradeCarsBought;
    mapping(uint => uint256[]) public regularCarsBought;
    mapping(uint256 => address) public tokenReserve;

    event consumerBulkBuy(uint256[] variants, address reserver, uint category);
    event CarBought(uint256 carId, uint256 value, address purchaser, uint category);
    event Withdrawal(uint256 amount);

    uint256 public constant COMMISSION_PERCENT = 5;

    //Max number of premium cars
    uint256 public constant MAX_PREMIUM = 30000;
    //Max number of midgrade cars
    uint256 public constant MAX_MIDGRADE = 150000;
    //Max number of regular cars
    uint256 public constant MAX_REGULAR = 1000000;

    //Max number of premium type cars
    uint public PREMIUM_TYPE_COUNT = 5;
    //Max number of midgrade type cars
    uint public MIDGRADE_TYPE_COUNT = 3;
    //Max number of regular type cars
    uint public REGULAR_TYPE_COUNT = 3;

    uint private midgrade_offset = 5;
    uint private regular_offset = 6;

    uint256 public constant GAS_REQUIREMENT = 250000;

    //Premium type id
    uint public constant PREMIUM_CATEGORY = 1;
    //Midgrade type id
    uint public constant MID_GRADE_CATEGORY = 2;
    //Regular type id
    uint public constant REGULAR_CATEGORY = 3;
    
    mapping(address => uint256) internal commissionRate;
    
    address internal constant OPENSEA = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

    //The percent increase for any given type
    mapping(uint => uint256) internal percentIncrease;
    mapping(uint => uint256) internal percentBase;
    //uint public constant PERCENT_INCREASE = 101;

    //How many car is in each category currently
    uint256 public premiumHold = 30000;
    uint256 public midGradeHold = 150000;
    uint256 public regularHold = 1000000;

    bool public premiumOpen = false;
    bool public midgradeOpen = false;
    bool public regularOpen = false;

    //Reference to other contracts
    CarToken public token;
    //AuctionManager public auctionManager;
    CarFactory internal factory;

    address internal escrow;

    modifier premiumIsOpen {
        //Ensure we are selling at least 1 car
        require(premiumHold > 0, "No more premium cars");
        require(premiumOpen, "Premium store not open for sale");
        _;
    }

    modifier midGradeIsOpen {
        //Ensure we are selling at least 1 car
        require(midGradeHold > 0, "No more midgrade cars");
        require(midgradeOpen, "Midgrade store not open for sale");
        _;
    }

    modifier regularIsOpen {
        //Ensure we are selling at least 1 car
        require(regularHold > 0, "No more regular cars");
        require(regularOpen, "Regular store not open for sale");
        _;
    }

    modifier onlyFactory {
        //Only factory can use this function
        require(msg.sender == address(factory), "Not authorized");
        _;
    }

    modifier onlyFactoryOrOwner {
        //Only factory or owner can use this function
        require(msg.sender == address(factory) || msg.sender == owner(), "Not authorized");
        _;
    }

    function() public payable { }

    constructor(
        address tokenAddress,
        address tokenFactory,
        address e
    ) public {
        token = CarToken(tokenAddress);

        //auctionManager = new AuctionManager(tokenAddress);

        factory = CarFactory(tokenFactory);

        escrow = e;

        //Set percent increases
        percentIncrease[1] = 100008;
        percentBase[1] = 100000;
        percentIncrease[2] = 100015;
        percentBase[2] = 100000;
        percentIncrease[3] = 1002;
        percentBase[3] = 1000;
        percentIncrease[4] = 1004;
        percentBase[4] = 1000;
        percentIncrease[5] = 102;
        percentBase[5] = 100;
        
        commissionRate[OPENSEA] = 10;
    }
    
    function setCommission(address referral, uint256 percent) public onlyOwner {
        require(percent > COMMISSION_PERCENT);
        require(percent < 95);
        percent = percent - COMMISSION_PERCENT;
        
        commissionRate[referral] = percent;
    }
    
    function setPercentIncrease(uint256 increase, uint256 base, uint cType) public onlyOwner {
        require(increase > base);
        
        percentIncrease[cType] = increase;
        percentBase[cType] = base;
    }

    function openShop(uint category) public onlyOwner {
        require(category == 1 || category == 2 || category == 3, "Invalid category");

        if (category == PREMIUM_CATEGORY) {
            premiumOpen = true;
        } else if (category == MID_GRADE_CATEGORY) {
            midgradeOpen = true;
        } else if (category == REGULAR_CATEGORY) {
            regularOpen = true;
        }
    }

    /**
     * Set the starting price for any given type. Can only be set once, and value must be greater than 0
     */
    function setTypePrice(uint cType, uint256 price) public onlyOwner {
        if (currentTypePrice[cType] == 0) {
            require(price > 0, "Price already set");
            currentTypePrice[cType] = price;
        }
    }

    /**
    Withdraw the amount from the contract&#39;s balance. Only the contract owner can execute this function
    */
    function withdraw(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;

        require(amount <= balance, "Requested to much");
        owner().transfer(amount);

        emit Withdrawal(amount);
    }

    function reserveManyTokens(uint[] cTypes, uint category) public payable returns (bool) {
        if (category == PREMIUM_CATEGORY) {
            require(premiumOpen, "Premium is not open for sale");
        } else if (category == MID_GRADE_CATEGORY) {
            require(midgradeOpen, "Midgrade is not open for sale");
        } else if (category == REGULAR_CATEGORY) {
            require(regularOpen, "Regular is not open for sale");
        } else {
            revert();
        }

        address reserver = msg.sender;

        uint256 ether_required = 0;
        for (uint i = 0; i < cTypes.length; i++) {
            uint cType = cTypes[i];

            uint256 price = priceFor(cType);

            ether_required += (price + GAS_REQUIREMENT);

            currentTypePrice[cType] = price;
        }

        require(msg.value >= ether_required);

        uint256 refundable = msg.value - ether_required;

        escrow.transfer(ether_required);

        if (refundable > 0) {
            reserver.transfer(refundable);
        }

        emit consumerBulkBuy(cTypes, reserver, category);
    }

     function buyBulkPremiumCar(address referal, uint[] variants, address new_owner) public payable premiumIsOpen returns (bool) {
         uint n = variants.length;
         require(n <= 10, "Max bulk buy is 10 cars");

         for (uint i = 0; i < n; i++) {
             buyCar(referal, variants[i], false, new_owner, PREMIUM_CATEGORY);
         }
     }

     function buyBulkMidGradeCar(address referal, uint[] variants, address new_owner) public payable midGradeIsOpen returns (bool) {
         uint n = variants.length;
         require(n <= 10, "Max bulk buy is 10 cars");

         for (uint i = 0; i < n; i++) {
             buyCar(referal, variants[i], false, new_owner, MID_GRADE_CATEGORY);
         }
     }

     function buyBulkRegularCar(address referal, uint[] variants, address new_owner) public payable regularIsOpen returns (bool) {
         uint n = variants.length;
         require(n <= 10, "Max bulk buy is 10 cars");

         for (uint i = 0; i < n; i++) {
             buyCar(referal, variants[i], false, new_owner, REGULAR_CATEGORY);
         }
     }

    function buyCar(address referal, uint cType, bool give_refund, address new_owner, uint category) public payable returns (bool) {
        require(category == PREMIUM_CATEGORY || category == MID_GRADE_CATEGORY || category == REGULAR_CATEGORY);
        if (category == PREMIUM_CATEGORY) {
            require(cType == 1 || cType == 2 || cType == 3 || cType == 4 || cType == 5, "Invalid car type");
            require(premiumHold > 0, "No more premium cars");
            require(premiumOpen, "Premium store not open for sale");
        } else if (category == MID_GRADE_CATEGORY) {
            require(cType == 6 || cType == 7 || cType == 8, "Invalid car type");
            require(midGradeHold > 0, "No more midgrade cars");
            require(midgradeOpen, "Midgrade store not open for sale");
        } else if (category == REGULAR_CATEGORY) {
            require(cType == 9 || cType == 10 || cType == 11, "Invalid car type");
            require(regularHold > 0, "No more regular cars");
            require(regularOpen, "Regular store not open for sale");
        }

        uint256 price = priceFor(cType);
        require(price > 0, "Price not yet set");
        require(msg.value >= price, "Not enough ether sent");
        /*if (tokenReserve[_tokenId] != address(0)) {
            require(new_owner == tokenReserve[_tokenId], "You don&#39;t have the rights to buy this token");
        }*/
        currentTypePrice[cType] = price; //Set new type price

        uint256 _tokenId = factory.mintFor(cType, new_owner); //Now mint the token
        
        if (category == PREMIUM_CATEGORY) {
            premiumCarsBought[cType].push(_tokenId);
            premiumHold--;
        } else if (category == MID_GRADE_CATEGORY) {
            midGradeCarsBought[cType - 5].push(_tokenId);
            midGradeHold--;
        } else if (category == REGULAR_CATEGORY) {
            regularCarsBought[cType - 8].push(_tokenId);
            regularHold--;
        }

        if (give_refund && msg.value > price) {
            uint256 change = msg.value - price;

            msg.sender.transfer(change);
        }

        if (referal != address(0)) {
            require(referal != msg.sender, "The referal cannot be the sender");
            require(referal != tx.origin, "The referal cannot be the tranaction origin");
            require(referal != new_owner, "The referal cannot be the new owner");

            //The commissionRate map adds any partner bonuses, or 0 if a normal user referral
            uint256 totalCommision = COMMISSION_PERCENT + commissionRate[referal];

            uint256 commision = (price * totalCommision) / 100;

            referal.transfer(commision);
        }

        emit CarBought(_tokenId, price, new_owner, category);
    }

    /**
    Get the price for any car with the given _tokenId
    */
    function priceFor(uint cType) public view returns (uint256) {
        uint256 percent = percentIncrease[cType];
        uint256 base = percentBase[cType];

        uint256 currentPrice = currentTypePrice[cType];
        uint256 nextPrice = (currentPrice * percent);

        //Return the next price, as this is the true price
        return nextPrice / base;
    }

    function sold(uint256 _tokenId) public view returns (bool) {
        return token.exists(_tokenId);
    }
}

contract BatchPreOrder is Destructible {
    /**
     * The current price for any given type (int)
     */
    mapping(uint => uint256) public currentTypePrice;

    // Maps Premium car variants to the tokens minted for their description
    // INPUT: variant #
    // OUTPUT: list of cars
    mapping(uint => uint256[]) public premiumCarsBought;
    mapping(uint => uint256[]) public midGradeCarsBought;
    mapping(uint => uint256[]) public regularCarsBought;
    mapping(uint256 => address) public tokenReserve;

    event consumerBulkBuy(uint256[] variants, address reserver, uint category, address referral);
    event CarBought(uint256 carId, uint256 value, address purchaser, uint category);
    event Withdrawal(uint256 amount);

    uint256 public constant COMMISSION_PERCENT = 5;

    //Max number of premium cars
    uint256 public constant MAX_PREMIUM = 30000;
    //Max number of midgrade cars
    uint256 public constant MAX_MIDGRADE = 150000;
    //Max number of regular cars
    uint256 public constant MAX_REGULAR = 1000000;

    //Max number of premium type cars
    uint public PREMIUM_TYPE_COUNT = 5;
    //Max number of midgrade type cars
    uint public MIDGRADE_TYPE_COUNT = 3;
    //Max number of regular type cars
    uint public REGULAR_TYPE_COUNT = 3;

    uint private midgrade_offset = 5;
    uint private regular_offset = 6;

    uint256 public constant GAS_REQUIREMENT = 4500000;
    uint256 public constant BUFFER = 0.0001 ether;

    //Premium type id
    uint public constant PREMIUM_CATEGORY = 1;
    //Midgrade type id
    uint public constant MID_GRADE_CATEGORY = 2;
    //Regular type id
    uint public constant REGULAR_CATEGORY = 3;
    
    mapping(address => uint256) internal commissionRate;
    
    address internal constant OPENSEA = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

    //The percent increase for any given type
    mapping(uint => uint256) internal percentIncrease;
    mapping(uint => uint256) internal percentBase;
    //uint public constant PERCENT_INCREASE = 101;

    //How many car is in each category currently
    uint256 public premiumHold = 30000;
    uint256 public midGradeHold = 150000;
    uint256 public regularHold = 1000000;

    bool public premiumOpen = false;
    bool public midgradeOpen = false;
    bool public regularOpen = false;

    //Reference to other contracts
    CarToken public token;
    //AuctionManager public auctionManager;
    CarFactory internal factory;
    
    PreOrder internal og;

    address internal escrow;

    modifier premiumIsOpen {
        //Ensure we are selling at least 1 car
        require(premiumHold > 0, "No more premium cars");
        require(premiumOpen, "Premium store not open for sale");
        _;
    }

    modifier midGradeIsOpen {
        //Ensure we are selling at least 1 car
        require(midGradeHold > 0, "No more midgrade cars");
        require(midgradeOpen, "Midgrade store not open for sale");
        _;
    }

    modifier regularIsOpen {
        //Ensure we are selling at least 1 car
        require(regularHold > 0, "No more regular cars");
        require(regularOpen, "Regular store not open for sale");
        _;
    }

    modifier onlyFactory {
        //Only factory can use this function
        require(msg.sender == address(factory), "Not authorized");
        _;
    }

    modifier onlyFactoryOrOwner {
        //Only factory or owner can use this function
        require(msg.sender == address(factory) || msg.sender == owner(), "Not authorized");
        _;
    }

    function() public payable { }

    constructor(
        address tokenAddress,
        address tokenFactory,
        address e,
        address preorder
    ) public {
        token = CarToken(tokenAddress);

        //auctionManager = new AuctionManager(tokenAddress);

        factory = CarFactory(tokenFactory);

        escrow = e;
        
        og = PreOrder(preorder);

        //Set percent increases
        percentIncrease[1] = 100008;
        percentBase[1] = 100000;
        percentIncrease[2] = 100015;
        percentBase[2] = 100000;
        percentIncrease[3] = 1002;
        percentBase[3] = 1000;
        percentIncrease[4] = 1004;
        percentBase[4] = 1000;
        percentIncrease[5] = 1012;
        percentBase[5] = 1000;
        
        commissionRate[OPENSEA] = 10;
    }
    
    function setCommission(address referral, uint256 percent) public onlyOwner {
        revert(); //NOT IMPLEMENTED 
    }
    
    function setPercentIncrease(uint256 increase, uint256 base, uint cType) public onlyOwner {
        require(increase > base);
        
        percentIncrease[cType] = increase;
        percentBase[cType] = base;
    }

    function openShop(uint category) public onlyOwner {
        require(category == 1 || category == 2 || category == 3, "Invalid category");

        if (category == PREMIUM_CATEGORY) {
            premiumOpen = true;
        } else if (category == MID_GRADE_CATEGORY) {
            midgradeOpen = true;
        } else if (category == REGULAR_CATEGORY) {
            regularOpen = true;
        }
    }

    /**
     * Set the starting price for any given type. Can only be set once, and value must be greater than 0
     */
    function setTypePrice(uint cType, uint256 price) public onlyOwner {
        revert(); //NOT IMPLEMENTED 
    }

    /**
    Withdraw the amount from the contract&#39;s balance. Only the contract owner can execute this function
    */
    function withdraw(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;

        require(amount <= balance, "Requested to much");
        owner().transfer(amount);

        emit Withdrawal(amount);
    }

    function reserveManyTokens(uint[] cTypes, uint category, address referral) public payable returns (bool) {
        if (category == PREMIUM_CATEGORY) {
            require(premiumOpen, "Premium is not open for sale");
        } else if (category == MID_GRADE_CATEGORY) {
            require(midgradeOpen, "Midgrade is not open for sale");
        } else if (category == REGULAR_CATEGORY) {
            require(regularOpen, "Regular is not open for sale");
        } else {
            revert();
        }

        address reserver = msg.sender;

        uint256 ether_required = 0;
        
        //Reset all type prices to current price
        for (uint c = 1; c <= 11; c++) {
            currentTypePrice[c] = og.currentTypePrice(c);
        }
        
        for (uint i = 0; i < cTypes.length; i++) {
            uint cType = cTypes[i];

            uint256 price = currentTypePrice[cType];
            
            uint256 percent = percentIncrease[cType];
            uint256 base = percentBase[cType];
            
            uint256 nextPrice = (price * percent) / base;

            ether_required += (price + (GAS_REQUIREMENT * tx.gasprice) + BUFFER);

            currentTypePrice[cType] = nextPrice;
        }

        require(msg.value >= ether_required);

        uint256 refundable = msg.value - ether_required;

        escrow.transfer(ether_required);

        if (refundable > 0) {
            reserver.transfer(refundable);
        }

        emit consumerBulkBuy(cTypes, reserver, category, referral);
    }

     function buyBulkPremiumCar(address referal, uint[] variants, address new_owner) public payable premiumIsOpen returns (bool) {
         revert(); //NOT IMPLEMENTED 
     }

     function buyBulkMidGradeCar(address referal, uint[] variants, address new_owner) public payable midGradeIsOpen returns (bool) {
          revert(); //NOT IMPLEMENTED 
     }

     function buyBulkRegularCar(address referal, uint[] variants, address new_owner) public payable regularIsOpen returns (bool) {
          revert(); //NOT IMPLEMENTED 
     }

    function buyCar(address referal, uint cType, bool give_refund, address new_owner, uint category) public payable returns (bool) {
         revert(); //NOT IMPLEMENTED 
    }

    /**
    Get the price for any car with the given _tokenId
    */
    function priceFor(uint cType) public view returns (uint256) {
         revert(); //NOT IMPLEMENTED 
    }

    function sold(uint256 _tokenId) public view returns (bool) {
         revert(); //NOT IMPLEMENTED 
    }
}