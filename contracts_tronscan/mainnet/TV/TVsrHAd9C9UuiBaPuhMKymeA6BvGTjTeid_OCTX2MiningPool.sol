//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: Migrations.sol

pragma solidity >=0.4.23 <0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

//SourceUnit: MinterRole.sol

pragma solidity ^0.5.10;

import "./Roles.sol";

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

//SourceUnit: OCTX2MiningPool.sol

/*! OCTX2MiningPool.sol | © 2021 ORACLETX FINANCE  */

pragma solidity 0.5.10;

import "./SafeMath.sol";
import "./OCTX2Token.sol";


contract OCTX2MiningPool {
  using SafeMath for uint256;

  struct User {
    uint256 octx2_userBalance;
    uint256 staked;
    uint256 dividends;
    uint256 entries;
    uint256 unfreezing;
    uint256 unfreeze_timer;
    uint256 investment;
    uint256 withdrawn;
    uint256 lastActivityRound;
  }

  struct Round {
    uint256 totalPoolDrop;
    uint256 currentRoundDrop;
    uint256 payoutRatio;
    bool committed;
  }

  struct DrawInfo {
    bytes32 secretHash;
    bytes32 entropy;
    uint256 winningNumber;
    address winner;
    uint256 roundPrize;
    address[] committedEntryRecord;
    bool committed;
    bool rewarded;
    bool skipped;
  }

  address payable public owner;
  address payable public growth;
  address payable public reserveAddr;
  address payable public prizeAddr;
  address public token_address;
  uint256 private roundIndex;
  uint256 public roundRate;
  uint256 private initialRate;
  uint256 public ticketRatio;
  uint256 public drawIndex;
  uint256 public rateOfIncrease;
  uint256 public coveragePercentage;
  uint256 public total_invested;
  uint256 public total_withdrawn;
  uint256 public total_mined;
  uint256 public burned;
  uint256 private burnPortion;
  uint256 public total_frozen;
  uint256 public roundRemaining;
  uint256 public start_timer;
  uint256 public eventEndTimer;
  uint256 public reserveBalance;
  uint256 public reserveContributions;
  uint256 public dropsContribution;

  mapping(address => User) public users;
  mapping(uint256 => Round) public roundDetail;
  mapping(uint256 => DrawInfo) public draws;
  mapping(address => uint256) public userPromoTracker;

  address payable[] public entries;
  uint256 public drawPrize;
  uint256 public prizeContributions;
  uint256 public availablePromoEntries;
  uint256 public availablePromoBuy;
  uint256 public draw_timer;

  event NewDeposit(address indexed addr, uint256 amount);

  event Withdraw(address indexed addr, uint256 amount);

  event WithdrawOCTX2(address indexed addr, uint256 amount);

  event DepositOCTX2(address indexed addr, uint256 amount);

  event ContributeToReserves(address indexed addr, uint256 amount);
  
  event ContributeToPrize(address indexed addr, uint256 amount);

  event ContributeToDrops(address indexed addr, uint256 amount, uint256 round);

  event ExchangePayout(address indexed addr, uint256 amount, uint256 payout);

  event Rewarded(uint256 indexed drawIndex, uint256 winningNumber, address winner, uint256 prize);

  event NewRound(uint256 indexed newRound, uint256 indexed previousRound, uint256 payout);

  event Freeze(address indexed addr, uint256 amount);

  event Unfreeze(address indexed addr, uint256 amount);

  event ClaimUnfreeze(address indexed addr, uint256 amount);

  event CancelUnfreeze(address indexed addr, uint256 amount);

  event EntryBuy(address indexed addr, uint256 entries, uint256 price);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor(uint8 _initialRate, uint8 _roundIndex, address _tokenAddr, uint256 _beginAt,
    address payable _reserveAddr, address payable _prizeAddr, address payable _growth, bytes32 _secretHash) public {
    owner = msg.sender;
    initialRate = _initialRate;
    roundRate = _initialRate;
    roundIndex = _roundIndex;
    token_address = _tokenAddr; 
    start_timer = _beginAt; 

    roundRemaining = 1e12;
    rateOfIncrease = 1e12;
    coveragePercentage = 100;
    availablePromoEntries = 10000;
    availablePromoBuy = 10000;
    burnPortion = 20;
    draw_timer = start_timer.add(2246400);
    eventEndTimer = start_timer.add(7776000);
    drawIndex = 1;

    draws[drawIndex].secretHash = _secretHash;
    reserveAddr = _reserveAddr;
    prizeAddr = _prizeAddr;
    growth = _growth;
  }
  
  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Can only be called by the current owner.
  */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0), "New owner cannot be the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function ownerNewRound() public onlyOwner {
    _newRound();
  }

  function _newRound() internal {
    require(block.timestamp >= start_timer.add(roundIndex * 86400));

    uint256 priorTotalPool = roundDetail[roundIndex].totalPoolDrop;
    uint256 newCurrentDrop = priorTotalPool / 20;
    uint256 newTotalPool = priorTotalPool.sub(newCurrentDrop);

    Round storage nextRound = roundDetail[roundIndex + 1];

    nextRound.totalPoolDrop = newTotalPool;
    nextRound.currentRoundDrop = newCurrentDrop;

    if (roundDetail[roundIndex].committed == false) {
      roundDetail[roundIndex].payoutRatio = roundDetail[roundIndex].currentRoundDrop.mul(1000000).div(total_frozen);
      roundDetail[roundIndex].committed = true;

      roundIndex = roundIndex + 1;
    }

    address reserve = reserveAddr;
    _updateDividendPayout(reserve);
    reserveBalance = reserveBalance.add(users[reserve].dividends.mul(9).div(10));
    reserveAddr.transfer(users[reserve].dividends.div(10));
    users[reserve].dividends = 0;

    address prize = prizeAddr;
    _updateDividendPayout(prize);
    drawPrize = drawPrize.add(users[prize].dividends.mul(9).div(10));
    prizeAddr.transfer(users[prize].dividends.div(10));
    users[prize].dividends = 0;


    uint256 priorRound = roundIndex - 1;
    uint256 lastPayout = roundDetail[priorRound].payoutRatio;
    emit NewRound(roundIndex, priorRound, lastPayout);
  }

  function getRoundIndex() public view returns(uint256) {
    return roundIndex;
  }

  function getRoundTotalPoolDrop() public view returns(uint256) {
    return roundDetail[roundIndex].totalPoolDrop;
  }

  function getRoundCurrentRoundDrop() public view returns(uint256) {
    return roundDetail[roundIndex].currentRoundDrop;
  }


  function freezeRate() public view returns(uint256) {
    return total_frozen.mul(100000).div(total_mined);
  }

  function getEntryCount() public view returns(uint256) {
    return entries.length;
  }

  function getBurnPortion() public view returns(uint256) {
    return burnPortion;
  }

  function setburnPortion(uint256 _percent) external onlyOwner {
    require(_percent <= 100);
    burnPortion = _percent;
  }

  function getAvailablePromoEntries() public view returns(uint256) {
    return availablePromoEntries;
  }

  function getAvailablePromoBuy() public view returns(uint256) {
    return availablePromoBuy;
  }

  function getPrizeStaked() public view returns(uint256) {
    return users[prizeAddr].staked;
  }

  function getReserveStaked() public view returns(uint256) {
    return users[reserveAddr].staked;
  }

  function _updateRate() internal {
    roundRate = initialRate.add(total_mined / rateOfIncrease);
  }

  function setGrowthAddr(address payable _growthAddr) external onlyOwner {
    growth = _growthAddr;
  }

  function setCoveragePercentage(uint256 _coverage) external onlyOwner {
    require(_coverage > 0 && _coverage < 1000);
    coveragePercentage = _coverage;
  }

  function deposit() external payable {
    require(block.timestamp >= start_timer);
    require(msg.value >= 2e7, "Require minimum amount of 20 TRX");
    require(msg.value <= roundRate * 1e12, "Hit max limit of for single deposit");

    User storage user = users[msg.sender];

    if (user.lastActivityRound == 0 || user.staked == 0) {
      user.lastActivityRound = roundIndex;
    }

    if (msg.value / roundRate >= roundRemaining) {
      _updateMiningRate(msg.sender, msg.value);
    }
    else {
      OCTX2Token(token_address).mint(address(this), (msg.value).div(roundRate));
      user.octx2_userBalance = user.octx2_userBalance.add((msg.value).div(roundRate));

      roundRemaining = roundRemaining.sub(msg.value / roundRate);
      total_mined = total_mined.add(msg.value / roundRate);

      user.investment = user.investment.add(msg.value);
      total_invested = total_invested.add(msg.value);
    }

    roundDetail[roundIndex].totalPoolDrop = roundDetail[roundIndex].totalPoolDrop.add(msg.value / 2);
    roundDetail[roundIndex].currentRoundDrop = roundDetail[roundIndex].currentRoundDrop + (msg.value / 5);
    reserveBalance = reserveBalance.add(msg.value / 25);
    drawPrize = drawPrize.add(msg.value / 100);

    owner.transfer(msg.value / 10);
    growth.transfer(msg.value * 3 / 20);

    emit NewDeposit(msg.sender, msg.value);

    if (block.timestamp < eventEndTimer && availablePromoEntries > 0) {
      _promoLaunchEntries(msg.sender, msg.value);
    }

    if (block.timestamp >= start_timer.add(roundIndex * 86400)) {
      _newRound();
    }

  } 
  
  function _updateMiningRate(address _user, uint256 _depAmount) internal {
    uint256 carryoverAmt = _depAmount.sub(roundRemaining.mul(roundRate));

    User storage user = users[_user];

    total_mined = total_mined.add(roundRemaining);
    uint256 addToBalance = roundRemaining;

    _updateRate();

    addToBalance = addToBalance.add(carryoverAmt.div(roundRate));

    OCTX2Token(token_address).mint(address(this), addToBalance);
    user.octx2_userBalance = user.octx2_userBalance.add(addToBalance);

    uint256 resetRemaining = 1e12;
    resetRemaining = resetRemaining.sub(carryoverAmt.div(roundRate));
    roundRemaining = resetRemaining;

    total_mined = total_mined.add(carryoverAmt.div(roundRate));
    user.investment = user.investment.add(_depAmount);
    total_invested = total_invested.add(_depAmount);

  }

  function _updateDividendPayout(address _addr) internal {
    User storage user = users[_addr];
    uint256 payoutSum;

    for(uint256 i = user.lastActivityRound; i < roundIndex; i++ ) {
      payoutSum = payoutSum.add(roundDetail[i].payoutRatio);
    }

    user.lastActivityRound = roundIndex;

    if (payoutSum > 0 && user.staked > 0) {
      user.dividends = user.dividends.add(payoutSum.mul(user.staked).div(1000000));
    }
  }

  function dividendOf(address _addr) external view returns(uint256 value) {
    uint256 payoutSum;

    for(uint256 i = users[_addr].lastActivityRound; i < roundIndex; i++ ) {
      payoutSum = payoutSum.add(roundDetail[i].payoutRatio);
    }

    uint256 users_div = users[_addr].dividends;
    uint256 added_dividends = payoutSum.mul(users[_addr].staked).div(1000000);

    return users_div.add(added_dividends);

  }

  function freeze(uint256 _amount) public {
    User storage user = users[msg.sender];

    require(_amount >= 1000000, "Minimum freeze of at least 1 token");
    require(user.octx2_userBalance >= _amount, "Token balance not enough / Invalid token amount to freeze");


    if (user.lastActivityRound < roundIndex && user.staked > 0) {
      _updateDividendPayout(msg.sender);
    }

    user.octx2_userBalance = user.octx2_userBalance.sub(_amount);
    user.staked = user.staked.add(_amount);
    total_frozen = total_frozen.add(_amount);

    emit Freeze(msg.sender, _amount);
  }

  function withdraw() external {
    User storage user = users[msg.sender];

    if (user.lastActivityRound < roundIndex && user.staked > 0) {
      _updateDividendPayout(msg.sender);
    }

    require(user.dividends > 0, "User does not have any dividends to withdraw");

    uint256 payoutAmount = user.dividends;

    user.dividends = 0;
    user.withdrawn = user.withdrawn.add(payoutAmount);
    total_withdrawn = total_withdrawn.add(payoutAmount);

    msg.sender.transfer(payoutAmount);

    emit Withdraw(msg.sender, payoutAmount);

    if (block.timestamp >= start_timer.add(roundIndex * 86400)) {
      _newRound();
    }
  }

  function unfreeze(uint256 _amount) external {
    User storage user = users[msg.sender];

    require(_amount <= user.staked, "Invalid amount to unfreeze");

    if (user.lastActivityRound < roundIndex && user.staked > 0) {
      _updateDividendPayout(msg.sender);
    }

    if (user.unfreezing > 0 && block.timestamp >= user.unfreeze_timer + 172800) {
      claimUnfreeze();
    }

    if (user.unfreezing > 0 && block.timestamp < user.unfreeze_timer + 172800) {
      user.unfreeze_timer = block.timestamp;
      user.staked = user.staked.sub(_amount);
      user.unfreezing = user.unfreezing.add(_amount);
      total_frozen = total_frozen.sub(_amount);
    }

    if (user.unfreezing == 0) {
      user.unfreeze_timer = block.timestamp;
      user.staked = user.staked.sub(_amount);
      total_frozen = total_frozen.sub(_amount);
      user.unfreezing = _amount;
    }

    emit Unfreeze(msg.sender, _amount);
  }

  function claimUnfreeze() public {
    User storage user = users[msg.sender];

    require(user.unfreezing > 0, "No tokens are being unfreeze (nothing to claim)");
    require(block.timestamp >= user.unfreeze_timer + 172800, "Unfreezing period has not pass yet");

    uint256 amountUnfreezing = user.unfreezing;
    user.unfreezing = 0;
    user.octx2_userBalance = user.octx2_userBalance.add(amountUnfreezing);

    emit ClaimUnfreeze(msg.sender, amountUnfreezing);
  }

  function cancelUnfreeze() public {
    User storage user = users[msg.sender];

    require(user.unfreezing > 0, "No tokens are being unfreeze");
  
    uint256 amountUnfreezing = user.unfreezing;
    user.unfreezing = 0;

    if (user.lastActivityRound < roundIndex && user.staked > 0) {
      _updateDividendPayout(msg.sender);
    }

    user.staked = user.staked.add(amountUnfreezing);
    total_frozen = total_frozen.add(amountUnfreezing);
    
    emit CancelUnfreeze(msg.sender, amountUnfreezing);
  }

  function withdrawOCTX2(uint256 _amount) external {
    User storage user = users[msg.sender];
    require(user.octx2_userBalance >= _amount, "Unavailable amount / Invalid balance for withdrawal");

    user.octx2_userBalance = user.octx2_userBalance.sub(_amount);
    OCTX2Token(token_address).transfer(msg.sender, _amount);

    emit WithdrawOCTX2(msg.sender, _amount);
  }

  function depositOCTX2(uint256 _amount) external {
   
    OCTX2Token(token_address).transferFrom(msg.sender, address(this), _amount);

    User storage user = users[msg.sender];
    user.octx2_userBalance = user.octx2_userBalance.add(_amount);

    emit DepositOCTX2(msg.sender, _amount);
  }

  function contributeToReserves() external payable {
    reserveBalance = reserveBalance.add(msg.value);
    reserveContributions = reserveContributions.add(msg.value);

    emit ContributeToReserves(msg.sender, msg.value);
  }

  function contributeToPrize() external payable {
    drawPrize = drawPrize.add(msg.value);
    prizeContributions = prizeContributions.add(msg.value);

    emit ContributeToPrize(msg.sender, msg.value);
  }

  function contributeToDrops() external payable {
    roundDetail[roundIndex].totalPoolDrop = roundDetail[roundIndex].totalPoolDrop.add(msg.value);
    dropsContribution = dropsContribution.add(msg.value);

    emit ContributeToDrops(msg.sender, msg.value, roundIndex);
  }

  function exchangeReserves(uint256 _amount) external {
    User storage user = users[msg.sender];
    require(user.octx2_userBalance >= _amount, "Invalid exchange amount or unavailable balance");

    require(_amount >= 1e7, "minimum exchange amount of 10 OCTX2");
    
    uint256 supplyCoverage = OCTX2Token(token_address).totalSupply().mul(coveragePercentage).div(1000);
    uint256 payoutExchangeRate = reserveBalance.div(supplyCoverage);

    user.octx2_userBalance = user.octx2_userBalance.sub(_amount);

    OCTX2Token(token_address).burn(_amount.mul(burnPortion).div(100));
    burned = burned.add(_amount.mul(burnPortion).div(100));

    users[reserveAddr].staked = users[reserveAddr].staked.add(_amount.mul(100 - burnPortion).div(100));
    total_frozen = total_frozen.add(_amount.mul(100 - burnPortion).div(100));

    uint256 reservePayout = _amount.mul(payoutExchangeRate).mul(99).div(100); 
    reserveBalance = reserveBalance.sub(reservePayout);
    msg.sender.transfer(reservePayout);

    emit ExchangePayout(msg.sender, _amount, reservePayout);
  }

  function setSecretHash(uint256 _drawRound, bytes32 _nextSecretHash) public onlyOwner {
    require(block.timestamp < draw_timer.add(_drawRound * 604800).sub(172800), "Restricted. Pass time window to change."); 
    draws[_drawRound].secretHash = _nextSecretHash;
  }

  function rewardDrawing(uint256 _drawRound, string memory _secret, string memory _salt) public onlyOwner {
    require(block.timestamp >= draw_timer.add(_drawRound * 604800));

    DrawInfo storage draw = draws[_drawRound];

    // require drawing has not been rewarded yet & authenticate and validate the pre-committed secretHash
    require(draw.committed == true && draw.rewarded == false, 'Either not committed yet or already rewarded.');
    require(draw.secretHash == keccak256(abi.encodePacked(_secret, _salt)));

    // derive entropy from secret if authenification passed
    bytes32 entropy = keccak256(abi.encodePacked(_secret));

    // Select the winner based on winning number from secret entropy & committed entries 
    uint256 winningNumber = calculateWinner(entropy);
    draw.committedEntryRecord = entries;
    address winner = draw.committedEntryRecord[winningNumber];

    User storage user = users[winner];
    user.dividends = user.dividends.add(draw.roundPrize);

    draw.entropy = entropy;
    draw.winningNumber = winningNumber;
    draw.winner = winner;
    draw.rewarded = true;

   

    emit Rewarded(
      _drawRound,
      winningNumber,
      winner,
      draw.roundPrize
    );

  }

  function calculateWinner(bytes32 _entropy) public view returns (uint256) {
    uint256 upperBound = entries.length;
    uint256 random = uint256(_entropy);
    uint256 winningNumber = random % upperBound;
    return winningNumber;
  }

  function _openNextDraw() internal {
    require(block.timestamp >= draw_timer.add(drawIndex * 604800));
    DrawInfo storage draw = draws[drawIndex];
    draw.committedEntryRecord = entries;

    draw.roundPrize = drawPrize;
    drawPrize = 0; 

    draw.committed = true;

    drawIndex++;
  }

  function ownerOpenNextDraw() public onlyOwner {
    _openNextDraw();
  }

  function skipDraw(uint256 _drawRound) public onlyOwner {
    require(block.timestamp >= draw_timer.add(_drawRound * 604800));
    DrawInfo storage skippedDraw = draws[_drawRound];

    require(skippedDraw.rewarded == false, 'Already committed. Cannot reward again');    

    drawPrize = drawPrize.add(skippedDraw.roundPrize);

    skippedDraw.rewarded = true;
    skippedDraw.skipped = true;

  }

  function readjustDrawTime() external onlyOwner {
    require(roundIndex > 30, "Initial drawing has not taken place yet");
    draw_timer = start_timer.add(roundIndex.mul(86400)).sub(drawIndex * 604800).add(604800);
  }


  function buyLotteryEntries(uint256 _numberOfEntries) external {
    uint256 entryPurchase = _numberOfEntries.mul(20000000); 
    User storage user = users[msg.sender];
    require(user.octx2_userBalance >= entryPurchase, "Not enough available OCTX2 tokens for purchase");

    user.octx2_userBalance = user.octx2_userBalance.sub(entryPurchase);
    users[prizeAddr].staked = users[prizeAddr].staked.add(entryPurchase);

    total_frozen = total_frozen.add(entryPurchase);

    for (uint256 i = 0; i < _numberOfEntries; i++) {
      entries.push(msg.sender);
    }

    user.entries = user.entries.add(_numberOfEntries);

    emit EntryBuy(msg.sender, _numberOfEntries, entryPurchase);

    if (block.timestamp >= draw_timer.add(drawIndex * 604800)) {
      _openNextDraw();
    }

  }


  function _promoLaunchEntries(address payable _user, uint256 _contributed) internal {
    require(block.timestamp < eventEndTimer, "Event is over");
    require(availablePromoEntries > 0, "No more remaining entries");

    uint256 entriesToGive = (userPromoTracker[_user].add(_contributed)).div(1e10);

    if (entriesToGive > availablePromoEntries) {
      for (uint256 i = 0; i < availablePromoEntries; i++) {
        entries.push(_user);
      }

      users[_user].entries = users[_user].entries.add(availablePromoEntries);

      availablePromoEntries = 0;
    }

    if (entriesToGive <= availablePromoEntries && entriesToGive > 0) {
      availablePromoEntries = availablePromoEntries.sub(entriesToGive);

      for (uint256 i = 0; i < entriesToGive; i++) {
        entries.push(_user);
      }

      users[_user].entries = users[_user].entries.add(entriesToGive);
    }

    uint256 priorInvested = userPromoTracker[_user].add(_contributed);
    userPromoTracker[_user] = priorInvested % 1e10;
  }

  function promoLotteryBuy(uint256 _numberOfEntries) external {
    require(availablePromoBuy > 0 && _numberOfEntries > 0);
    require(_numberOfEntries <= availablePromoBuy, 'Exceeded Availability');

    uint256 promoPurchase = _numberOfEntries.mul(10000000); 

    User storage user = users[msg.sender];
    require(user.octx2_userBalance >= promoPurchase, "Not enough available OCTX2 tokens for purchase");

    user.octx2_userBalance = user.octx2_userBalance.sub(promoPurchase);
    users[prizeAddr].staked = users[prizeAddr].staked.add(promoPurchase);

    availablePromoBuy = availablePromoBuy.sub(_numberOfEntries);

    total_frozen = total_frozen.add(promoPurchase);

    for (uint256 i = 0; i < _numberOfEntries; i++) {
      entries.push(msg.sender);
    }

    user.entries = user.entries.add(_numberOfEntries);

    emit EntryBuy(msg.sender, _numberOfEntries, promoPurchase);

    if (block.timestamp >= draw_timer.add(drawIndex * 604800)) {
      _openNextDraw();
    }
  }
}

//SourceUnit: OCTX2Token.sol

pragma solidity ^0.5.10;

import "./TRC20.sol";
import "./MinterRole.sol";

/**
 * @title TRC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on TRON all the operations are done in sun.
 *
 * Example inherits from basic TRC20 implementation but can be modified to
 * extend from other ITRC20-based tokens:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1536
 */
contract OCTX2Token is TRC20, MinterRole {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Constructor
     * @param name The name of the token
     * @param symbol he symbol of the token
     * @param decimals The decimal percision of token
     * @param tokenCap The cap on the token's total supply.
     */
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 tokenCap, uint256 testMint)
      TRC20(tokenCap)
      public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        _mint(msg.sender, testMint);
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

//SourceUnit: Roles.sol

pragma solidity ^0.5.10;

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
     * @dev remove an account's access to this role
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
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SourceUnit: TRC20.sol

pragma solidity ^0.5.10;

import "./ITRC20.sol";
import "./SafeMath.sol";

/**
 * @title Standard TRC20 token (compatible with ERC20 token)
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    uint256 private _cap;

    constructor (uint256 cap) public {
        require(cap > 0, "Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Cap the total number of tokens to be minted, sets the upper bound limit for totalSupply
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "TRC20: approve from the zero address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value, "TRC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "Burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _cap = _cap.sub(value);
        _balances[account] = _balances[account].sub(value, "Burn amount exceeds balance");
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }

    /**
     * @dev Checks for totalSupply exceeding capped.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount The amount of tokens
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "CappedSupply: token cap cannot be exceeded");
        }
    }
}