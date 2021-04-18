// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {Math} from '@openzeppelin/contracts/math/Math.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/SafeCast.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {PermissionAdmin} from '@kyber.network/utils-sc/contracts/PermissionAdmin.sol';

import {IKyberStaking} from '../interfaces/staking/IKyberStaking.sol';
import {IWithdrawHandler} from '../interfaces/staking/IWithdrawHandler.sol';
import {EpochUtils} from '../misc/EpochUtils.sol';

/**
 * @notice   This contract is using SafeMath for uint, which is inherited from EpochUtils
 *           Some events are moved to interface, easier for public uses
 */
contract KyberStaking is IKyberStaking, EpochUtils, ReentrancyGuard, PermissionAdmin {
  using Math for uint256;
  using SafeMath for uint256;
  struct StakerData {
    uint128 stake;
    uint128 delegatedStake;
    address representative;
    // true/false: if data has been initialized at an epoch for a staker
    bool hasInited;
  }

  IERC20 public immutable override kncToken;

  IWithdrawHandler public withdrawHandler;
  // staker data per epoch, including stake, delegated stake and representative
  mapping(uint256 => mapping(address => StakerData)) internal stakerPerEpochData;
  // latest data of a staker, including stake, delegated stake, representative
  mapping(address => StakerData) internal stakerLatestData;

  // event is fired if something is wrong with withdrawal
  // even though the withdrawal is still successful
  event WithdrawDataUpdateFailed(uint256 curEpoch, address staker, uint256 amount);

  event UpdateWithdrawHandler(IWithdrawHandler withdrawHandler);

  constructor(
    address _admin,
    IERC20 _kncToken,
    uint256 _epochPeriod,
    uint256 _startTime
  ) PermissionAdmin(_admin) EpochUtils(_epochPeriod, _startTime) {
    require(_startTime >= block.timestamp, 'ctor: start in the past');

    require(_kncToken != IERC20(0), 'ctor: kncToken 0');
    kncToken = _kncToken;
  }

  function updateWithdrawHandler(IWithdrawHandler _withdrawHandler) external onlyAdmin {
    withdrawHandler = _withdrawHandler;

    emit UpdateWithdrawHandler(_withdrawHandler);
  }

  /**
   * @dev calls to set delegation for msg.sender, will take effect from the next epoch
   * @param newRepresentative address to delegate to
   */
  function delegate(address newRepresentative) external override {
    require(newRepresentative != address(0), 'delegate: representative 0');
    address staker = msg.sender;
    uint256 curEpoch = getCurrentEpochNumber();

    initDataIfNeeded(staker, curEpoch);

    address curRepresentative = stakerPerEpochData[curEpoch + 1][staker].representative;
    // nothing changes here
    if (newRepresentative == curRepresentative) {
      return;
    }

    uint256 updatedStake = stakerPerEpochData[curEpoch + 1][staker].stake;

    // reduce delegatedStake for curRepresentative if needed
    if (curRepresentative != staker) {
      initDataIfNeeded(curRepresentative, curEpoch);
      decreaseDelegatedStake(stakerPerEpochData[curEpoch + 1][curRepresentative], updatedStake);
      decreaseDelegatedStake(stakerLatestData[curRepresentative], updatedStake);

      emit Delegated(staker, curRepresentative, curEpoch, false);
    }

    stakerLatestData[staker].representative = newRepresentative;
    stakerPerEpochData[curEpoch + 1][staker].representative = newRepresentative;

    // ignore if staker is delegating back to himself
    if (newRepresentative != staker) {
      initDataIfNeeded(newRepresentative, curEpoch);
      increaseDelegatedStake(stakerPerEpochData[curEpoch + 1][newRepresentative], updatedStake);
      increaseDelegatedStake(stakerLatestData[newRepresentative], updatedStake);

      emit Delegated(staker, newRepresentative, curEpoch, true);
    }
  }

  /**
   * @dev call to stake more KNC for msg.sender
   * @param amount amount of KNC to stake
   */
  function deposit(uint256 amount) external override {
    require(amount > 0, 'deposit: amount is 0');

    uint256 curEpoch = getCurrentEpochNumber();
    address staker = msg.sender;

    // collect KNC token from staker
    require(kncToken.transferFrom(staker, address(this), amount), 'deposit: can not get token');

    initDataIfNeeded(staker, curEpoch);
    increaseStake(stakerPerEpochData[curEpoch + 1][staker], amount);
    increaseStake(stakerLatestData[staker], amount);

    // increase delegated stake for address that staker has delegated to (if it is not staker)
    address representative = stakerPerEpochData[curEpoch + 1][staker].representative;
    if (representative != staker) {
      initDataIfNeeded(representative, curEpoch);
      increaseDelegatedStake(stakerPerEpochData[curEpoch + 1][representative], amount);
      increaseDelegatedStake(stakerLatestData[representative], amount);
    }

    emit Deposited(curEpoch, staker, amount);
  }

  /**
   * @dev call to withdraw KNC from staking
   * @dev it could affect voting point when calling withdrawHandlers handleWithdrawal
   * @param amount amount of KNC to withdraw
   */
  function withdraw(uint256 amount) external override nonReentrant {
    require(amount > 0, 'withdraw: amount is 0');

    uint256 curEpoch = getCurrentEpochNumber();
    address staker = msg.sender;

    require(
      stakerLatestData[staker].stake >= amount,
      'withdraw: latest amount staked < withdrawal amount'
    );

    initDataIfNeeded(staker, curEpoch);
    decreaseStake(stakerLatestData[staker], amount);

    (bool success, ) = address(this).call(
      abi.encodeWithSelector(KyberStaking.handleWithdrawal.selector, staker, amount, curEpoch)
    );
    if (!success) {
      // Note: should catch this event to check if something went wrong
      emit WithdrawDataUpdateFailed(curEpoch, staker, amount);
    }

    // transfer KNC back to staker
    require(kncToken.transfer(staker, amount), 'withdraw: can not transfer knc');
    emit Withdraw(curEpoch, staker, amount);
  }

  /**
   * @dev initialize data if needed, then return staker's data for current epoch
   * @param staker - staker's address to initialize and get data for
   */
  function initAndReturnStakerDataForCurrentEpoch(address staker)
    external
    override
    nonReentrant
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    uint256 curEpoch = getCurrentEpochNumber();
    initDataIfNeeded(staker, curEpoch);

    StakerData memory stakerData = stakerPerEpochData[curEpoch][staker];
    stake = stakerData.stake;
    delegatedStake = stakerData.delegatedStake;
    representative = stakerData.representative;
  }

  /**
   * @notice return raw data of a staker for an epoch
   *         WARN: should be used only for initialized data
   *          if data has not been initialized, it will return all 0
   *          pool master shouldn't use this function to compute/distribute rewards of pool members
   */
  function getStakerRawData(address staker, uint256 epoch)
    external
    override
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    StakerData memory stakerData = stakerPerEpochData[epoch][staker];
    stake = stakerData.stake;
    delegatedStake = stakerData.delegatedStake;
    representative = stakerData.representative;
  }

  /**
   * @dev allow to get data up to current epoch + 1
   */
  function getStake(address staker, uint256 epoch) external view returns (uint256) {
    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return 0;
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        return stakerPerEpochData[i][staker].stake;
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    return 0;
  }

  /**
   * @dev allow to get data up to current epoch + 1
   */
  function getDelegatedStake(address staker, uint256 epoch) external view returns (uint256) {
    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return 0;
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        return stakerPerEpochData[i][staker].delegatedStake;
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    return 0;
  }

  /**
   * @dev allow to get data up to current epoch + 1
   */
  function getRepresentative(address staker, uint256 epoch) external view returns (address) {
    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return address(0);
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        return stakerPerEpochData[i][staker].representative;
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    // not delegated to anyone, default to yourself
    return staker;
  }

  /**
   * @notice return combine data (stake, delegatedStake, representative) of a staker
   * @dev allow to get staker data up to current epoch + 1
   */
  function getStakerData(address staker, uint256 epoch)
    external
    override
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    stake = 0;
    delegatedStake = 0;
    representative = address(0);

    uint256 curEpoch = getCurrentEpochNumber();
    if (epoch > curEpoch + 1) {
      return (stake, delegatedStake, representative);
    }
    uint256 i = epoch;
    while (true) {
      if (stakerPerEpochData[i][staker].hasInited) {
        stake = stakerPerEpochData[i][staker].stake;
        delegatedStake = stakerPerEpochData[i][staker].delegatedStake;
        representative = stakerPerEpochData[i][staker].representative;
        return (stake, delegatedStake, representative);
      }
      if (i == 0) {
        break;
      }
      i--;
    }
    // not delegated to anyone, default to yourself
    representative = staker;
  }

  function getLatestRepresentative(address staker) external view returns (address) {
    return
      stakerLatestData[staker].representative == address(0)
        ? staker
        : stakerLatestData[staker].representative;
  }

  function getLatestDelegatedStake(address staker) external view returns (uint256) {
    return stakerLatestData[staker].delegatedStake;
  }

  function getLatestStakeBalance(address staker) external view returns (uint256) {
    return stakerLatestData[staker].stake;
  }

  function getLatestStakerData(address staker)
    external
    override
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    )
  {
    stake = stakerLatestData[staker].stake;
    delegatedStake = stakerLatestData[staker].delegatedStake;
    representative = stakerLatestData[staker].representative == address(0)
      ? staker
      : stakerLatestData[staker].representative;
  }

  /**
    * @dev  separate logics from withdraw, so staker can withdraw as long as amount <= staker's deposit amount
            calling this function from withdraw function, ignore reverting
    * @param staker staker that is withdrawing
    * @param amount amount to withdraw
    * @param curEpoch current epoch
    */
  function handleWithdrawal(
    address staker,
    uint256 amount,
    uint256 curEpoch
  ) external {
    require(msg.sender == address(this), 'only staking contract');
    // update staker's data for next epoch
    decreaseStake(stakerPerEpochData[curEpoch + 1][staker], amount);
    address representative = stakerPerEpochData[curEpoch + 1][staker].representative;
    if (representative != staker) {
      initDataIfNeeded(representative, curEpoch);
      decreaseDelegatedStake(stakerPerEpochData[curEpoch + 1][representative], amount);
      decreaseDelegatedStake(stakerLatestData[representative], amount);
    }

    representative = stakerPerEpochData[curEpoch][staker].representative;
    uint256 curStake = stakerPerEpochData[curEpoch][staker].stake;
    uint256 lStakeBal = stakerLatestData[staker].stake;
    uint256 newStake = curStake.min(lStakeBal);
    uint256 reduceAmount = curStake.sub(newStake); // newStake is always <= curStake

    if (reduceAmount > 0) {
      if (representative != staker) {
        initDataIfNeeded(representative, curEpoch);
        // staker has delegated to representative, withdraw will affect representative's delegated stakes
        decreaseDelegatedStake(stakerPerEpochData[curEpoch][representative], reduceAmount);
      }
      stakerPerEpochData[curEpoch][staker].stake = SafeCast.toUint128(newStake);
      // call withdrawHandlers to reduce reward, if staker has delegated, then pass his representative
      if (withdrawHandler != IWithdrawHandler(0)) {
        (bool success, ) = address(withdrawHandler).call(
          abi.encodeWithSelector(
            IWithdrawHandler.handleWithdrawal.selector,
            representative,
            reduceAmount
          )
        );
        if (!success) {
          emit WithdrawDataUpdateFailed(curEpoch, staker, amount);
        }
      }
    }
  }

  /**
   * @dev initialize data if it has not been initialized yet
   * @param staker staker's address to initialize
   * @param epoch should be current epoch
   */
  function initDataIfNeeded(address staker, uint256 epoch) internal {
    address representative = stakerLatestData[staker].representative;
    if (representative == address(0)) {
      // not delegate to anyone, consider as delegate to yourself
      stakerLatestData[staker].representative = staker;
      representative = staker;
    }

    uint128 lStakeBal = stakerLatestData[staker].stake;
    uint128 ldStake = stakerLatestData[staker].delegatedStake;

    if (!stakerPerEpochData[epoch][staker].hasInited) {
      stakerPerEpochData[epoch][staker] = StakerData({
        stake: lStakeBal,
        delegatedStake: ldStake,
        representative: representative,
        hasInited: true
      });
    }

    // whenever stakers deposit/withdraw/delegate, the current and next epoch data need to be updated
    // as the result, we will also initialize data for staker at the next epoch
    if (!stakerPerEpochData[epoch + 1][staker].hasInited) {
      stakerPerEpochData[epoch + 1][staker] = StakerData({
        stake: lStakeBal,
        delegatedStake: ldStake,
        representative: representative,
        hasInited: true
      });
    }
  }

  function decreaseDelegatedStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.delegatedStake = SafeCast.toUint128(uint256(stakeData.delegatedStake).sub(amount));
  }

  function increaseDelegatedStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.delegatedStake = SafeCast.toUint128(uint256(stakeData.delegatedStake).add(amount));
  }

  function increaseStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.stake = SafeCast.toUint128(uint256(stakeData.stake).add(amount));
  }

  function decreaseStake(StakerData storage stakeData, uint256 amount) internal {
    stakeData.stake = SafeCast.toUint128(uint256(stakeData.stake).sub(amount));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


abstract contract PermissionAdmin {
    address public admin;
    address public pendingAdmin;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IEpochUtils} from './IEpochUtils.sol';

interface IKyberStaking is IEpochUtils {
  event Delegated(
    address indexed staker,
    address indexed representative,
    uint256 indexed epoch,
    bool isDelegated
  );
  event Deposited(uint256 curEpoch, address indexed staker, uint256 amount);
  event Withdraw(uint256 indexed curEpoch, address indexed staker, uint256 amount);

  function initAndReturnStakerDataForCurrentEpoch(address staker)
    external
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  function deposit(uint256 amount) external;

  function delegate(address dAddr) external;

  function withdraw(uint256 amount) external;

  /**
   * @notice return combine data (stake, delegatedStake, representative) of a staker
   * @dev allow to get staker data up to current epoch + 1
   */
  function getStakerData(address staker, uint256 epoch)
    external
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  function getLatestStakerData(address staker)
    external
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  /**
   * @notice return raw data of a staker for an epoch
   *         WARN: should be used only for initialized data
   *          if data has not been initialized, it will return all 0
   *          pool master shouldn't use this function to compute/distribute rewards of pool members
   */
  function getStakerRawData(address staker, uint256 epoch)
    external
    view
    returns (
      uint256 stake,
      uint256 delegatedStake,
      address representative
    );

  function kncToken() external view returns (IERC20);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @title Interface for callbacks hooks when user withdraws from staking contract
 */
interface IWithdrawHandler {
  function handleWithdrawal(address staker, uint256 reduceAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../interfaces/staking/IEpochUtils.sol';

contract EpochUtils is IEpochUtils {
  using SafeMath for uint256;

  uint256 public immutable override epochPeriodInSeconds;
  uint256 public immutable override firstEpochStartTime;

  constructor(uint256 _epochPeriod, uint256 _startTime) {
    require(_epochPeriod > 0, 'ctor: epoch period is 0');

    epochPeriodInSeconds = _epochPeriod;
    firstEpochStartTime = _startTime;
  }

  function getCurrentEpochNumber() public override view returns (uint256) {
    return getEpochNumber(block.timestamp);
  }

  function getEpochNumber(uint256 currentTime) public override view returns (uint256) {
    if (currentTime < firstEpochStartTime || epochPeriodInSeconds == 0) {
      return 0;
    }
    // ((currentTime - firstEpochStartTime) / epochPeriodInSeconds) + 1;
    return ((currentTime.sub(firstEpochStartTime)).div(epochPeriodInSeconds)).add(1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IEpochUtils {
  function epochPeriodInSeconds() external view returns (uint256);

  function firstEpochStartTime() external view returns (uint256);

  function getCurrentEpochNumber() external view returns (uint256);

  function getEpochNumber(uint256 timestamp) external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}