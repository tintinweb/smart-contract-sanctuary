pragma solidity ^0.4.24;

contract CrabData {
  modifier crabDataLength(uint256[] memory _crabData) {
    require(_crabData.length == 8);
    _;
  }

  struct CrabPartData {
    uint256 hp;
    uint256 dps;
    uint256 blockRate;
    uint256 resistanceBonus;
    uint256 hpBonus;
    uint256 dpsBonus;
    uint256 blockBonus;
    uint256 mutiplierBonus;
  }

  function arrayToCrabPartData(
    uint256[] _partData
  ) 
    internal 
    pure 
    crabDataLength(_partData) 
    returns (CrabPartData memory _parsedData) 
  {
    _parsedData = CrabPartData(
      _partData[0],   // hp
      _partData[1],   // dps
      _partData[2],   // block rate
      _partData[3],   // resistance bonus
      _partData[4],   // hp bonus
      _partData[5],   // dps bonus
      _partData[6],   // block bonus
      _partData[7]);  // multiplier bonus
  }

  function crabPartDataToArray(CrabPartData _crabPartData) internal pure returns (uint256[] memory _resultData) {
    _resultData = new uint256[](8);
    _resultData[0] = _crabPartData.hp;
    _resultData[1] = _crabPartData.dps;
    _resultData[2] = _crabPartData.blockRate;
    _resultData[3] = _crabPartData.resistanceBonus;
    _resultData[4] = _crabPartData.hpBonus;
    _resultData[5] = _crabPartData.dpsBonus;
    _resultData[6] = _crabPartData.blockBonus;
    _resultData[7] = _crabPartData.mutiplierBonus;
  }
}

contract GeneSurgeon {
  //0 - filler, 1 - body, 2 - leg, 3 - left claw, 4 - right claw
  uint256[] internal crabPartMultiplier = [0, 10**9, 10**6, 10**3, 1];

  function extractElementsFromGene(uint256 _gene) internal view returns (uint256[] memory _elements) {
    _elements = new uint256[](4);
    _elements[0] = _gene / crabPartMultiplier[1] / 100 % 10;
    _elements[1] = _gene / crabPartMultiplier[2] / 100 % 10;
    _elements[2] = _gene / crabPartMultiplier[3] / 100 % 10;
    _elements[3] = _gene / crabPartMultiplier[4] / 100 % 10;
  }

  function extractPartsFromGene(uint256 _gene) internal view returns (uint256[] memory _parts) {
    _parts = new uint256[](4);
    _parts[0] = _gene / crabPartMultiplier[1] % 100;
    _parts[1] = _gene / crabPartMultiplier[2] % 100;
    _parts[2] = _gene / crabPartMultiplier[3] % 100;
    _parts[3] = _gene / crabPartMultiplier[4] % 100;
  }
}

interface GenesisCrabInterface {
  function generateCrabGene(bool isPresale, bool hasLegendaryPart) external returns (uint256 _gene, uint256 _skin, uint256 _heartValue, uint256 _growthValue);
  function mutateCrabPart(uint256 _part, uint256 _existingPartGene, uint256 _legendaryPercentage) external returns (uint256);
  function generateCrabHeart() external view returns (uint256, uint256);
}

contract LevelCalculator {
  event LevelUp(address indexed tokenOwner, uint256 indexed tokenId, uint256 currentLevel, uint256 currentExp);
  event ExpGained(address indexed tokenOwner, uint256 indexed tokenId, uint256 currentLevel, uint256 currentExp);

  function expRequiredToReachLevel(uint256 _level) internal pure returns (uint256 _exp) {
    require(_level > 1);

    uint256 _expRequirement = 10;
    for(uint256 i = 2 ; i < _level ; i++) {
      _expRequirement += 12;
    }
    _exp = _expRequirement;
  }
}

contract Randomable {
  // Generates a random number base on last block hash
  function _generateRandom(bytes32 seed) view internal returns (bytes32) {
    return keccak256(abi.encodePacked(blockhash(block.number-1), seed));
  }

  function _generateRandomNumber(bytes32 seed, uint256 max) view internal returns (uint256) {
    return uint256(_generateRandom(seed)) % max;
  }
}

contract CryptantCrabStoreInterface {
  function createAddress(bytes32 key, address value) external returns (bool);
  function createAddresses(bytes32[] keys, address[] values) external returns (bool);
  function updateAddress(bytes32 key, address value) external returns (bool);
  function updateAddresses(bytes32[] keys, address[] values) external returns (bool);
  function removeAddress(bytes32 key) external returns (bool);
  function removeAddresses(bytes32[] keys) external returns (bool);
  function readAddress(bytes32 key) external view returns (address);
  function readAddresses(bytes32[] keys) external view returns (address[]);
  // Bool related functions
  function createBool(bytes32 key, bool value) external returns (bool);
  function createBools(bytes32[] keys, bool[] values) external returns (bool);
  function updateBool(bytes32 key, bool value) external returns (bool);
  function updateBools(bytes32[] keys, bool[] values) external returns (bool);
  function removeBool(bytes32 key) external returns (bool);
  function removeBools(bytes32[] keys) external returns (bool);
  function readBool(bytes32 key) external view returns (bool);
  function readBools(bytes32[] keys) external view returns (bool[]);
  // Bytes32 related functions
  function createBytes32(bytes32 key, bytes32 value) external returns (bool);
  function createBytes32s(bytes32[] keys, bytes32[] values) external returns (bool);
  function updateBytes32(bytes32 key, bytes32 value) external returns (bool);
  function updateBytes32s(bytes32[] keys, bytes32[] values) external returns (bool);
  function removeBytes32(bytes32 key) external returns (bool);
  function removeBytes32s(bytes32[] keys) external returns (bool);
  function readBytes32(bytes32 key) external view returns (bytes32);
  function readBytes32s(bytes32[] keys) external view returns (bytes32[]);
  // uint256 related functions
  function createUint256(bytes32 key, uint256 value) external returns (bool);
  function createUint256s(bytes32[] keys, uint256[] values) external returns (bool);
  function updateUint256(bytes32 key, uint256 value) external returns (bool);
  function updateUint256s(bytes32[] keys, uint256[] values) external returns (bool);
  function removeUint256(bytes32 key) external returns (bool);
  function removeUint256s(bytes32[] keys) external returns (bool);
  function readUint256(bytes32 key) external view returns (uint256);
  function readUint256s(bytes32[] keys) external view returns (uint256[]);
  // int256 related functions
  function createInt256(bytes32 key, int256 value) external returns (bool);
  function createInt256s(bytes32[] keys, int256[] values) external returns (bool);
  function updateInt256(bytes32 key, int256 value) external returns (bool);
  function updateInt256s(bytes32[] keys, int256[] values) external returns (bool);
  function removeInt256(bytes32 key) external returns (bool);
  function removeInt256s(bytes32[] keys) external returns (bool);
  function readInt256(bytes32 key) external view returns (int256);
  function readInt256s(bytes32[] keys) external view returns (int256[]);
  // internal functions
  function parseKey(bytes32 key) internal pure returns (bytes32);
  function parseKeys(bytes32[] _keys) internal pure returns (bytes32[]);
}

contract StoreRBAC {
  // stores: storeName -> key -> addr -> isAllowed
  mapping(uint256 => mapping (uint256 => mapping(address => bool))) private stores;

  // store names
  uint256 public constant STORE_RBAC = 1;
  uint256 public constant STORE_FUNCTIONS = 2;
  uint256 public constant STORE_KEYS = 3;
  // rbac roles
  uint256 public constant RBAC_ROLE_ADMIN = 1; // "admin"

  // events
  event RoleAdded(uint256 storeName, address addr, uint256 role);
  event RoleRemoved(uint256 storeName, address addr, uint256 role);

  constructor() public {
    addRole(STORE_RBAC, msg.sender, RBAC_ROLE_ADMIN);
  }

  function hasRole(uint256 storeName, address addr, uint256 role) public view returns (bool) {
    return stores[storeName][role][addr];
  }

  function checkRole(uint256 storeName, address addr, uint256 role) public view {
    require(hasRole(storeName, addr, role));
  }

  function addRole(uint256 storeName, address addr, uint256 role) internal {
    stores[storeName][role][addr] = true;

    emit RoleAdded(storeName, addr, role);
  }

  function removeRole(uint256 storeName, address addr, uint256 role) internal {
    stores[storeName][role][addr] = false;

    emit RoleRemoved(storeName, addr, role);
  }

  function adminAddRole(uint256 storeName, address addr, uint256 role) onlyAdmin public {
    addRole(storeName, addr, role);
  }

  function adminRemoveRole(uint256 storeName, address addr, uint256 role) onlyAdmin public {
    removeRole(storeName, addr, role);
  }

  modifier onlyRole(uint256 storeName, uint256 role) {
    checkRole(storeName, msg.sender, role);
    _;
  }

  modifier onlyAdmin() {
    checkRole(STORE_RBAC, msg.sender, RBAC_ROLE_ADMIN);
    _;
  }
}

contract FunctionProtection is StoreRBAC { 
  // standard roles
  uint256 constant public FN_ROLE_CREATE = 2; // create
  uint256 constant public FN_ROLE_UPDATE = 3; // update
  uint256 constant public FN_ROLE_REMOVE = 4; // remove

  function canCreate() internal view returns (bool) {
    return hasRole(STORE_FUNCTIONS, msg.sender, FN_ROLE_CREATE);
  }
  
  function canUpdate() internal view returns (bool) {
    return hasRole(STORE_FUNCTIONS, msg.sender, FN_ROLE_UPDATE);
  }
  
  function canRemove() internal view returns (bool) {
    return hasRole(STORE_FUNCTIONS, msg.sender, FN_ROLE_REMOVE);
  }

  // external functions
  function applyAllPermission(address _address) external onlyAdmin {
    addRole(STORE_FUNCTIONS, _address, FN_ROLE_CREATE);
    addRole(STORE_FUNCTIONS, _address, FN_ROLE_UPDATE);
    addRole(STORE_FUNCTIONS, _address, FN_ROLE_REMOVE);
  }
}

contract CryptantCrabMarketStore is FunctionProtection {
  // Structure of each traded record
  struct TradeRecord {
    uint256 tokenId;
    uint256 auctionId;
    uint256 price;
    uint48 time;
    address owner;
    address seller;
  }

  // Structure of each trading item
  struct AuctionItem {
    uint256 tokenId;
    uint256 basePrice;
    address seller;
    uint48 startTime;
    uint48 endTime;
    uint8 state;              // 0 - on going, 1 - cancelled, 2 - claimed
    uint256[] bidIndexes;     // storing bidId
  }

  struct Bid {
    uint256 auctionId;
    uint256 price;
    uint48 time;
    address bidder;
  }

  // Structure to store withdrawal information
  struct WithdrawalRecord {
    uint256 auctionId;
    uint256 value;
    uint48 time;
    uint48 callTime;
    bool hasWithdrawn;
  }

  // stores awaiting withdrawal information
  mapping(address => WithdrawalRecord[]) public withdrawalList;

  // stores last withdrawal index
  mapping(address => uint256) public lastWithdrawnIndex;

  // All traded records will be stored here
  TradeRecord[] public tradeRecords;

  // All auctioned items will be stored here
  AuctionItem[] public auctionItems;

  Bid[] public bidHistory;

  event TradeRecordAdded(address indexed seller, address indexed buyer, uint256 tradeId, uint256 price, uint256 tokenId, uint256 indexed auctionId);

  event AuctionItemAdded(address indexed seller, uint256 auctionId, uint256 basePrice, uint256 duration, uint256 tokenId);

  event AuctionBid(address indexed bidder, address indexed previousBidder, uint256 auctionId, uint256 bidPrice, uint256 bidIndex, uint256 tokenId, uint256 endTime);

  event PendingWithdrawalCleared(address indexed withdrawer, uint256 withdrawnAmount);

  constructor() public 
  {
    // auctionItems index 0 should be dummy, 
    // because TradeRecord might not have auctionId
    auctionItems.push(AuctionItem(0, 0, address(0), 0, 0, 0, new uint256[](1)));

    // tradeRecords index 0 will be dummy
    // just to follow the standards skipping the index 0
    tradeRecords.push(TradeRecord(0, 0, 0, 0, address(0), address(0)));

    // bidHistory index 0 will be dummy
    // just to follow the standards skipping the index 0
    bidHistory.push(Bid(0, 0, uint48(0), address(0)));
  }

  // external functions
  // getters
  function getWithdrawalList(address withdrawer) external view returns (
    uint256[] memory _auctionIds,
    uint256[] memory _values,
    uint256[] memory _times,
    uint256[] memory _callTimes,
    bool[] memory _hasWithdrawn
  ) {
    WithdrawalRecord[] storage withdrawalRecords = withdrawalList[withdrawer];
    _auctionIds = new uint256[](withdrawalRecords.length);
    _values = new uint256[](withdrawalRecords.length);
    _times = new uint256[](withdrawalRecords.length);
    _callTimes = new uint256[](withdrawalRecords.length);
    _hasWithdrawn = new bool[](withdrawalRecords.length);

    for(uint256 i = 0 ; i < withdrawalRecords.length ; i++) {
      WithdrawalRecord storage withdrawalRecord = withdrawalRecords[i];
      _auctionIds[i] = withdrawalRecord.auctionId;
      _values[i] = withdrawalRecord.value; 
      _times[i] = withdrawalRecord.time;
      _callTimes[i] = withdrawalRecord.callTime;
      _hasWithdrawn[i] = withdrawalRecord.hasWithdrawn;
    }
  }

  function getTradeRecord(uint256 _tradeId) external view returns (
    uint256 _tokenId,
    uint256 _auctionId,
    uint256 _price,
    uint256 _time,
    address _owner,
    address _seller
  ) {
    TradeRecord storage _tradeRecord = tradeRecords[_tradeId];
    _tokenId = _tradeRecord.tokenId;
    _auctionId = _tradeRecord.auctionId;
    _price = _tradeRecord.price;
    _time = _tradeRecord.time;
    _owner = _tradeRecord.owner;
    _seller = _tradeRecord.seller;
  }

  function totalTradeRecords() external view returns (uint256) {
    return tradeRecords.length - 1; // need to exclude the dummy
  }

  function getPricesOfLatestTradeRecords(uint256 amount) external view returns (uint256[] memory _prices) {
    _prices = new uint256[](amount);
    uint256 startIndex = tradeRecords.length - amount;

    for(uint256 i = 0 ; i < amount ; i++) {
      _prices[i] = tradeRecords[startIndex + i].price;
    }
  }

  function getAuctionItem(uint256 _auctionId) external view returns (
    uint256 _tokenId,
    uint256 _basePrice,
    address _seller,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _state,
    uint256[] _bidIndexes
  ) {
    AuctionItem storage _auctionItem = auctionItems[_auctionId];
    _tokenId = _auctionItem.tokenId;
    _basePrice = _auctionItem.basePrice;
    _seller = _auctionItem.seller;
    _startTime = _auctionItem.startTime;
    _endTime = _auctionItem.endTime;
    _state = _auctionItem.state;
    _bidIndexes = _auctionItem.bidIndexes;
  }

  function getAuctionItems(uint256[] _auctionIds) external view returns (
    uint256[] _tokenId,
    uint256[] _basePrice,
    address[] _seller,
    uint256[] _startTime,
    uint256[] _endTime,
    uint256[] _state,
    uint256[] _lastBidId
  ) {
    _tokenId = new uint256[](_auctionIds.length);
    _basePrice = new uint256[](_auctionIds.length);
    _startTime = new uint256[](_auctionIds.length);
    _endTime = new uint256[](_auctionIds.length);
    _state = new uint256[](_auctionIds.length);
    _lastBidId = new uint256[](_auctionIds.length);
    _seller = new address[](_auctionIds.length);

    for(uint256 i = 0 ; i < _auctionIds.length ; i++) {
      AuctionItem storage _auctionItem = auctionItems[_auctionIds[i]];
      _tokenId[i] = (_auctionItem.tokenId);
      _basePrice[i] = (_auctionItem.basePrice);
      _seller[i] = (_auctionItem.seller);
      _startTime[i] = (_auctionItem.startTime);
      _endTime[i] = (_auctionItem.endTime);
      _state[i] = (_auctionItem.state);

      for(uint256 j = _auctionItem.bidIndexes.length - 1 ; j > 0 ; j--) {
        if(_auctionItem.bidIndexes[j] > 0) {
          _lastBidId[i] = _auctionItem.bidIndexes[j];
          break;
        }
      }
    }
  }

  function totalAuctionItems() external view returns (uint256) {
    return auctionItems.length - 1; // need to exclude the dummy
  }

  function getBid(uint256 _bidId) external view returns (
    uint256 _auctionId,
    uint256 _price,
    uint256 _time,
    address _bidder
  ) {
    Bid storage _bid = bidHistory[_bidId];
    _auctionId = _bid.auctionId;
    _price = _bid.price;
    _time = _bid.time;
    _bidder = _bid.bidder;
  }

  function getBids(uint256[] _bidIds) external view returns (
    uint256[] _auctionId,
    uint256[] _price,
    uint256[] _time,
    address[] _bidder
  ) {
    _auctionId = new uint256[](_bidIds.length);
    _price = new uint256[](_bidIds.length);
    _time = new uint256[](_bidIds.length);
    _bidder = new address[](_bidIds.length);

    for(uint256 i = 0 ; i < _bidIds.length ; i++) {
      Bid storage _bid = bidHistory[_bidIds[i]];
      _auctionId[i] = _bid.auctionId;
      _price[i] = _bid.price;
      _time[i] = _bid.time;
      _bidder[i] = _bid.bidder;
    }
  }

  // setters 
  function addTradeRecord
  (
    uint256 _tokenId,
    uint256 _auctionId,
    uint256 _price,
    uint256 _time,
    address _buyer,
    address _seller
  ) 
  external 
  returns (uint256 _tradeId)
  {
    require(canUpdate());

    _tradeId = tradeRecords.length;
    tradeRecords.push(TradeRecord(_tokenId, _auctionId, _price, uint48(_time), _buyer, _seller));

    if(_auctionId > 0) {
      auctionItems[_auctionId].state = uint8(2);
    }

    emit TradeRecordAdded(_seller, _buyer, _tradeId, _price, _tokenId, _auctionId);
  }

  function addAuctionItem
  (
    uint256 _tokenId,
    uint256 _basePrice,
    address _seller,
    uint256 _endTime
  ) 
  external
  returns (uint256 _auctionId)
  {
    require(canUpdate());

    _auctionId = auctionItems.length;
    auctionItems.push(AuctionItem(
      _tokenId,
      _basePrice, 
      _seller, 
      uint48(now), 
      uint48(_endTime),
      0,
      new uint256[](21)));

    emit AuctionItemAdded(_seller, _auctionId, _basePrice, _endTime - now, _tokenId);
  }

  function updateAuctionTime(uint256 _auctionId, uint256 _time, uint256 _state) external {
    require(canUpdate());

    AuctionItem storage _auctionItem = auctionItems[_auctionId];
    _auctionItem.endTime = uint48(_time);
    _auctionItem.state = uint8(_state);
  }

  function addBidder(uint256 _auctionId, address _bidder, uint256 _price, uint256 _bidIndex) external {
    require(canUpdate());

    uint256 _bidId = bidHistory.length;
    bidHistory.push(Bid(_auctionId, _price, uint48(now), _bidder));

    AuctionItem storage _auctionItem = auctionItems[_auctionId];

    // find previous bidder
    // Max bid index is 20, so maximum loop is 20 times
    address _previousBidder = address(0);
    for(uint256 i = _auctionItem.bidIndexes.length - 1 ; i > 0 ; i--) {
      if(_auctionItem.bidIndexes[i] > 0) {
        Bid memory _previousBid = bidHistory[_auctionItem.bidIndexes[i]];
        _previousBidder = _previousBid.bidder;
        break;
      }
    }

    _auctionItem.bidIndexes[_bidIndex] = _bidId;

    emit AuctionBid(_bidder, _previousBidder, _auctionId, _price, _bidIndex, _auctionItem.tokenId, _auctionItem.endTime);
  }

  function addWithdrawal
  (
    address _withdrawer,
    uint256 _auctionId,
    uint256 _value,
    uint256 _callTime
  )
  external 
  {
    require(canUpdate());

    WithdrawalRecord memory _withdrawal = WithdrawalRecord(_auctionId, _value, uint48(now), uint48(_callTime), false); 
    withdrawalList[_withdrawer].push(_withdrawal);
  }

  function clearPendingWithdrawal(address _withdrawer) external returns (uint256 _withdrawnAmount) {
    require(canUpdate());

    WithdrawalRecord[] storage _withdrawalList = withdrawalList[_withdrawer];
    uint256 _lastWithdrawnIndex = lastWithdrawnIndex[_withdrawer];

    for(uint256 i = _lastWithdrawnIndex ; i < _withdrawalList.length ; i++) {
      WithdrawalRecord storage _withdrawalRecord = _withdrawalList[i];
      _withdrawalRecord.hasWithdrawn = true;
      _withdrawnAmount += _withdrawalRecord.value;
    }

    // update the last withdrawn index so next time will start from this index
    lastWithdrawnIndex[_withdrawer] = _withdrawalList.length - 1;

    emit PendingWithdrawalCleared(_withdrawer, _withdrawnAmount);
  }
}

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

contract CryptantCrabBase is Ownable {
  GenesisCrabInterface public genesisCrab;
  CryptantCrabNFT public cryptantCrabToken;
  CryptantCrabStoreInterface public cryptantCrabStorage;

  constructor(address _genesisCrabAddress, address _cryptantCrabTokenAddress, address _cryptantCrabStorageAddress) public {
    // constructor
    
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);
  }

  function setAddresses(
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  external onlyOwner {
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);
  }

  function _setAddresses(
    address _genesisCrabAddress,
    address _cryptantCrabTokenAddress,
    address _cryptantCrabStorageAddress
  )
  internal 
  {
    if(_genesisCrabAddress != address(0)) {
      GenesisCrabInterface genesisCrabContract = GenesisCrabInterface(_genesisCrabAddress);
      genesisCrab = genesisCrabContract;
    }
    
    if(_cryptantCrabTokenAddress != address(0)) {
      CryptantCrabNFT cryptantCrabTokenContract = CryptantCrabNFT(_cryptantCrabTokenAddress);
      cryptantCrabToken = cryptantCrabTokenContract;
    }
    
    if(_cryptantCrabStorageAddress != address(0)) {
      CryptantCrabStoreInterface cryptantCrabStorageContract = CryptantCrabStoreInterface(_cryptantCrabStorageAddress);
      cryptantCrabStorage = cryptantCrabStorageContract;
    }
  }
}

contract CryptantCrabInformant is CryptantCrabBase{
  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabBase
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
    // constructor

  }

  function _getCrabData(uint256 _tokenId) internal view returns 
  (
    uint256 _gene, 
    uint256 _level, 
    uint256 _exp, 
    uint256 _mutationCount,
    uint256 _trophyCount,
    uint256 _heartValue,
    uint256 _growthValue
  ) {
    require(cryptantCrabStorage != address(0));

    bytes32[] memory keys = new bytes32[](7);
    uint256[] memory values;

    keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    keys[2] = keccak256(abi.encodePacked(_tokenId, "exp"));
    keys[3] = keccak256(abi.encodePacked(_tokenId, "mutationCount"));
    keys[4] = keccak256(abi.encodePacked(_tokenId, "trophyCount"));
    keys[5] = keccak256(abi.encodePacked(_tokenId, "heartValue"));
    keys[6] = keccak256(abi.encodePacked(_tokenId, "growthValue"));

    values = cryptantCrabStorage.readUint256s(keys);

    // process heart value
    uint256 _processedHeartValue;
    for(uint256 i = 1 ; i <= 1000 ; i *= 10) {
      if(uint256(values[5]) / i % 10 > 0) {
        _processedHeartValue += i;
      }
    }

    _gene = values[0];
    _level = values[1];
    _exp = values[2];
    _mutationCount = values[3];
    _trophyCount = values[4];
    _heartValue = _processedHeartValue;
    _growthValue = values[6];
  }

  function _geneOfCrab(uint256 _tokenId) internal view returns (uint256 _gene) {
    require(cryptantCrabStorage != address(0));

    _gene = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, "gene")));
  }
}

contract CrabManager is CryptantCrabInformant, CrabData {
  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
    // constructor
  }

  function getCrabsOfOwner(address _owner) external view returns (uint256[]) {
    uint256 _balance = cryptantCrabToken.balanceOf(_owner);
    uint256[] memory _tokenIds = new uint256[](_balance);

    for(uint256 i = 0 ; i < _balance ; i++) {
      _tokenIds[i] = cryptantCrabToken.tokenOfOwnerByIndex(_owner, i);
    }

    return _tokenIds;
  }

  function getCrab(uint256 _tokenId) external view returns (
    uint256 _gene,
    uint256 _level,
    uint256 _exp,
    uint256 _mutationCount,
    uint256 _trophyCount,
    uint256 _heartValue,
    uint256 _growthValue,
    uint256 _fossilType
  ) {
    require(cryptantCrabToken.exists(_tokenId));

    (_gene, _level, _exp, _mutationCount, _trophyCount, _heartValue, _growthValue) = _getCrabData(_tokenId);
    _fossilType = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, "fossilType")));
  }

  function getCrabStats(uint256 _tokenId) external view returns (
    uint256 _hp,
    uint256 _dps,
    uint256 _block,
    uint256[] _partBonuses,
    uint256 _fossilAttribute
  ) {
    require(cryptantCrabToken.exists(_tokenId));

    uint256 _gene = _geneOfCrab(_tokenId);
    (_hp, _dps, _block) = _getCrabTotalStats(_gene);
    _partBonuses = _getCrabPartBonuses(_tokenId);
    _fossilAttribute = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, "fossilAttribute")));
  }

  function _getCrabTotalStats(uint256 _gene) internal view returns (
    uint256 _hp, 
    uint256 _dps,
    uint256 _blockRate
  ) {
    CrabPartData[] memory crabPartData = _getCrabPartData(_gene);

    for(uint256 i = 0 ; i < crabPartData.length ; i++) {
      _hp += crabPartData[i].hp;
      _dps += crabPartData[i].dps;
      _blockRate += crabPartData[i].blockRate;
    }
  }

  function _getCrabPartBonuses(uint256 _tokenId) internal view returns (uint256[] _partBonuses) {
    bytes32[] memory _keys = new bytes32[](4);
    _keys[0] = keccak256(abi.encodePacked(_tokenId, uint256(1), "partBonus"));
    _keys[1] = keccak256(abi.encodePacked(_tokenId, uint256(2), "partBonus"));
    _keys[2] = keccak256(abi.encodePacked(_tokenId, uint256(3), "partBonus"));
    _keys[3] = keccak256(abi.encodePacked(_tokenId, uint256(4), "partBonus"));
    _partBonuses = cryptantCrabStorage.readUint256s(_keys);
  }

  function _getCrabPartData(uint256 _gene) internal view returns (CrabPartData[] memory _crabPartData) {
    require(cryptantCrabToken != address(0));
    uint256[] memory _bodyData;
    uint256[] memory _legData;
    uint256[] memory _leftClawData;
    uint256[] memory _rightClawData;
    
    (_bodyData, _legData, _leftClawData, _rightClawData) = cryptantCrabToken.crabPartDataFromGene(_gene);

    _crabPartData = new CrabPartData[](4);
    _crabPartData[0] = arrayToCrabPartData(_bodyData);
    _crabPartData[1] = arrayToCrabPartData(_legData);
    _crabPartData[2] = arrayToCrabPartData(_leftClawData);
    _crabPartData[3] = arrayToCrabPartData(_rightClawData);
  }
}

contract CryptantCrabPurchasableLaunch is CryptantCrabInformant {
  using SafeMath for uint256;

  Transmuter public transmuter;

  event CrabHatched(address indexed owner, uint256 tokenId, uint256 gene, uint256 specialSkin, uint256 crabPrice, uint256 growthValue);
  event CryptantFragmentsAdded(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event CryptantFragmentsRemoved(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event Refund(address indexed refundReceiver, uint256 reqAmt, uint256 paid, uint256 refundAmt);

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress
  ) 
  public 
  CryptantCrabInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
    // constructor
    if(_transmuterAddress != address(0)) {
      _setTransmuterAddress(_transmuterAddress);
    }
  }

  function setAddresses(
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress
  ) 
  external onlyOwner {
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);

    if(_transmuterAddress != address(0)) {
      _setTransmuterAddress(_transmuterAddress);
    }
  }

  function _setTransmuterAddress(address _transmuterAddress) internal {
    Transmuter _transmuterContract = Transmuter(_transmuterAddress);
    transmuter = _transmuterContract;
  }

  function getCryptantFragments(address _sender) public view returns (uint256) {
    return cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_sender, "cryptant")));
  }

  function createCrab(uint256 _customTokenId, uint256 _crabPrice, uint256 _customGene, uint256 _customSkin, bool _hasLegendary) external onlyOwner {
    _createCrab(_customTokenId, _crabPrice, _customGene, _customSkin, _hasLegendary);
  }
  function _addCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).add(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsAdded(_cryptantOwner, _amount, _newBalance);
  }

  function _removeCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).sub(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsRemoved(_cryptantOwner, _amount, _newBalance);
  }

  function _createCrab(uint256 _tokenId, uint256 _crabPrice, uint256 _customGene, uint256 _customSkin, bool _hasLegendary) internal {
    uint256[] memory _values = new uint256[](8);
    bytes32[] memory _keys = new bytes32[](8);

    uint256 _gene;
    uint256 _specialSkin;
    uint256 _heartValue;
    uint256 _growthValue;
    if(_customGene == 0) {
      (_gene, _specialSkin, _heartValue, _growthValue) = genesisCrab.generateCrabGene(false, _hasLegendary);
    } else {
      _gene = _customGene;
    }

    if(_customSkin != 0) {
      _specialSkin = _customSkin;
    }

    (_heartValue, _growthValue) = genesisCrab.generateCrabHeart();
    
    cryptantCrabToken.mintToken(msg.sender, _tokenId, _specialSkin);

    // Gene pair
    _keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    _values[0] = _gene;

    // Level pair
    _keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    _values[1] = 1;

    // Heart Value pair
    _keys[2] = keccak256(abi.encodePacked(_tokenId, "heartValue"));
    _values[2] = _heartValue;

    // Growth Value pair
    _keys[3] = keccak256(abi.encodePacked(_tokenId, "growthValue"));
    _values[3] = _growthValue;

    // Handling Legendary Bonus
    uint256[] memory _partLegendaryBonuses = transmuter.generateBonusForGene(_gene);
    // body
    _keys[4] = keccak256(abi.encodePacked(_tokenId, uint256(1), "partBonus"));
    _values[4] = _partLegendaryBonuses[0];

    // legs
    _keys[5] = keccak256(abi.encodePacked(_tokenId, uint256(2), "partBonus"));
    _values[5] = _partLegendaryBonuses[1];

    // left claw
    _keys[6] = keccak256(abi.encodePacked(_tokenId, uint256(3), "partBonus"));
    _values[6] = _partLegendaryBonuses[2];

    // right claw
    _keys[7] = keccak256(abi.encodePacked(_tokenId, uint256(4), "partBonus"));
    _values[7] = _partLegendaryBonuses[3];

    require(cryptantCrabStorage.createUint256s(_keys, _values));

    emit CrabHatched(msg.sender, _tokenId, _gene, _specialSkin, _crabPrice, _growthValue);
  }

  function _refundExceededValue(uint256 _senderValue, uint256 _requiredValue) internal {
    uint256 _exceededValue = _senderValue.sub(_requiredValue);

    if(_exceededValue > 0) {
      msg.sender.transfer(_exceededValue);

      emit Refund(msg.sender, _requiredValue, _senderValue, _exceededValue);
    } 
  }
}

contract CryptantInformant is CryptantCrabInformant {
  using SafeMath for uint256;

  event CryptantFragmentsAdded(address indexed cryptantOwner, uint256 amount, uint256 newBalance);
  event CryptantFragmentsRemoved(address indexed cryptantOwner, uint256 amount, uint256 newBalance);

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantCrabInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
    // constructor

  }

  function getCryptantFragments(address _sender) public view returns (uint256) {
    return cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_sender, "cryptant")));
  }

  function _addCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).add(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsAdded(_cryptantOwner, _amount, _newBalance);
  }

  function _removeCryptantFragments(address _cryptantOwner, uint256 _amount) internal returns (uint256 _newBalance) {
    _newBalance = getCryptantFragments(_cryptantOwner).sub(_amount);
    cryptantCrabStorage.updateUint256(keccak256(abi.encodePacked(_cryptantOwner, "cryptant")), _newBalance);
    emit CryptantFragmentsRemoved(_cryptantOwner, _amount, _newBalance);
  }
}

contract Transmuter is CryptantInformant, GeneSurgeon, Randomable, LevelCalculator {
  event Xenografted(address indexed tokenOwner, uint256 recipientTokenId, uint256 donorTokenId, uint256 oldPartGene, uint256 newPartGene, uint256 oldPartBonus, uint256 newPartBonus, uint256 xenograftPart);
  event Mutated(address indexed tokenOwner, uint256 tokenId, uint256 partIndex, uint256 oldGene, uint256 newGene, uint256 oldPartBonus, uint256 newPartBonus, uint256 mutationCount);

  /**
   * @dev Pre-generated keys to save gas
   * keys are generated with:
   * NORMAL_FOSSIL_RELIC_PERCENTAGE     = bytes4(keccak256("normalFossilRelicPercentage"))    = 0xcaf6fae2
   * PIONEER_FOSSIL_RELIC_PERCENTAGE    = bytes4(keccak256("pioneerFossilRelicPercentage"))   = 0x04988c65
   * LEGENDARY_FOSSIL_RELIC_PERCENTAGE  = bytes4(keccak256("legendaryFossilRelicPercentage")) = 0x277e613a
   * FOSSIL_ATTRIBUTE_COUNT             = bytes4(keccak256("fossilAttributesCount"))          = 0x06c475be
   * LEGENDARY_BONUS_COUNT              = bytes4(keccak256("legendaryBonusCount"))            = 0x45025094
   * LAST_PIONEER_TOKEN_ID              = bytes4(keccak256("lastPioneerTokenId"))             = 0xe562bae2
   */
  bytes4 internal constant NORMAL_FOSSIL_RELIC_PERCENTAGE = 0xcaf6fae2;
  bytes4 internal constant PIONEER_FOSSIL_RELIC_PERCENTAGE = 0x04988c65;
  bytes4 internal constant LEGENDARY_FOSSIL_RELIC_PERCENTAGE = 0x277e613a;
  bytes4 internal constant FOSSIL_ATTRIBUTE_COUNT = 0x06c475be;
  bytes4 internal constant LEGENDARY_BONUS_COUNT = 0x45025094;
  bytes4 internal constant LAST_PIONEER_TOKEN_ID = 0xe562bae2;

  mapping(bytes4 => uint256) internal internalUintVariable;

  // elements => legendary set index of that element
  mapping(uint256 => uint256[]) internal legendaryPartIndex;

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress
  ) 
  public 
  CryptantInformant
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress
  ) {
    // constructor

    // default values for relic percentages
    // normal crab relic is set to 5%
    _setUint(NORMAL_FOSSIL_RELIC_PERCENTAGE, 5000);

    // pioneer crab relic is set to 50%
    _setUint(PIONEER_FOSSIL_RELIC_PERCENTAGE, 50000);

    // legendary crab part relic is set to increase by 50%
    _setUint(LEGENDARY_FOSSIL_RELIC_PERCENTAGE, 50000);

    // The max number of attributes types
    // Every fossil will have 1 attribute
    _setUint(FOSSIL_ATTRIBUTE_COUNT, 6);

    // The max number of bonus types for legendary
    // Every legendary will have 1 bonus
    _setUint(LEGENDARY_BONUS_COUNT, 5);

    // The last pioneer token ID to be referred as Pioneer
    _setUint(LAST_PIONEER_TOKEN_ID, 1121);
  }

  function setPartIndex(uint256 _element, uint256[] _partIndexes) external onlyOwner {
    legendaryPartIndex[_element] = _partIndexes;
  }

  function getPartIndexes(uint256 _element) external view onlyOwner returns (uint256[] memory _partIndexes){
    _partIndexes = legendaryPartIndex[_element];
  }

  function getUint(bytes4 key) external view returns (uint256 value) {
    value = _getUint(key);
  }

  function setUint(bytes4 key, uint256 value) external onlyOwner {
    _setUint(key, value);
  }

  function _getUint(bytes4 key) internal view returns (uint256 value) {
    value = internalUintVariable[key];
  }

  function _setUint(bytes4 key, uint256 value) internal {
    internalUintVariable[key] = value;
  }

  function xenograft(uint256 _recipientTokenId, uint256 _donorTokenId, uint256 _xenograftPart) external {
    // get crab gene of both token
    // make sure both token is not fossil
    // replace the recipient part with donor part
    // mark donor as fosil
    // fosil will generate 1 attr
    // 3% of fosil will have relic
    // deduct 10 cryptant
    require(_xenograftPart != 1);  // part cannot be body (part index = 1)
    require(cryptantCrabToken.ownerOf(_recipientTokenId) == msg.sender);  // check ownership of both token
    require(cryptantCrabToken.ownerOf(_donorTokenId) == msg.sender);

    // due to stack too deep, need to use an array
    // to represent all the variables
    uint256[] memory _intValues = new uint256[](11);
    _intValues[0] = getCryptantFragments(msg.sender);
    // _intValues[0] = ownedCryptant
    // _intValues[1] = donorPartBonus
    // _intValues[2] = recipientGene
    // _intValues[3] = donorGene
    // _intValues[4] = recipientPart
    // _intValues[5] = donorPart
    // _intValues[6] = relicPercentage
    // _intValues[7] = fossilType
    // _intValues[8] = recipientExistingPartBonus
    // _intValues[9] = recipientLevel
    // _intValues[10] = recipientExp

    // perform transplant requires 5 cryptant
    require(_intValues[0] >= 5000);

    // make sure both tokens are not fossil
    uint256[] memory _values;
    bytes32[] memory _keys = new bytes32[](6);

    _keys[0] = keccak256(abi.encodePacked(_recipientTokenId, "fossilType"));
    _keys[1] = keccak256(abi.encodePacked(_donorTokenId, "fossilType"));
    _keys[2] = keccak256(abi.encodePacked(_donorTokenId, _xenograftPart, "partBonus"));
    _keys[3] = keccak256(abi.encodePacked(_recipientTokenId, _xenograftPart, "partBonus"));
    _keys[4] = keccak256(abi.encodePacked(_recipientTokenId, "level"));
    _keys[5] = keccak256(abi.encodePacked(_recipientTokenId, "exp"));
    _values = cryptantCrabStorage.readUint256s(_keys);

    require(_values[0] == 0);
    require(_values[1] == 0);

    _intValues[1] = _values[2];
    _intValues[8] = _values[3];

    // _values[5] = recipient Exp
    // _values[4] = recipient Level
    _intValues[9] = _values[4];
    _intValues[10] = _values[5];

    // Increase Exp
    _intValues[10] += 8;

    // check if crab level up
    uint256 _expRequired = expRequiredToReachLevel(_intValues[9] + 1);
    if(_intValues[10] >=_expRequired) {
      // increase level
      _intValues[9] += 1;

      // carry forward extra exp
      _intValues[10] -= _expRequired;

      emit LevelUp(msg.sender, _recipientTokenId, _intValues[9], _intValues[10]);
    } else {
      emit ExpGained(msg.sender, _recipientTokenId, _intValues[9], _intValues[10]);
    }

    // start performing Xenograft
    _intValues[2] = _geneOfCrab(_recipientTokenId);
    _intValues[3] = _geneOfCrab(_donorTokenId);

    // recipientPart
    _intValues[4] = _intValues[2] / crabPartMultiplier[_xenograftPart] % 1000;
    _intValues[5] = _intValues[3] / crabPartMultiplier[_xenograftPart] % 1000;
    
    int256 _partDiff = int256(_intValues[4]) - int256(_intValues[5]);
    _intValues[2] = uint256(int256(_intValues[2]) - (_partDiff * int256(crabPartMultiplier[_xenograftPart])));
    
    _values = new uint256[](6);
    _keys = new bytes32[](6);

    // Gene pair
    _keys[0] = keccak256(abi.encodePacked(_recipientTokenId, "gene"));
    _values[0] = _intValues[2];

    // Fossil Attribute
    _keys[1] = keccak256(abi.encodePacked(_donorTokenId, "fossilAttribute"));
    _values[1] = _generateRandomNumber(bytes32(_intValues[2] + _intValues[3] + _xenograftPart), _getUint(FOSSIL_ATTRIBUTE_COUNT)) + 1;

    
    // intVar1 will now use to store relic percentage variable
    if(isLegendaryPart(_intValues[3], 1)) {
      // if body part is legendary 100% become relic
      _intValues[7] = 2;
    } else {
      // Relic percentage will differ depending on the crab type / rarity
      _intValues[6] = _getUint(NORMAL_FOSSIL_RELIC_PERCENTAGE);

      if(_donorTokenId <= _getUint(LAST_PIONEER_TOKEN_ID)) {
        _intValues[6] = _getUint(PIONEER_FOSSIL_RELIC_PERCENTAGE);
      }

      if(isLegendaryPart(_intValues[3], 2) ||
        isLegendaryPart(_intValues[3], 3) || isLegendaryPart(_intValues[3], 4)) {
        _intValues[6] += _getUint(LEGENDARY_FOSSIL_RELIC_PERCENTAGE);
      }

      // Fossil Type
      // 1 = Normal Fossil
      // 2 = Relic Fossil
      _intValues[7] = 1;
      if(_generateRandomNumber(bytes32(_intValues[3] + _xenograftPart), 100000) < _intValues[6]) {
        _intValues[7] = 2;
      }
    }

    _keys[2] = keccak256(abi.encodePacked(_donorTokenId, "fossilType"));
    _values[2] = _intValues[7];

    // Part Attribute
    _keys[3] = keccak256(abi.encodePacked(_recipientTokenId, _xenograftPart, "partBonus"));
    _values[3] = _intValues[1];

    // Recipient Level
    _keys[4] = keccak256(abi.encodePacked(_recipientTokenId, "level"));
    _values[4] = _intValues[9];

    // Recipient Exp
    _keys[5] = keccak256(abi.encodePacked(_recipientTokenId, "exp"));
    _values[5] = _intValues[10];

    require(cryptantCrabStorage.updateUint256s(_keys, _values));

    _removeCryptantFragments(msg.sender, 5000);

    emit Xenografted(msg.sender, _recipientTokenId, _donorTokenId, _intValues[4], _intValues[5], _intValues[8], _intValues[1], _xenograftPart);
  }

  function mutate(uint256 _tokenId, uint256 _partIndex) external {
    // token must be owned by sender
    require(cryptantCrabToken.ownerOf(_tokenId) == msg.sender);
    // body part cannot mutate
    require(_partIndex > 1 && _partIndex < 5);

    // here not checking if sender has enough cryptant
    // is because _removeCryptantFragments uses safeMath
    // to do subtract, so it will revert if it&#39;s not enough
    _removeCryptantFragments(msg.sender, 1000);

    bytes32[] memory _keys = new bytes32[](5);
    _keys[0] = keccak256(abi.encodePacked(_tokenId, "gene"));
    _keys[1] = keccak256(abi.encodePacked(_tokenId, "level"));
    _keys[2] = keccak256(abi.encodePacked(_tokenId, "exp"));
    _keys[3] = keccak256(abi.encodePacked(_tokenId, "mutationCount"));
    _keys[4] = keccak256(abi.encodePacked(_tokenId, _partIndex, "partBonus"));

    uint256[] memory _values = new uint256[](5);
    (_values[0], _values[1], _values[2], _values[3], , , ) = _getCrabData(_tokenId);

    uint256[] memory _partsGene = new uint256[](5);
    uint256 i;
    for(i = 1 ; i <= 4 ; i++) {
      _partsGene[i] = _values[0] / crabPartMultiplier[i] % 1000;
    }

    // mutate starts from 3%, max is 20% which is 170 mutations
    if(_values[3] > 170) {
      _values[3] = 170;
    }

    uint256 newPartGene = genesisCrab.mutateCrabPart(_partIndex, _partsGene[_partIndex], (30 + _values[3]) * 100);

    //generate the new gene
    uint256 _oldPartBonus = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(_tokenId, _partIndex, "partBonus")));
    uint256 _partGene;  // this variable will be reused by oldGene
    uint256 _newGene;
    for(i = 1 ; i <= 4 ; i++) {
      _partGene = _partsGene[i];

      if(i == _partIndex) {
        _partGene = newPartGene;
      }

      _newGene += _partGene * crabPartMultiplier[i];
    }

    if(isLegendaryPart(_newGene, _partIndex)) {
      _values[4] = _generateRandomNumber(bytes32(_newGene + _partIndex + _tokenId), _getUint(LEGENDARY_BONUS_COUNT)) + 1;
    }

    // Reuse partGene as old gene
    _partGene = _values[0];

    // New Gene
    _values[0] = _newGene;

    // Increase Exp
    _values[2] += 8;

    // check if crab level up
    uint256 _expRequired = expRequiredToReachLevel(_values[1] + 1);
    if(_values[2] >=_expRequired) {
      // increase level
      _values[1] += 1;

      // carry forward extra exp
      _values[2] -= _expRequired;

      emit LevelUp(msg.sender, _tokenId, _values[1], _values[2]);
    } else {
      emit ExpGained(msg.sender, _tokenId, _values[1], _values[2]);
    }

    // Increase Mutation Count
    _values[3] += 1;

    require(cryptantCrabStorage.updateUint256s(_keys, _values));

    emit Mutated(msg.sender, _tokenId, _partIndex, _partGene, _newGene, _oldPartBonus, _values[4], _values[3]);
  }

  function generateBonusForGene(uint256 _gene) external view returns (uint256[] _bonuses) {
    _bonuses = new uint256[](4);
    uint256[] memory _elements = extractElementsFromGene(_gene);
    uint256[] memory _parts = extractPartsFromGene(_gene);    
    uint256[] memory _legendaryParts;

    for(uint256 i = 0 ; i < 4 ; i++) {
      _legendaryParts = legendaryPartIndex[_elements[i]];

      for(uint256 j = 0 ; j < _legendaryParts.length ; j++) {
        if(_legendaryParts[j] == _parts[i]) {
          // generate the bonus number and add it into the _bonuses array
          _bonuses[i] = _generateRandomNumber(bytes32(_gene + i), _getUint(LEGENDARY_BONUS_COUNT)) + 1;
          break;
        }
      }
    }
  }

  /**
   * @dev checks if the specified part of the given gene is a legendary part or not
   * returns true if its a legendary part, false otherwise.
   * @param _gene full body gene to be checked on
   * @param _part partIndex ranging from 1 = body, 2 = legs, 3 = left claw, 4 = right claw
   */
  function isLegendaryPart(uint256 _gene, uint256 _part) internal view returns (bool) {
    uint256[] memory _legendaryParts = legendaryPartIndex[extractElementsFromGene(_gene)[_part - 1]];
    for(uint256 i = 0 ; i < _legendaryParts.length ; i++) {
      if(_legendaryParts[i] == extractPartsFromGene(_gene)[_part - 1]) {
        return true;
      }
    }
    return false;
  }
}

contract Withdrawable is Ownable {
  address public withdrawer;

  /**
   * @dev Throws if called by any account other than the withdrawer.
   */
  modifier onlyWithdrawer() {
    require(msg.sender == withdrawer);
    _;
  }

  function setWithdrawer(address _newWithdrawer) external onlyOwner {
    withdrawer = _newWithdrawer;
  }

  /**
   * @dev withdraw the specified amount of ether from contract.
   * @param _amount the amount of ether to withdraw. Units in wei.
   */
  function withdraw(uint256 _amount) external onlyWithdrawer returns(bool) {
    require(_amount <= address(this).balance);
    withdrawer.transfer(_amount);
    return true;
  }
}

contract CryptantCrabMarket is CryptantCrabPurchasableLaunch, GeneSurgeon, Randomable, Withdrawable {
  event Purchased(address indexed owner, uint256 amount, uint256 cryptant, uint256 refund);
  event ReferralPurchase(address indexed referral, uint256 rewardAmount, address buyer);
  event CrabOnSaleStarted(address indexed seller, uint256 tokenId, uint256 sellingPrice, uint256 marketId, uint256 gene);
  event CrabOnSaleCancelled(address indexed seller, uint256 tokenId, uint256 marketId);
  event Traded(address indexed seller, address indexed buyer, uint256 tokenId, uint256 tradedPrice, uint256 marketId);   // Trade Type 0 = Purchase

  struct MarketItem {
    uint256 tokenId;
    uint256 sellingPrice;
    address seller;
    uint8 state;              // 1 - on going, 2 - cancelled, 3 - completed
  }

  PrizePool public prizePool;

  /**
   * @dev Pre-generated keys to save gas
   * keys are generated with:
   * MARKET_PRICE_UPDATE_PERIOD = bytes4(keccak256("marketPriceUpdatePeriod"))  = 0xf1305a10
   * CURRENT_TOKEN_ID           = bytes4(keccak256("currentTokenId"))           = 0x21339464
   * REFERRAL_CUT               = bytes4(keccak256("referralCut"))              = 0x40b0b13e
   * PURCHASE_PRIZE_POOL_CUT    = bytes4(keccak256("purchasePrizePoolCut"))     = 0x7625c58a
   * EXCHANGE_PRIZE_POOL_CUT    = bytes4(keccak256("exchangePrizePoolCut"))     = 0xb9e1adb0
   * EXCHANGE_DEVELOPER_CUT     = bytes4(keccak256("exchangeDeveloperCut"))     = 0xfe9ad0eb
   * LAST_TRANSACTION_PERIOD    = bytes4(keccak256("lastTransactionPeriod"))    = 0x1a01d5bb
   * LAST_TRANSACTION_PRICE     = bytes4(keccak256("lastTransactionPrice"))     = 0xf14adb6a
   */
  bytes4 internal constant MARKET_PRICE_UPDATE_PERIOD = 0xf1305a10;
  bytes4 internal constant CURRENT_TOKEN_ID = 0x21339464;
  bytes4 internal constant REFERRAL_CUT = 0x40b0b13e;
  bytes4 internal constant PURCHASE_PRIZE_POOL_CUT = 0x7625c58a;
  bytes4 internal constant EXCHANGE_PRIZE_POOL_CUT = 0xb9e1adb0;
  bytes4 internal constant EXCHANGE_DEVELOPER_CUT = 0xfe9ad0eb;
  bytes4 internal constant LAST_TRANSACTION_PERIOD = 0x1a01d5bb;
  bytes4 internal constant LAST_TRANSACTION_PRICE = 0xf14adb6a;

  /**
   * @dev The first 25 trading crab price will be fixed to 0.3 ether.
   * This only applies to crab bought from developer.
   * Crab on auction will depends on the price set by owner.
   */
  uint256 constant public initialCrabTradingPrice = 300 finney;
  
  // The initial cryptant price will be fixed to 0.03 ether.
  // It will changed to dynamic price after 25 crabs traded.
  // 1000 Cryptant Fragment = 1 Cryptant.
  uint256 constant public initialCryptantFragmentTradingPrice = 30 szabo;

  mapping(bytes4 => uint256) internal internalUintVariable;

  // All traded price will be stored here
  uint256[] public tradedPrices;

  // All auctioned items will be stored here
  MarketItem[] public marketItems;

  // PrizePool key, default value is 0xadd5d43f
  // 0xadd5d43f = bytes4(keccak256(bytes("firstPrizePool")));
  bytes4 public currentPrizePool = 0xadd5d43f;

  constructor
  (
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress,
    address _prizePoolAddress
  ) 
  public 
  CryptantCrabPurchasableLaunch
  (
    _genesisCrabAddress, 
    _cryptantCrabTokenAddress, 
    _cryptantCrabStorageAddress,
    _transmuterAddress
  ) {
    // constructor
    if(_prizePoolAddress != address(0)) {
      _setPrizePoolAddress(_prizePoolAddress);
    }
    
    // set the initial token id
    _setUint(CURRENT_TOKEN_ID, 1121);

    // The number of seconds that the market will stay at fixed price. 
    // Default set to 4 hours
    _setUint(MARKET_PRICE_UPDATE_PERIOD, 14400);

    // The percentage of referral cut
    // Default set to 10%
    _setUint(REFERRAL_CUT, 10000);

    // The percentage of price pool cut when purchase a new crab
    // Default set to 20%
    _setUint(PURCHASE_PRIZE_POOL_CUT, 20000);

    // The percentage of prize pool cut when market exchange traded
    // Default set to 2%
    _setUint(EXCHANGE_PRIZE_POOL_CUT, 2000);

    // The percentage of developer cut
    // Default set to 2.8%
    _setUint(EXCHANGE_DEVELOPER_CUT, 2800);

    // to prevent marketId = 0
    // put a dummy value for it
    marketItems.push(MarketItem(0, 0, address(0), 0));
  }

  function _setPrizePoolAddress(address _prizePoolAddress) internal {
    PrizePool _prizePoolContract = PrizePool(_prizePoolAddress);
    prizePool = _prizePoolContract;
  }

  function setAddresses(
    address _genesisCrabAddress, 
    address _cryptantCrabTokenAddress, 
    address _cryptantCrabStorageAddress,
    address _transmuterAddress,
    address _prizePoolAddress
  ) 
  external onlyOwner {
    _setAddresses(_genesisCrabAddress, _cryptantCrabTokenAddress, _cryptantCrabStorageAddress);

    if(_transmuterAddress != address(0)) {
      _setTransmuterAddress(_transmuterAddress);
    }

    if(_prizePoolAddress != address(0)) {
      _setPrizePoolAddress(_prizePoolAddress);
    }
  }

  function setCurrentPrizePool(bytes4 _newPrizePool) external onlyOwner {
    currentPrizePool = _newPrizePool;
  }

  function getUint(bytes4 key) external view returns (uint256 value) {
    value = _getUint(key);
  }

  function setUint(bytes4 key, uint256 value) external onlyOwner {
    _setUint(key, value);
  }

  function _getUint(bytes4 key) internal view returns (uint256 value) {
    value = internalUintVariable[key];
  }

  function _setUint(bytes4 key, uint256 value) internal {
    internalUintVariable[key] = value;
  }

  function purchase(uint256 _crabAmount, uint256 _cryptantFragmentAmount, address _referral) external payable {
    require(_crabAmount >= 0 && _crabAmount <= 10 );
    require(_cryptantFragmentAmount >= 0 && _cryptantFragmentAmount <= 10000);
    require(!(_crabAmount == 0 && _cryptantFragmentAmount == 0));
    require(_cryptantFragmentAmount % 1000 == 0);
    require(msg.sender != _referral);

    // check if ether payment is enough
    uint256 _singleCrabPrice = getCurrentCrabPrice();
    uint256 _totalCrabPrice = _singleCrabPrice * _crabAmount;
    uint256 _totalCryptantPrice = getCurrentCryptantFragmentPrice() * _cryptantFragmentAmount;
    uint256 _cryptantFragmentsGained = _cryptantFragmentAmount;

    // free 2 cryptant when purchasing 10
    if(_cryptantFragmentsGained == 10000) {
      _cryptantFragmentsGained += 2000;
    }

    uint256 _totalPrice = _totalCrabPrice + _totalCryptantPrice;
    uint256 _value = msg.value;

    require(_value >= _totalPrice);

    // Purchase 10 crabs will have 1 crab with legendary part
    // Default value for _crabWithLegendaryPart is just a unreacable number
    uint256 _currentTokenId = _getUint(CURRENT_TOKEN_ID);
    uint256 _crabWithLegendaryPart = 100;
    if(_crabAmount == 10) {
      // decide which crab will have the legendary part
      _crabWithLegendaryPart = _generateRandomNumber(bytes32(_currentTokenId), 10);
    }

    for(uint256 i = 0 ; i < _crabAmount ; i++) {
      // 5000 ~ 5500 is gift token
      // so if hit 5000 will skip to 5500 onwards
      if(_currentTokenId == 5000) {
        _currentTokenId = 5500;
      }

      _currentTokenId++;
      _createCrab(_currentTokenId, _singleCrabPrice, 0, 0, _crabWithLegendaryPart == i);
      tradedPrices.push(_singleCrabPrice);
    }

    if(_cryptantFragmentsGained > 0) {
      _addCryptantFragments(msg.sender, (_cryptantFragmentsGained));
    }

    _setUint(CURRENT_TOKEN_ID, _currentTokenId);
    
    // Refund exceeded value
    _refundExceededValue(_value, _totalPrice);

    // If there&#39;s referral, will transfer the referral reward to the referral
    if(_referral != address(0)) {
      uint256 _referralReward = _totalPrice * _getUint(REFERRAL_CUT) / 100000;
      _referral.transfer(_referralReward);
      emit ReferralPurchase(_referral, _referralReward, msg.sender);
    }

    // Send prize pool cut to prize pool
    uint256 _prizePoolAmount = _totalPrice * _getUint(PURCHASE_PRIZE_POOL_CUT) / 100000;
    prizePool.increasePrizePool.value(_prizePoolAmount)(currentPrizePool);

    _setUint(LAST_TRANSACTION_PERIOD, now / _getUint(MARKET_PRICE_UPDATE_PERIOD));
    _setUint(LAST_TRANSACTION_PRICE, _singleCrabPrice);

    emit Purchased(msg.sender, _crabAmount, _cryptantFragmentsGained, _value - _totalPrice);
  }

  function getCurrentPeriod() external view returns (uint256 _now, uint256 _currentPeriod) {
    _now = now;
    _currentPeriod = now / _getUint(MARKET_PRICE_UPDATE_PERIOD);
  }

  function getCurrentCrabPrice() public view returns (uint256) {
    if(totalCrabTraded() > 25) {
      uint256 _lastTransactionPeriod = _getUint(LAST_TRANSACTION_PERIOD);
      uint256 _lastTransactionPrice = _getUint(LAST_TRANSACTION_PRICE);

      if(_lastTransactionPeriod == now / _getUint(MARKET_PRICE_UPDATE_PERIOD) && _lastTransactionPrice != 0) {
        return _lastTransactionPrice;
      } else {
        uint256 totalPrice;
        for(uint256 i = 1 ; i <= 15 ; i++) {
          totalPrice += tradedPrices[tradedPrices.length - i];
        }

        // the actual calculation here is:
        // average price = totalPrice / 15
        return totalPrice / 15;
      }
    } else {
      return initialCrabTradingPrice;
    }
  }

  function getCurrentCryptantFragmentPrice() public view returns (uint256 _price) {
    if(totalCrabTraded() > 25) {
      // real calculation is 1 Cryptant = 10% of currentCrabPrice
      // should be written as getCurrentCrabPrice() * 10 / 100 / 1000
      return getCurrentCrabPrice() * 10 / 100000;
    } else {
      return initialCryptantFragmentTradingPrice;
    }
  }

  // After pre-sale crab tracking (excluding fossil transactions)
  function totalCrabTraded() public view returns (uint256) {
    return tradedPrices.length;
  }

  function sellCrab(uint256 _tokenId, uint256 _sellingPrice) external {
    require(cryptantCrabToken.ownerOf(_tokenId) == msg.sender);
    require(_sellingPrice >= 50 finney && _sellingPrice <= 100 ether);

    marketItems.push(MarketItem(_tokenId, _sellingPrice, msg.sender, 1));

    // escrow
    cryptantCrabToken.transferFrom(msg.sender, address(this), _tokenId);

    uint256 _gene = _geneOfCrab(_tokenId);

    emit CrabOnSaleStarted(msg.sender, _tokenId, _sellingPrice, marketItems.length - 1, _gene);
  }

  function cancelOnSaleCrab(uint256 _marketId) external {
    MarketItem storage marketItem = marketItems[_marketId];

    // Only able to cancel on sale Item
    require(marketItem.state == 1);

    // Set Market Item state to 2(Cancelled)
    marketItem.state = 2;

    // Only owner can cancel on sale item
    require(marketItem.seller == msg.sender);

    // Release escrow to the owner
    cryptantCrabToken.transferFrom(address(this), msg.sender, marketItem.tokenId);

    emit CrabOnSaleCancelled(msg.sender, marketItem.tokenId, _marketId);
  }

  function buyCrab(uint256 _marketId) external payable {
    MarketItem storage marketItem = marketItems[_marketId];
    require(marketItem.state == 1);   // make sure the sale is on going
    require(marketItem.sellingPrice == msg.value);
    require(marketItem.seller != msg.sender);

    cryptantCrabToken.safeTransferFrom(address(this), msg.sender, marketItem.tokenId);

    uint256 _developerCut = msg.value * _getUint(EXCHANGE_DEVELOPER_CUT) / 100000;
    uint256 _prizePoolCut = msg.value * _getUint(EXCHANGE_PRIZE_POOL_CUT) / 100000;
    uint256 _sellerAmount = msg.value - _developerCut - _prizePoolCut;
    marketItem.seller.transfer(_sellerAmount);

    // Send prize pool cut to prize pool
    prizePool.increasePrizePool.value(_prizePoolCut)(currentPrizePool);

    uint256 _fossilType = cryptantCrabStorage.readUint256(keccak256(abi.encodePacked(marketItem.tokenId, "fossilType")));
    if(_fossilType > 0) {
      tradedPrices.push(marketItem.sellingPrice);
    }

    marketItem.state = 3;

    _setUint(LAST_TRANSACTION_PERIOD, now / _getUint(MARKET_PRICE_UPDATE_PERIOD));
    _setUint(LAST_TRANSACTION_PRICE, getCurrentCrabPrice());

    emit Traded(marketItem.seller, msg.sender, marketItem.tokenId, marketItem.sellingPrice, _marketId);
  }

  function() public payable {
    revert();
  }
}

contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

contract PrizePool is Ownable, Whitelist, HasNoEther {
  event PrizePoolIncreased(uint256 amountIncreased, bytes4 prizePool, uint256 currentAmount);
  event WinnerAdded(address winner, bytes4 prizeTitle, uint256 claimableAmount);
  event PrizedClaimed(address winner, bytes4 prizeTitle, uint256 claimedAmount);

  // prizePool key => prizePool accumulated amount
  // this is just to track how much a prizePool has
  mapping(bytes4 => uint256) prizePools;

  // winner&#39;s address => prize title => amount
  // prize title itself need to be able to determine
  // the prize pool it is from
  mapping(address => mapping(bytes4 => uint256)) winners;

  constructor() public {

  }

  function increasePrizePool(bytes4 _prizePool) external payable onlyIfWhitelisted(msg.sender) {
    prizePools[_prizePool] += msg.value;

    emit PrizePoolIncreased(msg.value, _prizePool, prizePools[_prizePool]);
  }

  function addWinner(address _winner, bytes4 _prizeTitle, uint256 _claimableAmount) external onlyIfWhitelisted(msg.sender) {
    winners[_winner][_prizeTitle] = _claimableAmount;

    emit WinnerAdded(_winner, _prizeTitle, _claimableAmount);
  }

  function claimPrize(bytes4 _prizeTitle) external {
    uint256 _claimableAmount = winners[msg.sender][_prizeTitle];

    require(_claimableAmount > 0);

    msg.sender.transfer(_claimableAmount);

    winners[msg.sender][_prizeTitle] = 0;

    emit PrizedClaimed(msg.sender, _prizeTitle, _claimableAmount);
  }

  function claimableAmount(address _winner, bytes4 _prizeTitle) external view returns (uint256 _claimableAmount) {
    _claimableAmount = winners[_winner][_prizeTitle];
  }

  function prizePoolTotal(bytes4 _prizePool) external view returns (uint256 _prizePoolTotal) {
    _prizePoolTotal = prizePools[_prizePool];
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

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

contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

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

contract CryptantCrabNFT is ERC721Token, Whitelist, CrabData, GeneSurgeon {
  event CrabPartAdded(uint256 hp, uint256 dps, uint256 blockAmount);
  event GiftTransfered(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event DefaultMetadataURIChanged(string newUri);

  /**
   * @dev Pre-generated keys to save gas
   * keys are generated with:
   * CRAB_BODY       = bytes4(keccak256("crab_body"))       = 0xc398430e
   * CRAB_LEG        = bytes4(keccak256("crab_leg"))        = 0x889063b1
   * CRAB_LEFT_CLAW  = bytes4(keccak256("crab_left_claw"))  = 0xdb6290a2
   * CRAB_RIGHT_CLAW = bytes4(keccak256("crab_right_claw")) = 0x13453f89
   */
  bytes4 internal constant CRAB_BODY = 0xc398430e;
  bytes4 internal constant CRAB_LEG = 0x889063b1;
  bytes4 internal constant CRAB_LEFT_CLAW = 0xdb6290a2;
  bytes4 internal constant CRAB_RIGHT_CLAW = 0x13453f89;

  /**
   * @dev Stores all the crab data
   */
  mapping(bytes4 => mapping(uint256 => CrabPartData[])) internal crabPartData;

  /**
   * @dev Mapping from tokenId to its corresponding special skin
   * tokenId with default skin will not be stored. 
   */
  mapping(uint256 => uint256) internal crabSpecialSkins;

  /**
   * @dev default MetadataURI
   */
  string public defaultMetadataURI = "https://www.cryptantcrab.io/md/";

  constructor(string _name, string _symbol) public ERC721Token(_name, _symbol) {
    // constructor
    initiateCrabPartData();
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist.
   * Will return the token&#39;s metadata URL if it has one, 
   * otherwise will just return base on the default metadata URI
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));

    string memory _uri = tokenURIs[_tokenId];

    if(bytes(_uri).length == 0) {
      _uri = getMetadataURL(bytes(defaultMetadataURI), _tokenId);
    }

    return _uri;
  }

  /**
   * @dev Returns the data of a specific parts
   * @param _partIndex the part to retrieve. 1 = Body, 2 = Legs, 3 = Left Claw, 4 = Right Claw
   * @param _element the element of part to retrieve. 1 = Fire, 2 = Earth, 3 = Metal, 4 = Spirit, 5 = Water
   * @param _setIndex the set index of for the specified part. This will starts from 1.
   */
  function dataOfPart(uint256 _partIndex, uint256 _element, uint256 _setIndex) public view returns (uint256[] memory _resultData) {
    bytes4 _key;
    if(_partIndex == 1) {
      _key = CRAB_BODY;
    } else if(_partIndex == 2) {
      _key = CRAB_LEG;
    } else if(_partIndex == 3) {
      _key = CRAB_LEFT_CLAW;
    } else if(_partIndex == 4) {
      _key = CRAB_RIGHT_CLAW;
    } else {
      revert();
    }

    CrabPartData storage _crabPartData = crabPartData[_key][_element][_setIndex];

    _resultData = crabPartDataToArray(_crabPartData);
  }

  /**
   * @dev Gift(Transfer) a token to another address. Caller must be token owner
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function giftToken(address _from, address _to, uint256 _tokenId) external {
    safeTransferFrom(_from, _to, _tokenId);

    emit GiftTransfered(_from, _to, _tokenId);
  }

  /**
   * @dev External function to mint a new token, for whitelisted address only.
   * Reverts if the given token ID already exists
   * @param _tokenOwner address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   * @param _skinId the skin ID to be applied for all the token minted
   */
  function mintToken(address _tokenOwner, uint256 _tokenId, uint256 _skinId) external onlyIfWhitelisted(msg.sender) {
    super._mint(_tokenOwner, _tokenId);

    if(_skinId > 0) {
      crabSpecialSkins[_tokenId] = _skinId;
    }
  }

  /**
   * @dev Returns crab data base on the gene provided
   * @param _gene the gene info where crab data will be retrieved base on it
   * @return 4 uint arrays:
   * 1st Array = Body&#39;s Data
   * 2nd Array = Leg&#39;s Data
   * 3rd Array = Left Claw&#39;s Data
   * 4th Array = Right Claw&#39;s Data
   */
  function crabPartDataFromGene(uint256 _gene) external view returns (
    uint256[] _bodyData,
    uint256[] _legData,
    uint256[] _leftClawData,
    uint256[] _rightClawData
  ) {
    uint256[] memory _parts = extractPartsFromGene(_gene);
    uint256[] memory _elements = extractElementsFromGene(_gene);

    _bodyData = dataOfPart(1, _elements[0], _parts[0]);
    _legData = dataOfPart(2, _elements[1], _parts[1]);
    _leftClawData = dataOfPart(3, _elements[2], _parts[2]);
    _rightClawData = dataOfPart(4, _elements[3], _parts[3]);
  }

  /**
   * @dev For developer to add new parts, notice that this is the only method to add crab data
   * so that developer can add extra content. there&#39;s no other method for developer to modify
   * the data. This is to assure token owner actually owns their data.
   * @param _partIndex the part to add. 1 = Body, 2 = Legs, 3 = Left Claw, 4 = Right Claw
   * @param _element the element of part to add. 1 = Fire, 2 = Earth, 3 = Metal, 4 = Spirit, 5 = Water
   * @param _partDataArray data of the parts.
   */
  function setPartData(uint256 _partIndex, uint256 _element, uint256[] _partDataArray) external onlyOwner {
    CrabPartData memory _partData = arrayToCrabPartData(_partDataArray);

    bytes4 _key;
    if(_partIndex == 1) {
      _key = CRAB_BODY;
    } else if(_partIndex == 2) {
      _key = CRAB_LEG;
    } else if(_partIndex == 3) {
      _key = CRAB_LEFT_CLAW;
    } else if(_partIndex == 4) {
      _key = CRAB_RIGHT_CLAW;
    }

    // if index 1 is empty will fill at index 1
    if(crabPartData[_key][_element][1].hp == 0 && crabPartData[_key][_element][1].dps == 0) {
      crabPartData[_key][_element][1] = _partData;
    } else {
      crabPartData[_key][_element].push(_partData);
    }

    emit CrabPartAdded(_partDataArray[0], _partDataArray[1], _partDataArray[2]);
  }

  /**
   * @dev Updates the default metadata URI
   * @param _defaultUri the new metadata URI
   */
  function setDefaultMetadataURI(string _defaultUri) external onlyOwner {
    defaultMetadataURI = _defaultUri;

    emit DefaultMetadataURIChanged(_defaultUri);
  }

  /**
   * @dev Updates the metadata URI for existing token
   * @param _tokenId the tokenID that metadata URI to be changed
   * @param _uri the new metadata URI for the specified token
   */
  function setTokenURI(uint256 _tokenId, string _uri) external onlyIfWhitelisted(msg.sender) {
    _setTokenURI(_tokenId, _uri);
  }

  /**
   * @dev Returns the special skin of the provided tokenId
   * @param _tokenId cryptant crab&#39;s tokenId
   * @return Special skin belongs to the _tokenId provided. 
   * 0 will be returned if no special skin found.
   */
  function specialSkinOfTokenId(uint256 _tokenId) external view returns (uint256) {
    return crabSpecialSkins[_tokenId];
  }

  /**
   * @dev This functions will adjust the length of crabPartData
   * so that when adding data the index can start with 1.
   * Reason of doing this is because gene cannot have parts with index 0.
   */
  function initiateCrabPartData() internal {
    require(crabPartData[CRAB_BODY][1].length == 0);

    for(uint256 i = 1 ; i <= 5 ; i++) {
      crabPartData[CRAB_BODY][i].length = 2;
      crabPartData[CRAB_LEG][i].length = 2;
      crabPartData[CRAB_LEFT_CLAW][i].length = 2;
      crabPartData[CRAB_RIGHT_CLAW][i].length = 2;
    }
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token, 
   *  or has been whitelisted by contract owner
   */
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender) || whitelist(_spender);
  }

  /**
   * @dev Will merge the uri and tokenId together. 
   * @param _uri URI to be merge. This will be the first part of the result URL.
   * @param _tokenId tokenID to be merge. This will be the last part of the result URL.
   * @return the merged urL
   */
  function getMetadataURL(bytes _uri, uint256 _tokenId) internal pure returns (string) {
    uint256 _tmpTokenId = _tokenId;
    uint256 _tokenLength;

    // Getting the length(number of digits) of token ID
    do {
      _tokenLength++;
      _tmpTokenId /= 10;
    } while (_tmpTokenId > 0);

    // creating a byte array with the length of URL + token digits
    bytes memory _result = new bytes(_uri.length + _tokenLength);

    // cloning the uri bytes into the result bytes
    for(uint256 i = 0 ; i < _uri.length ; i ++) {
      _result[i] = _uri[i];
    }

    // appending the tokenId to the end of the result bytes
    uint256 lastIndex = _result.length - 1;
    for(_tmpTokenId = _tokenId ; _tmpTokenId > 0 ; _tmpTokenId /= 10) {
      _result[lastIndex--] = byte(48 + _tmpTokenId % 10);
    }

    return string(_result);
  }
}