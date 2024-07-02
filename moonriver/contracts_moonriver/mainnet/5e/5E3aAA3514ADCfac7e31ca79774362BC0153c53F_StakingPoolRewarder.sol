/**
 *Submitted for verification at moonriver.moonscan.io on 2022-03-03
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/math/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/math/[email protected]



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
library SafeMathUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File contracts/interfaces/IStakingPoolRewarder.sol


pragma solidity ^0.6.12;

interface IStakingPoolRewarder {
    function onReward(
        uint256 poolId,
        address user,
        uint256 amount,
        uint32 entryTime
    ) external;

    function claimVestedReward(
        uint256 poolId,
        address user
    ) external returns (uint256);

}


// File contracts/libraries/TransferHelper.sol


pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/StakingPoolRewarder.sol


pragma solidity ^0.6.12;






/**
 * @title StakingPoolRewarder
 *
 * @dev An upgradeable rewarder contract for releasing Convergence tokens based on
 * schedule.
 */
contract StakingPoolRewarder is OwnableUpgradeable, IStakingPoolRewarder {
    using SafeMathUpgradeable for uint256;

    event VestingScheduleAdded(address indexed user, uint256 amount, uint256 startTime, uint256 endTime, uint256 step);
    event VestingSettingChanged(uint8 percentageToVestingSchedule, uint256 claimDuration, uint256 claimStep);
    event TokenVested(address indexed user, uint256 poolId, uint256 amount);
    event MoveVestingScheduleEarlier(uint256 poolId, address indexed user, uint32 startTime, uint32 endTime, uint256 duration);
    event VestingStartTimeUpdated(uint256 poolId, uint32 oldVestingStartTime, uint32 newVestingStartTime);

    /**
     * @param amount Total amount to be vested over the complete period
     * @param startTime Unix timestamp in seconds for the period start time
     * @param endTime Unix timestamp in seconds for the period end time
     * @param step Interval in seconds at which vestable amounts are accumulated
     * @param lastClaimTime Unix timestamp in seconds for the last claim time
     */
    struct VestingSchedule {
        uint128 amount;
        uint32 startTime;
        uint32 endTime;
        uint32 step;
        uint32 lastClaimTime;
    }

    mapping(address => mapping(uint256 => VestingSchedule)) public vestingSchedules;
    mapping(address => mapping(uint256 => uint256)) public claimableAmounts;
    address public stakingPools;
    address public rewardToken;
    address public rewardDispatcher;
    uint8 public percentageToVestingSchedule;
    uint256 public claimDuration;
    uint256 public claimStep;
    bool private locked;
    mapping(uint256 => uint32) public vestingStartTime;

    modifier blockReentrancy {
        require(!locked, "Reentrancy is blocked");
        locked = true;
        _;
        locked = false;
    }

    function __StakingPoolRewarder_init(
        address _stakingPools,
        address _rewardToken,
        address _rewardDispatcher,
        uint8 _percentageToVestingSchedule,
        uint256 _claimDuration,
        uint256 _claimStep
    ) public initializer {
        __Ownable_init();
        require(_stakingPools != address(0), "StakingPoolRewarder: stakingPools zero address");
        require(_rewardToken != address(0), "StakingPoolRewarder: rewardToken zero address");
        require(_rewardDispatcher != address(0), "StakingPoolRewarder: rewardDispatcher zero address");
        require(_claimDuration % _claimStep == 0, "StakingPoolRewarder: invalid step");
        require(_claimDuration >= _claimStep, "StakingPoolRewarder: invalid step");
        require(_percentageToVestingSchedule <= 100, 
            "StakingPoolRewarder: percentage to vesting schedule should be <= 100");
        require(_claimStep > 0, "StakingPoolRewarder: invalid step");

        stakingPools = _stakingPools;
        rewardToken = _rewardToken;
        rewardDispatcher = _rewardDispatcher;

        percentageToVestingSchedule = _percentageToVestingSchedule;
        claimDuration = _claimDuration;
        claimStep = _claimStep;
    }

    modifier onlyStakingPools() {
        require(stakingPools == msg.sender, "StakingPoolRewarder: only stakingPool can call");
        _;
    }

    function updateVestingSetting(
        uint8 _percentageToVestingSchedule,
        uint256 _claimDuration,
        uint256 _claimStep
    ) external onlyOwner {
        require(_claimDuration % _claimStep == 0, "StakingPoolRewarder: invalid step");
        require(_claimDuration >= _claimStep, "StakingPoolRewarder: invalid step");
        require(_percentageToVestingSchedule <= 100, 
            "StakingPoolRewarder: percentage to vesting schedule should be <= 100");
        require(_claimStep > 0, "StakingPoolRewarder: invalid step");

        percentageToVestingSchedule = _percentageToVestingSchedule;
        claimDuration = _claimDuration;
        claimStep = _claimStep;
        emit VestingSettingChanged(_percentageToVestingSchedule, _claimDuration, _claimStep);
    }

    function moveVestingScheduleEarlier(uint256 poolId, address user, uint256 duration) external onlyOwner {
        require(user != address(0), "StakingPoolRewarder: zero address");
        require(vestingSchedules[user][poolId].amount != 0, "StakingPoolRewarder: Vesting schedule not exist" );
        VestingSchedule memory vestingSchedule = vestingSchedules[user][poolId];
        vestingSchedules[user][poolId] = VestingSchedule({
            amount : vestingSchedule.amount,
            startTime : uint32(uint256(vestingSchedule.startTime).sub(duration)),
            endTime : uint32(uint256(vestingSchedule.endTime).sub(duration)),
            step : vestingSchedule.step,
            lastClaimTime : uint32(uint256(vestingSchedule.lastClaimTime).sub(duration))
        });
        emit MoveVestingScheduleEarlier(poolId, user, vestingSchedules[user][poolId].startTime, vestingSchedules[user][poolId].endTime, duration);
    }

    function setRewardDispatcher(address _rewardDispatcher) external onlyOwner {
        rewardDispatcher = _rewardDispatcher;
    }

    function setRewarderVestingStartTime(uint256 poolId, uint32 _vestingStartTime) external onlyOwner {
        require(_vestingStartTime > block.timestamp, 
            "StakingPoolRewarder: New pool vesting start time must be later than current time");
        uint32 oldPoolVestingStartTime = vestingStartTime[poolId];
        require(block.timestamp < oldPoolVestingStartTime || oldPoolVestingStartTime == 0,
            "StakingPoolRewarder: Pool vesting start time cannot be changed after it has started");
        vestingStartTime[poolId] = _vestingStartTime;
        emit VestingStartTimeUpdated(poolId, oldPoolVestingStartTime, _vestingStartTime);
    }

    function updateVestingSchedule(
        address user,
        uint256 poolId,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 step
    ) private {
        require(user != address(0), "StakingPoolRewarder: zero address");
        require(amount > 0, "StakingPoolRewarder: zero amount");
        require(startTime < endTime, "StakingPoolRewarder: invalid time range");
        require(step > 0 && endTime.sub(startTime) % step == 0, "StakingPoolRewarder: invalid step");

        // Overflow checks
        require(uint256(uint128(amount)) == amount, "StakingPoolRewarder: amount overflow");
        require(uint256(uint32(startTime)) == startTime, "StakingPoolRewarder: startTime overflow");
        require(uint256(uint32(endTime)) == endTime, "StakingPoolRewarder: endTime overflow");
        require(uint256(uint32(step)) == step, "StakingPoolRewarder: step overflow");

        vestingSchedules[user][poolId] = VestingSchedule({
            amount : uint128(amount),
            startTime : uint32(startTime),
            endTime : uint32(endTime),
            step : uint32(step),
            lastClaimTime: uint32(startTime)
        });

        emit VestingScheduleAdded(user, amount, startTime, endTime, step);
    }

    function calculateTotalReward(address user, uint256 poolId) external view returns (uint256) {
        (uint256 withdrawableFromVesting, ,) = _calculateWithdrawableFromVesting(user, poolId, block.timestamp);
        uint256 claimableAmount = claimableAmounts[user][poolId];
        uint256 unvestedAmount = _calculateUnvestedAmountAtCurrentStep(user, poolId, block.timestamp);
        return withdrawableFromVesting.add(unvestedAmount).add(claimableAmount);
    }

    function calculateWithdrawableReward(address user, uint256 poolId) external view returns (uint256) {
        (uint256 withdrawableFromVesting, ,) = _calculateWithdrawableFromVesting(user, poolId, block.timestamp);
        uint256 claimableAmount = claimableAmounts[user][poolId];
        return withdrawableFromVesting.add(claimableAmount);
    }

    function _calculateWithdrawableFromVesting(address user, uint256 poolId, uint256 timestamp) private view returns (
        uint256 amount,
        uint256 newClaimTime,
        bool allVested
    ){

        VestingSchedule memory vestingSchedule = vestingSchedules[user][poolId];
        if (vestingSchedule.amount == 0) return (0, 0, false);
        if (timestamp <= uint256(vestingSchedule.startTime)) return (0, 0, false);

        uint256 currentStepTime =
        MathUpgradeable.min(
            timestamp
            .sub(uint256(vestingSchedule.startTime))
            .div(uint256(vestingSchedule.step))
            .mul(uint256(vestingSchedule.step))
            .add(uint256(vestingSchedule.startTime)),
            uint256(vestingSchedule.endTime)
        );

        if (currentStepTime <= uint256(vestingSchedule.lastClaimTime)) return (0, 0, false);

        uint256 totalSteps =
        uint256(vestingSchedule.endTime).sub(uint256(vestingSchedule.startTime)).div(vestingSchedule.step);

        if (currentStepTime == uint256(vestingSchedule.endTime)) {
            // All vested

            uint256 stepsVested =
             uint256(vestingSchedule.lastClaimTime).sub(uint256(vestingSchedule.startTime)).div(vestingSchedule.step);
            uint256 amountToVest =
             uint256(vestingSchedule.amount).sub(uint256(vestingSchedule.amount).div(totalSteps).mul(stepsVested));
            return (amountToVest, currentStepTime, true);
        } else {
            // Partially vested
            uint256 stepsToVest = currentStepTime.sub(uint256(vestingSchedule.lastClaimTime)).div(vestingSchedule.step);
            uint256 amountToVest = uint256(vestingSchedule.amount).div(totalSteps).mul(stepsToVest);
            return (amountToVest, currentStepTime, false);
        }
    }

    function _calculateUnvestedAmountAtCurrentStep(address user, uint256 poolId, uint256 timestamp) private view returns (uint256) {
        if (timestamp < uint256(vestingSchedules[user][poolId].startTime)
            || vestingSchedules[user][poolId].amount == 0) return 0;
        uint256 currentStepTime =
        MathUpgradeable.min(
            timestamp
            .sub(uint256(vestingSchedules[user][poolId].startTime))
            .div(uint256(vestingSchedules[user][poolId].step))
            .mul(uint256(vestingSchedules[user][poolId].step))
            .add(uint256(vestingSchedules[user][poolId].startTime)),
            uint256(vestingSchedules[user][poolId].endTime)
        );
        if (currentStepTime == uint256(vestingSchedules[user][poolId].endTime)){
            return 0;
        } else {
            return _calculateUnvestedAmount(user, poolId, currentStepTime);
        }
    }

    function _calculateUnvestedAmount(address user, uint256 poolId, uint256 stepTime) private view returns (uint256) {
        if (vestingSchedules[user][poolId].amount == 0) return 0;
        
        uint256 totalSteps =
            uint256(vestingSchedules[user][poolId].endTime)
            .sub(uint256(vestingSchedules[user][poolId].startTime))
            .div(vestingSchedules[user][poolId].step);
        uint256 stepsVested =
            stepTime
            .sub(uint256(vestingSchedules[user][poolId].startTime))
            .div(vestingSchedules[user][poolId].step);
        return uint256(vestingSchedules[user][poolId].amount)
            .sub(uint256(vestingSchedules[user][poolId].amount)
            .div(totalSteps)
            .mul(stepsVested));

    }

    function _withdrawFromVesting(address user, uint256 poolId, uint256 timestamp) private returns (uint256) {
        (uint256 lastVestedAmount,uint256 newClaimTime, bool allVested) = _calculateWithdrawableFromVesting(user, poolId, timestamp);
        if (lastVestedAmount > 0) {
            if (allVested) {
                // Remove storage slot to save gas
                delete vestingSchedules[user][poolId];
            } else {
                vestingSchedules[user][poolId].lastClaimTime = uint32(newClaimTime);
            }
        }
        return lastVestedAmount;
    }

    function onReward(
        uint256 poolId,
        address user,
        uint256 amount,
        uint32 entryTime
    ) onlyStakingPools external override {
        _onReward(poolId, user, amount, entryTime);
    }

    function _onReward(uint256 poolId, address user, uint256 amount, uint32 entryTime) private blockReentrancy {
        require(user != address(0), "StakingPoolRewarder: zero address");

        uint32 poolVestingStartTime = vestingStartTime[poolId];
        uint256 vestingScheduleStartTime = 
            MathUpgradeable.max(uint32(entryTime), poolVestingStartTime);

        uint256 lastVestedAmount = _withdrawFromVesting(user, poolId, block.timestamp);

        uint256 newUnvestedAmount = 0;
        uint256 newVestedAmount = 0;
        if (amount > 0) {
            newUnvestedAmount = amount.div(100).mul(uint256(percentageToVestingSchedule));
            newVestedAmount = amount.sub(newUnvestedAmount);
        }
        uint newEntryVestedAmount = 0;

        if (newUnvestedAmount > 0) {
            uint256 lastUnvestedAmount = _calculateUnvestedAmountAtCurrentStep(user, poolId, block.timestamp);
            updateVestingSchedule(user, poolId, newUnvestedAmount.add(lastUnvestedAmount),
                vestingScheduleStartTime,
                vestingScheduleStartTime.add(claimDuration),
                claimStep);
            newEntryVestedAmount = _withdrawFromVesting(user, poolId, block.timestamp);
        }

        uint256 totalVested = lastVestedAmount.add(newVestedAmount).add(newEntryVestedAmount);
        claimableAmounts[user][poolId] = claimableAmounts[user][poolId].add(totalVested);
        emit TokenVested(user, poolId, totalVested);
    }
    
    function claimVestedReward(
        uint256 poolId, 
        address user
    ) override onlyStakingPools blockReentrancy external returns (uint256) {
        require(poolId > 0, "StakingPoolRewarder: poolId is 0");
        require(block.timestamp >= vestingStartTime[poolId], 
            "StakingPoolRewarder: cannot claim reward before pool vesting start time");
        uint256 claimableAmount = claimableAmounts[user][poolId];

        if (claimableAmount > 0) {
            claimableAmounts[user][poolId] = 0;
            TransferHelper.safeTransferFrom(
                rewardToken,
                rewardDispatcher,
                user,
                claimableAmount
            );
        }

        return claimableAmount;
    }

}