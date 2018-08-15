pragma solidity 0.4.24;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  ///bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

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
   * @return `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
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

contract MyCryptoChampCore{
    struct Champ {
        uint id;
        uint attackPower;
        uint defencePower;
        uint cooldownTime; 
        uint readyTime;
        uint winCount;
        uint lossCount;
        uint position; 
        uint price; 
        uint withdrawCooldown; 
        uint eq_sword; 
        uint eq_shield; 
        uint eq_helmet; 
        bool forSale; 
    }
    
    struct AddressInfo {
        uint withdrawal;
        uint champsCount;
        uint itemsCount;
        string name;
    }

    struct Item {
        uint id;
        uint8 itemType; 
        uint8 itemRarity; 
        uint attackPower;
        uint defencePower;
        uint cooldownReduction;
        uint price;
        uint onChampId; 
        bool onChamp; 
        bool forSale;
    }
    
    Champ[] public champs;
    Item[] public items;
    mapping (uint => uint) public leaderboard;
    mapping (address => AddressInfo) public addressInfo;
    mapping (bool => mapping(address => mapping (address => bool))) public tokenOperatorApprovals;
    mapping (bool => mapping(uint => address)) public tokenApprovals;
    mapping (bool => mapping(uint => address)) public tokenToOwner;
    mapping (uint => string) public champToName;
    mapping (bool => uint) public tokensForSaleCount;
    uint public pendingWithdrawal = 0;

    function addWithdrawal(address _address, uint _amount) public;
    function clearTokenApproval(address _from, uint _tokenId, bool _isTokenChamp) public;
    function setChampsName(uint _champId, string _name) public;
    function setLeaderboard(uint _x, uint _value) public;
    function setTokenApproval(uint _id, address _to, bool _isTokenChamp) public;
    function setTokenOperatorApprovals(address _from, address _to, bool _approved, bool _isTokenChamp) public;
    function setTokenToOwner(uint _id, address _owner, bool _isTokenChamp) public;
    function setTokensForSaleCount(uint _value, bool _isTokenChamp) public;
    function transferToken(address _from, address _to, uint _id, bool _isTokenChamp) public;
    function newChamp(uint _attackPower,uint _defencePower,uint _cooldownTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale,address _owner) public returns (uint);
    function newItem(uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale,address _owner) public returns (uint);
    function updateAddressInfo(address _address, uint _withdrawal, bool _updatePendingWithdrawal, uint _champsCount, bool _updateChampsCount, uint _itemsCount, bool _updateItemsCount, string _name, bool _updateName) public;
    function updateChamp(uint _champId, uint _attackPower,uint _defencePower,uint _cooldownTime,uint _readyTime,uint _winCount,uint _lossCount,uint _position,uint _price,uint _withdrawCooldown,uint _eq_sword, uint _eq_shield, uint _eq_helmet, bool _forSale) public;
    function updateItem(uint _id,uint8 _itemType,uint8 _itemRarity,uint _attackPower,uint _defencePower,uint _cooldownReduction,uint _price,uint _onChampId,bool _onChamp,bool _forSale) public;

    function getChampStats(uint256 _champId) public view returns(uint256,uint256,uint256);
    function getChampsByOwner(address _owner) external view returns(uint256[]);
    function getTokensForSale(bool _isTokenChamp) view external returns(uint256[]);
    function getItemsByOwner(address _owner) external view returns(uint256[]);
    function getTokenCount(bool _isTokenChamp) external view returns(uint);
    function getTokenURIs(uint _tokenId, bool _isTokenChamp) public view returns(string);
    function onlyApprovedOrOwnerOfToken(uint _id, address _msgsender, bool _isTokenChamp) external view returns(bool);
    
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal contractOwner;

  constructor () internal {
    if(contractOwner == address(0)){
      contractOwner = msg.sender;
    }
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }
  

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    contractOwner = newOwner;
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


contract ERC721 is Ownable, SupportsInterfaceWithLookup {

  using AddressUtils for address;

  string private _ERC721name = "Champ";
  string private _ERC721symbol = "MXC";
  bool private tokenIsChamp = true;
  address private controllerAddress;
  MyCryptoChampCore core;

  function setCore(address newCoreAddress) public onlyOwner {
    core = MyCryptoChampCore(newCoreAddress);
  }

  function setController(address _address) external onlyOwner {
    controllerAddress = _address;
  }

  function emitTransfer(address _from, address _to, uint _tokenId) external {
    require(msg.sender == controllerAddress);
    emit Transfer(_from, _to, _tokenId);
  }

  //ERC721 START
  event Transfer(address indexed _from, address indexed _to, uint indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
  /**
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
  /**
   * 0x4f558e79 ===
   *   bytes4(keccak256(&#39;exists(uint256)&#39;))
   */

   /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
  
  bytes4 constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
      bytes4(keccak256(&#39;totalSupply()&#39;)) ^
      bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
      bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;));
  */

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
     * 0x5b5e139f ===
     *   bytes4(keccak256(&#39;name()&#39;)) ^
     *   bytes4(keccak256(&#39;symbol()&#39;)) ^
     *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
  */

   constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }


  /**
 * @dev Guarantees msg.sender is owner of the given token
 * @param _tokenId uint ID of the token to validate its ownership belongs to msg.sender
 */
  modifier onlyOwnerOf(uint _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
 * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
 * @param _tokenId uint ID of the token to validate
 */
  modifier canTransfer(uint _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
}

  /**
 * @dev Gets the balance of the specified address
 * @param _owner address to query the balance of
 * @return uint representing the amount owned by the passed address
 */
  function balanceOf(address _owner) public view returns (uint) {
    require(_owner != address(0));
    uint balance;
    if(tokenIsChamp){
      (,balance,,) = core.addressInfo(_owner);
    }else{
      (,,balance,) = core.addressInfo(_owner);
    }
    return balance;
}

  /**
 * @dev Gets the owner of the specified token ID
 * @param _tokenId uint ID of the token to query the owner of
 * @return owner address currently marked as the owner of the given token ID
 */
function ownerOf(uint _tokenId) public view returns (address) {
    address owner = core.tokenToOwner(tokenIsChamp,_tokenId);
    require(owner != address(0));
    return owner;
}


/**
 * @dev Returns whether the specified token exists
 * @param _tokenId uint ID of the token to query the existence of
 * @return whether the token exists
 */
function exists(uint _tokenId) public view returns (bool) {
    address owner = core.tokenToOwner(tokenIsChamp,_tokenId);
    return owner != address(0);
}

/**
 * @dev Approves another address to transfer the given token ID
 * The zero address indicates there is no approved address.
 * There can only be one approved address per token at a given time.
 * Can only be called by the token owner or an approved operator.
 * @param _to address to be approved for the given token ID
 * @param _tokenId uint ID of the token to be approved
 */
function approve(address _to, uint _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    core.setTokenApproval(_tokenId, _to,tokenIsChamp);
    emit Approval(owner, _to, _tokenId);
 }

/**
 * @dev Gets the approved address for a token ID, or zero if no address set
 * @param _tokenId uint ID of the token to query the approval of
 * @return address currently approved for the given token ID
 */
  function getApproved(uint _tokenId) public view returns (address) {
    return core.tokenApprovals(tokenIsChamp,_tokenId);
  }

/**
 * @dev Sets or unsets the approval of a given operator
 * An operator is allowed to transfer all tokens of the sender on their behalf
 * @param _to operator address to set the approval
 * @param _approved representing the status of the approval to be set
 */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    core.setTokenOperatorApprovals(msg.sender,_to,_approved,tokenIsChamp);
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
    return core.tokenOperatorApprovals(tokenIsChamp, _owner,_operator);
}

/**
 * @dev Returns whether the given spender can transfer a given token ID
 * @param _spender address of the spender to query
 * @param _tokenId uint ID of the token to be transferred
 * @return bool whether the msg.sender is approved for the given token ID,
 *  is an operator of the owner, or is the owner of the token
 */
function isApprovedOrOwner(
    address _spender,
    uint _tokenId
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
 * @dev Transfers the ownership of a given token ID to another address
 * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
 * Requires the msg sender to be the owner, approved, or operator
 * @param _from current owner of the token
 * @param _to address to receive the ownership of the given token ID
 * @param _tokenId uint ID of the token to be transferred
*/
function transferFrom(
    address _from,
    address _to,
    uint _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    core.clearTokenApproval(_from, _tokenId, tokenIsChamp);
    core.transferToken(_from, _to, _tokenId, tokenIsChamp);

    emit Transfer(_from, _to, _tokenId);
}

/**
 * @dev Safely transfers the ownership of a given token ID to another address
 * If the target address is a contract, it must implement `onERC721Received`,
 * which is called upon a safe transfer, and return the magic value
 * `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`; otherwise,
 * the transfer is reverted.
 *
 * Requires the msg sender to be the owner, approved, or operator
 * @param _from current owner of the token
 * @param _to address to receive the ownership of the given token ID
 * @param _tokenId uint ID of the token to be transferred
*/
function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId
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
   * `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId,
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
 * @dev Internal function to invoke `onERC721Received` on a target address
 * The call is not executed if the target address is not a contract
 * @param _from address representing the previous owner of the given token ID
 * @param _to target address that will receive the tokens
 * @param _tokenId uint ID of the token to be transferred
 * @param _data bytes optional data to send along with the call
 * @return whether the call correctly returned the expected magic value
 */
function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint _tokenId,
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

  ///
  /// ERC721Enumerable
  ///
  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint){
    return core.getTokenCount(tokenIsChamp);
  }

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint _index) external view returns (uint){
    uint tokenIndexesLength = this.totalSupply();
    require(_index < tokenIndexesLength);
    return _index;
  }

  
  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid NFTs.
  /// @param _owner An address where we are interested in NFTs owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint _index) external view returns (uint){
      require(_index >= balanceOf(_owner));
      require(_owner!=address(0));
      
      uint[] memory tokens;
      uint tokenId;
      
      if(tokenIsChamp){
          tokens = core.getChampsByOwner(_owner);
      }else{
          tokens = core.getItemsByOwner(_owner);
      }
      
      for(uint i = 0; i < tokens.length; i++){
          if(i + 1 == _index){
              tokenId = tokens[i];
              break;
          }
      }
      
      return tokenId;
  }
  
  
  ///
  /// ERC721Metadata
  ///
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string _name){
    return _ERC721name;
  }

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external view returns (string _symbol){
    return _ERC721symbol;
  }

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint _tokenId) external view returns (string){
    require(exists(_tokenId));
    return core.getTokenURIs(_tokenId,tokenIsChamp);
  }

}