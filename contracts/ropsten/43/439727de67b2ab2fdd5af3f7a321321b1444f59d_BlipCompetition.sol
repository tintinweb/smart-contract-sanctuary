/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

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
  )
    public;
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
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

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
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existance of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
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
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
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
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
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
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

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
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() public view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() public view returns (string) {
    return symbol_;
  }

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
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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

/**
 * @title BlipToken
 * @author Carlos Beltran <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c3aaaeb7aba2b7a0a2b1afacb083a4aea2aaafeda0acae">[email&#160;protected]</a>>
 *
 * @dev This contract implements the ERC721Token standard interface
 */
contract BlipToken is ERC721Token, Ownable {

  /**
   * The contract&#39;s constructor
   * @dev Calls the ERC721Token constructor
   *
   * @param _name   The name for the ERC721 token
   * @param _symbol The symbol for the ERC721 token
   */
  function BlipToken(string _name, string _symbol) ERC721Token(_name, _symbol) public {
  }

  /**
   * Public function to mint a new token
   * @dev Calls ERC721Token internal function _mint()
   *
   * @param _to      The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function mint(address _to, uint256 _tokenId) public {
    ERC721Token._mint(_to, _tokenId);
  }

  /**
   * Public function to burn a specific token
   *
   * @dev Calls ERC721Token internal function _burn()
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function burn(address _owner, uint256 _tokenId) public {
    ERC721Token._burn(_owner, _tokenId);
  }
}


/**
 * @title BlipCompetition
 * @author Carlos Beltran <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fb92968f939a8f989a89979488bb9c969a9297d5989496">[email&#160;protected]</a>>
 *
 * @dev This contract manages competition entries and the funds associated with them.
 * Authorized accounts can payout the winners or refund them if necessary.
 * This contract inherits from Pausable so that the contract owner can pause the contract,
 * prohibiting new entries from being submitted and paid out, while still being able to refund.
 */
contract BlipCompetition is Pausable {

  //============================================================================
  // EVENTS
  //============================================================================

  event EntrySubmitted(uint256 indexed competitionId, address indexed owner, bytes32 id);
  event InvalidActionOnCompetition(uint256 indexed competitionId, string action, address withAccount);
  event ErrorOnCompetition(uint256 indexed competitionId, string action, address withAccount);

  //============================================================================
  // STORAGE
  //============================================================================

  struct CompetitionEntry {
    uint256 competitionId;    // for reference
    address owner;            // to pay out or refund
    uint256 tokenId;          // for dispute
    uint256 value;            // for dispute - in WEI
    uint createdAt;           // for dispute
    uint competitionLockedAt; // to guard locked competitions
  }

  BlipToken public tokenContract;

  address public competitionAdmin;

  mapping (bytes32 => CompetitionEntry) competitionEntries;
  mapping (address => mapping (uint256 => bytes32)) accountActiveEntries; // address => competitionId => entryId
  mapping (uint256 => bytes32[]) competitionEntryIds; // competitionId => entryId

  //============================================================================
  // MODIFIERS
  //============================================================================

  modifier onlyAuthorized {
    require(msg.sender == owner || msg.sender == competitionAdmin);
    _;
  }

  modifier onlyEntryOwner(uint _competitionId) {
    require(_hasEntryForCompetition(msg.sender, _competitionId));
    _;
  }

  modifier onlyAuthorizedOrEntryOwner(bytes32 entryId) {
    require(
      msg.sender == owner
      || msg.sender == competitionAdmin
      || msg.sender == competitionEntries[entryId].owner
    );
    _;
  }

  //============================================================================
  // PUBLIC FUNCTIONS
  //============================================================================

  /**
   * The contract&#39;s constructor
   *
   * @param _tokenAddress The address of the BlipToken contract
   */
  function BlipCompetition(address _tokenAddress) public {
    setBlipTokenAddress(_tokenAddress);
  }

  /**
   * Sets the address for the BlipToken contract
   * @dev Only contract owner may set this
   *
   * @param _tokenAddress The address for the token
   */
  function setBlipTokenAddress(address _tokenAddress) public onlyOwner {
    require(_tokenAddress != address(0));
    tokenContract = BlipToken(_tokenAddress);
  }

  /**
   * Returns the address for the BlipToken contract
   */
  function getBlipTokenAddress() public view returns (address) {
    return address(tokenContract);
  }

  //============================================================================
  // EXTERNAL FUNCTIONS
  //============================================================================

  /**
   * Tokenizes the lineup and collects entry fee
   * Requires payment in order for the record to be created
   *
   * @param _competitionId       The external ID for this competition
   * @param _tokenId             The external ID for the token
   * @param _competitionLockedAt The datetime for when the competition entries will be locked in
   * @param _value               The value of the entry fee (in WEI)
   */
  function submitEntry(
    uint256 _competitionId,
    uint256 _tokenId,
    uint _competitionLockedAt,
    uint _value
  )
    external
    whenNotPaused
    payable
  {
    // sanity checks
    require(_competitionId != uint(0));
    require(_tokenId != uint(0));

    // they sent the right amount in WEI
    require(msg.value == _value);

    // mint the lineup w/ _tokenId being the external id
    tokenContract.mint(msg.sender, _tokenId);

    // create the entry
    bytes32 id = keccak256(msg.sender, _tokenId, now);
    CompetitionEntry memory entry = CompetitionEntry({
      competitionId: _competitionId,
      owner: msg.sender,
      tokenId: _tokenId,
      value: _value,
      createdAt: now,
      competitionLockedAt: _competitionLockedAt
    });

    // save to storage and lookup tables
    competitionEntries[id] = entry;
    accountActiveEntries[msg.sender][_competitionId] = id;
    competitionEntryIds[_competitionId].push(id);

    // emit event
    emit EntrySubmitted(_competitionId, msg.sender, id);
  }

  /**
   * Pays ETH to each of the winning addresses
   * @dev Validate that each address has an entry in this competition
   * @dev Only contract owner and admin can access
   * TODO: along with winner accounts, need to know how much ETH to send to each of them
   * TODO: sending ETH like this is a big no-no. We should just have a withdrawWinnings()
   *       method for users to receive their funds, winning or refunds
   *
   * @param _competitionId  The external ID for this competition
   * @param _winnerAccounts The addresses of accounts to be paid
   * @param _payoutAmounts  The amounts in ETH to pay each winner
   */
  function payoutWinners(
    uint256 _competitionId,
    address[] _winnerAccounts,
    uint[] _payoutAmounts
  )
    external
    onlyAuthorized
    whenNotPaused
    returns (bool)
  {
    bool totalSuccess = true;

    // sanity checks
    require(competitionEntryIds[_competitionId].length > 0);
    require(_winnerAccounts.length == _payoutAmounts.length);

    // iterate over all winner addresses, pay them and clear their entry info
    for(uint i = 0; i < _winnerAccounts.length; i++) {
      address winner = _winnerAccounts[i];

      if (_hasEntryForCompetition(winner, _competitionId)) {
        // pay them
        if (winner.send(_payoutAmounts[i])) {
          // clear entry and burn lineup token
          _burnToken(winner, _competitionId);
        }
        else {
          emit ErrorOnCompetition(_competitionId, &#39;send()&#39;, winner);
          totalSuccess = false;
        }
      }
      else {
        emit InvalidActionOnCompetition(_competitionId, &#39;payoutWinners()&#39;, winner);
        totalSuccess = false;
      }
    }

    return totalSuccess;
  }

  /**
   * Refunds ETH to each participant equal to the value in the entry
   * @dev Only contract owner and admin can access
   *
   * @param _competitionId  The external ID for this competition
   */
  function refundParticipants(uint256 _competitionId)
    external
    onlyAuthorized
    returns (bool)
  {
    // sanity check
    require(competitionEntryIds[_competitionId].length > 0);

    bool totalSuccess = true;
    bytes32[] memory entryIds = competitionEntryIds[_competitionId];

    // iterate over all entry addresses, refund them and clear their entry info
    for(uint i = 0; i < entryIds.length; i++) {
      address owner = competitionEntries[entryIds[i]].owner;

      // refund them
      if (owner.send(competitionEntries[entryIds[i]].value)) {
        // clear entry and burn lineup token
        _burnToken(owner, _competitionId);
      }
      else {
        emit ErrorOnCompetition(_competitionId, &#39;send()&#39;, owner);
        totalSuccess = false;
      }
    }

    return totalSuccess;
  }

  /**
  * Returns information for the given entry
  * @dev Only entry owner may access
  *
  * @param _competitionId The ID for the competition entry to retrieve
  */
  function getOwnedActiveEntry(uint _competitionId)
    external
    view
    onlyEntryOwner(_competitionId)
    returns(
      uint256 tokenId,
      uint256 value,
      uint createdAt,
      uint competitionLockedAt
    )
   {
     bytes32 id = accountActiveEntries[msg.sender][_competitionId];

     // sanity check
     require(id != bytes32(0));

     CompetitionEntry memory entry = competitionEntries[id];

     tokenId = entry.tokenId;
     value = entry.value;
     createdAt = entry.createdAt;
     competitionLockedAt = entry.competitionLockedAt;
   }

   /**
   * Returns information for the given entry
   * @dev Only authorized or entry owner may access
   *
   * @param id The ID for this competition entry
   */
   function getActiveEntryById(bytes32 id)
     external
     view
     onlyAuthorizedOrEntryOwner(id)
     returns(
       uint256 competitionId,
       address owner,
       uint256 tokenId,
       uint256 value,
       uint createdAt,
       uint competitionLockedAt
     )
   {
     // sanity check
     require(id != bytes32(0));

     CompetitionEntry memory entry = competitionEntries[id];

     competitionId = entry.competitionId;
     owner = entry.owner;
     tokenId = entry.tokenId;
     value = entry.value;
     createdAt = entry.createdAt;
     competitionLockedAt = entry.competitionLockedAt;
   }

   /**
   * Returns the number of entries for the given competition
   *
   * @param _competitionId The ID for the competition
   */
   function getEntriesCountForCompetition(uint256 _competitionId) public view returns(uint) {
     return competitionEntryIds[_competitionId].length;
   }

  /**
   * Sets a second authorized account for competition-related functionality (payouts & refunds)
   * @dev Only contract owner may set this
   *
   * @param _adminAddress The address for the admin
   */
  function setCompetitionAdmin(address _adminAddress) external onlyOwner {
    require(_adminAddress != address(0));
    competitionAdmin = _adminAddress;
  }

  //============================================================================
  // INTERNAL FUNCTIONS
  //============================================================================

  /**
   * Returns true if the given owner address has an active entry in the given competition
   *
   * @param _owner         The address of the entry owner
   * @param _competitionId The ID of the competition
   */
  function _hasEntryForCompetition(address _owner, uint256 _competitionId) internal view returns (bool) {
    return accountActiveEntries[_owner][_competitionId] != bytes32(0);
  }

  /**
   * Burns the token associated to the owner&#39;s competition entry and clears it from the lookup table
   *
   * @param _entryOwner    The address of the entry owner
   * @param _competitionId The ID of the competition
   */
  function _burnToken(address _entryOwner, uint256 _competitionId) internal {
    bytes32 entryId = accountActiveEntries[_entryOwner][_competitionId];

    // burn the token
    tokenContract.burn(_entryOwner, competitionEntries[entryId].tokenId);

    // clear their active entry for this competition
    delete accountActiveEntries[_entryOwner][_competitionId];
  }
}