pragma solidity ^0.4.23;

// imported contracts/access/roles/AuctionManagerRole.sol
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

// imported contracts/proposals/OCP-IP-5/AuctionHouseBidRegistry.sol
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

// imported contracts/proposals/OCP-IP-1/IBlindBidRegistry.sol
// implementation from https://github.com/open-city-protocol/OCP-IPs/blob/jeichel/ocp-ip-1/OCP-IPs/ocp-ip-1.md
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

// imported contracts/proposals/OCP-IP-4/Proxiable.sol
// imported contracts/access/roles/ProxyManagerRole.sol
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

// imported contracts/proposals/OCP-IP-5/IAuctionHouse.sol
// imported contracts/proposals/OCP-IP-6/IOCPTokenReceiver.sol
// imported node_modules/@open-city-protocol/erc223/contracts/Receiver_Interface.sol
 /*
 * Contract that is working with ERC223 tokens
 */
 contract ContractReceiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
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

// imported contracts/proposals/OCP-IP-5/IAuctionHouseBiddingComponent.sol
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

// imported contracts/proposals/OCP-IP-5/IAuctionHouseClearingPriceComponent.sol
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
  function percentAllocationFeeNumerator() public view returns(uint256);
  function percentAllocationFeeDenominator() public view returns(uint256);
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

// imported contracts/proposals/OCP-IP-5/IAuctionHouseStateTransition.sol
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

// imported contracts/proposals/OCP-IP-6/OCPToken.sol
// imported node_modules/@open-city-protocol/erc223/contracts/ERC223_Token.sol
// imported node_modules/@open-city-protocol/erc223/contracts/ERC223_Interface.sol
 /* New ERC223 contract interface */
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

 /**
 * ERC223 token by Dexaran
 *
 * https://github.com/Dexaran/ERC223-token-standard
 */
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMathERC223 {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }
    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }
    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}
contract ERC223Token is ERC223, SafeMathERC223 {
  mapping(address => uint) balances;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  // Function to access name of token .
  function name() public view returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() public view returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() public view returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public view returns (uint256 _totalSupply) {
      return totalSupply;
  }
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        assert(_to.call.value(0)(abi.encodeWithSignature(_custom_fallback, msg.sender, _value, _data)));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) public returns (bool success) {
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}
  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
      }
      return (length>0);
    }
  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
}
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }
}

contract OCPToken is ERC223Token {
  constructor() public {
    name = "Open City Token";
    symbol = "OCT"; // todo: ensure unique symbol
    decimals = 18;
    totalSupply = 0xc9f2c9cd04674edea40000000; // 1 trillion coins
    balances[msg.sender] = totalSupply;
  }
}

// imported contracts/proposals/OCP-IP-6/OCPTokenReceiver.sol
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