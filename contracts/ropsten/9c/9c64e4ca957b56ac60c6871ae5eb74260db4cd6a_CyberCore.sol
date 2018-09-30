pragma solidity ^0.4.24;


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
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param _info The contact information to attach to the contract.
    */
  function setContactInformation(string _info) public onlyOwner {
    contactInformation = _info;
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


/**
 * @title Cyber Academy DApp ERC721 modified token
 * @author [Kolya Kornilov](https://facebook.com/k.kornilov01)
 */
contract CyberCoin is ERC721, Contactable {
  using AddressUtils for address;
  using SafeMath for uint;

  string internal constant name_ = "CyberCoin";
  string internal constant symbol_ = "CYBER";

  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;
  bytes4 internal constant InterfaceId_ERC165 = 0x01ffc9a7;
  bytes4 internal constant InterfaceId_ERC721TokensOf = 0x5a3f2672;

  uint internal totalSupply_;
  uint[] internal allTokens;

  mapping (address => uint) internal balances;
  mapping (address => uint[]) internal ownedTokens;
  mapping (address => mapping (address => bool)) internal approvedForAll;
  mapping (uint => address) internal tokenOwner;
  mapping (uint => uint) internal ownedTokensIndex;
  mapping (uint => address) internal tokenApproval;
  mapping (uint => uint) internal allTokensIndex;
  mapping (uint => bool) internal freezedTokens;
  mapping (uint => uint) internal tokenEventId;
  mapping (uint => bytes32) internal tokenData;
  mapping (uint => string) internal tokenURIs;
  mapping (bytes4 => bool) internal supportedInterfaces;

  event Burn(address indexed from, uint tokenId);
  event TokenFreeze(uint tokenId);
  event Mint(address indexed to, uint tokenId);

  /**
   * @dev Throws if the `msg.sender` doesn&#39;t own the specified token
   * @param _tokenId uint the validated token ID
   */
  modifier onlyOwnerOf(uint _tokenId) {
    require(msg.sender == ownerOf(_tokenId));
    _;
  }

  /**
   * @dev Throws if the `msg.sender` cannot transfer the specified token
   * @param _tokenId uint the validated token ID
   */
  modifier canTransfer(address _to, uint _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(!tokenFrozen(_tokenId));
    require(exists(_tokenId));
    require(_to != address(0));
    _;
  }

  /**
   * @dev Throws if the specified token frozen
   * @param _tokenId uint the validated token ID
   */
  modifier checkFreeze(uint _tokenId) {
    require(!tokenFrozen(_tokenId));
    _;
  }

  /**
   * @dev Constructor that registers implemented interfaces
   */
  constructor() public {
    _registerInterface(InterfaceId_ERC165);
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
    _registerInterface(InterfaceId_ERC721TokensOf);
  }

  /**
   * @dev Gets the token name
   * @return string the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Gets the total tokens amount
   * @return uint the total tokens value
   */
  function totalSupply() public view returns (uint) {
    return totalSupply_;
  }

  /**
   * @dev Gets the given account tokens balance
   * @param _owner address the tokens owner which balance need to return
   * @return uint the current given address owned tokens amount
   */
  function balanceOf(address _owner) public view returns (uint) {
    require(_owner != address(0));
    return balances[_owner];
  }

  /**
   * @dev Gets the token owner by its ID
   * @param _tokenId uint ID of the token the owner of wich need to find
   * @return address the `_tokenId` owner
   */
  function ownerOf(uint _tokenId) public view returns (address) {
    require(exists(_tokenId));
    return tokenOwner[_tokenId];
  }

  /**
   * @dev Gets the list of the given address owned tokens
   * @param _owner address the tokens owner
   * @return uint[] the list of the specified address owned tokens
   */
  function tokensOf(address _owner) public view returns (uint[]) {
    require(_owner != address(0));
    return ownedTokens[_owner];
  }

  /**
   * @dev Gets the token ID by its owner address and the `ownedTokens`
   * @dev list position
   * @param _owner address the token owner
   * @param _index uint the `ownedTokens` array posotion
   * @return uint the seeking token ID
   */
  function tokenOfOwnerByIndex(address _owner, uint _index)
    public
    view
    returns (uint)
  {
    require(_owner != address(0));
    require(ownedTokens[_owner].length > _index);
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the token by its `allTokens` array index
   * @param _index uint the `allTokens` array position
   * @return uint the seeking token ID
   */
  function tokenByIndex(uint _index) public view returns (uint) {
    require(allTokens.length > _index);
    return allTokens[_index];
  }

  /**
   * @dev Gets the token approval
   * @param _tokenId uint the specified token ID
   * @return address the `_tokenId` approval
   */
  function getApproved(uint _tokenId) public view returns (address) {
    require(exists(_tokenId));
    return tokenApproval[_tokenId];
  }

  /**
   * @dev Gets the address allowed to spend all the `_owner` tokens
   * @param _owner address the tokens owner
   * @param _spender address the validated account
   * @return bool the approved for all tokens state
   */
  function isApprovedForAll(address _owner, address _spender)
    public
    view
    returns (bool)
  {
    require(_owner != address(0));
    require(_spender != address(0));
    return approvedForAll[_owner][_spender];
  }

  /**
   * @dev Function to check that the given account is allowed to spend the
   * @dev specified token
   * @param _spender address the validated account
   * @param _tokenId uint ID of the specified token
   * @return bool the validation result
   */
  function isApprovedOrOwner(address _spender, uint _tokenId)
    public
    view
    returns (bool)
  {
    require(_spender != address(0));
    require(exists(_tokenId));

    address owner = ownerOf(_tokenId);
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Function to check the existence of the token
   * @param _tokenId uint ID of the validated token
   * @return bool the token existence
   */
  function exists(uint _tokenId) public view returns (bool) {
    return tokenOwner[_tokenId] != address(0);
  }

  /**
   * @dev Gets the token freeze state
   * @param _tokenId uint ID of the validated token
   * @return bool the `_tokenId` freeze state
   */
  function tokenFrozen(uint _tokenId) public view returns (bool) {
    require(exists(_tokenId));
    return freezedTokens[_tokenId];
  }

  /**
   * @dev Gets the given token event ID
   * @param _tokenId uint ID of the specified token
   * @return uint `_tokenId` event ID
   */
  function eventId(uint _tokenId) public view returns (uint) {
    require(exists(_tokenId));
    return tokenEventId[_tokenId];
  }

  /**
   * @dev Gets the given token data
   * @param _tokenId uint ID of the specified token
   * @return bytes32 `_tokenId` data
   */
  function getTokenData(uint _tokenId) public view returns (bytes32) {
    require(exists(_tokenId));
    return tokenData[_tokenId];
  }

  /**
   * @dev Gets the given token URI
   * @param _tokenId uint the specified token ID
   * @return string the `_tokenId` URI
   */
  function tokenURI(uint _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the inteface support state by its ID
   * @param _eventId bytes4 validated interface ID
   * @return bool `true` if supports
   */
  function supportsInterface(bytes4 _eventId) external view returns (bool) {
    require(_eventId != 0xffffffff);
    return supportedInterfaces[_eventId];
  }

  /**
   * @dev Function to approve address to spend the owned token
   * @param _spender address the token spender
   * @param _tokenId uint ID of the token to be approved
   */
  function approve(address _spender, uint _tokenId)
    public
    onlyOwnerOf(_tokenId)
    checkFreeze(_tokenId)
  {
    require(_spender != address(0));
    require(_spender != ownerOf(_tokenId));
    tokenApproval[_tokenId] = _spender;
    emit Approval(msg.sender, _spender, _tokenId);
  }

  /**
   * @dev Function to set the approval for all owned tokens
   * @param _spender address the tokens spender
   * @param _approve bool approval
   */
  function setApprovalForAll(address _spender, bool _approve) public {
    require(_spender != address(0));
    approvedForAll[msg.sender][_spender] = _approve;
    emit ApprovalForAll(msg.sender, _spender, _approve);
  }

  /**
   * @dev Function to clear approval from owned token
   * @param _tokenId uint spending token ID
   */
  function clearApproval(uint _tokenId)
    public
    onlyOwnerOf(_tokenId)
    checkFreeze(_tokenId)
  {
    _clearApproval(_tokenId);
  }

  /**
   * @dev Method to transfer token from the `msg.sender` balance or from the
   * @dev account that approved `msg.sender` to spend all owned tokens or the
   * @dev specified token
   * @param _from token owner (address)
   * @param _to token recepient (address)
   * @param _tokenId sending token ID (uint)
   */
  function transferFrom(
    address _from,
    address _to,
    uint _tokenId
  )
    public
    canTransfer(_to, _tokenId)
  {
    _clearApproval(_tokenId);
    _removeToken(_tokenId);
    _addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Function to transfer token with onERC721Received() call if the
   * @dev token recipient is the smart contract
   * @param _from address the token owner
   * @param _to address the token recepient
   * @param _tokenId uint sending token ID
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  )
    public
  {
    bytes memory empty;
    safeTransferFrom(_from, _to, _tokenId, empty);
  }

  /**
   * @dev Function to transfer token with onERC721Received() call if the
   * @dev token recipient is the smart contract and with the additional
   * @dev transaction metadata
   * @param _from address the token owner
   * @param _to address the token recepient
   * @param _tokenId uint sending token ID
   * @param _data bytes metadata
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId,
    bytes _data
  )
    public
    canTransfer(_to, _tokenId)
  {
    _clearApproval(_tokenId);
    _removeToken(_tokenId);
    _addTokenTo(_to, _tokenId);
    require(_safeContract(msg.sender, _from, _to, _tokenId, _data));

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Internal function to call `onERC721Received` `ERC721Receiver`
   * @dev interface function `safeTransferFrom` if the token recepient
   * @dev is the smart contract
   * @param _from address the token owner
   * @param _to address the token recepient
   * @param _tokenId uint sending token ID
   * @param _data bytes transaction metadata
   */
  function _safeContract(
    address _operator,
    address _from,
    address _to,
    uint _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (_to.isContract()) {
      ERC721Receiver receiver = ERC721Receiver(_to);
      require(ERC721_RECEIVED == receiver.onERC721Received(
        _operator,
        _from,
        _tokenId,
        _data
      ));
    }

    return true;
  }

  /**
   * @dev Internal function to add token to an account
   * @param _to address the token recepient
   * @param _tokenId uint sending tokens ID
   */
  function _addTokenTo(address _to, uint _tokenId) internal {
    tokenOwner[_tokenId] = _to;
    balances[_to] =  balances[_to].add(1);
    ownedTokensIndex[_tokenId] = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
  }

  /**
   * @dev Internal function to remove token from the account
   * @param _tokenId uint owned token ID
   */
  function _removeToken(uint _tokenId) internal {
    address owner_ = ownerOf(_tokenId);
    tokenOwner[_tokenId] = address(0);
    balances[owner_] = balances[owner_].sub(1);

    uint tokenIndex = ownedTokensIndex[_tokenId];
    uint lastTokenIndex = ownedTokens[owner_].length.sub(1);
    uint lastToken = ownedTokens[owner_][lastTokenIndex];

    ownedTokens[owner_][tokenIndex] = lastToken;
    ownedTokens[owner_][lastTokenIndex] = 0;
    ownedTokens[owner_].length = ownedTokens[owner_].length.sub(1);
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to clear approvals from the token
   * @param _tokenId uint approved token ID
   */
  function _clearApproval(uint _tokenId) internal {
    tokenApproval[_tokenId] = address(0);
    emit Approval(ownerOf(_tokenId), address(0), _tokenId);
  }

  /**
   * @dev Function to create a token and send it to the specified account
   * @param _to address the token recepient
   * @param _eventId uint ID of the event for wich the token will be minted
   * @param _data bytes32 value will be used in the `checkIn` function
   * @return bool the transaction success state
   */
  function _mint(address _to, uint _eventId, bytes32 _data)
    internal
    returns (bool)
  {
    require(_to != address(0));
    require(_eventId > 0);

    totalSupply_ = totalSupply_.add(1);
    uint tokenId = totalSupply_;
    allTokensIndex[tokenId] = allTokens.length;
    allTokens.push(tokenId);
    tokenEventId[tokenId] = _eventId;
    tokenData[tokenId] = _data;
    _addTokenTo(_to, tokenId);

    emit Mint(_to, tokenId);
    return true;
  }

  /**
   * @dev Function to set token URI
   * @param _tokenId uint the token ID
   * @param _uri string the token URI that will be set
   */
  function _setTokenURI(uint _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Function to freeze the given token. After the token was frozen the
   * @dev token owner cannot transfer or approve this token
   * @param _tokenId uint ID of token to be frozen
   */
  function _freeze(uint _tokenId)
    internal
  {
    require(!tokenFrozen(_tokenId));
    freezedTokens[_tokenId] = true;
    _clearApproval(_tokenId);
    emit TokenFreeze(_tokenId);
  }

  /**
   * @dev Internal function to register the support of an interface
   * @param _interfaceId bytes4 ID of the interface to be registered
   */
  function _registerInterface(bytes4 _interfaceId) internal {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }

}


/**
 * @title Cyber Academy DApp core
 * @author [Kolya Kornilov](https://facebook.com/k.kornilov01)
 */
contract CyberCore is CyberCoin {
  using SafeMath for uint;

  uint public lastEvent;
  uint[] public allEvents;

  struct Event {
    uint eventId;
    uint startTime;
    uint endTime;
    uint ticketPrice;
    uint ticketsAmount;
    uint paidAmount;
    uint ownerPercent;
    uint speakersPercent;
    address[] participants;
    address[] speakers;
    bool canceled;
  }

  mapping (uint => Event) public events;
  mapping (address => mapping (uint => bool)) public participations;
  mapping (uint => mapping (address => uint)) public paidAmountOf;

  event EventCreated(uint eventId);
  event EventCanceled(uint eventId);
  event EventClosed(uint eventId);
  event SignUp(address indexed participant, uint indexed eventId);
  event CheckIn(address indexed participant, uint indexed eventId);

  /**
   * @dev Fallback function
   * @dev Calls the `signUp` function with the last event ID and keccak256 of 
   * @dev the msg.data in the parameters
   */
  function() public payable {
    require(signUp(lastEvent, keccak256(msg.data)));
  }


  /**
   * @dev Gets the event data
   * @dev This method is bathed up to the two parts
   * @dev because there&#39;s too much arguments to return
   * @dev and the Solidity compiler returns
   * @dev `Compile Error: Stack too deep`
   * @param _eventId uint ID of the event
   * @return eventId uint the event ID
   * @return startTime uint the event start time
   * @return endTime uint the event end time
   * @return ticketPrice uint the price for those the tickets will be sold
   * @return ticketsAmount uint participants limit
   * @return paidAmount uint the total paid for the event tickets ETH amount
   */
  function getEventFirst(uint _eventId)
    public 
    view 
    returns (
      uint eventId,
      uint startTime,
      uint endTime,
      uint ticketPrice,
      uint ticketsAmount,
      uint paidAmount
    ) 
  {
    require(eventExists(_eventId));
    return (
      events[_eventId].eventId,
      events[_eventId].startTime,
      events[_eventId].endTime,
      events[_eventId].ticketPrice,
      events[_eventId].ticketsAmount,
      events[_eventId].paidAmount
    );
  }

  /**
   * @dev Gets the event data
   * @param _eventId uint ID of the event
   * @return ownerPercent uint percent of the paid ETH that will receive the owner
   * @return speakersPercent uint percent of the paid ETH that will receive the speakers
   * @return participants address[] participants list
   * @return speakers address[] speakers list
   * @return canceled bool state of the event (`true` if canceled)
   */
  function getEventSecond(uint _eventId)
    public 
    view 
    returns (
      uint ownerPercent,
      uint speakersPercent,
      address[] participants,
      address[] speakers,
      bool canceled
    ) 
  {
    require(eventExists(_eventId));
    return(
      events[_eventId].ownerPercent,
      events[_eventId].speakersPercent,
      events[_eventId].participants,
      events[_eventId].speakers,
      events[_eventId].canceled
    );
  }

  /**
   * @dev Function to check the existence of the event
   * @param _eventId uint ID of the validated event
   * @return bool the event existence
   */
  function eventExists(uint _eventId) public view returns (bool) {
    return _eventId <= lastEvent;
  }

  /**
   * @dev Function to get the participation status of an account in the 
   * @dev specified event
   * @param _who address perhaps the participant
   * @param _eventId uint ID of the event
   * @return bool `true` if participated
   */
  function participated(address _who, uint _eventId) 
    public 
    view 
    returns (bool) 
  {
    require(_who != address(0));
    require(eventExists(_eventId));
    return participations[_who][_eventId];
  }

  /**
   * @dev Function to sign up a new participant
   * @dev - participant pays ETH for a ticket
   * @dev - the function calls the CyberCoin `mint` function
   * @dev - partipant receives his ticket (token)
   * @notice Participant can paid amount bigger, that the ticket price but 
   * @notice when he will receive the cashback he will get the participant
   * @notice percent only from the ticket price, so amount paid from above will
   * @notice share the contract owner and speakers
   * @param _eventId uint event&#39;s ID participant
   * @param _data bytes32 value will be used in the `checkIn` function
   */
  function signUp(uint _eventId, bytes32 _data) public payable returns (bool) {
    require(now < events[_eventId].startTime);
    require(events[_eventId].ticketsAmount > 0);
    require(msg.value >= events[_eventId].ticketPrice);
    // require(msg.sender != owner);
    require(!participated(msg.sender, _eventId));
    require(!events[_eventId].canceled);

    require(_mint(msg.sender, _eventId, _data));
    events[_eventId].ticketsAmount = events[_eventId].ticketsAmount.sub(1);
    events[_eventId].paidAmount = events[_eventId].paidAmount.add(msg.value);
    events[_eventId].participants.push(msg.sender);
    participations[msg.sender][_eventId] = true;

    emit SignUp(msg.sender, _eventId);
    return true;
  }

  /**
   * @dev Function to check the participant on the event
   * @param _tokenId uint ID of the token minted for the specified event
   * @param _data string the token data
   * @notice the `keccak256` of the `_data` should be equal to the specified 
   * @notice token `bytes32` data (can be received from the `getTokenData(uint)` function)
   */
  function checkIn(uint _tokenId, string _data) 
    public 
    onlyOwner 
  {
    require(!tokenFrozen(_tokenId));
    require(events[eventId(_tokenId)].endTime > now);
    require(!events[eventId(_tokenId)].canceled);
    require(keccak256(abi.encodePacked(_data)) == getTokenData(_tokenId));

    _freeze(_tokenId);

    if (events[eventId(_tokenId)].ticketPrice > 0) {
      uint cashback = (
        events[eventId(_tokenId)].ticketPrice.div(100).
        mul(100 - events[eventId(_tokenId)].
        speakersPercent - events[eventId(_tokenId)].
        ownerPercent)
      );
    }
    ownerOf(_tokenId).transfer(cashback);

    emit CheckIn(ownerOf(_tokenId), eventId(_tokenId));
  }

  /**
   * @dev Function to create a new event
   * @param _startTime uint the event start time
   * @param _endTime uint the event end time
   * @param _ticketPrice uint the ticket ETH price
   * @param _ticketsAmount uint the tickets amount for this event
   * @param _ownerPercent uint the owner percent
   * @param _speakersPercent uint the speakers percent
   * @param _speakers address[] the speakers ethereum accounts list
   */
  function createEvent(
    uint _startTime,
    uint _endTime,
    uint _ticketPrice,
    uint _ticketsAmount,
    uint _ownerPercent,
    uint _speakersPercent,
    address[] _speakers
  ) 
    public 
    onlyOwner
  {
    require(_startTime > now);
    require(_endTime > _startTime);
    require(_ticketsAmount > 0);
    require(_speakers.length > 0);
    require(_ownerPercent.add(_speakersPercent) <= 100);

    lastEvent++;
    address[] memory participants_;
    Event memory event_ = Event({
      eventId         : lastEvent,
      startTime       : _startTime,
      endTime         : _endTime,
      ticketPrice     : _ticketPrice,
      ticketsAmount   : _ticketsAmount,
      paidAmount      : 0,
      participants    : participants_,
      ownerPercent    : _ownerPercent,
      speakersPercent : _speakersPercent,
      speakers        : _speakers,
      canceled        : false
    });
    events[lastEvent] = event_;
    allEvents.push(lastEvent);

    emit EventCreated(lastEvent);
  }

  /**
   * @dev Function to cancel an event
   * @param _eventId uint an event ID to be canceled
   */
  function cancelEvent(uint _eventId) public onlyOwner {
    require(eventExists(_eventId));
    require(!events[_eventId].canceled);
    events[_eventId].canceled = true;
    emit EventCanceled(_eventId);
  }

  /**
   * @dev Function to close the past event
   * @param _eventId uint ID of the event to be closed
   */
  function closeEvent(uint _eventId) public onlyOwner {
    require(now > events[_eventId].endTime);

    if (events[_eventId].canceled) {
      for (uint i = 0; i < events[_eventId].participants.length; i++) {
        events[_eventId].participants[i].transfer(
          paidAmountOf[_eventId][events[_eventId].participants[i]]
        ); 
      }
    } else {
      owner.transfer(
        events[_eventId].paidAmount.
        div(100).
        mul(events[_eventId].ownerPercent)
      );

      for (uint j = 0; j < events[_eventId].speakers.length; j++) {
        events[_eventId].speakers[j].transfer(
          events[_eventId].paidAmount.
          div(100).
          mul(events[_eventId].speakersPercent).
          div(events[_eventId].speakers.length)
        );
      }
    }
    if (events[_eventId].ticketsAmount > 0) events[_eventId].ticketsAmount = 0;

    emit EventClosed(_eventId);
  }

}