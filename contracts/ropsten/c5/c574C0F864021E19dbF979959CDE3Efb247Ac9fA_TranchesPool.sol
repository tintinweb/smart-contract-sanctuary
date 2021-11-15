// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IConsolidation.sol";
import "./interfaces/IGlobalEpoch.sol";


contract TranchesPool is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant BASE_MULTIPLIER = 1 ether;

  uint256 public epochStart;
  uint256 public epochsCount;
  uint256 public epochDuration;
  uint256 public seniorRatio = 5 * BASE_MULTIPLIER;
  uint256 public rewardPerEpoch;
  uint256 public epochDelayedFromFirst;
  address public rewardFunds;

  IERC20 internal rewardToken;
  IERC20 internal stakingToken;
  IGlobalEpoch internal globalEpoch;
  IConsolidation internal consolidation;

  enum Tranches { JUNIOR, SENIOR }

  struct Balances {
    uint256 junior;
    uint256 senior;
  }

  struct Epoch {
    bool posted;
    Balances staked;
    Balances result;
  }

  mapping(uint256 => Epoch) internal _epochs;

  struct Checkpoint {
    uint256 deposit;
    uint256 multiplier;
  }

  struct UserHistory {
    uint256 juniorBalance;
    uint256 seniorBalance;

    bool juniorRewardsClaimed;
    bool seniorRewardsClaimed;

    Checkpoint[] juniorCheckpoints;
    Checkpoint[] seniorCheckpoints;
  }

  mapping(address => mapping(uint256 => UserHistory)) internal _balances;

  event NewDeposit(address user, uint256 amount, Tranches tranche);
  event NewWithdraw(address user, uint256 amount, Tranches tranche);
  event ResultsPosted(uint256 epochId, uint256 juniorResult, uint256 seniorResult);

  // ------------------
  // CONSTRUCTOR
  // ------------------

  constructor(
    address _rewardToken,
    address _stakingToken,
    address _globalEpoch,
    address _rewardFunds,
    address _consolidation,
    uint256 _rewardPerEpoch,
    uint256 _epochsCount,
    uint256 _epochDelayedFromFirst
  ) public {
    rewardToken = IERC20(_rewardToken);
    stakingToken = IERC20(_stakingToken);
    globalEpoch = IGlobalEpoch(_globalEpoch);
    consolidation = IConsolidation(_consolidation);

    epochsCount = _epochsCount;
    epochDuration = globalEpoch.getEpochDelay();
    epochStart = globalEpoch.getFirstEpochTime() + epochDuration.mul(epochDelayedFromFirst);

    rewardFunds = _rewardFunds;
    rewardPerEpoch = _rewardPerEpoch;
    epochDelayedFromFirst = _epochDelayedFromFirst;
  }

  // ------------------
  // SETTERS
  // ------------------


  function deposit(uint256 amount, Tranches tranche) public {
    require(amount > 0, "deposit: Amount can not be 0!");

    uint256 currentEpoch = _getCurrentEpoch();
    require(currentEpoch > 0, "deposit: Not started yet!");

    Epoch storage epoch = _epochs[currentEpoch];
    UserHistory storage user = _balances[msg.sender][currentEpoch];

    if (tranche == Tranches.JUNIOR) {
      require(globalEpoch.isJuniorStakePeriod(), "deposit: Not junior stake period!");

      // Transfer tokens
      stakingToken.safeTransferFrom(msg.sender, address(this), amount);
      _safeKeep(amount);

      // Update epoch data
      epoch.staked.junior = epoch.staked.junior.add(amount);

      // Update user data
      user.juniorBalance = user.juniorBalance.add(amount);
      user.juniorCheckpoints.push(Checkpoint({
        deposit: amount,
        multiplier: _currentEpochMultiplier()
      }));
    } else if (tranche == Tranches.SENIOR) {
      require(!globalEpoch.isJuniorStakePeriod(), "deposit: Only junior tranche accepted now!");
      require(!_isSeniorLimitReached(currentEpoch, amount), "deposit: Senior pool limit is reached!");

      // Transfer tokens
      stakingToken.safeTransferFrom(msg.sender, address(this), amount);
      _safeKeep(amount);

      // Update epoch data
      epoch.staked.senior = epoch.staked.senior.add(amount);

      // Update user data
      user.seniorBalance = user.seniorBalance.add(amount);
      user.seniorCheckpoints.push(Checkpoint({
        deposit: amount,
        multiplier: _currentEpochMultiplier()
      }));
    }

    emit NewDeposit(msg.sender, amount, Tranches.SENIOR);
  }

  function withdraw(uint256 epochId, Tranches tranche) public {
    require(_getCurrentEpoch() > epochId, "withdraw: This epoch is in the future!");
    require(epochsCount >= epochId, "withdraw: Reached maximum number of epochs!");
    require(_epochs[epochId].posted, "withdraw: Results not posted!");

    uint256 withdrawAmount = _calculateWithdrawAmount(epochId, msg.sender, tranche);

    if (withdrawAmount > 0) {
      if (tranche == Tranches.SENIOR) {
        _balances[msg.sender][epochId].seniorBalance = 0;
      } else {
        _balances[msg.sender][epochId].juniorBalance = 0;
      }

      // Transfer tokens
      consolidation.safeWithdraw(address(stakingToken), withdrawAmount);
      stakingToken.safeTransfer(msg.sender, withdrawAmount);
    }

    emit NewWithdraw(msg.sender, withdrawAmount, tranche);
  }

  function clamReward(uint256 epochId, Tranches tranche) public {
    require(_getCurrentEpoch() > epochId, "clamReward: This epoch is in the future!");
    require(epochsCount >= epochId, "clamReward: Reached maximum number of epochs!");
    require(_epochs[epochId].posted, "clamReward: Results not posted!");

    uint256 availableReward = _calculateReward(epochId, msg.sender, tranche);

    if (tranche == Tranches.JUNIOR && !_balances[msg.sender][epochId].juniorRewardsClaimed) {
      _balances[msg.sender][epochId].juniorRewardsClaimed = true;
      rewardToken.safeTransferFrom(rewardFunds, msg.sender, availableReward);
    } else if (tranche == Tranches.SENIOR && !_balances[msg.sender][epochId].seniorRewardsClaimed) {
      _balances[msg.sender][epochId].seniorRewardsClaimed = true;
      rewardToken.safeTransferFrom(rewardFunds, msg.sender, availableReward);
    }
  }

  function exit(uint256 epochId, Tranches tranche) public {
    withdraw(epochId, tranche);
    clamReward(epochId, tranche);
  }

  function postResults(uint256 epochId, uint256 juniorResult, uint256 seniorResult) public onlyOwner {
    require(_getCurrentEpoch() > epochId, "postResults: This epoch is in the future!");
    require(epochsCount >= epochId, "postResults: Reached maximum number of epochs!");
    require(globalEpoch.isJuniorStakePeriod(), "postResults: Not results posting period!");

    Epoch storage epoch = _epochs[epochId];
    require(!epoch.posted, "postResults: Already posted!");
    require(juniorResult.add(seniorResult) == epoch.staked.junior.add(epoch.staked.senior), "postResults: Results and actual size should be the same!");

    epoch.posted = true;
    epoch.result.junior = juniorResult;
    epoch.result.senior = seniorResult;

    emit ResultsPosted(epochId, juniorResult, seniorResult);
  }

  function changeRewardsPerEpoch(uint256 newRewards) public onlyOwner {
    rewardPerEpoch = newRewards;
  }


  // ------------------
  // GETTERS
  // ------------------

  function getEpochData(uint256 epochId) public view returns (
    uint256 juniorStaked,
    uint256 seniorStaked,
    uint256 juniorResult,
    uint256 seniorResult
  ) {
    Epoch memory _epoch = _epochs[epochId];
    return (
      _epoch.staked.junior,
      _epoch.staked.senior,
      _epoch.result.junior,
      _epoch.result.senior
    );
  }

  function getUserBalances(address userAddress, uint256 epochId) public view returns (
    uint256 juniorStaked,
    uint256 seniorStaked
  ) {
    return (
      _balances[userAddress][epochId].juniorBalance,
      _balances[userAddress][epochId].seniorBalance
    );
  }

  function getAvailableReward(uint256 epochId, address userAddress, Tranches tranche) public view returns (uint256) {
    if (tranche == Tranches.JUNIOR && _balances[userAddress][epochId].juniorRewardsClaimed) {
      return 0;
    }

    if (tranche == Tranches.SENIOR && _balances[userAddress][epochId].seniorRewardsClaimed) {
      return 0;
    }

    return _calculateReward(epochId, userAddress, tranche);
  }

  function currentEpochMultiplier() public view returns (uint256) {
    return _currentEpochMultiplier();
  }

  // ------------------
  // INTERNAL
  // ------------------

  function _getCurrentEpoch() internal view returns (uint256) {
    if (block.timestamp < epochStart) {
      return 0;
    }

    return block.timestamp.sub(epochStart).div(epochDuration).add(1);
  }

  function _calculateWithdrawAmount(uint256 epochId, address userAddress, Tranches tranche) internal view returns (uint256) {
    Epoch memory epoch = _epochs[epochId];
    UserHistory memory user = _balances[userAddress][epochId];

    uint256 poolSize;
    uint256 poolResult;
    uint256 userStake;

    if (tranche == Tranches.JUNIOR) {
      poolSize = epoch.staked.junior;
      poolResult = epoch.result.junior;
      userStake = user.juniorBalance;
    } else if (tranche == Tranches.SENIOR) {
      poolSize = epoch.staked.senior;
      poolResult = epoch.result.senior;
      userStake = user.seniorBalance;
    }

    uint256 diff = poolResult.mul(BASE_MULTIPLIER).div(poolSize.div(100));
    uint256 amount = userStake.mul(diff).div(100).div(BASE_MULTIPLIER);

    return amount;
  }

  function _isSeniorLimitReached(uint256 epochId, uint256 amount) internal view returns (bool) {
    uint256 juniorStaked = _epochs[epochId].staked.junior;
    uint256 seniorStaked = _epochs[epochId].staked.senior;

    return seniorStaked.add(amount).mul(BASE_MULTIPLIER) > juniorStaked.mul(seniorRatio);
  }

  function _currentEpochMultiplier() internal view returns (uint256) {
    uint256 timeLeft = globalEpoch.getSecondsUntilNextEpoch();
    uint256 multiplier = timeLeft.mul(BASE_MULTIPLIER).div(globalEpoch.getEpochDelay());

    return multiplier;
  }

  function _calculateReward(uint256 epochId, address userAddress, Tranches tranche) internal view returns (uint256) {
    uint256 epochPoolSize;
    uint256 availableReward;
    Checkpoint[] memory checkpoints;

    if (tranche == Tranches.JUNIOR) {
      epochPoolSize = _epochs[epochId].staked.junior;
      checkpoints = _balances[userAddress][epochId].juniorCheckpoints;
    } else if (tranche == Tranches.SENIOR) {
      epochPoolSize = _epochs[epochId].staked.senior;
      checkpoints = _balances[userAddress][epochId].seniorCheckpoints;
    }

    for (uint256 i = 0; i < checkpoints.length; i++) {
      uint256 effectiveAmount = checkpoints[i].deposit.mul(checkpoints[i].multiplier).div(BASE_MULTIPLIER);
      availableReward = availableReward.add(rewardPerEpoch.mul(effectiveAmount).div(epochPoolSize));
    }

    return availableReward;
  }

  function _safeKeep(uint256 amount) internal {
    stakingToken.safeApprove(address(consolidation), amount);
    consolidation.safeKeep(address(stakingToken), amount);
    stakingToken.safeApprove(address(consolidation), 0);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.3;


interface IConsolidation {
  function safeKeep() external payable;
  function safeKeep(address token, uint256 amount) external;
  function safeWithdraw(uint256 amount) external;
  function safeWithdraw(address token, uint256 amount) external;
  function getBalance(address user, address token) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.3;


interface IGlobalEpoch {
function getCurrentEpoch() external view returns (uint256);
function getSecondsUntilNextEpoch() external view returns (uint256);
function getSecondsSinceThisEpoch() external view returns (uint256);
function getSecondsSinceFirstEpoch() external view returns (uint256);
function isJuniorStakePeriod() external view returns (bool);
function getFirstEpochTime() external view returns (uint256);
function getEpochDelay() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

