// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "IERC20.sol";
import "SafeMath.sol";
import "Address.sol";

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

pragma solidity ^0.6.0;

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

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/v3.0.0/contracts/Initializable.sol
// Added public isInitialized() view of private initialized bool.

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    /**
     * @dev Return true if and only if the contract has been initialized
     * @return whether the contract has been initialized
     */
    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {Context} from "Context.sol";

import {Initializable} from "Initializable.sol";

/**
 * @title UpgradeableClaimable
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. Since
 * this contract combines Claimable and UpgradableOwnable contracts, ownership
 * can be later change via 2 step method {transferOwnership} and {claimOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract UpgradeableClaimable is Initializable, Context {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting a custom initial owner of choice.
     * @param __owner Initial owner of contract to be set.
     */
    function initialize(address __owner) internal initializer {
        _owner = __owner;
        emit OwnershipTransferred(address(0), __owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pending owner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

interface ITrueDistributor {
    function trustToken() external view returns (IERC20);

    function farm() external view returns (address);

    function distribute() external;

    function nextDistribution() external view returns (uint256);

    function empty() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";

import {ITrueDistributor} from "ITrueDistributor.sol";

interface ITrueMultiFarm {
    function trueDistributor() external view returns (ITrueDistributor);

    function stake(IERC20 token, uint256 amount) external;

    function unstake(IERC20 token, uint256 amount) external;

    function claim(IERC20[] calldata tokens) external;

    function exit(IERC20[] calldata tokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";
import {SafeMath} from "SafeMath.sol";
import {SafeERC20} from "SafeERC20.sol";

import {UpgradeableClaimable} from "UpgradeableClaimable.sol";
import {ITrueDistributor} from "ITrueDistributor.sol";
import {ITrueMultiFarm} from "ITrueMultiFarm.sol";

/**
 * @title TrueMultiFarm
 * @notice Deposit liquidity tokens to earn TRU rewards over time
 * @dev Staking pool where tokens are staked for TRU rewards
 * A Distributor contract decides how much TRU all farms in total can earn over time
 * Calling setShare() by owner decides ratio of rewards going to respective token farms
 * You can think of this contract as of a farm that is a distributor to the multiple other farms
 * A share of a farm in the multifarm is it's stake
 */
contract TrueMultiFarm is ITrueMultiFarm, UpgradeableClaimable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 private constant PRECISION = 1e30;

    struct Stakes {
        // total amount of a particular token staked
        uint256 totalStaked;
        // who staked how much
        mapping(address => uint256) staked;
    }

    struct Rewards {
        // track overall cumulative rewards
        uint256 cumulativeRewardPerToken;
        // track previous cumulate rewards for accounts
        mapping(address => uint256) previousCumulatedRewardPerToken;
        // track claimable rewards for accounts
        mapping(address => uint256) claimableReward;
        // track total rewards
        uint256 totalClaimedRewards;
        uint256 totalRewards;
    }

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    IERC20 public rewardToken;
    ITrueDistributor public override trueDistributor;

    mapping(IERC20 => Stakes) public stakes;
    mapping(IERC20 => Rewards) public stakerRewards;

    // Shares of farms in the multifarm
    Stakes public shares;
    // Total rewards per farm
    Rewards public farmRewards;

    // ======= STORAGE DECLARATION END ============

    /**
     * @dev Emitted when an account stakes
     * @param who Account staking
     * @param amountStaked Amount of tokens staked
     */
    event Stake(IERC20 indexed token, address indexed who, uint256 amountStaked);

    /**
     * @dev Emitted when an account unstakes
     * @param who Account unstaking
     * @param amountUnstaked Amount of tokens unstaked
     */
    event Unstake(IERC20 indexed token, address indexed who, uint256 amountUnstaked);

    /**
     * @dev Emitted when an account claims TRU rewards
     * @param who Account claiming
     * @param amountClaimed Amount of TRU claimed
     */
    event Claim(IERC20 indexed token, address indexed who, uint256 amountClaimed);

    /**
     * @dev Update all rewards associated with the token and msg.sender
     */
    modifier update(IERC20 token) {
        distribute();
        updateRewards(token);
        _;
    }

    /**
     * @dev Is there any reward allocatiion for given token
     */
    modifier hasShares(IERC20 token) {
        require(shares.staked[address(token)] > 0, "TrueMultiFarm: This token has no shares");
        _;
    }

    /**
     * @dev How much is staked by staker on token farm
     */
    function staked(IERC20 token, address staker) external view returns (uint256) {
        return stakes[token].staked[staker];
    }

    /**
     * @dev Initialize staking pool with a Distributor contract
     * The distributor contract calculates how much TRU rewards this contract
     * gets, and stores TRU for distribution.
     * @param _trueDistributor Distributor contract
     */
    function initialize(ITrueDistributor _trueDistributor) public initializer {
        UpgradeableClaimable.initialize(msg.sender);
        trueDistributor = _trueDistributor;
        rewardToken = _trueDistributor.trustToken();
        require(trueDistributor.farm() == address(this), "TrueMultiFarm: Distributor farm is not set");
    }

    /**
     * @dev Stake tokens for TRU rewards.
     * Also claims any existing rewards.
     * @param amount Amount of tokens to stake
     */
    function stake(IERC20 token, uint256 amount) external override hasShares(token) update(token) {
        if (stakerRewards[token].claimableReward[msg.sender] > 0) {
            _claim(token);
        }
        stakes[token].staked[msg.sender] = stakes[token].staked[msg.sender].add(amount);
        stakes[token].totalStaked = stakes[token].totalStaked.add(amount);

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Stake(token, msg.sender, amount);
    }

    /**
     * @dev Remove staked tokens
     * @param amount Amount of tokens to unstake
     */
    function unstake(IERC20 token, uint256 amount) external override update(token) {
        _unstake(token, amount);
    }

    /**
     * @dev Claim TRU rewards
     */
    function claim(IERC20[] calldata tokens) external override {
        uint256 tokensLength = tokens.length;

        distribute();
        for (uint256 i = 0; i < tokensLength; i++) {
            updateRewards(tokens[i]);
        }
        for (uint256 i = 0; i < tokensLength; i++) {
            _claim(tokens[i]);
        }
    }

    /**
     * @dev Unstake amount and claim rewards
     */
    function exit(IERC20[] calldata tokens) external override {
        distribute();

        uint256 tokensLength = tokens.length;

        for (uint256 i = 0; i < tokensLength; i++) {
            updateRewards(tokens[i]);
        }
        for (uint256 i = 0; i < tokensLength; i++) {
            _unstake(tokens[i], stakes[tokens[i]].staked[msg.sender]);
            _claim(tokens[i]);
        }
    }

    /**
     * @dev Set shares for farms
     * Example: setShares([DAI, USDC], [1, 2]) will ensure that 33.(3)% of rewards will go to DAI farm and rest to USDC farm
     * If later setShares([DAI, TUSD], [2, 1]) will be called then shares of DAI will grow to 2, shares of USDC won't change and shares of TUSD will be 1
     * So this will give 40% of rewards going to DAI farm, 40% to USDC and 20% to TUSD
     * @param tokens Token addresses
     * @param updatedShares share of the i-th token in the multifarm
     */
    function setShares(IERC20[] calldata tokens, uint256[] calldata updatedShares) external onlyOwner {
        uint256 tokensLength = tokens.length;

        require(tokensLength == updatedShares.length, "TrueMultiFarm: Array lengths mismatch");
        distribute();

        for (uint256 i = 0; i < tokensLength; i++) {
            _updateClaimableRewardsForFarm(tokens[i]);
        }
        for (uint256 i = 0; i < tokensLength; i++) {
            uint256 oldStaked = shares.staked[address(tokens[i])];
            shares.staked[address(tokens[i])] = updatedShares[i];
            shares.totalStaked = shares.totalStaked.sub(oldStaked).add(updatedShares[i]);
        }
    }

    /**
     * @dev Internal unstake function
     * @param amount Amount of tokens to unstake
     */
    function _unstake(IERC20 token, uint256 amount) internal {
        require(amount <= stakes[token].staked[msg.sender], "TrueMultiFarm: Cannot withdraw amount bigger than available balance");
        stakes[token].staked[msg.sender] = stakes[token].staked[msg.sender].sub(amount);
        stakes[token].totalStaked = stakes[token].totalStaked.sub(amount);

        token.safeTransfer(msg.sender, amount);
        emit Unstake(token, msg.sender, amount);
    }

    /**
     * @dev Internal claim function
     */
    function _claim(IERC20 token) internal {
        uint256 rewardToClaim = stakerRewards[token].claimableReward[msg.sender];

        stakerRewards[token].totalClaimedRewards = stakerRewards[token].totalClaimedRewards.add(rewardToClaim);
        farmRewards.totalClaimedRewards = farmRewards.totalClaimedRewards.add(rewardToClaim);

        stakerRewards[token].claimableReward[msg.sender] = 0;
        farmRewards.claimableReward[address(token)] = farmRewards.claimableReward[address(token)].sub(rewardToClaim);

        rewardToken.safeTransfer(msg.sender, rewardToClaim);
        emit Claim(token, msg.sender, rewardToClaim);
    }

    /**
     * @dev View to estimate the claimable reward for an account that is staking token
     * @return claimable rewards for account
     */
    function claimable(IERC20 token, address account) external view returns (uint256) {
        if (stakes[token].staked[account] == 0) {
            return stakerRewards[token].claimableReward[account];
        }
        // estimate pending reward from distributor
        uint256 pending = _pendingDistribution(token);
        // calculate total rewards (including pending)
        uint256 newTotalRewards = pending.add(stakerRewards[token].totalClaimedRewards).mul(PRECISION);
        // calculate block reward
        uint256 totalBlockReward = newTotalRewards.sub(stakerRewards[token].totalRewards);
        // calculate next cumulative reward per token
        uint256 nextcumulativeRewardPerToken = stakerRewards[token].cumulativeRewardPerToken.add(
            totalBlockReward.div(stakes[token].totalStaked)
        );
        // return claimable reward for this account
        return
            stakerRewards[token].claimableReward[account].add(
                stakes[token].staked[account]
                    .mul(nextcumulativeRewardPerToken.sub(stakerRewards[token].previousCumulatedRewardPerToken[account]))
                    .div(PRECISION)
            );
    }

    function _pendingDistribution(IERC20 token) internal view returns (uint256) {
        // estimate pending reward from distributor
        uint256 pending = trueDistributor.farm() == address(this) ? trueDistributor.nextDistribution() : 0;

        // calculate new total rewards ever received by farm
        uint256 newTotalRewards = rewardToken.balanceOf(address(this)).add(pending).add(farmRewards.totalClaimedRewards).mul(
            PRECISION
        );
        // calculate new rewards that were received since previous distribution
        uint256 totalBlockReward = newTotalRewards.sub(farmRewards.totalRewards);

        uint256 cumulativeRewardPerShare = farmRewards.cumulativeRewardPerToken;
        if (shares.totalStaked > 0) {
            cumulativeRewardPerShare = cumulativeRewardPerShare.add(totalBlockReward.div(shares.totalStaked));
        }

        uint256 newReward = shares.staked[address(token)]
            .mul(cumulativeRewardPerShare.sub(farmRewards.previousCumulatedRewardPerToken[address(token)]))
            .div(PRECISION);

        return farmRewards.claimableReward[address(token)].add(newReward);
    }

    /**
     * @dev Distribute rewards from distributor and increase cumulativeRewardPerShare in Multifarm
     */
    function distribute() internal {
        // pull TRU from distributor
        // only pull if there is distribution and distributor farm is set to this farm
        if (trueDistributor.nextDistribution() > 0 && trueDistributor.farm() == address(this)) {
            trueDistributor.distribute();
        }
        _updateCumulativeRewardPerShare();
    }

    /**
     * @dev This function must be called before any change of token share in multifarm happens (e.g. before shares.totalStaked changes)
     * This will also update cumulativeRewardPerToken after distribution has happened
     * 1. Get total lifetime rewards as Balance of TRU plus total rewards that have already been claimed
     * 2. See how much reward we got since previous update (R)
     * 3. Increase cumulativeRewardPerToken by R/total shares
     */
    function _updateCumulativeRewardPerShare() internal {
        // calculate new total rewards ever received by farm
        uint256 newTotalRewards = rewardToken.balanceOf(address(this)).add(farmRewards.totalClaimedRewards).mul(PRECISION);
        // calculate new rewards that were received since previous distribution
        uint256 rewardSinceLastUpdate = newTotalRewards.sub(farmRewards.totalRewards);
        // update info about total farm rewards
        farmRewards.totalRewards = newTotalRewards;
        // if there are sub farms increase their value per share
        if (shares.totalStaked > 0) {
            farmRewards.cumulativeRewardPerToken = farmRewards.cumulativeRewardPerToken.add(
                rewardSinceLastUpdate.div(shares.totalStaked)
            );
        }
    }

    /**
     * @dev Update rewards for the farm on token and for the staker.
     * The function must be called before any modification of staker's stake and to update values when claiming rewards
     */
    function updateRewards(IERC20 token) internal {
        _updateTokenFarmRewards(token);
        _updateClaimableRewardsForStaker(token);
    }

    /**
     * @dev Update rewards data for the token farm - update all values associated with total available rewards for the farm inside multifarm
     */
    function _updateTokenFarmRewards(IERC20 token) internal {
        _updateClaimableRewardsForFarm(token);
        _updateTotalRewards(token);
    }

    /**
     * @dev Increase total claimable rewards for token farm in multifarm.
     * This function must be called before share of the token in multifarm is changed and to update total claimable rewards for the staker
     */
    function _updateClaimableRewardsForFarm(IERC20 token) internal {
        if (shares.staked[address(token)] == 0) {
            return;
        }
        // claimableReward += staked(token) * (cumulativeRewardPerShare - previousCumulatedRewardPerShare(token))
        uint256 newReward = shares.staked[address(token)]
            .mul(farmRewards.cumulativeRewardPerToken.sub(farmRewards.previousCumulatedRewardPerToken[address(token)]))
            .div(PRECISION);

        farmRewards.claimableReward[address(token)] = farmRewards.claimableReward[address(token)].add(newReward);
        farmRewards.previousCumulatedRewardPerToken[address(token)] = farmRewards.cumulativeRewardPerToken;
    }

    /**
     * @dev Update total reward for the farm
     * Get total farm reward as claimable rewards for the given farm plus total rewards claimed by stakers in the farm
     */
    function _updateTotalRewards(IERC20 token) internal {
        uint256 totalRewards = farmRewards.claimableReward[address(token)].add(stakerRewards[token].totalClaimedRewards).mul(
            PRECISION
        );
        // calculate received reward
        uint256 rewardReceivedSinceLastUpdate = totalRewards.sub(stakerRewards[token].totalRewards);

        // if there are stakers of the token, increase cumulativeRewardPerToken by newly received reward per total staked amount
        if (stakes[token].totalStaked > 0) {
            stakerRewards[token].cumulativeRewardPerToken = stakerRewards[token].cumulativeRewardPerToken.add(
                rewardReceivedSinceLastUpdate.div(stakes[token].totalStaked)
            );
        }

        // update farm rewards
        stakerRewards[token].totalRewards = totalRewards;
    }

    /**
     * @dev Update claimable rewards for the msg.sender who is staking this token
     * Increase claimable reward by the number that is
     * staker's stake times the change of cumulativeRewardPerToken for the given token since this function was previously called
     * This method must be called before any change of staker's stake
     */
    function _updateClaimableRewardsForStaker(IERC20 token) internal {
        // increase claimable reward for sender by amount staked by the staker times the growth of cumulativeRewardPerToken since last update
        stakerRewards[token].claimableReward[msg.sender] = stakerRewards[token].claimableReward[msg.sender].add(
            stakes[token].staked[msg.sender]
                .mul(
                stakerRewards[token].cumulativeRewardPerToken.sub(stakerRewards[token].previousCumulatedRewardPerToken[msg.sender])
            )
                .div(PRECISION)
        );

        // update previous cumulative for sender
        stakerRewards[token].previousCumulatedRewardPerToken[msg.sender] = stakerRewards[token].cumulativeRewardPerToken;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}