//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./aspects/WithOperators.sol";

import { DividendPeriod } from "./utils/DividendPeriod.sol";
import { Math } from "./utils/Math.sol";

import "./IDividends.sol";

contract DividendsV3 is IDividends, ReentrancyGuard, WithOperators {

  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  struct UserState {
    bool tracked;

    uint256 paidDividends;
    uint256 unpaidDividends;
  }

  struct PoolState {
    bool tracked;

    uint256 lastUpdatedAt;

    uint256 totalShares;
  }

  struct PeriodState {
    bool prepared;

    uint256 totalAllocationPoints;
    
    uint256 accumulatedDividends;
    uint256 dividendsPerSecond;
    uint256 totalDividends;
  }

  struct PoolPeriodState {
    uint256 allocationPoints;

    uint256 accumulatedDividendsPerShare;
  }

  struct UserPoolState {
    uint256 shares;

    uint256 rewardDebt;

    uint256 lastUpdatedAt;
  }

  uint256 public constant periodDurationSeconds = 1 weeks;
  // Fri May 28 2021 14:00:00 GMT
  uint256 public constant firstPeriodStartSeconds = 1622210400;

  IERC20 public dividendToken;

  mapping(uint256 => PeriodState) public periods;

  uint256[] public poolIds;
  mapping(uint256 => PoolState) public pools;
  
  address[] public userIds;
  mapping(address => UserState) public users;
  
  mapping(uint256 => mapping(uint256 => PoolPeriodState)) public poolPeriods;
  mapping(uint256 => mapping(address => UserPoolState)) public poolUsers;

  address public communityWallet;

  constructor(IERC20 _dividendToken, address _communityWallet) {
      dividendToken = _dividendToken;
      communityWallet = _communityWallet;
  }

  function getCurrentPeriod() external view returns (uint256) {
    return DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds);
  }

  function poolCount() external view returns (uint256) {
    return poolIds.length;
  }

  function userCount() external view returns (uint256) {
    return userIds.length;
  }

  function setPoolPeriodAllocation(uint256 _pid, uint256 _period, uint256 _points) public onlyOperator {
    require(!periods[_period].prepared, "expected period to not be ready.");
    
    if(!pools[_pid].tracked) {
      poolIds.push(_pid);
      pools[_pid].lastUpdatedAt = DividendPeriod.firstSecond(DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds), firstPeriodStartSeconds, periodDurationSeconds);
      pools[_pid].tracked = true;
    }

    poolPeriods[_pid][_period].allocationPoints = _points;
  }

  function preparePeriod(uint256 _period, uint256 _totalDividends) public onlyOperator {

    uint256 totalPoints = 0;
    for(uint256 i = 0; i < poolIds.length; i++) {
      uint256 pid = poolIds[i];

      totalPoints = totalPoints.add(poolPeriods[pid][_period].allocationPoints);
    }

    periods[_period].prepared = true;
    periods[_period].totalAllocationPoints = totalPoints;
    periods[_period].totalDividends = _totalDividends;
    periods[_period].dividendsPerSecond = _totalDividends.div(periodDurationSeconds);
  }

  function calculatePeriodMultiplier(uint256 _period, uint256 _pid, uint256 _from, uint256 _to) public view returns (uint256) {
      
      require(_from <= _to, "calculatePeriodMultiplier: expected _from to be less than _to.");
      if(!pools[_pid].tracked) {
        return 0;
      }

      PeriodState storage period = periods[_period];
      if(period.accumulatedDividends >= period.totalDividends) {
        return 0;
      }

      uint256 firstSecond = DividendPeriod.firstSecond(_period, firstPeriodStartSeconds, periodDurationSeconds);
      uint256 lastSecond = DividendPeriod.lastSecond(_period, firstPeriodStartSeconds, periodDurationSeconds);
      _from = Math.clamp(_from, firstSecond, lastSecond);
      _to = Math.clamp(_to, firstSecond, lastSecond);

      return _to.sub(_from);
  }

  function calcateUserPoolPeriodDividends(uint256 _period, uint256 _pid, address _userAddress) private view returns (uint256) {
      
      PeriodState storage period = periods[_period];
      if(!period.prepared) {
        return 0;
      }

      PoolState storage pool = pools[_pid];
      PoolPeriodState storage poolPeriod = poolPeriods[_pid][_period];
      UserPoolState storage user = poolUsers[_pid][_userAddress];

      uint256 lastSecond = Math.min(block.timestamp, DividendPeriod.lastSecond(_period, firstPeriodStartSeconds, periodDurationSeconds));
      uint256 accDividendPerShare = poolPeriod.accumulatedDividendsPerShare;
      if(pool.totalShares > 0 && pool.lastUpdatedAt < lastSecond) {
          uint256 multiplier = calculatePeriodMultiplier(_period, _pid, pool.lastUpdatedAt, lastSecond);
          uint256 dividendReward = multiplier.mul(period.dividendsPerSecond).mul(poolPeriod.allocationPoints).div(period.totalAllocationPoints);
          accDividendPerShare = accDividendPerShare.add(dividendReward.mul(1e36).div(pool.totalShares));
      }

      return user.shares.mul(accDividendPerShare);
  }

  function calculateRawUserReward(uint256 _pid, address _userAddress, uint256 _maxPeriod) private view returns (uint256) {
      UserPoolState storage user = poolUsers[_pid][_userAddress];

      uint256 updatedAt = user.lastUpdatedAt == 0 ? _maxPeriod
        : DividendPeriod.fromSeconds(user.lastUpdatedAt, firstPeriodStartSeconds, periodDurationSeconds);
      
      uint256 total = 0;
      for(uint256 i = updatedAt; i <= _maxPeriod; i++) {
        uint256 _inc = calcateUserPoolPeriodDividends(i, _pid, _userAddress);

        total = total.add(_inc);
      }

      return total;
  }

  function calculatePoolUserPendingDividends(uint256 _pid, address _userAddress, uint256 _maxPeriod) public view returns (uint256) {

      uint256 rawDividends = calculateRawUserReward(_pid, _userAddress, _maxPeriod);
      uint256 rewardDebt = poolUsers[_pid][_userAddress].rewardDebt;

      return (rawDividends - rewardDebt) / 1e36;
  }

  function updatePoolPeriod(uint256 _period, uint256 _pid) private returns (bool) {

      PeriodState storage period = periods[_period];
      if(!period.prepared) {
        return false;
      }

      PoolState storage pool = pools[_pid];
      if (block.timestamp <= pool.lastUpdatedAt) {
        return false;
      }

      if (pool.totalShares == 0) {
        return false;
      }

      uint256 previousLastUpdatedSeconds = Math.max(pool.lastUpdatedAt, DividendPeriod.firstSecond(_period, firstPeriodStartSeconds, periodDurationSeconds));
      pool.lastUpdatedAt = Math.min(block.timestamp, DividendPeriod.lastSecond(_period, firstPeriodStartSeconds, periodDurationSeconds));

      PoolPeriodState storage poolPeriod = poolPeriods[_pid][_period];
      if(poolPeriod.allocationPoints == 0) {
        return true;
      }

      uint256 multiplier = calculatePeriodMultiplier(_period, _pid, previousLastUpdatedSeconds, pool.lastUpdatedAt);
      uint256 dividendReward = multiplier.mul(period.dividendsPerSecond).mul(poolPeriod.allocationPoints).div(period.totalAllocationPoints);
      period.accumulatedDividends = period.accumulatedDividends.add(dividendReward);
      poolPeriod.accumulatedDividendsPerShare = poolPeriod.accumulatedDividendsPerShare.add(dividendReward.mul(1e36).div(pool.totalShares));
      
      return true;
  }

  function updatePool(uint256 _pid) private {
  
    PoolState storage pool = pools[_pid];
    if(!pool.tracked) {
      poolIds.push(_pid);
      pools[_pid].lastUpdatedAt = DividendPeriod.firstSecond(DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds), firstPeriodStartSeconds, periodDurationSeconds);
      pool.tracked = true;
    }

    uint256 updatedPeriod = DividendPeriod.fromSeconds(pool.lastUpdatedAt, firstPeriodStartSeconds, periodDurationSeconds);
    uint256 currentPeriod = DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds);
    for(uint256 i = updatedPeriod; i <= currentPeriod; i++) {
      bool didUpdate = updatePoolPeriod(i, _pid);
      if(!didUpdate) {
        break;
      }
    }
  }
  function updateUser(uint256 _pid, address _userAddress, uint256 _maxPeriod) private {
    
    if(!users[_userAddress].tracked) {
      userIds.push(_userAddress);
      users[_userAddress].tracked = true;
    }

    uint256 unpaidDividends = calculatePoolUserPendingDividends(_pid, _userAddress, _maxPeriod);
    UserPoolState storage user = poolUsers[_pid][_userAddress];
    user.lastUpdatedAt = Math.min(block.timestamp, DividendPeriod.lastSecond(_maxPeriod, firstPeriodStartSeconds, periodDurationSeconds));
    users[_userAddress].unpaidDividends = users[_userAddress].unpaidDividends.add(unpaidDividends);
  }

  function operatorUpdateUser(uint256 _pid, address _userAddress, uint256 _maxPeriod) external onlyOperator {
    
    uint256 currentPeriod = DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds);
    require(_maxPeriod < currentPeriod, "expected period to be in the past.");

    updateUser(_pid, _userAddress, _maxPeriod);
    poolUsers[_pid][_userAddress].rewardDebt = calculateRawUserReward(_pid, _userAddress, _maxPeriod);
  }

  function _setUserStakedAmount(uint256 _pid, address _userAddress, uint256 _userShares) private {
    
    updatePool(_pid);
    updateUser(_pid, _userAddress, DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds));

    UserPoolState storage user = poolUsers[_pid][_userAddress];
    PoolState storage pool = pools[_pid];
    if(user.shares > _userShares) {
      // withdrawal
      pool.totalShares = pool.totalShares.sub(user.shares.sub(_userShares));
    } else {
      // deposit
      pool.totalShares = pool.totalShares.add(_userShares.sub(user.shares));
    }

    user.shares = _userShares;
    user.rewardDebt = calculateRawUserReward(_pid, _userAddress, DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds));
  }

  function setUserStakedAmount(uint256 _pid, address _userAddress, uint256 _userShares) external override nonReentrant onlyOwner {
    _setUserStakedAmount(_pid, _userAddress, _userShares);
  }

  function calculateUnclaimedDividends(address _userAddress) public override view returns (uint256) {

    uint256 totalUnpaid = users[_userAddress].unpaidDividends.sub(users[_userAddress].paidDividends);
    for(uint256 i = 0; i < poolIds.length; i++) {
      uint256 _pid = poolIds[i];

      uint256 owed = calculatePoolUserPendingDividends(_pid, _userAddress, DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds));

      totalUnpaid = totalUnpaid.add(owed);
    }

    return totalUnpaid;
  }
  
  function collectDividends() external override nonReentrant {

    for(uint256 i = 0; i < poolIds.length; i++) {
      uint256 _pid = poolIds[i];

      updatePool(_pid);
      updateUser(_pid, msg.sender, DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds));

      poolUsers[_pid][msg.sender].rewardDebt = calculateRawUserReward(_pid, msg.sender, DividendPeriod.currentPeriod(firstPeriodStartSeconds, periodDurationSeconds));
    }

    uint256 totalUnpaid = users[msg.sender].unpaidDividends.sub(users[msg.sender].paidDividends);
    users[msg.sender].paidDividends = users[msg.sender].unpaidDividends;

    dividendToken.safeTransfer(msg.sender, totalUnpaid);
  }

  function returnFundsToCommunityWallet(uint256 _amount) external {
    require(msg.sender == communityWallet, "expected community wallet to initiate transfer");

    dividendToken.safeTransfer(communityWallet, _amount);
  }

  function migrateUsers(DividendsV3 dividends, address[] calldata _users, uint256[] calldata _pools) external onlyOperator {

    for(uint256 poolI = 0; poolI < _pools.length; poolI++) {
      uint256 pid = _pools[poolI];

      PoolState storage pool = pools[pid];
      if(!pool.tracked) {
        pool.tracked = true;
        pool.lastUpdatedAt = block.timestamp;
        pool.totalShares = 0;
      }

      for(uint256 userI = 0; userI < _users.length; userI++) {
        address user = _users[userI];

        // when the user has already been migrated, we skip them!
        if(poolUsers[pid][user].lastUpdatedAt > 0) {
          continue;
        }

        (uint256 shares,,uint256 lastUpdatedAt) = dividends.poolUsers(pid, user);
        if(lastUpdatedAt == 0 || shares == 0) {
          continue;
        }

        _setUserStakedAmount(pid, user, shares);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WithOperators is Ownable {
    
    mapping(address => bool) public operators;

    event OperatorUpdated(address indexed operator, bool indexed status);

    constructor() {
        operators[msg.sender] = true;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operable: caller is not the operator");
        _;
    }

    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        
        emit OperatorUpdated(_operator, _status);
    }
}

pragma solidity ^0.8.0;

library DividendPeriod {
  function firstSecond(uint256 _period, uint256 _offset, uint256 _duration) public pure returns (uint256) {
    return (_period * _duration) + _offset;
  }

  function lastSecond(uint256 _period, uint256 _offset, uint256 _duration) public pure returns (uint256) {
    return firstSecond(_period + 1, _offset, _duration);
  }

  function fromSeconds(uint256 _seconds, uint256 _offset, uint256 _duration) public pure returns (uint256) {
    
    _seconds = _seconds - _offset;
    return _seconds > _duration ? _seconds / _duration
      : 0;
  }

  function currentPeriod(uint256 _offset, uint256 _duration) public view returns (uint256) {
    return fromSeconds(block.timestamp, _offset, _duration);
  }
}

pragma solidity ^0.8.0;

library Math {
  function min(uint256 _a, uint256 _b) public pure returns (uint256) {
    return _a <= _b ? _a
      : _b;
  }

  function max(uint256 _a, uint256 _b) public pure returns (uint256) {
    return _a >= _b ? _a
      : _b;
  }

  function clamp(uint256 _a, uint256 _min, uint256 _max) public pure returns (uint256) {

    // _a is in range
    return _a >= _min && _a <= _max ? _a
      // _a is too small
      : _a < _min ? _min
        // _a is too large
        : _a;
  }
}

pragma solidity ^0.8.0;

interface IDividends {
  function setUserStakedAmount(uint256 _pid, address _userAddress, uint256 _totalShares) external;
  function calculateUnclaimedDividends(address _userAddress) external view returns (uint256);
  function collectDividends() external;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}