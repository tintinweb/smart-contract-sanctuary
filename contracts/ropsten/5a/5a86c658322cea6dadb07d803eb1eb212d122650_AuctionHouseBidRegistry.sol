pragma solidity ^0.4.23;

// imported contracts/proposals/OCP-IP-1/BlindBidRegistryProxiable.sol
// imported contracts/proposals/OCP-IP-1/BlindBidRegistry.sol
// imported contracts/proposals/OCP-IP-1/BidRegistry.sol
// imported node_modules/openzeppelin-solidity/contracts/ownership/Secondary.sol
/**
 * @title Secondary
 * @dev A Secondary contract can only be used by its primary account (the one that created it)
 */
contract Secondary {
  address private _primary;
  event PrimaryTransferred(
    address recipient
  );
  /**
   * @dev Sets the primary account to the one that is creating the Secondary contract.
   */
  constructor() internal {
    _primary = msg.sender;
    emit PrimaryTransferred(_primary);
  }
  /**
   * @dev Reverts if called from any account other than the primary.
   */
  modifier onlyPrimary() {
    require(msg.sender == _primary);
    _;
  }
  /**
   * @return the address of the primary.
   */
  function primary() public view returns (address) {
    return _primary;
  }
  /**
   * @dev Transfers contract to a new primary.
   * @param recipient The address of new primary. 
   */
  function transferPrimary(address recipient) public onlyPrimary {
    require(recipient != address(0));
    _primary = recipient;
    emit PrimaryTransferred(_primary);
  }
}

// imported contracts/proposals/OCP-IP-1/IBidRegistry.sol
// implementation from https://github.com/open-city-protocol/OCP-IPs/blob/jeichel/ocp-ip-1/OCP-IPs/ocp-ip-1.md
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
    bytes32 schema,
    bytes32 licenseTerms,
    uint256 durationSec,
    uint256 bidPrice,
    uint256 updatedAtUtcSec
  );
  event BidAuctionStatusChange(bytes32 indexed hash, uint8 indexed auctionStatus, uint256 updatedAtUtcSec);
  event BidStateChange(bytes32 indexed hash, uint8 indexed bidState, uint256 updatedAtUtcSec);
  event BidClearingPriceChange(bytes32 indexed hash, uint256 clearingPrice, uint256 updatedAtUtcSec);
  function hashBid(
    address _creator,
    uint256 _auction,
    address _bidder,
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public constant returns(bytes32);
  function verifyStoredData(bytes32 hash) public view returns(bool);
  function creator(bytes32 hash) public view returns(address);
  function auction(bytes32 hash) public view returns(uint256);
  function bidder(bytes32 hash) public view returns(address);
  function schema(bytes32 hash) public view returns(bytes32);
  function licenseTerms(bytes32 hash) public view returns(bytes32);
  function durationSec(bytes32 hash) public view returns(uint256);
  function bidPrice(bytes32 hash) public view returns(uint256);
  function clearingPrice(bytes32 hash) public view returns(uint256);
  function auctionStatus(bytes32 hash) public view returns(uint8);
  function bidState(bytes32 hash) public view returns(uint8);
  function allocationFee(bytes32 hash) public view returns(uint256);
  function createBid(
    uint256 _auction,
    address _bidder,
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public;
  function setAllocationFee(bytes32 hash, uint256 fee) public;
  function setAuctionStatus(bytes32 hash, uint8 _auctionStatus) public;
  function setBidState(bytes32 hash, uint8 _bidState) public;
  function setClearingPrice(bytes32 hash, uint256 _clearingPrice) public;
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
    bytes32 schema;
    bytes32 licenseTerms;
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
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public constant returns(bytes32) {
    return keccak256(abi.encodePacked(
      _creator,
      _auction,
      _bidder,
      _schema,
      _licenseTerms,
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
      bid.licenseTerms,
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
  function schema(bytes32 hash) public view returns(bytes32) {
    return registry[hash].schema;
  }
  function licenseTerms(bytes32 hash) public view returns(bytes32) {
    return registry[hash].licenseTerms;
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
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint _durationSec,
    uint _bidPrice
  ) public {
    _createBid(
      msg.sender,
      _auction,
      _bidder,
      _schema,
      _licenseTerms,
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
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint _durationSec,
    uint _bidPrice
  ) internal {
    bytes32 hash = hashBid(
      _creator,
      _auction,
      _bidder,
      _schema,
      _licenseTerms,
      _durationSec,
      _bidPrice
    );
    registry[hash] = Bid(
      _creator,
      _auction,
      _bidder,
      _schema,
      _licenseTerms,
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
      _licenseTerms,
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

// imported contracts/proposals/OCP-IP-1/IBlindBidRegistry.sol
// implementation from https://github.com/open-city-protocol/OCP-IPs/blob/jeichel/ocp-ip-1/OCP-IPs/ocp-ip-1.md
contract IBlindBidRegistry is IBidRegistry {
  event BlindBidCreated(
    bytes32 indexed hash,
    address creator,
    uint256 indexed auction,
    uint256 updatedAtUtcSec
  );
  event BlindBidRevealed(
    bytes32 indexed hash,
    address creator,
    uint256 indexed auction,
    address indexed bidder,
    bytes32 schema,
    bytes32 licenseTerms,
    uint256 durationSec,
    uint256 bidPrice,
    uint256 updatedAtUtcSec
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
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public;
}

contract BlindBidRegistry is BidRegistry, IBlindBidRegistry {
  address public constant BLIND_BIDDER = 0;
  bytes32 public constant BLIND_SCHEMA = 0x0;
  bytes32 public constant BLIND_LICENSE = 0x0;
  uint256 public constant BLIND_DURATION = 0;
  uint256 public constant BLIND_PRICE = 0;
  function createBid(bytes32 hash, uint256 _auction) public {
    _createBid(hash, msg.sender, _auction);
  }
  function revealBid(
    bytes32 hash,
    uint256 _auction,
    address _bidder,
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public {
    _revealBid(
      hash,
      msg.sender,
      _auction,
      _bidder,
      _schema,
      _licenseTerms,
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
    bytes32 _schema,
    bytes32 _licenseTerms,
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
      _licenseTerms,
      _durationSec,
      _bidPrice
    );
    require(revealedHash == hash);
    registry[hash] = Bid(
      _creator,
      _auction,
      _bidder,
      _schema,
      _licenseTerms,
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
      _licenseTerms,
      _durationSec,
      _bidPrice,
      now // solhint-disable-line not-rely-on-time
    );
  }
}

// imported contracts/proposals/OCP-IP-4/Proxiable.sol
// imported contracts/access/roles/ProxyManagerRole.sol
// imported node_modules/openzeppelin-solidity/contracts/access/Roles.sol
/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }
  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));
    role.bearer[account] = true;
  }
  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));
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

// implementation from https://github.com/open-city-protocol/OCP-IPs/blob/master/OCP-IPs/ocp-ip-4.md
contract Proxiable is ProxyManagerRole {
  mapping(address => bool) private _globalProxies; // proxy -> valid
  mapping(address => mapping(address => bool)) private _senderProxies; // sender -> proxy -> valid
  event ProxyAdded(address indexed proxy, uint256 updatedAtUtcSec);
  event ProxyRemoved(address indexed proxy, uint256 updatedAtUtcSec);
  event ProxyForSenderAdded(address indexed proxy, address indexed sender, uint256 updatedAtUtcSec);
  event ProxyForSenderRemoved(address indexed proxy, address indexed sender, uint256 updatedAtUtcSec);
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

contract BlindBidRegistryProxiable is BlindBidRegistry, Proxiable {
  function createBid(bytes32 hash, address _creator, uint256 _auction) public proxyOrSender(_creator) {
    super._createBid(hash, _creator, _auction);
  }
  function revealBid(
    bytes32 hash,
    address _creator,
    uint256 _auction,
    address _bidder,
    bytes32 _schema,
    bytes32 _licenseTerms,
    uint256 _durationSec,
    uint256 _bidPrice
  ) public proxyOrSender(_creator) {
    super._revealBid(
      hash,
      _creator,
      _auction,
      _bidder,
      _schema,
      _licenseTerms,
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