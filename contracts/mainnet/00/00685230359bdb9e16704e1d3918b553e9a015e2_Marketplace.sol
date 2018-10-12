pragma solidity ^0.4.24;

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


contract IAssetManager {
    function createAssetPack(bytes32 _packCover, string _name, uint[] _attributes, bytes32[] _ipfsHashes, uint _packPrice) public;
    function createAsset(uint _attributes, bytes32 _ipfsHash, uint _packId) public;
    function buyAssetPack(address _to, uint _assetPackId) public payable;
    function getNumberOfAssets() public view returns (uint);
    function getNumberOfAssetPacks() public view returns(uint);
    function checkHasPermissionForPack(address _address, uint _packId) public view returns (bool);
    function checkHashExists(bytes32 _ipfsHash) public view returns (bool);
    function givePermission(address _address, uint _packId) public;
    function pickUniquePacks(uint [] assetIds) public view returns (uint[]);
    function getAssetInfo(uint id) public view returns (uint, uint, bytes32);
    function getAssetPacksUserCreated(address _address) public view returns(uint[]);
    function getAssetIpfs(uint _id) public view returns (bytes32);
    function getAssetAttributes(uint _id) public view returns (uint);
    function getIpfsForAssets(uint [] _ids) public view returns (bytes32[]);
    function getAttributesForAssets(uint [] _ids) public view returns(uint[]);
    function withdraw() public;
    function getAssetPackData(uint _assetPackId) public view returns(string, uint[], uint[], bytes32[]);
    function getAssetPackName(uint _assetPackId) public view returns (string);
    function getAssetPackPrice(uint _assetPackId) public view returns (uint);
    function getCoversForPacks(uint [] _packIds) public view returns (bytes32[]);
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





contract Functions {

    bytes32[] public randomHashes;

    function fillWithHashes() public {
        require(randomHashes.length == 0);

        for (uint i = block.number - 100; i < block.number; i++) {
            randomHashes.push(blockhash(i));
        }
    }

    /// @notice Function to calculate initial random seed based on our hashes
    /// @param _randomHashIds are ids in our array of hashes
    /// @param _timestamp is timestamp for that hash
    /// @return uint representation of random seed
    function calculateSeed(uint[] _randomHashIds, uint _timestamp) public view returns (uint) {
        require(_timestamp != 0);
        require(_randomHashIds.length == 10);

        bytes32 randomSeed = keccak256(
            abi.encodePacked(
            randomHashes[_randomHashIds[0]], randomHashes[_randomHashIds[1]],
            randomHashes[_randomHashIds[2]], randomHashes[_randomHashIds[3]],
            randomHashes[_randomHashIds[4]], randomHashes[_randomHashIds[5]],
            randomHashes[_randomHashIds[6]], randomHashes[_randomHashIds[7]],
            randomHashes[_randomHashIds[8]], randomHashes[_randomHashIds[9]],
            _timestamp
            )
        );

        return uint(randomSeed);
    }

    function getRandomHashesLength() public view returns(uint) {
        return randomHashes.length;
    }

    /// @notice Function which decodes bytes32 to array of integers
    /// @param _potentialAssets are potential assets user would like to have
    /// @return array of assetIds
    function decodeAssets(bytes32[] _potentialAssets) public pure returns (uint[] assets) {
        require(_potentialAssets.length > 0);

        uint[] memory assetsCopy = new uint[](_potentialAssets.length*10);
        uint numberOfAssets = 0;

        for (uint j = 0; j < _potentialAssets.length; j++) {
            uint input;
            bytes32 pot = _potentialAssets[j];

            assembly {
                input := pot
            }

            for (uint i = 10; i > 0; i--) {
                uint mask = (2 << ((i-1) * 24)) / 2;
                uint b = (input & (mask * 16777215)) / mask;

                if (b != 0) {
                    assetsCopy[numberOfAssets] = b;
                    numberOfAssets++;
                }
            }
        }

        assets = new uint[](numberOfAssets);
        for (i = 0; i < numberOfAssets; i++) {
            assets[i] = assetsCopy[i];
        }
    }

    /// @notice Function to pick random assets from potentialAssets array
    /// @param _finalSeed is final random seed
    /// @param _potentialAssets is bytes32[] array of potential assets
    /// @return uint[] array of randomly picked assets
    function pickRandomAssets(uint _finalSeed, bytes32[] _potentialAssets) public pure returns(uint[] finalPicked) {
        require(_finalSeed != 0);
        require(_potentialAssets.length > 0);

        uint[] memory assetIds = decodeAssets(_potentialAssets);
        uint[] memory pickedIds = new uint[](assetIds.length);

        uint finalSeedCopy = _finalSeed;
        uint index = 0;

        for (uint i = 0; i < assetIds.length; i++) {
            finalSeedCopy = uint(keccak256(abi.encodePacked(finalSeedCopy, assetIds[i])));
            if (finalSeedCopy % 2 == 0) {
                pickedIds[index] = assetIds[i];
                index++;
            }
        }

        finalPicked = new uint[](index);
        for (i = 0; i < index; i++) {
            finalPicked[i] = pickedIds[i];
        }
    }

    /// @notice Function to pick random assets from potentialAssets array
    /// @param _finalSeed is final random seed
    /// @param _potentialAssets is bytes32[] array of potential assets
    /// @param _width of canvas
    /// @param _height of canvas
    /// @return arrays of randomly picked assets defining ids, coordinates, zoom, rotation and layers
    function getImage(uint _finalSeed, bytes32[] _potentialAssets, uint _width, uint _height) public pure 
    returns(uint[] finalPicked, uint[] x, uint[] y, uint[] zoom, uint[] rotation, uint[] layers) {
        require(_finalSeed != 0);
        require(_potentialAssets.length > 0);

        uint[] memory assetIds = decodeAssets(_potentialAssets);
        uint[] memory pickedIds = new uint[](assetIds.length);
        x = new uint[](assetIds.length);
        y = new uint[](assetIds.length);
        zoom = new uint[](assetIds.length);
        rotation = new uint[](assetIds.length);
        layers = new uint[](assetIds.length);

        uint finalSeedCopy = _finalSeed;
        uint index = 0;

        for (uint i = 0; i < assetIds.length; i++) {
            finalSeedCopy = uint(keccak256(abi.encodePacked(finalSeedCopy, assetIds[i])));
            if (finalSeedCopy % 2 == 0) {
                pickedIds[index] = assetIds[i];
                (x[index], y[index], zoom[index], rotation[index], layers[index]) = pickRandomAssetPosition(finalSeedCopy, _width, _height);
                index++;
            }
        }

        finalPicked = new uint[](index);
        for (i = 0; i < index; i++) {
            finalPicked[i] = pickedIds[i];
        }
    }

    /// @notice Function to pick random position for an asset
    /// @param _randomSeed is random seed for that image
    /// @param _width of canvas
    /// @param _height of canvas
    /// @return tuple of uints representing x,y,zoom,and rotation
    function pickRandomAssetPosition(uint _randomSeed, uint _width, uint _height) public pure 
    returns (uint x, uint y, uint zoom, uint rotation, uint layer) {
        
        x = _randomSeed % _width;
        y = _randomSeed % _height;
        zoom = _randomSeed % 200 + 800;
        rotation = _randomSeed % 360;
        // using random number for now
        // if two layers are same, sort by (keccak256(layer, assetId))
        layer = _randomSeed % 1234567; 
    }

    /// @notice Function to calculate final random seed for user
    /// @param _randomSeed is initially given random seed
    /// @param _iterations is number of iterations
    /// @return final seed for user as uint
    function getFinalSeed(uint _randomSeed, uint _iterations) public pure returns (bytes32) {
        require(_randomSeed != 0);
        require(_iterations != 0);
        bytes32 finalSeed = bytes32(_randomSeed);

        finalSeed = keccak256(abi.encodePacked(_randomSeed, _iterations));
        for (uint i = 0; i < _iterations; i++) {
            finalSeed = keccak256(abi.encodePacked(finalSeed, i));
        }

        return finalSeed;
    }

    function toHex(uint _randomSeed) public pure returns (bytes32) {
        return bytes32(_randomSeed);
    }
}





contract UserManager {

    struct User {
        string username;
        bytes32 hashToProfilePicture;
        bool exists;
    }

    uint public numberOfUsers;

    mapping(string => bool) internal usernameExists;
    mapping(address => User) public addressToUser;

    mapping(bytes32 => bool) public profilePictureExists;
    mapping(string => address) internal usernameToAddress;

    event NewUser(address indexed user, string username, bytes32 profilePicture);

    function register(string _username, bytes32 _hashToProfilePicture) public {
        require(usernameExists[_username] == false || 
                keccak256(abi.encodePacked(getUsername(msg.sender))) == keccak256(abi.encodePacked(_username))
        );

        if (usernameExists[getUsername(msg.sender)]) {
            // if he already had username, that username is free now
            usernameExists[getUsername(msg.sender)] = false;
        } else {
            numberOfUsers++;
            emit NewUser(msg.sender, _username, _hashToProfilePicture);
        }

        addressToUser[msg.sender] = User({
            username: _username,
            hashToProfilePicture: _hashToProfilePicture,
            exists: true
        });

        usernameExists[_username] = true;
        profilePictureExists[_hashToProfilePicture] = true;
        usernameToAddress[_username] = msg.sender;
    }

    function changeProfilePicture(bytes32 _hashToProfilePicture) public {
        require(addressToUser[msg.sender].exists, "User doesn&#39;t exists");

        addressToUser[msg.sender].hashToProfilePicture = _hashToProfilePicture;
    }

    function getUserInfo(address _address) public view returns(string, bytes32) {
        User memory user = addressToUser[_address];
        return (user.username, user.hashToProfilePicture);
    }

    function getUsername(address _address) public view returns(string) {
        return addressToUser[_address].username;
    } 

    function getProfilePicture(address _address) public view returns(bytes32) {
        return addressToUser[_address].hashToProfilePicture;
    }

    function isUsernameExists(string _username) public view returns(bool) {
        return usernameExists[_username];
    }

}


contract DigitalPrintImage is ERC721Token("DigitalPrintImage", "DPM"), UserManager, Ownable {

    struct ImageMetadata {
        uint finalSeed;
        bytes32[] potentialAssets;
        uint timestamp;
        address creator;
        string ipfsHash;
        string extraData;
    }

    mapping(uint => bool) public seedExists;
    mapping(uint => ImageMetadata) public imageMetadata;
    mapping(uint => string) public idToIpfsHash;

    address public marketplaceContract;
    IAssetManager public assetManager;
    Functions public functions;

    modifier onlyMarketplaceContract() {
        require(msg.sender == address(marketplaceContract));
        _;
    }

    event ImageCreated(uint indexed imageId, address indexed owner);
    /// @dev only for testing purposes
    // function createImageTest() public {
    //     _mint(msg.sender, totalSupply());
    // }

    /// @notice Function will create new image
    /// @param _randomHashIds is array of random hashes from our array
    /// @param _timestamp is timestamp when image is created
    /// @param _iterations is number of how many times he generated random asset positions until he liked what he got
    /// @param _potentialAssets is set of all potential assets user selected for an image
    /// @param _author is nickname of image owner
    /// @param _ipfsHash is ipfsHash of the image .png
    /// @param _extraData string containing ipfsHash that contains (frame,width,height,title,description)
    /// @return returns id of created image
    function createImage(
        uint[] _randomHashIds,
        uint _timestamp,
        uint _iterations,
        bytes32[] _potentialAssets,
        string _author,
        string _ipfsHash,
        string _extraData) public payable {
        require(_potentialAssets.length <= 5);
        // if user exists send his username, if it doesn&#39;t check for some username that doesn&#39;t exists
        require(msg.sender == usernameToAddress[_author] || !usernameExists[_author]);

        // if user doesn&#39;t exists create that user with no profile picture
        if (!usernameExists[_author]) {
            register(_author, bytes32(0));
        }

        uint[] memory pickedAssets;
        uint finalSeed;
       
        (pickedAssets, finalSeed) = getPickedAssetsAndFinalSeed(_potentialAssets, _randomHashIds, _timestamp, _iterations); 
        uint[] memory pickedAssetPacks = assetManager.pickUniquePacks(pickedAssets);
        uint finalPrice = 0;

        for (uint i = 0; i < pickedAssetPacks.length; i++) {
            if (assetManager.checkHasPermissionForPack(msg.sender, pickedAssetPacks[i]) == false) {
                finalPrice += assetManager.getAssetPackPrice(pickedAssetPacks[i]);

                assetManager.buyAssetPack.value(assetManager.getAssetPackPrice(pickedAssetPacks[i]))(msg.sender, pickedAssetPacks[i]);
            }
        }
        
        require(msg.value >= finalPrice);

        uint id = totalSupply();
        _mint(msg.sender, id);

        imageMetadata[id] = ImageMetadata({
            finalSeed: finalSeed,
            potentialAssets: _potentialAssets,
            timestamp: _timestamp,
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            extraData: _extraData
        });

        idToIpfsHash[id] = _ipfsHash;
        seedExists[finalSeed] = true;

        emit ImageCreated(id, msg.sender);
    }

    /// @notice approving image to be taken from specific address
    /// @param _from address from which we transfer image
    /// @param _to address that we give permission to take image
    /// @param _imageId we are willing to give
    function transferFromMarketplace(address _from, address _to, uint256 _imageId) public onlyMarketplaceContract {
        require(isApprovedOrOwner(_from, _imageId));

        clearApproval(_from, _imageId);
        removeTokenFrom(_from, _imageId);
        addTokenTo(_to, _imageId);

        emit Transfer(_from, _to, _imageId);
    }

    /// @notice adds marketplace address to contract only if it doesn&#39;t already exist
    /// @param _marketplaceContract address of marketplace contract
    function addMarketplaceContract(address _marketplaceContract) public onlyOwner {
        require(address(marketplaceContract) == 0x0);
        
        marketplaceContract = _marketplaceContract;
    }

    /// @notice Function to add assetManager
    /// @param _assetManager is address of assetManager contract
    function addAssetManager(address _assetManager) public onlyOwner {
        require(address(assetManager) == 0x0);

        assetManager = IAssetManager(_assetManager);
    }

    /// @notice Function to add functions contract
    /// @param _functions is address of functions contract
    function addFunctions(address _functions) public onlyOwner {
        require(address(functions) == 0x0);

        functions = Functions(_functions);
    }

    /// @notice Function to calculate final price for an image based on selected assets
    /// @param _pickedAssets is array of picked packs
    /// @param _owner is address of image owner
    /// @return finalPrice for the image
    function calculatePrice(uint[] _pickedAssets, address _owner) public view returns (uint) {
        if (_pickedAssets.length == 0) {
            return 0;
        }

        uint[] memory pickedAssetPacks = assetManager.pickUniquePacks(_pickedAssets);
        uint finalPrice = 0;
        for (uint i = 0; i < pickedAssetPacks.length; i++) {
            if (assetManager.checkHasPermissionForPack(_owner, pickedAssetPacks[i]) == false) {
                finalPrice += assetManager.getAssetPackPrice(pickedAssetPacks[i]);
            }
        }

        return finalPrice;
    }

    /// @notice Method returning informations needed for gallery page
    /// @param _imageId id of image 
    function getGalleryData(uint _imageId) public view 
    returns(address, address, string, bytes32, string, string) {
        require(_imageId < totalSupply());

        return(
            imageMetadata[_imageId].creator,
            ownerOf(_imageId),
            addressToUser[ownerOf(_imageId)].username,
            addressToUser[ownerOf(_imageId)].hashToProfilePicture,
            imageMetadata[_imageId].ipfsHash,
            imageMetadata[_imageId].extraData
        );

    }

    /// @notice returns metadata of image
    /// @dev not possible to use public mapping because of array of bytes32
    /// @param _imageId id of image
    function getImageMetadata(uint _imageId) public view
    returns(address, string, uint, string, uint, bytes32[]) {
        ImageMetadata memory metadata = imageMetadata[_imageId];

        return(
            metadata.creator,
            metadata.extraData,
            metadata.finalSeed,
            metadata.ipfsHash,
            metadata.timestamp,
            metadata.potentialAssets
        );
    }

    /// @notice returns all images owned by _user
    /// @param _user address of user
    function getUserImages(address _user) public view returns(uint[]) {
        return ownedTokens[_user];
    }

    /// @notice returns picked assets from potential assets and final seed
    /// @param _potentialAssets array of all potential assets encoded in bytes32
    /// @param _randomHashIds selected random hash ids from our contract
    /// @param _timestamp timestamp of image creation
    /// @param _iterations number of iterations to get to final seed
    function getPickedAssetsAndFinalSeed(bytes32[] _potentialAssets, uint[] _randomHashIds, uint _timestamp, uint _iterations) internal view returns(uint[], uint) {
        uint finalSeed = uint(functions.getFinalSeed(functions.calculateSeed(_randomHashIds, _timestamp), _iterations));

        require(!seedExists[finalSeed]);

        return (functions.pickRandomAssets(finalSeed, _potentialAssets), finalSeed);
    }

}



contract Marketplace is Ownable {

    struct Ad {
        uint price;
        address exchanger;
        bool exists;
        bool active;
    }

    DigitalPrintImage public digitalPrintImageContract;

    uint public creatorPercentage = 3; // 3 percentage
    uint public marketplacePercentage = 2; // 2 percentage
    uint public numberOfAds;
    uint[] public allAds;
    //image id to Ad
    mapping(uint => Ad) public sellAds;
    mapping(address => uint) public balances;

    constructor(address _digitalPrintImageContract) public {
        digitalPrintImageContract = DigitalPrintImage(_digitalPrintImageContract);
        numberOfAds = 0;
    }

    event SellingImage(uint indexed imageId, uint price);
    event ImageBought(uint indexed imageId, address indexed newOwner, uint price);

    /// @notice Function to add image on marketplace
    /// @dev only image owner can add image to marketplace
    /// @param _imageId is id of image
    /// @param _price is price for which we are going to sell image
    function sell(uint _imageId, uint _price) public {
        require(digitalPrintImageContract.ownerOf(_imageId) == msg.sender);

        bool exists = sellAds[_imageId].exists;

        sellAds[_imageId] = Ad({
            price: _price,
            exchanger: msg.sender,
            exists: true,
            active: true
        });

        if (!exists) {
            numberOfAds++;
            allAds.push(_imageId);
        }

        emit SellingImage(_imageId, _price);
    }
    
    function getActiveAds() public view returns (uint[], uint[]) {
        uint count;
        for (uint i = 0; i < numberOfAds; i++) {
            // active on sale are only those that exists and its still the same owner
            if (isImageOnSale(allAds[i])) {
                count++;
            }
        }

        uint[] memory imageIds = new uint[](count);
        uint[] memory prices = new uint[](count);
        count = 0;
        for (i = 0; i < numberOfAds; i++) {
            Ad memory ad = sellAds[allAds[i]];
            // active on sale are only those that exists and its still the same owner
            if (isImageOnSale(allAds[i])) {
                imageIds[count] = allAds[i];
                prices[count] = ad.price;
                count++;
            }
        }

        return (imageIds, prices);
    }

    function isImageOnSale(uint _imageId) public view returns(bool) {
        Ad memory ad = sellAds[_imageId];

        return ad.exists && ad.active && (ad.exchanger == digitalPrintImageContract.ownerOf(_imageId));
    }

    /// @notice Function to buy image from Marketplace
    /// @param _imageId is Id of image we are going to buy
    function buy(uint _imageId) public payable {
        require(isImageOnSale(_imageId));
        require(msg.value >= sellAds[_imageId].price);

        removeOrder(_imageId);

        address _creator;
        address _imageOwner = digitalPrintImageContract.ownerOf(_imageId);
        (, , _creator, ,) = digitalPrintImageContract.imageMetadata(_imageId);

        balances[_creator] += msg.value * 2 / 100;
        balances[owner] += msg.value * 3 / 100;
        balances[_imageOwner] += msg.value * 95 / 100;

        digitalPrintImageContract.transferFromMarketplace(sellAds[_imageId].exchanger, msg.sender, _imageId);

        emit ImageBought(_imageId, msg.sender, msg.value);
    }

    /// @notice Function to remove image from Marketplace
    /// @dev image can be withdrawed only by its owner
    /// @param _imageId is id of image we would like to get back
    function cancel(uint _imageId) public {
        require(sellAds[_imageId].exists == true);
        require(sellAds[_imageId].exchanger == msg.sender);
        require(sellAds[_imageId].active == true);

        removeOrder(_imageId);
    }

    function withdraw() public {
        
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

    /// @notice Removes image from imgagesOnSale list
    /// @param _imageId is id of image we want to remove
    function removeOrder(uint _imageId) private {
        sellAds[_imageId].active = false;
    }
}