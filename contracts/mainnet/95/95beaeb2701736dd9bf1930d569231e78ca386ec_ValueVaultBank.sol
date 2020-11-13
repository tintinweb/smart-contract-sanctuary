// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

// File: contracts/vaults/strategies/IStrategy.sol

interface IStrategy {
    function approve(IERC20 _token) external;

    function approveForSpender(IERC20 _token, address spender) external;

    // Deposit tokens to a farm to yield more tokens.
    function deposit(address _vault, uint256 _amount) external;

    // Claim farming tokens
    function claim(address _vault) external;

    // The vault request to harvest the profit
    function harvest(uint256 _bankPoolId) external;

    // Withdraw the principal from a farm.
    function withdraw(address _vault, uint256 _amount) external;

    // Target farming token of this strategy.
    function getTargetToken() external view returns(address);

    function balanceOf(address _vault) external view returns (uint256);

    function pendingReward(address _vault) external view returns (uint256);

    function expectedAPY(address _vault) external view returns (uint256);

    function governanceRescueToken(IERC20 _token) external returns (uint256);
}

// File: contracts/vaults/ValueVaultBank.sol

interface IValueVaultMaster {
    function minorPool() view external returns(address);
    function performanceReward() view external returns(address);
    function minStakeTimeToClaimVaultReward() view external returns(uint256);
}

interface IValueVault {
    function balanceOf(address account) view external returns(uint256);
    function getStrategyCount() external view returns(uint256);
    function depositAvailable() external view returns(bool);
    function strategies(uint256 _index) view external returns(IStrategy);
    function mintByBank(IERC20 _token, address _to, uint256 _amount) external;
    function burnByBank(IERC20 _token, address _account, uint256 _amount) external;
    function harvestAllStrategies(uint256 _bankPoolId) external;
    function harvestStrategy(IStrategy _strategy, uint256 _bankPoolId) external;
}

interface IValueMinorPool {
    function depositOnBehalf(address farmer, uint256 _pid, uint256 _amount, address _referrer) external;
    function withdrawOnBehalf(address farmer, uint256 _pid, uint256 _amount) external;
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract ValueVaultBank {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    address public governance;
    IValueVaultMaster public vaultMaster;

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        IValueVault vault; // Address of vault contract.
        uint256 minorPoolId; // minorPool's subpool id
        uint256 startTime;
        uint256 individualCap; // 0 to disable
        uint256 totalCap; // 0 to disable
    }

    // Info of each pool.
    mapping(uint256 => PoolInfo) public poolMap;  // By poolId

    struct Staker {
        uint256 stake;
        uint256 payout;
        uint256 total_out;
    }

    mapping(uint256 => mapping(address => Staker)) public stakers; // poolId -> stakerAddress -> staker's info

    struct Global {
        uint256 total_stake;
        uint256 total_out;
        uint256 earnings_per_share;
    }

    mapping(uint256 => Global) public global; // poolId -> global data

    mapping(uint256 => mapping(address => uint256)) public lastStakeTimes; // poolId -> user's last staked
    uint256 constant internal magnitude = 10 ** 40;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event Claim(address indexed user, uint256 indexed poolId);

    constructor() public {
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVaultMaster(IValueVaultMaster _vaultMaster) external {
        require(msg.sender == governance, "!governance");
        vaultMaster = _vaultMaster;
    }

    function setPoolInfo(uint256 _poolId, IERC20 _token, IValueVault _vault, uint256 _minorPoolId, uint256 _startTime, uint256 _individualCap, uint256 _totalCap) public {
        require(msg.sender == governance, "!governance");
        poolMap[_poolId].token = _token;
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].minorPoolId = _minorPoolId;
        poolMap[_poolId].startTime = _startTime;
        poolMap[_poolId].individualCap = _individualCap;
        poolMap[_poolId].totalCap = _totalCap;
    }

    function setPoolCap(uint256 _poolId, uint256 _individualCap, uint256 _totalCap) public {
        require(msg.sender == governance, "!governance");
        require(_totalCap == 0 || _totalCap >= _individualCap, "_totalCap < _individualCap");
        poolMap[_poolId].individualCap = _individualCap;
        poolMap[_poolId].totalCap = _totalCap;
    }

    function depositAvailable(uint256 _poolId) external view returns(bool) {
        return poolMap[_poolId].vault.depositAvailable();
    }

    // Deposit tokens to Bank. If we have a strategy, then tokens will be moved there.
    function deposit(uint256 _poolId, uint256 _amount, bool _farmMinorPool, address _referrer) public discountCHI {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "deposit: after startTime");
        require(_amount > 0, "!_amount");
        require(address(pool.vault) != address(0), "pool.vault = 0");
        require(pool.individualCap == 0 || stakers[_poolId][msg.sender].stake.add(_amount) <= pool.individualCap, "Exceed pool.individualCap");
        require(pool.totalCap == 0 || global[_poolId].total_stake.add(_amount) <= pool.totalCap, "Exceed pool.totalCap");

        pool.token.safeTransferFrom(msg.sender, address(pool.vault), _amount);
        pool.vault.mintByBank(pool.token, msg.sender, _amount);
        if (_farmMinorPool && address(vaultMaster) != address(0)) {
            address minorPool = vaultMaster.minorPool();
            if (minorPool != address(0)) {
                IValueMinorPool(minorPool).depositOnBehalf(msg.sender, pool.minorPoolId, pool.vault.balanceOf(msg.sender), _referrer);
            }
        }

        _handleDepositStakeInfo(_poolId, _amount);
        emit Deposit(msg.sender, _poolId, _amount);
    }

    function _handleDepositStakeInfo(uint256 _poolId, uint256 _amount) internal {
        stakers[_poolId][msg.sender].stake = stakers[_poolId][msg.sender].stake.add(_amount);
        if (global[_poolId].earnings_per_share != 0) {
            stakers[_poolId][msg.sender].payout = stakers[_poolId][msg.sender].payout.add(
                global[_poolId].earnings_per_share.mul(_amount).sub(1).div(magnitude).add(1)
            );
        }
        global[_poolId].total_stake = global[_poolId].total_stake.add(_amount);
        lastStakeTimes[_poolId][msg.sender] = block.timestamp;
    }

    // Withdraw tokens from ValueVaultBank (from a strategy first if there is one).
    function withdraw(uint256 _poolId, uint256 _amount, bool _farmMinorPool) public discountCHI {
        PoolInfo storage pool = poolMap[_poolId];
        require(address(pool.vault) != address(0), "pool.vault = 0");
        require(now >= pool.startTime, "withdraw: after startTime");
        require(_amount <= stakers[_poolId][msg.sender].stake, "!balance");

        claimProfit(_poolId);

        if (_farmMinorPool && address(vaultMaster) != address(0)) {
            address minorPool = vaultMaster.minorPool();
            if (minorPool != address(0)) {
                IValueMinorPool(minorPool).withdrawOnBehalf(msg.sender, pool.minorPoolId, _amount);
            }
        }
        pool.vault.burnByBank(pool.token, msg.sender, _amount);
        pool.token.safeTransfer(msg.sender, _amount);

        _handleWithdrawStakeInfo(_poolId, _amount);
        emit Withdraw(msg.sender, _poolId, _amount);
    }

    function _handleWithdrawStakeInfo(uint256 _poolId, uint256 _amount) internal {
        stakers[_poolId][msg.sender].payout = stakers[_poolId][msg.sender].payout.sub(
            global[_poolId].earnings_per_share.mul(_amount).div(magnitude)
        );
        stakers[_poolId][msg.sender].stake = stakers[_poolId][msg.sender].stake.sub(_amount);
        global[_poolId].total_stake = global[_poolId].total_stake.sub(_amount);
    }

    function exit(uint256 _poolId, bool _farmMinorPool) external discountCHI {
        withdraw(_poolId, stakers[_poolId][msg.sender].stake, _farmMinorPool);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _poolId) public {
        uint256 amount = stakers[_poolId][msg.sender].stake;
        poolMap[_poolId].token.safeTransfer(address(msg.sender), amount);
        stakers[_poolId][msg.sender].stake = 0;
        global[_poolId].total_stake = global[_poolId].total_stake.sub(amount);
    }

    function harvestVault(uint256 _poolId) external discountCHI {
        poolMap[_poolId].vault.harvestAllStrategies(_poolId);
    }

    function harvestStrategy(uint256 _poolId, IStrategy _strategy) external discountCHI {
        poolMap[_poolId].vault.harvestStrategy(_strategy, _poolId);
    }

    function make_profit(uint256 _poolId, uint256 _amount) public {
        require(_amount > 0, "not 0");
        PoolInfo storage pool = poolMap[_poolId];
        pool.token.safeTransferFrom(msg.sender, address(this), _amount);
        if (global[_poolId].total_stake > 0) {
            global[_poolId].earnings_per_share = global[_poolId].earnings_per_share.add(
                _amount.mul(magnitude).div(global[_poolId].total_stake)
            );
        }
        global[_poolId].total_out = global[_poolId].total_out.add(_amount);
    }

    function cal_out(uint256 _poolId, address user) public view returns (uint256) {
        uint256 _cal = global[_poolId].earnings_per_share.mul(stakers[_poolId][user].stake).div(magnitude);
        if (_cal < stakers[_poolId][user].payout) {
            return 0;
        } else {
            return _cal.sub(stakers[_poolId][user].payout);
        }
    }

    function cal_out_pending(uint256 _pendingBalance, uint256 _poolId, address user) public view returns (uint256) {
        uint256 _earnings_per_share = global[_poolId].earnings_per_share.add(
            _pendingBalance.mul(magnitude).div(global[_poolId].total_stake)
        );
        uint256 _cal = _earnings_per_share.mul(stakers[_poolId][user].stake).div(magnitude);
        _cal = _cal.sub(cal_out(_poolId, user));
        if (_cal < stakers[_poolId][user].payout) {
            return 0;
        } else {
            return _cal.sub(stakers[_poolId][user].payout);
        }
    }

    function claimProfit(uint256 _poolId) public discountCHI {
        uint256 out = cal_out(_poolId, msg.sender);
        stakers[_poolId][msg.sender].payout = global[_poolId].earnings_per_share.mul(stakers[_poolId][msg.sender].stake).div(magnitude);
        stakers[_poolId][msg.sender].total_out = stakers[_poolId][msg.sender].total_out.add(out);

        if (out > 0) {
            PoolInfo storage pool = poolMap[_poolId];
            uint256 _stakeTime = now - lastStakeTimes[_poolId][msg.sender];
            if (address(vaultMaster) != address(0) && _stakeTime < vaultMaster.minStakeTimeToClaimVaultReward()) { // claim too soon
                uint256 actually_out = _stakeTime.mul(out).mul(1e18).div(vaultMaster.minStakeTimeToClaimVaultReward()).div(1e18);
                uint256 earlyClaimCost = out.sub(actually_out);
                safeTokenTransfer(pool.token, vaultMaster.performanceReward(), earlyClaimCost);
                out = actually_out;
            }
            safeTokenTransfer(pool.token, msg.sender, out);
        }
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough token.
    function safeTokenTransfer(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.safeTransfer(_to, bal);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    /**
     * @dev if there is any token stuck we will need governance support to rescue the fund
     */
    function governanceRescueFromStrategy(IERC20 _token, IStrategy _strategy) external {
        require(msg.sender == governance, "!governance");
        _strategy.governanceRescueToken(_token);
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract.
     * This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these.
     * It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.safeTransfer(to, amount);
    }
}