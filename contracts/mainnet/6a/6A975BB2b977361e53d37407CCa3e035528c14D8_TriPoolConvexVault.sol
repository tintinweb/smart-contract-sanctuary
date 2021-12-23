// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseConvexVault.sol";

contract TriPoolConvexVault is BaseConvexVault {
  constructor(address _depositor, address _governor)
    BaseConvexVault(
      address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490), // 3poolCrv
      _depositor,
      _governor,
      address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31), // Convex Finance: Booster,
      9 // pid
    )
  {
    address[] memory _rewardTokens = new address[](2);
    _rewardTokens[0] = address(0xD533a949740bb3306d119CC777fa900bA034cd52); // CRV
    _rewardTokens[1] = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B); // CVX

    _setupRewardTokens(_rewardTokens);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../MultipleRewardsVaultBase.sol";

interface IBooster {
  struct PoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
  }

  function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) external returns (bool);

  function depositAll(uint256 _pid, bool _stake) external returns (bool);

  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

  function withdrawAll(uint256 _pid) external returns (bool);
}

interface IBaseRewardPool {
  function balanceOf(address account) external view returns (uint256);

  function getReward() external returns (bool);

  function getReward(address _account, bool _claimExtras) external returns (bool);

  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

  function earned(address _account) external view returns (uint256);
}

abstract contract BaseConvexVault is MultipleRewardsVaultBase {
  using SafeERC20 for IERC20;

  IBooster public booster;
  IBaseRewardPool public cvxRewardPool;

  uint256 public pid;

  constructor(
    address _baseToken,
    address _depositor,
    address _governor,
    address _booster,
    uint256 _pid
  ) MultipleRewardsVaultBase(_baseToken, _depositor, _governor) {
    IBooster.PoolInfo memory info = IBooster(_booster).poolInfo(_pid);
    require(info.lptoken == _baseToken, "invalid pid or token");

    booster = IBooster(_booster);
    cvxRewardPool = IBaseRewardPool(info.crvRewards);
    pid = _pid;
  }

  // Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal override {
    IERC20 _baseToken = IERC20(baseToken);
    uint256 amount = _baseToken.balanceOf(address(this));
    if (amount > 0) {
      IBooster _booster = booster;
      _baseToken.safeApprove(address(_booster), amount);
      _booster.deposit(pid, amount, true);
    }
  }

  // Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal override {
    cvxRewardPool.withdrawAndUnwrap(_amount, false);
  }

  // Harvest rewards from strategy into vault
  function _harvest() internal override {
    cvxRewardPool.getReward();
  }

  // Balance of deposit token in underlying strategy
  function _strategyBalance() internal view override returns (uint256) {
    // The cvxStakeToken is 1:1 with lpToken
    return cvxRewardPool.balanceOf(address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IRewardBondDepositor.sol";
import "./VaultBase.sol";

abstract contract MultipleRewardsVaultBase is VaultBase {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  uint256 private constant MAX_REWARD_TOKENS = 4;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  event Claim(address indexed user, uint256[] amount);
  event Harvest(address indexed keeper, uint256[] bondAmount, uint256[] rewardAmount);

  // The list of address of reward token.
  address[] private rewardTokens;

  // The last harvest block number.
  uint256 public lastUpdateBlock;
  // Mapping for reward token index to the reward per share.
  mapping(uint256 => uint256) public rewardsPerShareStored;
  // Mapping from user address to reward token index to reward per share paid.
  mapping(address => mapping(uint256 => uint256)) public userRewardPerSharePaid;
  // Mapping from user address to reward token index to reward amount.
  mapping(address => mapping(uint256 => uint256)) public rewards;

  /// @param _baseToken The address of staked token.
  /// @param _depositor The address of RewardBondDepositor.
  /// @param _governor The address of governor.
  constructor(
    address _baseToken,
    address _depositor,
    address _governor
  ) VaultBase(_baseToken, _depositor, _governor) {}

  /// @dev setup reward tokens, should be called in constrctor.
  /// @param _rewardTokens A list of reward tokens.
  function _setupRewardTokens(address[] memory _rewardTokens) internal {
    require(_rewardTokens.length <= MAX_REWARD_TOKENS, "MultipleRewardsVaultBase: too much reward");
    rewardTokens = _rewardTokens;
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      IERC20(_rewardTokens[i]).safeApprove(depositor, uint256(-1));
    }
  }

  /// @dev return the reward tokens in current vault.
  function getRewardTokens() external view override returns (address[] memory) {
    return rewardTokens;
  }

  /// @dev return the reward token earned in current vault.
  /// @param _account The address of account.
  /// @param _index The index of reward token.
  function earned(address _account, uint256 _index) public view returns (uint256) {
    uint256 _balance = balanceOf[_account];
    return
      _balance.mul(rewardsPerShareStored[_index].sub(userRewardPerSharePaid[_account][_index])).div(PRECISION).add(
        rewards[_account][_index]
      );
  }

  /// @dev Amount of deposit token per vault share
  function getPricePerFullShare() public view returns (uint256) {
    if (balance == 0) return 0;
    return _strategyBalance().mul(PRECISION).div(balance);
  }

  /// @dev Deposit baseToken to vault.
  /// @param _amount The amount of token to deposit.
  function deposit(uint256 _amount) external override nonReentrant {
    _updateReward(msg.sender);

    address _token = baseToken; // gas saving
    uint256 _pool = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    _amount = IERC20(_token).balanceOf(address(this)).sub(_pool);

    uint256 _share;
    if (balance == 0) {
      _share = _amount;
    } else {
      _share = _amount.mul(balance).div(_strategyBalance());
    }

    balance = balance.add(_share);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_share);

    _deposit();

    emit Deposit(msg.sender, _amount);
  }

  /// @dev Withdraw baseToken from vault.
  /// @param _share The share of vault to withdraw.
  function withdraw(uint256 _share) public override nonReentrant {
    require(_share <= balanceOf[msg.sender], "Vault: not enough share");
    _updateReward(msg.sender);

    uint256 _amount = _share.mul(_strategyBalance()).div(balance);

    // sub will not overflow here.
    balanceOf[msg.sender] = balanceOf[msg.sender] - _share;
    balance = balance - _share;

    address _token = baseToken; // gas saving
    uint256 _pool = IERC20(_token).balanceOf(address(this));
    if (_pool < _amount) {
      uint256 _withdrawAmount = _amount - _pool;
      // Withdraw from strategy
      _withdraw(_withdrawAmount);
      uint256 _poolAfter = IERC20(_token).balanceOf(address(this));
      uint256 _diff = _poolAfter.sub(_pool);
      if (_diff < _withdrawAmount) {
        _amount = _pool.add(_diff);
      }
    }

    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit Withdraw(msg.sender, _amount);
  }

  /// @dev Claim pending rewards from vault.
  function claim() public override {
    _updateReward(msg.sender);

    uint256 length = rewardTokens.length;
    uint256[] memory _rewards = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 reward = rewards[msg.sender][i];
      if (reward > 0) {
        rewards[msg.sender][i] = 0;
        IERC20(rewardTokens[i]).safeTransfer(msg.sender, reward);
      }
      _rewards[i] = reward;
    }

    emit Claim(msg.sender, _rewards);
  }

  /// @dev Withdraw and claim pending rewards from vault.
  function exit() external override {
    withdraw(balanceOf[msg.sender]);
    claim();
  }

  /// @dev harvest pending rewards from strategy.
  function harvest() public override {
    if (lastUpdateBlock == block.number) {
      return;
    }
    lastUpdateBlock = block.number;
    if (balance == 0) {
      IRewardBondDepositor(depositor).notifyRewards(msg.sender, new uint256[](rewardTokens.length));
      return;
    }

    uint256 length = rewardTokens.length;
    uint256[] memory harvested = new uint256[](length);
    uint256[] memory bondAmount = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      harvested[i] = IERC20(rewardTokens[i]).balanceOf(address(this));
    }
    // Harvest rewards from strategy
    _harvest();

    for (uint256 i = 0; i < length; i++) {
      harvested[i] = IERC20(rewardTokens[i]).balanceOf(address(this)).sub(harvested[i]);
      bondAmount[i] = harvested[i].mul(bondPercentage).div(PRECISION);
      harvested[i] = harvested[i].sub(bondAmount[i]);
    }

    IRewardBondDepositor(depositor).notifyRewards(msg.sender, bondAmount);

    // distribute new rewards to current shares evenly
    for (uint256 i = 0; i < length; i++) {
      rewardsPerShareStored[i] = rewardsPerShareStored[i].add(harvested[i].mul(1e18).div(balance));
    }

    emit Harvest(msg.sender, bondAmount, harvested);
  }

  /********************************** STRATEGY FUNCTIONS **********************************/

  /// @dev Deposit token into strategy. Deposits entire vault balance
  function _deposit() internal virtual;

  /// @dev Withdraw token from strategy. _amount is the amount of deposit tokens
  function _withdraw(uint256 _amount) internal virtual;

  /// @dev Harvest rewards from strategy into vault
  function _harvest() internal virtual;

  /// @dev Return the amount of baseToken in strategy.
  function _strategyBalance() internal view virtual returns (uint256);

  /********************************** INTERNAL FUNCTIONS **********************************/

  /// @dev Update pending reward for user.
  /// @param _account The address of account.
  function _updateReward(address _account) internal {
    harvest();

    uint256 length = rewardTokens.length;
    for (uint256 i = 0; i < length; i++) {
      rewards[_account][i] = earned(_account, i);
      userRewardPerSharePaid[_account][i] = rewardsPerShareStored[i];
    }
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

pragma solidity ^0.7.6;

interface IRewardBondDepositor {
  function currentEpoch()
    external
    view
    returns (
      uint64 epochNumber,
      uint64 startBlock,
      uint64 nextBlock,
      uint64 epochLength
    );

  function rewardShares(uint256 _epoch, address _vault) external view returns (uint256);

  function getVaultsFromAccount(address _user) external view returns (address[] memory);

  function getAccountRewardShareSince(
    uint256 _epoch,
    address _user,
    address _vault
  ) external view returns (uint256[] memory);

  function bond(address _vault) external;

  function rebase() external;

  function notifyRewards(address _user, uint256[] memory _amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IVault.sol";

abstract contract VaultBase is ReentrancyGuard, IVault {
  uint256 public constant PRECISION = 1e18;

  // The address of staked token.
  address public immutable baseToken;
  // The address of reward bond depositor.
  address public depositor;

  // The address of governor.
  address public governor;

  // The percentage take from harvested reward to bond.
  uint256 public bondPercentage;

  // The total share of vault.
  uint256 public override balance;
  // Mapping from user address to vault share.
  mapping(address => uint256) public override balanceOf;

  modifier onlyGovernor() {
    require(msg.sender == governor, "VaultBase: only governor");
    _;
  }

  constructor(
    address _baseToken,
    address _depositor,
    address _governor
  ) {
    baseToken = _baseToken;
    depositor = _depositor;
    governor = _governor;

    bondPercentage = PRECISION;
  }

  function setGovernor(address _governor) external onlyGovernor {
    governor = _governor;
  }

  function setBondPercentage(uint256 _bondPercentage) external onlyGovernor {
    require(_bondPercentage <= PRECISION, "VaultBase: percentage too large");

    bondPercentage = _bondPercentage;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.6;

interface IVault {
  function getRewardTokens() external view returns (address[] memory);

  function balance() external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function claim() external;

  function exit() external;

  function harvest() external;
}