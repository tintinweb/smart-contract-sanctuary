pragma solidity ^0.4.24;

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

// imported contracts/access/roles/ClearingPriceValidatorRole.sol
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

contract ClearingPriceValidatorRole {
  using Roles for Roles.Role;
  event ClearingPriceValidatorAdded(address indexed account);
  event ClearingPriceValidatorRemoved(address indexed account);
  Roles.Role private proxyManagers;
  constructor() public {
    proxyManagers.add(msg.sender);
  }
  modifier onlyClearingPriceValidator() {
    require(isClearingPriceValidator(msg.sender));
    _;
  }
  function isClearingPriceValidator(address account) public view returns (bool) {
    return proxyManagers.has(account);
  }
  function addClearingPriceValidator(address account) public onlyClearingPriceValidator {
    proxyManagers.add(account);
    emit ClearingPriceValidatorAdded(account);
  }
  function renounceClearingPriceValidator() public {
    proxyManagers.remove(msg.sender);
  }
  function _removeClearingPriceValidator(address account) internal {
    proxyManagers.remove(account);
    emit ClearingPriceValidatorRemoved(account);
  }
}

// imported contracts/proposals/OCP-IP-1/IBlindBidRegistry.sol
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

contract AuctionHouseClearingPriceComponent is Secondary, IAuctionHouseClearingPriceComponent, Proxiable, ClearingPriceValidatorRole {
  struct CostParams {
    uint256 submissionDeposit;
    uint256 percentAllocationFeeNumerator;
    uint256 percentAllocationFeeDenominator;
  }
  struct State {
    bool submissionOpen;
    bool validationOpen;
    bool finalized;
    bool rewardOpen;
  }
  struct Submitter {
    bool accepted;
    bool rewarded;
    uint depositCollected;
    // bidHash =>
    mapping(bytes32 => uint256) clearingPrices;
    mapping(bytes32 => bool) hasClearingPrices;
  }
  IBlindBidRegistry private _bidRegistry;
  bytes private _clearingPriceCode;
  CostParams private _costParams;
  mapping(uint256 => State) private _state;
  // bidHash => paidFees
  mapping(bytes32 => bool) private _paidFees;
  // auction => value
  mapping(uint256 => uint256) private _feeAllocationPool;
  mapping(uint256 => uint256) private _feeAllocationPoolRemainder;
  // auction => validator => submitter => bidHash => clearingPrice
  mapping(uint256 => mapping(address => mapping(address => mapping(bytes32 => uint256)))) private _rejectPrices;
  // auction => submitter =>
  mapping(uint256 => mapping(address => Submitter)) private _submitter;
  // auction => submitter
  mapping(uint256 => uint32) private _numAcceptedSubmitters;
  constructor(address auctionHouse) public {
    transferPrimary(auctionHouse);
  }
  function bidRegistry() public view returns(address) {
    return address(_bidRegistry);
  }
  function clearingPriceCode() public view returns(bytes) {
    return _clearingPriceCode;
  }
  function submissionDeposit() public view returns(uint256) {
    return _costParams.submissionDeposit;
  }
  function percentAllocationFeeNumerator() public view returns(uint256) {
    return _costParams.percentAllocationFeeNumerator;
  }
  function percentAllocationFeeDenominator() public view returns(uint256) {
    return _costParams.percentAllocationFeeDenominator;
  }
  function setBidRegistry(address registry) public onlyPrimary {
    _bidRegistry = IBlindBidRegistry(registry);
  }
  function setClearingPriceCode(bytes reference) public onlyPrimary {
    _clearingPriceCode = reference;
  }
  function setSubmissionDeposit(uint256 deposit) public onlyPrimary {
    _costParams.submissionDeposit = deposit;
  }
  function setPercentAllocationFee(uint256 numerator, uint256 denominator) public onlyPrimary {
    _costParams.percentAllocationFeeNumerator = numerator;
    _costParams.percentAllocationFeeDenominator = denominator;
  }
  function setSubmissionOpen(uint256 auctionId) public onlyPrimary {
    _state[auctionId].submissionOpen = true;
    _state[auctionId].finalized = false;
  }
  function setSubmissionClosed(uint256 auctionId) public onlyPrimary {
    _state[auctionId].submissionOpen = false;
    _state[auctionId].finalized = false;
  }
  function payDeposit(uint256 auctionId, address submitter, uint256 value) public onlyPrimary {
    require(_submitter[auctionId][submitter].depositCollected == 0);
    require(value == _costParams.submissionDeposit);
    require(_state[auctionId].submissionOpen);
    _feeAllocationPool[auctionId] += value;
    _submitter[auctionId][submitter].depositCollected += value;
    _numAcceptedSubmitters[auctionId] += 1;
    _submitter[auctionId][submitter].accepted = true;
  }
  function submitClearingPrice(address submitter, bytes32 bidHash, uint256 clearingPrice) public proxyOrSender(submitter) {
    uint256 auctionId = _bidRegistry.auction(bidHash);
    require(_state[auctionId].submissionOpen);
    require(_submitter[auctionId][submitter].depositCollected >= _costParams.submissionDeposit);
    _submitter[auctionId][submitter].clearingPrices[bidHash] = clearingPrice;
    _submitter[auctionId][submitter].hasClearingPrices[bidHash] = true;
    emit ClearingPriceSubmitted(submitter, auctionId, bidHash, clearingPrice);
  }
  function setValidationOpen(uint256 auctionId) public onlyPrimary {
    _state[auctionId].validationOpen = true;
    _state[auctionId].finalized = false;
  }
  function setValidationClosed(uint256 auctionId) public onlyPrimary {
    _state[auctionId].validationOpen = false;
    _state[auctionId].finalized = true;
  }
  function rejectClearingPriceSubmission(
    address validator,
    address submitter,
    bytes32 bidHash,
    uint256 correctedClearingPrice
  ) public proxyOrSender(validator) {
    uint256 auctionId = _bidRegistry.auction(bidHash);
    require(_state[auctionId].validationOpen);
    uint256 submittedClearingPrice = _submitter[auctionId][submitter].clearingPrices[bidHash];
    require(correctedClearingPrice != submittedClearingPrice);
    _rejectPrices[auctionId][validator][submitter][bidHash] = correctedClearingPrice;
    emit ClearingPriceRejected(validator, submitter, auctionId, bidHash, correctedClearingPrice);
    if (isClearingPriceValidator(validator)) {
      if (_submitter[auctionId][submitter].accepted) {
        _numAcceptedSubmitters[auctionId] -= 1;
        _submitter[auctionId][submitter].accepted = false;
      }
      emit ClearingPriceSubmitterRejected(validator, submitter, auctionId, bidHash, correctedClearingPrice);
    }
  }
  function isSubmitterAccepted(uint256 auctionId, address submitter) public view returns(bool) {
    return _submitter[auctionId][submitter].accepted;
  }
  function isValidSubmitter(address submitter, bytes32 bidHash) public view returns(bool) {
    uint256 auctionId = _bidRegistry.auction(bidHash);
    return _state[auctionId].finalized && _submitter[auctionId][submitter].accepted;
  }
  function hasClearingPrice(address anyValidSubmitter, bytes32 bidHash) public view returns(bool) {
    address submitter = anyValidSubmitter;
    uint256 auctionId = _bidRegistry.auction(bidHash);
    return
      _state[auctionId].finalized &&
      _submitter[auctionId][submitter].accepted &&
      _submitter[auctionId][submitter].hasClearingPrices[bidHash];
  }
  function clearingPrice(address anyValidSubmitter, bytes32 bidHash) public view returns(uint256) {
    address submitter = anyValidSubmitter;
    uint256 auctionId = _bidRegistry.auction(bidHash);
    require(hasClearingPrice(submitter, bidHash));
    return _submitter[auctionId][submitter].clearingPrices[bidHash];
  }
  function paidBidAllocationFee(bytes32 bidHash) public view returns(bool) {
    return _paidFees[bidHash];
  }
  function calcBidAllocationFee(bytes32 bidHash) public view returns(uint256) {
    if (_bidRegistry.auctionStatus(bidHash) == uint8(IBidRegistry.AuctionStatus.Won)) {
      uint256 bidClearingPrice = _bidRegistry.clearingPrice(bidHash);
      return (_costParams.percentAllocationFeeNumerator * bidClearingPrice) / _costParams.percentAllocationFeeDenominator;
    } else {
      return 0;
    }
  }
  function payBidAllocationFee(bytes32 bidHash, uint256 fee) public onlyPrimary {
    require(!_paidFees[bidHash]);
    uint256 auctionId = _bidRegistry.auction(bidHash);
    _feeAllocationPool[auctionId] += fee;
    _paidFees[bidHash] = true;
  }
  function setRewardOpen(uint256 auctionId) public onlyPrimary {
    _state[auctionId].rewardOpen = true;
    if (_numAcceptedSubmitters[auctionId] > 0) {
      uint256 avgReward = _feeAllocationPool[auctionId] / _numAcceptedSubmitters[auctionId];
      uint256 totalReward = avgReward * _numAcceptedSubmitters[auctionId];
      _feeAllocationPoolRemainder[auctionId] = _feeAllocationPool[auctionId] - totalReward;
    }
  }
  function setRewardClosed(uint256 auctionId) public onlyPrimary {
    _state[auctionId].rewardOpen = false;
  }
  function rewarded(uint256 auctionId, address clearingPriceSubmitter) public view returns(bool) {
    return _submitter[auctionId][clearingPriceSubmitter].rewarded;
  }
  function calcReward(uint256 auctionId, address clearingPriceSubmitter) public view returns(uint256) {
    uint reward = 0;
    if (_submitter[auctionId][clearingPriceSubmitter].accepted) {
      reward = _feeAllocationPool[auctionId] / _numAcceptedSubmitters[auctionId];
      if (_feeAllocationPoolRemainder[auctionId] > 0) {
        reward += 1;
      }
    }
    return reward;
  }
  function payReward(uint256 auctionId, address clearingPriceSubmitter, uint256 reward) public onlyPrimary {
    require(reward == calcReward(auctionId, clearingPriceSubmitter));
    require(_state[auctionId].rewardOpen);
    require(!_submitter[auctionId][clearingPriceSubmitter].rewarded);
    _submitter[auctionId][clearingPriceSubmitter].rewarded = true;
    if (_feeAllocationPoolRemainder[auctionId] > 0) {
      _feeAllocationPoolRemainder[auctionId] -= 1;
    }
  }
}