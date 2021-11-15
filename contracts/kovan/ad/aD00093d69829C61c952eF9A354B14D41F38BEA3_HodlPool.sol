//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

/*
 * @title A pool that allows ETH deposits and withdrawals with penalty 
 * and bonus mechanisms to encaurage long term holding.
 * @author artdgn (@github)
 * @notice The mechanism rules:
 * - A depositor is committing for the "commitment period", after which the
 *   deposit can be withdrawn with its share of the bonus pool.
 * - Bonus pool is populated from the penalties for early withdrawals,
 *   which are withdrawals done before each deposit's commitment period is elapsed.
 * - The share of the bonus pool is equal to the share of the deposit from all deposits
 *   at the time of withdrawal.
 * - Withdrawal before commitment period is not entitled to any part of the bonus
 *   and is instead "slashed" with a penalty (that is added to the bonus pool).
 * - The penalty percent is decreasing linearly from 
 *   maxPenaltyPercent to 0 with time (for the duration of the commitPeriod). 
 * - Any additional deposit is added to the current deposit and "resets" the
 *   commitment period required to wait.
 * @dev For safety and clarity, the withdrawal functionality is split into 
 * two methods, one for withdrawing with penalty, and the other one for withdrawing
 * with bonus.
 * The total deposits amount is tracked in depositsSum, any other ETH in the contract's
 * balance is "the bonus pool".
 */
contract HodlPool {

  struct Deposit {
    uint value;
    uint time;
  }

  /// @notice a cap on a single deposit for safety
  uint public constant MAX_DEPOSIT = 1 ether;

  /// @notice maximum percent of penalty
  uint public immutable maxPenaltyPercent;  

  /// @notice time it takes for withdrawal penalty to be reduced to 0
  uint public immutable commitPeriod;

  /// @dev each sender has only a single deposit
  mapping(address => Deposit) internal deposits;  

  /// @notice sum of all deposits currently held in the pool
  uint public depositsSum;

  /*
   * @param sender address that has made the deposit
   * @param amount size of new deposit, or deposit increase
   * @param time timestamp from which the commitment period will be counted
   */
  event Deposited(address indexed sender, uint amount, uint time);
  
  /*
   * @param sender address that has made the withdrawal
   * @param amount amount sent out to sender as withdrawal
   * @param depositAmount the original amount deposited
   * @param penalty the penalty incurred for this withdrawal
   * @param bonus the bonus included in this withdrawal
   * @param timeHeld the time in seconds the deposit was held
   */
  event Withdrawed(
    address indexed sender, 
    uint amount, 
    uint depositAmount, 
    uint penalty, 
    uint bonus,
    uint timeHeld
  );

  modifier onlyDepositors() {
    require(deposits[msg.sender].value > 0, "no deposit");
    _;
  }

  /*
   * @param maxPenaltyPercent_ the penalty percent for early withdrawal penalty 
   *   calculations.
   * @param commitPeriod_ the time in seconds after the deposit at which the 
   *   penalty becomes 0
   * @dev the contstructor is payable in order to allow "seeding" the bonus pool.
  */
  constructor (uint maxPenaltyPercent_, uint commitPeriod_) payable {
    require(maxPenaltyPercent_ > 0, "no penalty"); 
    require(maxPenaltyPercent_ <= 100, "max penalty > 100%"); 
    // TODO: remove the short commitment check (that's required for testing)
    require(commitPeriod_ >= 10 seconds, "commitment period too short");
    // require(commitPeriod_ >= 7 days, "commitment period too short");
    require(commitPeriod_ <= 365 days, "commitment period too long");
    maxPenaltyPercent = maxPenaltyPercent_;
    commitPeriod = commitPeriod_;
  }

  /// @notice contract doesn't support sending ETH directly, 
  /// but only through the deposit() method
  receive() external payable {
    revert("no receive(), use deposit()");
  }

  /// @notice any subsequent deposit after the first is added to the first one,
  /// and the time for waiting is "reset".
  function deposit() external payable {
    require(msg.value > 0, "deposit too small");
    require(msg.value <= MAX_DEPOSIT, "deposit too large");
    deposits[msg.sender].value += msg.value;
    deposits[msg.sender].time = block.timestamp;
    depositsSum += msg.value;
    emit Deposited(msg.sender, msg.value, block.timestamp);
  }

  /// @notice withdraw the full deposit with the proportional share of bonus pool.
  ///   will fail for early withdawals (for which there is another method)
  /// @dev checks that the deposit is non-zero
  function withdrawWithBonus() external onlyDepositors {
    require(
      penaltyOf(msg.sender) == 0, 
      "cannot withdraw without penalty yet, use withdrawWithPenalty()"
    );
    _withdraw();
  }

  /// @notice withdraw the deposit with any applicable penalty. Will withdraw 
  ///   with any available bonus if penalty is 0 (commitment period elapsed).
  /// @dev checks that the deposit is non-zero
  function withdrawWithPenalty() external onlyDepositors {
    _withdraw();
  }

  /// @return amount of ETH in the bonus pool
  /// @dev anything in the contract balance that's not in depositsSum is bonus
  ///   (e.g. including anything force-sent to contract)
  function bonusesPool() public view returns (uint) {
    return address(this).balance - depositsSum;
  }

  /// @param sender address of the depositor
  /// @return total deposit of the sender
  function balanceOf(address sender) public view returns (uint) {
    return deposits[sender].value;
  }

  /// @param sender address of the depositor
  /// @return penalty for the sender's deposit if withdrawal would happen now
  function penaltyOf(address sender) public view returns (uint) {
    return _depositPenalty(deposits[sender]);
  }

  /*
   * @param sender address of the depositor
   * @return bonus share of the sender's deposit if withdrawal
   *   would happen now and there was no penalty (the potential bonus).
   * @notice bonus share can be returned with this method before
   *   commitment period is actually done, but it won't be withdrawn 
   *   if the penalty is non-0
  */
  function bonusOf(address sender) public view returns (uint) {
    return _depositBonus(deposits[sender]);
  }

  /// @param sender address of the depositor
  /// @return time in seconds left to wait until sender's deposit can
  /// be withdrawn without penalty
  function timeLeftToHoldOf(address sender) public view returns (uint) {
    if (balanceOf(sender) == 0) return 0;
    uint timeHeld = _depositTimeHeld(deposits[sender]);
    return (timeHeld < commitPeriod) ? (commitPeriod - timeHeld) : 0;
  }
  
  function _withdraw() internal {
    Deposit memory dep = deposits[msg.sender];

    // calculate penalty & bunus before making changes
    uint penalty = _depositPenalty(dep);
    // only get bonus if no penalty
    uint bonus = (penalty == 0) ? _depositBonus(dep) : 0;
    uint withdrawAmount = dep.value - penalty + bonus;

    // update state
    // remove deposit
    deposits[msg.sender] = Deposit(0, 0);
    depositsSum -= dep.value;

    // transfer
    payable(msg.sender).transfer(withdrawAmount);    
    emit Withdrawed(
      msg.sender,
      withdrawAmount, 
      dep.value, 
      penalty, 
      bonus, 
      _depositTimeHeld(dep));
  }

  function _depositTimeHeld(Deposit memory dep) internal view returns (uint) {
    return block.timestamp - dep.time;
  }

  function _depositPenalty(Deposit memory dep) internal view returns (uint) {
    uint timeHeld = _depositTimeHeld(dep);
    if (timeHeld >= commitPeriod) {
      return 0;
    } else {
      uint timeLeft = commitPeriod - timeHeld;
      // order important to prevent rounding to 0
      return ((dep.value * maxPenaltyPercent * timeLeft) / commitPeriod) / 100;
    }
  }

  function _depositBonus(Deposit memory dep) internal view returns (uint) {
    if (dep.value == 0 || bonusesPool() == 0) {
      return 0;  // no luck
    } else {
      // order important to prevent rounding to 0
      return (bonusesPool() * dep.value) / depositsSum;
    }
  }

}

