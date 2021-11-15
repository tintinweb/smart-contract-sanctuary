//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
 * @title Token pools that allow different ERC20 tokens and ETH deposits and withdrawals
 * with penalty and bonus mechanisms that incentivise long term holding. 
 * The initial penalty and commitment time are chosen at the time of the deposit by
 * the user.
 * There are two bonus types for each pool - holding bonus (to incetivise holding), 
 * and commitment bonus (to incetivise commiting to penalties & time).
 * Each token has one independent pool. i.e. all accounting is separate for each token.
 * ERC20 tokens may have fee-on-transfer or dynamic supply mechanisms, and for these
 * kinds of tokens this contract tracks everything as "shares of initial deposits". 
 * @notice The mechanism rules:
 * - A depositor is committing for "commitment period" and an "initial penalty percent" 
 *   of his choice (within allowed ranges). After the commitment period the
 *   deposit can be withdrawn with its share of both of the bonus pools.
 * - The two bonus pools are populated from the penalties for early withdrawals,
 *   which are withdrawals done before a deposit's commitment period is elapsed.
 * - The penalties are split in half and added to both bonus pools (isolated per token): 
 *   Hold bonus pool and Commit bonus pool.
 * - The share of the bonus pools is equal to the share of the bonus points (hold-points 
 *   and commit-points) for the deposit at the time of withdrawal relative to the other
 *   deposits in the pool.
 * - Hold points are calculated as amount of token (or ETH) x seconds held. So more tokens
 *   held for longer add more points - and increase the bonus share. This bonus is
 *   independent of commitment or penalties. The points keep increasing after commitment period
 *   is over.
 * - Commit points are calculated as amount of token (or ETH) x seconds committed to penalty.
 *   These points depend only on commitment time and commitment penalty 
 *   at the time of the deposit.
 * - Withdrawal before commitment period is not entitled to any part of the bonus
 *   and is instead "slashed" with a penalty (that is split between the bonuses pools).
 * - The penalty percent is decreasing with time from the chosen
 *   initialPenaltyPercent to 0 at the end of the commitPeriod. 
 * - Any additional deposit is added to the current deposit, carries over commit-points
 *   and hold-points that already actrued, and "resets" the commitment period and penalty
 *   according to the new user choice (but not in a way that will reduce the outstanding 
 *   commitment for the initial deposit).
 *
 * @dev 
 * 1. For safety and clarity, the withdrawal functionality is split into 
 * two methods, one for withdrawing with penalty, and the other one for withdrawing
 * with bonus.
 * 2. The ERC20 token and ETH functionality is split into separate methods.
 * The total deposits shares are tracked per token contract in 
 * depositSums, bonuses in bonusSums.
 * 3. For tokens with dynamic supply mechanisms and fee on transfer all internal
 * calculations are done using the "initial desposit amounts" as fair shares, and
 * upon withdrawal are translated to actual amounts of the contract's token balance.
 * This means that for these tokens the actual amounts received are depends on their
 * mechanisms (because the amount is unknown before actual transfers).
 * 4. To reduce RPC calls and simplify interface, all the deposit and pool views are
 * batched in depositDetails and poolDetails which return arrays of values.
 * 5. The total of a pool's hold points are updated incrementally on each interaction
 * with a pool using the depositsSum in that pool for that period. If can only happen
 * once per block because it depends on the time since last update.
 *
 * @author artdgn (@github)
 */
contract HodlPoolV2 {

  using SafeERC20 for IERC20;

  /// @dev state variables for a deposit in a pool
  struct Deposit {
    uint value;
    uint120 time;
    uint16 initialPenaltyPercent;
    uint120 commitPeriod;
  }

  /// @dev state variables for a carry over deposits (not first deposits)
  ///   separate mapping for gas savings
  struct CarryOver {
    uint prevHoldPoints;
    uint prevCommitPoints;
  }

  /// @dev state variables for a token pool
  struct Pool {
    // sum of all current deposits
    uint depositsSum;  
    // sum of hold bonus pool
    uint holdBonusesSum;  
    // sum of commit bonus pool
    uint commitBonusesSum; 
    // sum of hold-points 
    uint totalHoldPoints;  
    // holds the time of the latest incremental hold-points update
    uint totalHoldPointsUpdateTime;  
    // sum of commit-points
    uint totalCommitPoints;  
    // token deposits per token contract and per user, each account has only a single deposit 
    mapping(address => Deposit) deposits;
    // carry overs for subsequent deposits per token contract and per user
    mapping(address => CarryOver) carryOvers;
  }
  
  /// @notice minimum initial percent of penalty
  uint public immutable minInitialPenaltyPercent;  

  /// @notice minimum commitment period for a deposit
  uint public immutable minCommitPeriod;

  /// @notice WETH token contract this pool is using for handling ETH
  address public immutable WETH;

  /// @dev the pool states for each token contract address
  mapping(address => Pool) internal pools;  

  /*
   * @param token ERC20 token address for the deposited token
   * @param account address that has made the deposit
   * @param amount size of new deposit, or deposit increase
   * @param amountReceived received balance after transfer (actual deposit)
   *  which may be different due to transfer-fees and other token shenanigans
   * @param time timestamp from which the commitment period will be counted
   * @param initialPenaltyPercent initial penalty percent for the deposit
   * @param commitPeriod commitment period in seconds for the deposit
   */
  event Deposited(
    address indexed token, 
    address indexed account, 
    uint amount, 
    uint amountReceived, 
    uint time,
    uint initialPenaltyPercent,
    uint commitPeriod
  );

  /*
   * @param token ERC20 token address for the withdrawed token
   * @param account address that has made the withdrawal
   * @param amount amount sent out to account as withdrawal
   * @param depositAmount the original amount deposited
   * @param penalty the penalty incurred for this withdrawal
   * @param holdBonus the hold-bonus included in this withdrawal
   * @param commitBonus the commit-bonus included in this withdrawal
   * @param timeHeld the time in seconds the deposit was held
   */
  event Withdrawed(
    address indexed token,
    address indexed account, 
    uint amount, 
    uint depositAmount, 
    uint penalty, 
    uint holdBonus,
    uint commitBonus,
    uint timeHeld
  );

  /// @dev limits interaction to depositors in the pool
  modifier onlyDepositors(address token) {
    require(pools[token].deposits[msg.sender].value > 0, "no deposit");
    _;
  }

  /// @dev checks commitment params are within allowed ranges
  modifier validCommitment(uint initialPenaltyPercent, uint commitPeriod) {
    require(initialPenaltyPercent >= minInitialPenaltyPercent, "penalty too small"); 
    require(initialPenaltyPercent <= 100, "initial penalty > 100%"); 
    require(commitPeriod >= minCommitPeriod, "commitment period too short");
    require(commitPeriod <= 4 * 365 days, "commitment period too long");
    _;
  }

  /*
   * @param _minInitialPenaltyPercent the minimum penalty percent for deposits
   * @param _minCommitPeriod the minimum time in seconds for commitPeriod of a deposit
   * @param _WETH wrapped ETH contract address this pool will be using for ETH
  */
  constructor (uint _minInitialPenaltyPercent, uint _minCommitPeriod, address _WETH) {
    require(_minInitialPenaltyPercent > 0, "no min penalty"); 
    require(_minInitialPenaltyPercent <= 100, "minimum initial penalty > 100%"); 
    require(_minCommitPeriod >= 10 seconds, "minimum commitment period too short");
    require(_minCommitPeriod <= 4 * 365 days, "minimum commitment period too long");
    require(_WETH != address(0), "WETH address can't be 0x0");
    minInitialPenaltyPercent = _minInitialPenaltyPercent;
    minCommitPeriod = _minCommitPeriod;
    WETH = _WETH;
  }

  /// @notice contract doesn't support sending ETH directly
  receive() external payable {
    require(
      msg.sender == WETH, 
      "no receive() except from WETH contract, use depositETH()");
  }

  /* * * * * * * * * * *
   * 
   * Public transactions
   * 
   * * * * * * * * * * *
  */

  /*
   * @param token address of token contract
   * @param amount of token to deposit
   * @param initialPenaltyPercent initial penalty percent for deposit
   * @param commitPeriod period during which a withdrawal results in penalty and no bonus
   * @notice Any additional deposit is added to the current deposit, carries over commit-points
   *   and hold-points that already actrued, and "resets" the commitment period and penalty
   *   according to the new user choice (but not in a way that will reduce the outstanding 
   *   commitment for the initial deposit).
   */
  function deposit(
    address token, 
    uint amount, 
    uint initialPenaltyPercent,
    uint commitPeriod
  ) external
    validCommitment(initialPenaltyPercent, commitPeriod) 
  {
    require(amount > 0, "deposit too small");

    // interal accounting update
    _depositStateUpdate(
      token, 
      msg.sender,
      amount,
      initialPenaltyPercent, 
      commitPeriod
    );

    // this contract's balance before the transfer
    uint beforeBalance = IERC20(token).balanceOf(address(this));

    // transfer
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    // what was actually received
    uint amountReceived = IERC20(token).balanceOf(address(this)) - beforeBalance;

    emit Deposited(
      token,
      msg.sender, 
      amount, 
      amountReceived, 
      block.timestamp, 
      initialPenaltyPercent, 
      commitPeriod
    );
  }

  /*
   * @notice payable method for depositing ETH with same logic as deposit()
   * @param initialPenaltyPercent initial penalty percent for deposit
   * @param commitPeriod period during which a withdrawal results in penalty and no bonus
   */
  function depositETH(
    uint initialPenaltyPercent,
    uint commitPeriod
  ) external
    validCommitment(initialPenaltyPercent, commitPeriod) 
    payable
  {
    require(msg.value > 0, "deposit too small");

    // interal accounting update
    _depositStateUpdate(
      WETH, 
      msg.sender,
      msg.value,
      initialPenaltyPercent, 
      commitPeriod
    );

    // note: no share vs. balance accounting for WETH because it's assumed to
    // exactly correspond to actual deposits and withdrawals (no fee-on-transfer etc)
    IWETH(WETH).deposit{value: msg.value}();

    emit Deposited(
      WETH, 
      msg.sender, 
      msg.value, 
      msg.value, 
      block.timestamp, 
      initialPenaltyPercent, 
      commitPeriod
    );
  }
  
  /*
   * @param token address of token contract
   * @notice withdraw the full deposit with the proportional shares of bonus pools.
   *   will fail for early withdawals (for which there is another method)
   * @dev checks that the deposit is non-zero
   */
  function withdrawWithBonus(address token) external onlyDepositors(token) {
    require(
      _depositPenalty(pools[token].deposits[msg.sender]) == 0, 
      "cannot withdraw without penalty yet, use withdrawWithPenalty()"
    );
    _withdraw(token, msg.sender);
  }

  /// @notice withdraw ETH with penalty with same logic as withdrawWithPenalty()
  function withdrawWithBonusETH() external onlyDepositors(WETH) {
    require(
      _depositPenalty(pools[WETH].deposits[msg.sender]) == 0, 
      "cannot withdraw without penalty yet, use withdrawWithPenalty()"
    );
    _withdrawETH(msg.sender);
  }

  /*
   * @param token address of token contract
   * @notice withdraw the deposit with any applicable penalty. Will withdraw 
   * with any available bonus if penalty is 0 (commitment period elapsed).
   */
  function withdrawWithPenalty(address token) external onlyDepositors(token) {
    _withdraw(token, msg.sender);
  }

  /// @notice withdraw ETH with penalty with same logic as withdrawWithPenalty()
  function withdrawWithPenaltyETH() external onlyDepositors(WETH) {
    _withdrawETH(msg.sender);
  }

  /* * * * * * * *
   * 
   * Public views
   * 
   * * * * * * * *
  */

  /*
   * @param token address of token contract
   * @param account address of the depositor
   * @return array of 10 values corresponding to the details of the deposit:
   *  0. balance - original deposit(s) value
   *  1. timeLeftToHold - time in seconds until deposit can be withdrawed 
   *     with bonus and no penalty
   *  2. penalty - penalty if withdrawed now
   *  3. holdBonus - hold-bonus if withdrawed now (if possible to withdraw with bonus)
   *  4. commitBonus - commit-bonus if withdrawed now (if possible to withdraw with bonus)
   *  5. holdPoints - current amount of hold-point
   *  6. commitPoints - current amount of commit-point
   *  7. initialPenaltyPercent - initial penalty percent (set at time od deposit)
   *  8. currentPenaltyPercent - current penalty percent (penalty percent if withdrawed now)
   *  9. commitPeriod - commitment period set at the time of deposit
   */
  function depositDetails(
    address token, address account
  ) public view returns (uint[10] memory) {
    Deposit storage dep = pools[token].deposits[account];
    return [
      _shareToAmount(token, dep.value),  // balance
      _timeLeft(dep),  // timeLeftToHold
      _shareToAmount(token, _depositPenalty(dep)),  // penalty
      _shareToAmount(token, _holdBonus(token, account)),  // holdBonus
      _shareToAmount(token, _commitBonus(token, account)),  // commitBonus
      _holdPoints(token, account),  // holdPoints
      _commitPoints(token, account),  // commitPoints
      dep.initialPenaltyPercent,  // initialPenaltyPercent
      _currentPenaltyPercent(dep),  // currentPenaltyPercent
      dep.commitPeriod  // commitPeriod
    ];
  }

  /*
   * @param token address of token contract
   * @return array of 5 values corresponding to the details of the pool:
   *  0. depositsSum - sum of current deposits
   *  1. holdBonusesSum - sum of tokens to be distributed as hold bonuses
   *  2. commitBonusesSum - sum of tokens to be distributed as commitment bonuses
   *  3. totalHoldPoints - sum of hold-points of all current deposits
   *  4. totalCommitPoints - sum of commit-points of all current deposits
   */
  function poolDetails(address token) public view returns (uint[5] memory) {
    Pool storage pool = pools[token];
    return [
      _shareToAmount(token, pool.depositsSum),  // depositsSum
      _shareToAmount(token, pool.holdBonusesSum),  // holdBonusesSum
      _shareToAmount(token, pool.commitBonusesSum),  // commitBonusesSum
      _totalHoldPoints(pool),  // totalHoldPoints
      pool.totalCommitPoints  // totalCommitPoints
    ];
  }

  /* * * * * * * * * * * *
   * 
   * Internal transactions
   * 
   * * * * * * * * * * * *
  */

  /// @dev the order of calculations is important for correct accounting
  function _depositStateUpdate(
    address token, 
    address account,
    uint amount, 
    uint initialPenaltyPercent, 
    uint commitPeriod
  ) internal {      
    Pool storage pool = pools[token];

    // possible commit points that will need to be subtracted from deposit and pool
    uint commitPointsToSubtract = 0; 

    Deposit storage dep = pool.deposits[account];

    if (dep.value > 0) {  // adding to previous deposit            
      require(
        initialPenaltyPercent >= _currentPenaltyPercent(dep), 
        "penalty percent less than existing deposits's percent"
      );
      require(
        commitPeriod >= _timeLeft(dep),
        "commit period less than existing deposit's time left"
      );

      CarryOver storage carry = pool.carryOvers[account];

      // carry over previous points and add points for the time 
      // held since latest deposit
      // WARNING: this needs to happen before deposit value is updated
      carry.prevHoldPoints = _holdPoints(token, account);
      
      // this value will need to be sutracted from both deposit and pool's points
      commitPointsToSubtract = _outstandingCommitPoints(dep);
      // subtract un-held commitment from commit points
      carry.prevCommitPoints = _commitPoints(token, account) - commitPointsToSubtract;
    }

    // deposit update for both new & existing
    dep.value += amount;  // add the amount
    dep.time = uint120(block.timestamp);  // set the time
    // set the commitment params
    dep.commitPeriod = uint120(commitPeriod);  
    dep.initialPenaltyPercent = uint16(initialPenaltyPercent);

    // pool update    
    // update pool's total hold time due to passage of time
    // because the deposits sum is going to change
    _updatePoolHoldPoints(pool);
    // WARNING: the deposits sum needs to be updated after the hold-points
    // for the passed time were updated
    pool.depositsSum += amount;    
    // the full new amount is committed minus any commit points that need to be sutracted
    pool.totalCommitPoints = (
      pool.totalCommitPoints + _fullCommitPoints(dep) - commitPointsToSubtract);
  }

  // this happens on every pool interaction (so every withdrawal and deposit to that pool)
  function _updatePoolHoldPoints(Pool storage pool) internal {
    // add points proportional to value held in pool since last update
    pool.totalHoldPoints = _totalHoldPoints(pool);    
    pool.totalHoldPointsUpdateTime = block.timestamp;
  }  
  
  function _withdraw(address token, address account) internal {
    uint withdrawAmount = _withdrawAmountAndUpdate(token, account);
    IERC20(token).safeTransfer(account, withdrawAmount);
  }

  function _withdrawETH(address account) internal {
    uint withdrawAmount = _withdrawAmountAndUpdate(WETH, account);
    IWETH(WETH).withdraw(withdrawAmount);
    payable(account).transfer(withdrawAmount);
  }

  /// @dev the order of calculations is important for correct accounting
  function _withdrawAmountAndUpdate(
    address token, 
    address account
  ) internal returns (uint) {
    Pool storage pool = pools[token];
    // update pool hold-time points due to passage of time
    // WARNING: failing to do so will break hold-time holdBonus calculation
    _updatePoolHoldPoints(pool);

    // WARNING: deposit is only read here and is not updated until it's removal
    Deposit storage dep = pool.deposits[account];

    // calculate penalty & bunus before making changes
    uint penalty = _depositPenalty(dep);
    
    // only get any bonuses if no penalty
    uint holdBonus = (penalty == 0) ? _holdBonus(token, account) : 0;
    uint commitBonus = (penalty == 0) ? _commitBonus(token, account) : 0;
    uint withdrawShare = dep.value - penalty + holdBonus + commitBonus;    

    // WARNING: get amount here before state is updated
    uint withdrawAmount = _shareToAmount(token, withdrawShare);

    // WARNING: emit event here with all the needed data, before state updates
    // affect shareToAmount calculations
    // this refactor is needed for handling stack-too-deep error because for some
    // reason just putting it in its own scope didn't help
    _emitWithdrawalEvent(
      token, account, dep, penalty, holdBonus, commitBonus, withdrawAmount);

    // pool state update
    // WARNING: should happen after calculating shares, because the depositSum changes    
    // update total deposits
    pool.depositsSum -= dep.value;        
    // remove the acrued hold-points for this deposit
    pool.totalHoldPoints -= _holdPoints(token, account);
    // remove the commit-points
    pool.totalCommitPoints -= _commitPoints(token, account);
    // update hold-bonus pool: split the penalty into two parts
    // half for hold bonuses, half for commit bonuses
    uint holdBonusPoolUpdate = penalty / 2;
    uint commitBonusPoolUpdate = penalty - holdBonusPoolUpdate;
    pool.holdBonusesSum = pool.holdBonusesSum + holdBonusPoolUpdate - holdBonus;
    // update commitBonus pool
    pool.commitBonusesSum = pool.commitBonusesSum + commitBonusPoolUpdate - commitBonus;  

    // deposit update: remove deposit
    // WARNING: note that removing the deposit before this line will 
    // change "dep" because it's used by reference and will affect the other
    // computations for pool state updates (e.g. hold points)
    delete pool.deposits[account];
    delete pool.carryOvers[account];

    return withdrawAmount;
  }

  /// @dev emits the Withdrawed event
  function _emitWithdrawalEvent(
    address token, 
    address account, 
    Deposit storage dep,
    uint penalty,
    uint holdBonus,
    uint commitBonus,
    uint withdrawAmount
  ) internal {  
    emit Withdrawed(
      token,
      account,
      withdrawAmount, 
      dep.value, 
      _shareToAmount(token, penalty), 
      _shareToAmount(token, holdBonus), 
      _shareToAmount(token, commitBonus), 
      _timeHeld(dep.time));
  }

  /* * * * * * * * *
   * 
   * Internal views
   * 
   * * * * * * * * *
  */

  function _timeLeft(Deposit storage dep) internal view returns (uint) {
    uint timeHeld = _timeHeld(dep.time);
    return (timeHeld < dep.commitPeriod) ? (dep.commitPeriod - timeHeld) : 0;
  }

  /// @dev translates deposit shares to actual token amounts - which can be different 
  /// from the initial deposit amount for tokens with funky fees and supply mechanisms.
  function _shareToAmount(address token, uint share) internal view returns (uint) {
    if (share == 0) {  // gas savings
      return 0;
    }
    // all tokens that belong to this contract are either 
    // in deposits or in the two bonuses pools
    Pool storage pool = pools[token];
    uint totalShares = pool.depositsSum + pool.holdBonusesSum + pool.commitBonusesSum;
    if (totalShares == 0) {  // don't divide by zero
      return 0;  
    } else {
      // it's safe to call external balanceOf here because 
      // it's a view (and this method is also view)
      uint actualBalance = IERC20(token).balanceOf(address(this));      
      return actualBalance * share / totalShares;
    }
  }
  
  function _holdPoints(
    address token, 
    address account
  ) internal view returns (uint) {
    Deposit storage dep = pools[token].deposits[account];
    uint prev = pools[token].carryOvers[account].prevHoldPoints;
    // points proportional to value held since deposit start    
    return prev + (dep.value * _timeHeld(dep.time));
  }

  function _commitPoints(
    address token, 
    address account
  ) internal view returns (uint) {
    Deposit storage dep = pools[token].deposits[account];
    uint prev = pools[token].carryOvers[account].prevCommitPoints;
    // points proportional to value held since deposit start    
    return prev + _fullCommitPoints(dep);
  }

  function _totalHoldPoints(Pool storage pool) internal view returns (uint) {
    uint elapsed = block.timestamp - pool.totalHoldPointsUpdateTime;
    // points proportional to value held in pool since last update
    return pool.totalHoldPoints + (pool.depositsSum * elapsed);
  }

  function _fullCommitPoints(Deposit storage dep) internal view returns (uint) {
    // triangle area of commitpent time and penalty
    return (
      dep.value * dep.initialPenaltyPercent * dep.commitPeriod
      / 100 / 2
    );
  }

  function _outstandingCommitPoints(Deposit storage dep) internal view returns (uint) {
    // triangle area of commitpent time and penalty
    uint timeLeft = _timeLeft(dep);
    if (timeLeft == 0) {  // no outstanding commitment
      return 0;
    } else {      
      // smaller triangle of left commitment time * smaller penalty left
      // can refactor to use _currentPenaltyPercent() here, but it's more precise to 
      // do all calculations here to avoid rounding (all multiplication before all divisions)
      return (
        dep.value * dep.initialPenaltyPercent * timeLeft * timeLeft / 
        (dep.commitPeriod * 100 * 2)  // triangle area
      );
    }
  }

  function _currentPenaltyPercent(Deposit storage dep) internal view returns (uint) {
    uint timeLeft = _timeLeft(dep);
    if (timeLeft == 0) { // no penalty
      return 0;
    } else {
      // current penalty percent is proportional to time left
      uint curPercent = (dep.initialPenaltyPercent * timeLeft) / dep.commitPeriod;
      // add 1 to compensate for rounding down unless when below initial value
      return curPercent < dep.initialPenaltyPercent ? curPercent + 1 : curPercent;
    }
  }

  function _timeHeld(uint time) internal view returns (uint) {
    return block.timestamp - time;
  }

  function _depositPenalty(Deposit storage dep) internal view returns (uint) {
    uint timeLeft = _timeLeft(dep);
    if (timeLeft == 0) {  // no penalty
      return 0;
    } else {
      // order important to prevent rounding to 0
      return (
        (dep.value * dep.initialPenaltyPercent * timeLeft) 
        / dep.commitPeriod)  // can't be zero
        / 100;
    }
  }

  function _holdBonus(
    address token, 
    address account
  ) internal view returns (uint) {
    Pool storage pool = pools[token];
    // share of bonus is proportional to hold-points of this deposit relative
    // to total hold-points in the pool
    // order important to prevent rounding to 0
    uint denom = _totalHoldPoints(pool);  // don't divide by 0
    uint holdPoints = _holdPoints(token, account);
    return denom > 0 ? ((pool.holdBonusesSum * holdPoints) / denom) : 0;
  }

  function _commitBonus(
    address token, 
    address account
  ) internal view returns (uint) {
    Pool storage pool = pools[token];
    // share of bonus is proportional to commit-points of this deposit relative
    // to all other commit-points in the pool
    // order important to prevent rounding to 0
    uint denom = pool.totalCommitPoints;  // don't divide by 0
    uint commitPoints = _commitPoints(token, account);
    return denom > 0 ? ((pool.commitBonusesSum * commitPoints) / denom) : 0;
  }
}

/// @dev interface for interacting with WETH (wrapped ether) for handling ETH
/// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

