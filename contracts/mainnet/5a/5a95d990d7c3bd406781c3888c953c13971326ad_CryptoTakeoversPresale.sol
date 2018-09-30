pragma solidity 0.4.24;

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

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  constructor() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

contract Operatable is Ownable {

    address public operator;

    event LogOperatorChanged(address indexed from, address indexed to);

    modifier isValidOperator(address _operator) {
        require(_operator != address(0));
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    constructor(address _owner, address _operator) public isValidOperator(_operator) {
        require(_owner != address(0));
        
        owner = _owner;
        operator = _operator;
    }

    function setOperator(address _operator) public onlyOwner isValidOperator(_operator) {
        emit LogOperatorChanged(operator, _operator);
        operator = _operator;
    }
}

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

contract CryptoTakeoversNFT is ERC721Token("CryptoTakeoversNFT",""), Operatable {
    
    event LogGameOperatorChanged(address indexed from, address indexed to);

    address public gameOperator;

    modifier onlyGameOperator() {
        assert(gameOperator != address(0));
        require(msg.sender == gameOperator);
        _;
    }

    constructor (address _owner, address _operator) Operatable(_owner, _operator) public {
    }

    function mint(uint256 _tokenId, string _tokenURI) public onlyGameOperator {
        super._mint(operator, _tokenId);
        super._setTokenURI(_tokenId, _tokenURI);
    }

    function hostileTakeover(address _to, uint256 _tokenId) public onlyGameOperator {
        address tokenOwner = super.ownerOf(_tokenId);
        operatorApprovals[tokenOwner][gameOperator] = true;
        super.safeTransferFrom(tokenOwner, _to, _tokenId);
    }

    function setGameOperator(address _gameOperator) public onlyOperator {
        emit LogGameOperatorChanged(gameOperator, _gameOperator);
        gameOperator = _gameOperator;
    }

    function burn(uint256 _tokenId) public onlyGameOperator {
        super._burn(operator, _tokenId);
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/// @title CryptoTakeovers In-Game Token.
/// @dev The token used in the game to participate in NFT airdrop raffles.
/// @author Ido Amram <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e8818c87a88b9a91989c879c89838d879e8d9a9bc68b8785">[email&#160;protected]</a>>, Elad Mallel <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c2a7aea3a682a1b0bbb2b6adb6a3a9a7adb4a7b0b1eca1adaf">[email&#160;protected]</a>>
contract CryptoTakeoversToken is MintableToken, Operatable {

    /*
     * Events
     */

    event LogGameOperatorChanged(address indexed from, address indexed to);
    event LogShouldBlockPublicTradeSet(bool value, address indexed owner);

    /*
     * Storage
     */

    bool public shouldBlockPublicTrade;
    address public gameOperator;

    /*
     * Modifiers
     */

    modifier hasMintPermission() {
        require(msg.sender == operator || (gameOperator != address(0) && msg.sender == gameOperator));
        _;
    }

    modifier hasTradePermission(address _from) {
        require(_from == operator || !shouldBlockPublicTrade);
        _;
    }

    /*
     * Public (unauthorized) functions
     */

    /// @dev CryptoTakeoversToken constructor.
    /// @param _owner the address of the owner to set for this contract
    /// @param _operator the address ofh the operator to set for this contract
    constructor (address _owner, address _operator) Operatable(_owner, _operator) public {
        shouldBlockPublicTrade = true;
    }

    /*
     * Operator (authorized) functions
     */

    /// @dev Allows an authorized set of accounts to transfer tokens.
    /// @param _to the account to transfer tokens to
    /// @param _value the amount of tokens to transfer
    /// @return true if the transfer succeeded, and false otherwise
    function transfer(address _to, uint256 _value) public hasTradePermission(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }

    /// @dev Allows an authorized set of accounts to transfer tokens.
    /// @param _from the account from which to transfer tokens
    /// @param _to the account to transfer tokens to
    /// @param _value the amount of tokens to transfer
    /// @return true if the transfer succeeded, and false otherwise
    function transferFrom(address _from, address _to, uint256 _value) public hasTradePermission(_from) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// @dev Allows the operator to set the address of the game operator, which should be the pre-sale contract or the game contract.
    /// @param _gameOperator the address of the game operator
    function setGameOperator(address _gameOperator) public onlyOperator {
        require(_gameOperator != address(0));

        emit LogGameOperatorChanged(gameOperator, _gameOperator);

        gameOperator = _gameOperator;
    }

    /*
     * Owner (authorized) functions
     */

    /// @dev Allows the owner to enable or restrict open trade of tokens.
    /// @param _shouldBlockPublicTrade true if trade should be restricted, and false to open trade
    function setShouldBlockPublicTrade(bool _shouldBlockPublicTrade) public onlyOwner {
        shouldBlockPublicTrade = _shouldBlockPublicTrade;

        emit LogShouldBlockPublicTradeSet(_shouldBlockPublicTrade, owner);
    }
}

/// @title CryptoTakeovers PreSale.
/// @dev Manages the sale of in-game assets (cities and countries) and tokens.
/// @author Ido Amram <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7f161b103f1c0d060f0b100b1e141a10091a0d0c511c1012">[email&#160;protected]</a>>, Elad Mallel <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fd98919c99bd9e8f848d8992899c9698928b988f8ed39e9290">[email&#160;protected]</a>>
contract CryptoTakeoversPresale is Destructible, Pausable, Operatable {

    /*
     * Events
     */

    event LogNFTBought(uint256 indexed tokenId, address indexed buyer, uint256 value);
    event LogTokensBought(address indexed buyer, uint256 amount, uint256 value);
    event LogNFTGifted(address indexed to, uint256 indexed tokenId, uint256 price, address indexed operator);
    event LogTokensGifted(address indexed to, uint256 amount, address indexed operator);
    event LogNFTBurned(uint256 indexed tokenId, address indexed operator);
    event LogTokenPricesSet(
        uint256[] previousThresholds, 
        uint256[] previousPrices, 
        uint256[] newThresholds, 
        uint256[] newPrices, 
        address indexed operator);
    event LogNFTMintedNotForSale(uint256 indexed tokenId, address indexed operator);
    event LogNFTMintedForSale(uint256 indexed tokenId, uint256 tokenPrice, address indexed operator);
    event LogNFTSetNotForSale(uint256 indexed tokenId, address indexed operator);
    event LogNFTSetForSale(uint256 indexed tokenId, uint256 tokenPrice, address indexed operator);
    event LogDiscountSet(uint256 indexed tokenId, uint256 discountPrice, address indexed operator);
    event LogDiscountUpdated(uint256 indexed tokenId, uint256 discountPrice, address indexed operator);
    event LogDiscountRemoved(uint256 indexed tokenId, address indexed operator);
    event LogDiscountsReset(uint256 count, address indexed operator);
    event LogStartAndEndTimeSet(uint256 startTime, uint256 endTime, address indexed operator);
    event LogStartTimeSet(uint256 startTime, address indexed operator);
    event LogEndTimeSet(uint256 endTime, address indexed operator);
    event LogTokensContractSet(address indexed previousAddress, address indexed newAddress, address indexed owner);
    event LogItemsContractSet(address indexed previousAddress, address indexed newAddress, address indexed owner);
    event LogWithdrawToChanged(address indexed previousAddress, address indexed newAddress, address indexed owner);
    event LogWithdraw(address indexed withdrawTo, uint256 value, address indexed owner);

    /*
     * Storage
     */

    using SafeMath for uint256;

    CryptoTakeoversNFT public items;
    CryptoTakeoversToken public tokens;

    uint256 public startTime;
    uint256 public endTime;
    address public withdrawTo;
    
    mapping (uint256 => uint256) tokenPrices;
    uint256[] public itemsForSale;
    mapping (uint256 => uint256) itemsForSaleIndex;
    mapping (uint256 => uint256) discountedItemPrices;
    uint256[] public discountedItems;
    mapping (uint256 => uint256) discountedItemsIndex;

    uint256[] public tokenDiscountThresholds;
    uint256[] public tokenDiscountedPrices;

    /*
     * Modifiers
     */

    modifier onlyDuringPresale() {
        require(startTime != 0 && endTime != 0);
        require(now >= startTime);
        require(now <= endTime);
        _;
    }

    /*
     * Public (unauthorized) functions
     */

    /// @dev CryptoTakeoversPresale constructor.
    /// @param _owner the account with owner permissions
    /// @param _operator the admin of the pre-sale, who can start and stop the sale, and mint items for sale
    /// @param _cryptoTakeoversNFTAddress the address of the ERC721 game tokens, representing cities and countries
    /// @param _cryptoTakeoversTokenAddress the address of the in-game fungible tokens, which grant their owners
    /// the chance to win NFT assets in airdrops the team will perform periodically
    constructor (
        address _owner,
        address _operator, 
        address _cryptoTakeoversNFTAddress, 
        address _cryptoTakeoversTokenAddress
    ) 
        Operatable(_owner, _operator) 
        public 
    {
        items = CryptoTakeoversNFT(_cryptoTakeoversNFTAddress);
        tokens = CryptoTakeoversToken(_cryptoTakeoversTokenAddress);
        withdrawTo = owner;
    }

    /// @dev Allows anyone to buy an asset during the pre-sale.
    /// @param _tokenId the ID of the asset to buy
    function buyNFT(uint256 _tokenId) public payable onlyDuringPresale whenNotPaused {
        require(msg.value == _getItemPrice(_tokenId), "value sent must equal the price");
    
        _setItemNotForSale(_tokenId);

        items.hostileTakeover(msg.sender, _tokenId);

        emit LogNFTBought(_tokenId, msg.sender, msg.value);
    }

    /// @dev Allows anyone to buy tokens during the pre-sale.
    /// @param _amount the amount of tokens to buy
    function buyTokens(uint256 _amount) public payable onlyDuringPresale whenNotPaused {
        require(tokenDiscountedPrices.length > 0, "prices should be set before selling tokens");
        uint256 priceToUse = tokenDiscountedPrices[0];
        for (uint256 index = 1; index < tokenDiscountedPrices.length; index++) {
            if (_amount >= tokenDiscountThresholds[index]) {
                priceToUse = tokenDiscountedPrices[index];
            }
        }
        require(msg.value == _amount.mul(priceToUse), "we only accept exact payment");

        tokens.mint(msg.sender, _amount);

        emit LogTokensBought(msg.sender, _amount, msg.value);
    }

    /// @dev Returns the details of a CryptoTakeovers asset.
    /// @param _tokenId the ID of the asset
    /// @return tokenId the ID of the asset
    /// @return owner the address of the asset&#39;s owner
    /// @return tokenURI the URI of the asset&#39;s metadata
    /// @return price the asset
    /// @return forSale a bool indicating if the asset is up for sale or not
    function getItem(uint256 _tokenId) external view 
        returns(uint256 tokenId, address owner, string tokenURI, uint256 price, uint256 discountedPrice, bool forSale, bool discounted) {
        tokenId = _tokenId;
        owner = items.ownerOf(_tokenId);
        tokenURI = items.tokenURI(_tokenId);
        price = tokenPrices[_tokenId];
        discountedPrice = discountedItemPrices[_tokenId];
        forSale = isTokenForSale(_tokenId);
        discounted = _isTokenDiscounted(_tokenId);
    }

    /// @dev Returns the details of up to 20 assets in one call. Acts as a performance optimization for getItem.
    /// @param _fromIndex the index of the first asset to return (inclusive)
    /// @param _toIndex the index of the last asset to return (exclusive. use the array&#39;s length value to get the last asset)
    /// @return ids the IDs of  the requested assets
    /// @return owners the addresses of the owners of the requested assets
    /// @return prices the prices of the requested assets
    function getItemsForSale(uint256 _fromIndex, uint256 _toIndex) public view 
        returns(uint256[20] ids, address[20] owners, uint256[20] prices, uint256[20] discountedPrices) {
        require(_toIndex <= itemsForSale.length);
        require(_fromIndex < _toIndex);
        require(_toIndex.sub(_fromIndex) <= ids.length);

        uint256 resultIndex = 0;
        for (uint256 index = _fromIndex; index < _toIndex; index++) {
            uint256 tokenId = itemsForSale[index];
            ids[resultIndex] = tokenId;
            owners[resultIndex] = items.ownerOf(tokenId);
            prices[resultIndex] = tokenPrices[tokenId];
            discountedPrices[resultIndex] = discountedItemPrices[tokenId];
            resultIndex = resultIndex.add(1);
        }
    }

    /// @dev Returns the details of up to 20 items that have been set with a discounted price.
    /// @param _fromIndex the index of the first item to get (inclusive)
    /// @param _toIndex the index of the last item to get (exclusive)
    /// @return ids the IDs of the requested items
    /// @return owners the owners of the requested items
    /// @return prices the prices of the requested items
    /// @return discountedPrices the discounted prices of the requested items
    function getDiscountedItemsForSale(uint256 _fromIndex, uint256 _toIndex) public view 
        returns(uint256[20] ids, address[20] owners, uint256[20] prices, uint256[20] discountedPrices) {
        require(_toIndex <= discountedItems.length, "toIndex out of bounds");
        require(_fromIndex < _toIndex, "fromIndex must be less than toIndex");
        require(_toIndex.sub(_fromIndex) <= ids.length, "requested range cannot exceed 20 items");
        
        uint256 resultIndex = 0;
        for (uint256 index = _fromIndex; index < _toIndex; index++) {
            uint256 tokenId = discountedItems[index];
            ids[resultIndex] = tokenId;
            owners[resultIndex] = items.ownerOf(tokenId);
            prices[resultIndex] = tokenPrices[tokenId];
            discountedPrices[resultIndex] = discountedItemPrices[tokenId];
            resultIndex = resultIndex.add(1);
        }
    }

    /// @dev Returns whether a specific asset is for sale.
    /// @param _tokenId the ID of the asset
    /// @return true if the asset is for sale, and false otherwise
    function isTokenForSale(uint256 _tokenId) internal view returns(bool) {
        return tokenPrices[_tokenId] != 0;
    }

    /// @dev Returns the total number of assets for sale.
    /// @return the total number of assets for sale
    function totalItemsForSale() public view returns(uint256) {
        return itemsForSale.length;
    }

    /// @dev Returns the number of assets for the provided account.
    /// @return the number of assets owner owns
    function NFTBalanceOf(address _owner) public view returns (uint256) {
        return items.balanceOf(_owner);
    }

    /// @dev Returns up to 20 IDs of assets for the provided account.
    /// @return an array of tokenIDs
    function tokenOfOwnerByRange(address _owner, uint256 _fromIndex, uint256 _toIndex) public view returns(uint256[20] ids) {
        require(_toIndex <= items.balanceOf(_owner));
        require(_fromIndex < _toIndex);
        require(_toIndex.sub(_fromIndex) <= ids.length);

        uint256 resultIndex = 0;
        for (uint256 index = _fromIndex; index < _toIndex; index++) {
            ids[resultIndex] = items.tokenOfOwnerByIndex(_owner, index);
            resultIndex = resultIndex.add(1);
        }
    }

    /// @dev Returns the token balance of the provided account.
    /// @return the number of tokens owner owns
    function tokenBalanceOf(address _owner) public view returns (uint256) {
        return tokens.balanceOf(_owner);
    }

    /// @dev Returns the total number of assets with a discounted price.
    /// @return the number of items set with a discounted price
    function totalDiscountedItemsForSale() public view returns (uint256) {
        return discountedItems.length;
    }

    /*
     * Operator (authorized) functions
     */

    /// @dev Allows the operator to give assets without payment. Will be used to perform asset airdrops.
    /// Only works on items that have not been sold yet.
    /// @param _to the address to give the asset to
    /// @param _tokenId the ID of the asset to give
    /// @param _tokenPrice the price of the gifted token
    function giftNFT(address _to, uint256 _tokenId, uint256 _tokenPrice) public onlyOperator {
        require(_to != address(0));
        require(items.ownerOf(_tokenId) == operator);
        require(_tokenPrice > 0, "must provide the token price to log");

        if (isTokenForSale(_tokenId)) {
            _setItemNotForSale(_tokenId);
        }

        items.hostileTakeover(_to, _tokenId);

        emit LogNFTGifted(_to, _tokenId, _tokenPrice, operator);
    }

    /// @dev Allows the operator to give tokens without payment. Will be used to perform token airdrops.
    /// @param _to the address to give tokens to (cannot be 0x0)
    /// @param _amount the amount of tokens to mint and give
    function giftTokens(address _to, uint256 _amount) public onlyOperator {
        require(_to != address(0));
        require(_amount > 0);
        
        tokens.mint(_to, _amount);

        emit LogTokensGifted(_to, _amount, operator);
    }

    /// @dev Allows the operator to burn an item in case of any errors in setting up the items for sale.
    /// It uses items.burn which makes sure it only works for items we haven&#39;t sold yet (i.e. only works
    /// for items owned by the operator).
    /// @param _tokenId the ID of the asset to burn
    function burnNFT(uint256 _tokenId) public onlyOperator {
        if (isTokenForSale(_tokenId)) {
            _setItemNotForSale(_tokenId);
        }
        
        items.burn(_tokenId);

        emit LogNFTBurned(_tokenId, operator);
    }

    /// @dev Allows the operator to set the discounted prices of tokens per threshold of purchased amount.
    /// @param _tokenDiscountThresholds an array of token quantity thresholds. Cannot contain more than 10 items
    /// @param _tokenDiscountedPrices an array of token prices to match each quantity threshold. Cannot contain more than 10 items
    function setTokenPrices(uint256[] _tokenDiscountThresholds, uint256[] _tokenDiscountedPrices) public onlyOperator {
        require(_tokenDiscountThresholds.length <= 10, "inputs length must be under 10 options");
        require(_tokenDiscountThresholds.length == _tokenDiscountedPrices.length, "input arrays must have the same length");

        emit LogTokenPricesSet(tokenDiscountThresholds, tokenDiscountedPrices, _tokenDiscountThresholds, _tokenDiscountedPrices, operator);

        tokenDiscountThresholds = _tokenDiscountThresholds;
        tokenDiscountedPrices = _tokenDiscountedPrices;
    }

    /// @dev Returns the discount thresholds and prices that match those thresholds in two arrays.
    /// @return discountThresholds an array of discount thresholds
    /// @return discountedPrices an array of token prices per threshold
    function getTokenPrices() public view returns(uint256[10] discountThresholds, uint256[10] discountedPrices) {
        for (uint256 index = 0; index < tokenDiscountThresholds.length; index++) {
            discountThresholds[index] = tokenDiscountThresholds[index];
            discountedPrices[index] = tokenDiscountedPrices[index];
        }
    }

    /// @dev Allows the operator to create an asset but not put it up for sale yet.
    /// @param _tokenId the ID of the asset to mint
    /// @param _tokenURI the URI of the asset&#39;s metadata
    function mintNFTNotForSale(uint256 _tokenId, string _tokenURI) public onlyOperator {
        items.mint(_tokenId, _tokenURI);

        emit LogNFTMintedNotForSale(_tokenId, operator);
    }

    /// @dev A bulk optimization for mintNFTNotForSale
    /// @param _tokenIds the IDs of the tokens to mint
    /// @param _tokenURIParts parts of the base URI, e.g. ["https://", "host.com", "/path"]
    function mintNFTsNotForSale(uint256[] _tokenIds, bytes32[] _tokenURIParts) public onlyOperator {
        require(_tokenURIParts.length > 0, "need at least one string to build URIs");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            uint256 tokenId = _tokenIds[index];
            string memory tokenURI = _generateTokenURI(_tokenURIParts, tokenId);

            mintNFTNotForSale(tokenId, tokenURI);
        }
    }

    /// @dev Allows the operator to create an asset and immediately put it up for sale.
    /// @param _tokenId the ID of the asset to mint
    /// @param _tokenURI the URI of the asset&#39;s metadata
    /// @param _tokenPrice the price of the asset
    function mintNFTForSale(uint256 _tokenId, string _tokenURI, uint256 _tokenPrice) public onlyOperator {
        tokenPrices[_tokenId] = _tokenPrice;
        itemsForSaleIndex[_tokenId] = itemsForSale.push(_tokenId).sub(1);
        items.mint(_tokenId, _tokenURI);

        emit LogNFTMintedForSale(_tokenId, _tokenPrice, operator);
    }

    /// @dev A bulk optimization for mintNFTForSale
    /// @param _tokenIds the IDs for the tokens to mint
    /// @param _tokenURIParts parts of the base URI, e.g. ["https://", "host.com", "/path"]
    /// @param _tokenPrices the prices of the tokens to mint
    function mintNFTsForSale(uint256[] _tokenIds, bytes32[] _tokenURIParts, uint256[] _tokenPrices) public onlyOperator {
        require(_tokenIds.length == _tokenPrices.length, "ids and prices must have the same length");
        require(_tokenURIParts.length > 0, "must have URI parts to build URIs");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            uint256 tokenId = _tokenIds[index];
            uint256 tokenPrice = _tokenPrices[index];
            string memory tokenURI = _generateTokenURI(_tokenURIParts, tokenId);

            mintNFTForSale(tokenId, tokenURI, tokenPrice);
        }
    }

    /// @dev Allows the operator to take an asset that&#39;s not up for sale and put it up for sale.
    /// @param _tokenId the ID of the asset
    /// @param _tokenPrice the price of the asset
    function setItemForSale(uint256 _tokenId, uint256 _tokenPrice) public onlyOperator {
        require(items.exists(_tokenId));
        require(!isTokenForSale(_tokenId));
        require(items.ownerOf(_tokenId) == operator, "cannot set item for sale after it has been sold");

        tokenPrices[_tokenId] = _tokenPrice;
        itemsForSaleIndex[_tokenId] = itemsForSale.push(_tokenId).sub(1);
        
        emit LogNFTSetForSale(_tokenId, _tokenPrice, operator);
    }

    /// @dev A bulk optimization for setItemForSale.
    /// @param _tokenIds an array of IDs of assets to update
    /// @param _tokenPrices an array of prices to set
    function setItemsForSale(uint256[] _tokenIds, uint256[] _tokenPrices) public onlyOperator {
        require(_tokenIds.length == _tokenPrices.length);
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            setItemForSale(_tokenIds[index], _tokenPrices[index]);
        }
    }

    /// @dev Allows the operator to take down an item for sale.
    /// @param _tokenId the ID of the asset to take down
    function setItemNotForSale(uint256 _tokenId) public onlyOperator {
        _setItemNotForSale(_tokenId);

        emit LogNFTSetNotForSale(_tokenId, operator);
    }

    /// @dev A bulk optimization for setItemNotForSale.
    /// @param _tokenIds an array of IDs of assets to update
    function setItemsNotForSale(uint256[] _tokenIds) public onlyOperator {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            setItemNotForSale(_tokenIds[index]);
        }
    }

    /// @dev Allows the operator to update an asset&#39;s price.
    /// @param _tokenId the ID of the asset
    /// @param _tokenPrice the new price to set
    function updateItemPrice(uint256 _tokenId, uint256 _tokenPrice) public onlyOperator {
        require(items.exists(_tokenId));
        require(items.ownerOf(_tokenId) == operator);
        require(isTokenForSale(_tokenId));
        tokenPrices[_tokenId] = _tokenPrice;
    }

    /// @dev A bulk optimization for updateItemPrice
    /// @param _tokenIds the IDs of tokens to update
    /// @param _tokenPrices the new prices to set
    function updateItemsPrices(uint256[] _tokenIds, uint256[] _tokenPrices) public onlyOperator {
        require(_tokenIds.length == _tokenPrices.length, "input arrays must have the same length");
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            updateItemPrice(_tokenIds[index], _tokenPrices[index]);
        }
    }

    /// @dev Allows the operator to set discount prices for specific items.
    /// @param _tokenIds the IDs of items to set a discount price for
    /// @param _discountPrices the discount prices to set
    function setDiscounts(uint256[] _tokenIds, uint256[] _discountPrices) public onlyOperator {
        require(_tokenIds.length == _discountPrices.length, "input arrays must have the same length");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            _setDiscount(_tokenIds[index], _discountPrices[index]);    
        }
    }

    /// @dev Allows the operator to remove the discount from specific items.
    /// @param _tokenIds the IDs of the items to remove the discount from
    function removeDiscounts(uint256[] _tokenIds) public onlyOperator {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            _removeDiscount(_tokenIds[index]);            
        }
    }

    /// @dev Allows the operator to update discount prices.
    /// @param _tokenIds the IDs of the items to update
    /// @param _discountPrices the new discount prices to set 
    function updateDiscounts(uint256[] _tokenIds, uint256[] _discountPrices) public onlyOperator {
        require(_tokenIds.length == _discountPrices.length, "arrays must be same-length");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            _updateDiscount(_tokenIds[index], _discountPrices[index]);
        }
    }

    /// @dev Allows the operator to reset all discounted items at once.
    function resetDiscounts() public onlyOperator {
        emit LogDiscountsReset(discountedItems.length, operator);

        for (uint256 index = 0; index < discountedItems.length; index++) {
            uint256 tokenId = discountedItems[index];
            discountedItemPrices[tokenId] = 0;
            discountedItemsIndex[tokenId] = 0;            
        }
        discountedItems.length = 0;
    }

    /// @dev An atomic txn optimization for calling resetDiscounts and then setDiscounts, so we don&#39;t have to experience
    /// any moment of not having any items under discount.
    /// @param _tokenIds the IDs of the new items to discount
    /// @param _discountPrices the discounted prices of the new items to discount
    function resetOldAndSetNewDiscounts(uint256[] _tokenIds, uint256[] _discountPrices) public onlyOperator {
        resetDiscounts();
        setDiscounts(_tokenIds, _discountPrices);
    }

    /// @dev Allows the operator to set the start and end time of the sale. 
    /// Before startTime and after endTime no one should be able to buy items from this contract.
    /// @param _startTime the time the pre-sale should start
    /// @param _endTime the time the pre-sale should end
    function setStartAndEndTime(uint256 _startTime, uint256 _endTime) public onlyOperator {
        require(_startTime >= now);
        require(_startTime < _endTime);

        startTime = _startTime;
        endTime = _endTime;

        emit LogStartAndEndTimeSet(_startTime, _endTime, operator);
    }

    function setStartTime(uint256 _startTime) public onlyOperator {
        require(_startTime > 0);

        startTime = _startTime;

        emit LogStartTimeSet(_startTime, operator);
    }

    function setEndTime(uint256 _endTime) public onlyOperator {
        require(_endTime > 0);

        endTime = _endTime;

        emit LogEndTimeSet(_endTime, operator);
    }

    /// @dev Allows the operator to withdraw funds from the sale to the address defined by the owner.
    function withdraw() public onlyOperator {
        require(withdrawTo != address(0));
        uint256 balance = address(this).balance;
        require(address(this).balance > 0);

        withdrawTo.transfer(balance);

        emit LogWithdraw(withdrawTo, balance, owner);
    }

    /*
     * Owner (authorized) functions
     */

    /// @dev Allows the owner to change the contract representing the tokens. Reserved for emergency bugs only.
    /// Because this is a big deal we hope to avoid ever using it, the operator cannot run it, but only the
    /// owner.
    /// @param _cryptoTakeoversTokenAddress the address of the new contract to use
    function setTokensContract(address _cryptoTakeoversTokenAddress) public onlyOwner {
        emit LogTokensContractSet(tokens, _cryptoTakeoversTokenAddress, owner);

        tokens = CryptoTakeoversToken(_cryptoTakeoversTokenAddress);
    }

    /// @dev Allows the owner to change the contract representing the assets. Reserved for emergency bugs only.
    /// Because this is a big deal we hope to avoid ever using it, the operator cannot run it, but only the
    /// owner.
    /// @param _cryptoTakeoversNFTAddress the address of the new contract to use
    function setItemsContract(address _cryptoTakeoversNFTAddress) public onlyOwner {
        emit LogItemsContractSet(items, _cryptoTakeoversNFTAddress, owner);

        items = CryptoTakeoversNFT(_cryptoTakeoversNFTAddress);
    }

    /// @dev Allows the owner to change the address to which the operator can withdraw this contract&#39;s
    /// ETH balance.
    /// @param _withdrawTo the address future withdraws will go to
    function setWithdrawTo(address _withdrawTo) public onlyOwner {
        require(_withdrawTo != address(0));

        emit LogWithdrawToChanged(withdrawTo, _withdrawTo, owner);

        withdrawTo = _withdrawTo;
    }

    /*
     * Internal functions
     */

    /// @dev Marks an asset as not for sale.
    /// @param _tokenId the ID of the item to take down from the sale
    function _setItemNotForSale(uint256 _tokenId) internal {
        require(items.exists(_tokenId));
        require(isTokenForSale(_tokenId));

        if (_isTokenDiscounted(_tokenId)) {
            _removeDiscount(_tokenId);
        }

        tokenPrices[_tokenId] = 0;

        uint256 currentTokenIndex = itemsForSaleIndex[_tokenId];
        uint256 lastTokenIndex = itemsForSale.length.sub(1);
        uint256 lastTokenId = itemsForSale[lastTokenIndex];

        itemsForSale[currentTokenIndex] = lastTokenId;
        itemsForSale[lastTokenIndex] = 0;
        itemsForSale.length = itemsForSale.length.sub(1);

        itemsForSaleIndex[_tokenId] = 0;
        itemsForSaleIndex[lastTokenId] = currentTokenIndex;
    }

    function _appendUintToString(string inStr, uint vInput) internal pure returns (string str) {
        uint v = vInput;
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function _bytes32ArrayToString(bytes32[] data) internal pure returns (string) {
        bytes memory bytesString = new bytes(data.length * 32);
        uint urlLength;
        for (uint256 i = 0; i < data.length; i++) {
            for (uint256 j = 0; j < 32; j++) {
                byte char = byte(bytes32(uint(data[i]) * 2 ** (8 * j)));
                if (char != 0) {
                    bytesString[urlLength] = char;
                    urlLength += 1;
                }
            }
        }
        bytes memory bytesStringTrimmed = new bytes(urlLength);
        for (i = 0; i < urlLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }

    function _generateTokenURI(bytes32[] _tokenURIParts, uint256 _tokenId) internal pure returns(string tokenURI) {
        string memory baseUrl = _bytes32ArrayToString(_tokenURIParts);
        tokenURI = _appendUintToString(baseUrl, _tokenId);
    }

    function _setDiscount(uint256 _tokenId, uint256 _discountPrice) internal {
        require(items.exists(_tokenId), "does not make sense to set a discount for an item that does not exist");
        require(items.ownerOf(_tokenId) == operator, "we only change items still owned by us");
        require(isTokenForSale(_tokenId), "does not make sense to set a discount for an item not for sale");
        require(!_isTokenDiscounted(_tokenId), "cannot discount the same item twice");
        require(_discountPrice > 0 && _discountPrice < tokenPrices[_tokenId], "discount price must be positive and less than full price");

        discountedItemPrices[_tokenId] = _discountPrice;
        discountedItemsIndex[_tokenId] = discountedItems.push(_tokenId).sub(1);

        emit LogDiscountSet(_tokenId, _discountPrice, operator);
    }

    function _updateDiscount(uint256 _tokenId, uint256 _discountPrice) internal {
        require(items.exists(_tokenId), "item must exist");
        require(items.ownerOf(_tokenId) == operator, "we must own the item");
        require(_isTokenDiscounted(_tokenId), "must be discounted");
        require(_discountPrice > 0 && _discountPrice < tokenPrices[_tokenId], "discount price must be positive and less than full price");

        discountedItemPrices[_tokenId] = _discountPrice;

        emit LogDiscountUpdated(_tokenId, _discountPrice, operator);
    }

    function _getItemPrice(uint256 _tokenId) internal view returns(uint256) {
        if (_isTokenDiscounted(_tokenId)) {
            return discountedItemPrices[_tokenId];
        }
        return tokenPrices[_tokenId];
    }

    function _isTokenDiscounted(uint256 _tokenId) internal view returns(bool) {
        return discountedItemPrices[_tokenId] != 0;
    }

    function _removeDiscount(uint256 _tokenId) internal {
        require(items.exists(_tokenId), "item must exist");
        require(_isTokenDiscounted(_tokenId), "item must be discounted");

        discountedItemPrices[_tokenId] = 0;

        uint256 currentTokenIndex = discountedItemsIndex[_tokenId];
        uint256 lastTokenIndex = discountedItems.length.sub(1);
        uint256 lastTokenId = discountedItems[lastTokenIndex];

        discountedItems[currentTokenIndex] = lastTokenId;
        discountedItems[lastTokenIndex] = 0;
        discountedItems.length = discountedItems.length.sub(1);

        discountedItemsIndex[_tokenId] = 0;
        discountedItemsIndex[lastTokenId] = currentTokenIndex;

        emit LogDiscountRemoved(_tokenId, operator);
    }
}