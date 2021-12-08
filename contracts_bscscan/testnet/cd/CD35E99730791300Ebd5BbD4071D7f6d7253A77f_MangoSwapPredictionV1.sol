// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
  function _msgSender() internal view virtual returns(address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns(bytes memory) {
    this;
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view virtual returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function OwnershipRenounce() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function OwnershipTransfer(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

abstract contract Pausable is Context {

  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() {
    _paused = false;
  }

  function paused() public view virtual returns(bool) {
    return _paused;
  }

  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}

contract MangoSwapPredictionV1 is Ownable, Pausable, ReentrancyGuard {


  struct Round {
    uint256 epoch;
    uint256 bullAmount;
    uint256 bearAmount;
    uint256 rewardBaseCalAmount;
    uint256 rewardAmount;
    int256 lockPrice;
    int256 closePrice;
    uint32 startTimestamp;
    uint32 lockTimestamp;
    uint32 closeTimestamp;
    uint32 lockPriceTimestamp;
    uint32 closePriceTimestamp;
    bool closed;
    bool cancelled;
  }

  enum Position {
    Bull,
    Bear
  }

  struct BetInfo {
    Position position;
    uint256 amount;
    bool claimed;
  }

  mapping(uint256 => Round) public Rounds;
  mapping(uint256 => mapping(address => BetInfo)) public Bets;
  mapping(address => uint256[]) public UserBets;
  mapping(address => bool) internal Blacklist;

  uint256 public currentEpoch;

  address public operatorAddress;
  string public priceSource;

  uint256 public rewardRate = 97;
  uint256 constant internal minimumRewardRate = 90;
  uint256 public intervalSeconds = 300;
  uint256 public minBetAmount = 1000000000000000;
  uint256 public bufferSeconds = 30;

  uint256 public potAmount;


  bool public startOnce = false;
  bool public lockOnce = false;

  event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount);
  event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount);
  event HouseBet(address indexed sender, uint256 indexed epoch, uint256 bullAmount, uint256 bearAmount);
  event LockRound(uint256 indexed epoch, int256 price, uint32 timestamp);
  event EndRound(uint256 indexed epoch, int256 price, uint32 timestamp);
  event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);

  event StartRound(uint256 indexed epoch);
  event CancelRound(uint256 indexed epoch);
  event Pause(uint256 indexed epoch);
  event Unpause(uint256 indexed epoch);
  event PotClaim(uint256 amount);


  event RewardsCalculated(
    uint256 indexed epoch,
    uint256 rewardBaseCalAmount,
    uint256 rewardAmount,
    uint256 potAmount
  );

  event InjectFunds(address indexed sender);
  event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);
  event BufferAndIntervalSecondsUpdated(uint256 bufferSeconds, uint256 intervalSeconds);
  event NewPriceSource(string priceSource);

  constructor(address _operatorAddress) {
    operatorAddress = _operatorAddress;
  }

  modifier onlyOwnerOrOperator() {
    require(msg.sender == _owner || msg.sender == operatorAddress, "Only owner or operator can call this function");
    _;
  }


  modifier notContract() {
    require(!_isContract(msg.sender), "contract not allowed");
    require(msg.sender == tx.origin, "proxy contract not allowed");
    _;
  }

  function _safeStartRound(uint256 epoch, uint32 timestamp) internal {

    Round storage round = Rounds[epoch];
    round.startTimestamp = uint32(timestamp);
    round.lockTimestamp = uint32(timestamp + intervalSeconds);
    round.closeTimestamp = uint32(timestamp + (2 * intervalSeconds));
    // round.startTimestamp = uint32(block.timestamp);
    // round.lockTimestamp = uint32(block.timestamp + intervalSeconds);
    // round.closeTimestamp = uint32(block.timestamp + (2 * intervalSeconds));
    round.epoch = epoch;

    emit StartRound(epoch);
  }

  function _safeLockRound(uint256 epoch, int256 price, uint32 timestamp) internal {
    require(Rounds[epoch].startTimestamp != 0, "Can only lock round after round has started");
    require(block.timestamp >= Rounds[epoch].lockTimestamp, "Can only lock round after lock timestamp"); // 19:24:10
    require(block.timestamp <= Rounds[epoch].closeTimestamp, "Can only lock before end timestamp"); // 19:29:10

    Round storage round = Rounds[epoch];
    round.lockPrice = price;
    round.lockPriceTimestamp = timestamp;

    emit LockRound(epoch, price, timestamp);
  }

  function _safeEndRound(uint256 epoch, int256 price, uint32 timestamp) internal {
    require(Rounds[epoch].lockTimestamp != 0, "Can only end round after round has locked");
    require(block.timestamp >= Rounds[epoch].closeTimestamp, "Can only end round after endBlock");

    Round storage round = Rounds[epoch];
    round.closePrice = price;
    round.closePriceTimestamp = timestamp;
    round.closed = true;

    emit EndRound(epoch, price, timestamp);
  }

  function _calculateRewards(uint256 epoch) internal {

    require(Rounds[epoch].rewardBaseCalAmount == 0 && Rounds[epoch].rewardAmount == 0, "Rewards calculated");
    Round storage round = Rounds[epoch];
    uint256 rewardBaseCalAmount;
    uint256 rewardAmount;
    uint256 potAmt;

    uint256 totalAmount = round.bullAmount + round.bearAmount;

    if (round.closePrice > round.lockPrice) {
      rewardBaseCalAmount = round.bullAmount;
      rewardAmount = totalAmount * rewardRate / 100;
    }else if (round.closePrice < round.lockPrice) {
      rewardBaseCalAmount = round.bearAmount;
      rewardAmount = totalAmount * rewardRate / 100;
    }else {
      rewardBaseCalAmount = 0;
      rewardAmount = 0;
    }
    round.rewardBaseCalAmount = rewardBaseCalAmount;
    round.rewardAmount = rewardAmount;

    potAmount += totalAmount - rewardAmount;

    emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount, potAmt);
  }

  function _safeCancelRound(uint256 epoch, bool cancelled, bool closed) internal {
    Round storage round = Rounds[epoch];
    round.cancelled = cancelled;
    round.closed = closed;
    emit CancelRound(epoch);
  }


  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call {
      gas: 23000,
      value: value
    }("");
    require(success, "Transfer Failed");
  }


  function _isContract(address addr) internal view returns(bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  function _bettable(uint256 epoch) internal view returns(bool) {
    return
      Rounds[epoch].startTimestamp != 0 &&
      Rounds[epoch].lockTimestamp != 0 &&
      block.timestamp > Rounds[epoch].startTimestamp &&
      block.timestamp < Rounds[epoch].lockTimestamp;
  }

  function ownerSetOperator(address _operatorAddress) external onlyOwner {
    require(_operatorAddress != address(0), "Cannot be zero address");
    operatorAddress = _operatorAddress;
  }

  function ownerFundsInject() external payable onlyOwner {
    emit InjectFunds(msg.sender);
  }

  function ownerFundsExtract(uint256 value) external onlyOwner {
    _safeTransferBNB(_owner, value);
  }

  function ownerRewardUser(address user, uint256 value) external onlyOwner {
    _safeTransferBNB(user, value);
  }

  function ownerBlackListInsert(address _user) public onlyOwner {
    require(!Blacklist[_user], "Address already blacklisted");
    Blacklist[_user] = true;
  }

  function ownerBlackListRemove(address _user) public onlyOwner {
    require(Blacklist[_user], "Address already whitelisted");
    Blacklist[_user] = false;
  }

  function ownerChangePriceSource(string memory _priceSource) external onlyOwner {
    require(bytes(_priceSource).length > 0, "Price source can not be empty");

    priceSource = _priceSource;
    emit NewPriceSource(_priceSource);
  }


  function ownerHouseBet(uint256 bullAmount, uint256 bearAmount) external onlyOwnerOrOperator whenNotPaused notContract {
    require(_bettable(currentEpoch), "Round not bettable");
    require(address(this).balance >= bullAmount + bearAmount, "Contract balance must be greater than house bet totals");

    if (bullAmount > 0) {
      Round storage round = Rounds[currentEpoch];
      round.bullAmount += bullAmount;

      BetInfo storage betInfo = Bets[currentEpoch][address(this)];
      betInfo.position = Position.Bull;
      betInfo.amount = bullAmount;
      UserBets[address(this)].push(currentEpoch);
    }

    if (bearAmount > 0) {
      Round storage round = Rounds[currentEpoch];
      round.bearAmount += bearAmount;

      BetInfo storage betInfo = Bets[currentEpoch][address(this)];
      betInfo.position = Position.Bear;
      betInfo.amount = bearAmount;
      UserBets[address(this)].push(currentEpoch);
    }

    emit HouseBet(address(this), currentEpoch, bullAmount, bearAmount);
  }

  function controlPause() public onlyOwnerOrOperator whenNotPaused {
    _pause();

    emit Pause(currentEpoch);
  }

  function claimPot() external nonReentrant onlyOwner {
    uint256 currentpotAmount = potAmount;
    potAmount = 0;
    _safeTransferBNB(_owner, currentpotAmount);

    emit PotClaim(currentpotAmount);
  }

  function controlResume() public onlyOwnerOrOperator whenPaused {
    startOnce = false;
    lockOnce = false;
    _unpause();

    emit Unpause(currentEpoch);
  }

  function controlRoundStart(uint32 timestamp) external onlyOwnerOrOperator whenNotPaused {
    require(!startOnce, "Can only run startRound once");

    currentEpoch = currentEpoch + 1;
    _safeStartRound(currentEpoch, timestamp);
    startOnce = true;
  }


  function controlRoundLock(int256 price, uint32 timestamp) external onlyOwnerOrOperator whenNotPaused {
    require(startOnce, "Can only run after startRound is triggered");
    require(!lockOnce, "Can only run lockRound once");

    _safeLockRound(currentEpoch, price, timestamp);

    currentEpoch = currentEpoch + 1;
    _safeStartRound(currentEpoch, timestamp);
    lockOnce = true;
  }

  function controlRoundExecute(int256 price, uint32 timestamp) external onlyOwnerOrOperator whenNotPaused {

    require(startOnce && lockOnce, "Can only run after startRound and lockRound is triggered");
    require(Rounds[currentEpoch - 2].closeTimestamp != 0, "Can only start round after round n-2 has ended");
    require(block.timestamp >= Rounds[currentEpoch - 2].closeTimestamp, "Can only start new round after round n-2 endBlock");

    _safeLockRound(currentEpoch, price, timestamp);
    _safeEndRound(currentEpoch - 1, price, timestamp);

    _calculateRewards(currentEpoch - 1);

    currentEpoch = currentEpoch + 1;

    _safeStartRound(currentEpoch, timestamp);

  }


  function controlRoundCancel(uint256 epoch, bool cancelled, bool closed) external onlyOwner {
    _safeCancelRound(epoch, cancelled, closed);
  }


  function setBufferAndIntervalSeconds(uint256 _bufferSeconds, uint256 _intervalSeconds) external onlyOwner {
    require(_bufferSeconds < _intervalSeconds, "BufferSeconds must be inferior to intervalSeconds");
    bufferSeconds = _bufferSeconds;
    intervalSeconds = _intervalSeconds;
    emit BufferAndIntervalSecondsUpdated(_bufferSeconds, _intervalSeconds);
  }


  function settingsSetRewardRate(uint256 _rewardRate) external onlyOwner {
    require(_rewardRate >= minimumRewardRate, "Reward rate can't be lower than minimum reward rate");
    rewardRate = _rewardRate;
  }


  function settingsSetMinBetAmount(uint256 _minBetAmount) external onlyOwner {
    minBetAmount = _minBetAmount;

    emit MinBetAmountUpdated(currentEpoch, minBetAmount);
  }


  function mangoBetBull(uint256 epoch) external payable whenNotPaused nonReentrant notContract {
    require(epoch == currentEpoch, "Bet is too early/late");
    require(_bettable(epoch), "Round not bettable");
    require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
    require(Bets[epoch][msg.sender].amount == 0, "Can only bet once per round");
    require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");

    uint256 amount = msg.value;
    Round storage round = Rounds[epoch];
    round.bullAmount = round.bullAmount + amount;

    BetInfo storage betInfo = Bets[epoch][msg.sender];
    betInfo.position = Position.Bull;
    betInfo.amount = amount;
    UserBets[msg.sender].push(epoch);

    emit BetBull(msg.sender, currentEpoch, amount);
  }


  function mangoBetBear(uint256 epoch) external payable whenNotPaused nonReentrant notContract {
    require(epoch == currentEpoch, "Bet is too early/late");
    require(_bettable(epoch), "Round not bettable");
    require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
    require(Bets[epoch][msg.sender].amount == 0, "Can only bet once per round");
    require(!Blacklist[msg.sender], "Blacklisted! Are you a bot ?");

    uint256 amount = msg.value;
    Round storage round = Rounds[epoch];
    round.bearAmount = round.bearAmount + amount;

    BetInfo storage betInfo = Bets[epoch][msg.sender];
    betInfo.position = Position.Bear;
    betInfo.amount = amount;
    UserBets[msg.sender].push(epoch);

    emit BetBear(msg.sender, epoch, amount);
  }


  function mangoClaim(uint256[] calldata epochs) external nonReentrant notContract {

    uint256 reward;

    for (uint256 i = 0; i < epochs.length; i++) {
      require(Rounds[epochs[i]].startTimestamp != 0, "Round has not started");
      require(block.timestamp > Rounds[epochs[i]].closeTimestamp, "Round has not ended");

      uint256 addedReward = 0;

      if (Rounds[epochs[i]].closed) {
        require(claimable(epochs[i], msg.sender), "Not eligible for claim");
        Round memory round = Rounds[epochs[i]];
        addedReward = (Bets[epochs[i]][msg.sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
      }else {
        require(refundable(epochs[i], msg.sender), "Not eligible for refund");
        addedReward = Bets[epochs[i]][msg.sender].amount;
      }

      Bets[epochs[i]][msg.sender].claimed = true;
      reward += addedReward;

      emit Claim(msg.sender, epochs[i], addedReward);
    }

    if (reward > 0) {
      _safeTransferBNB(address(msg.sender), reward);
    }

  }

  function getUserRounds(address user, uint256 cursor, uint256 size) external view returns(uint256[] memory, BetInfo[] memory, uint256) {
    uint256 length = size;

    if (length > UserBets[user].length - cursor) {
      length = UserBets[user].length - cursor;
    }

    uint256[] memory values = new uint256[](length);
    BetInfo[] memory betInfo = new BetInfo[](length);

    for (uint256 i = 0; i < length; i++) {
      values[i] = UserBets[user][cursor + i];
      betInfo[i] = Bets[values[i]][user];
    }

    return (values, betInfo, cursor + length);
  }

  function getUserRoundsLength(address user) external view returns(uint256) {
    return UserBets[user].length;
  }


  function claimable(uint256 epoch, address user) public view returns(bool) {
    BetInfo memory betInfo = Bets[epoch][user];
    Round memory round = Rounds[epoch];

    if (round.lockPrice == round.closePrice) {
      return false;
    }

    return round.closed && !betInfo.claimed && ((round.closePrice > round.lockPrice &&
      betInfo.position == Position.Bull) || (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
  }

  function refundable(uint256 epoch, address user) public view returns(bool) {
    BetInfo memory betInfo = Bets[epoch][user];
    Round memory round = Rounds[epoch];

    return !round.closed && !betInfo.claimed && block.timestamp > round.closeTimestamp + bufferSeconds && betInfo.amount != 0;
  }


  function currentBlockNumber() public view returns(uint256) {
    return block.number;
  }

  function currentBlockTimestamp() public view returns(uint256) {
    return block.timestamp;
  }
}