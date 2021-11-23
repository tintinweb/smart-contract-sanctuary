/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol

// SPDX-License-Identifier: AGPL-3.0

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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// MIT

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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol

// MIT

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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol

// MIT

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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol

// MIT

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

// File: @openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol

// MIT

pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// MIT

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

// File: contracts/interfaces/IRewardChest.sol

// AGPL-3.0
pragma solidity 0.7.6;

interface IRewardChest {
    function addToBalance(address _user, uint256 _amount)
        external
        returns (bool);

    function sendInstantClaim(address _user, uint256 _amount)
        external
        returns (bool);

    function owner() external view returns (address);
}

// File: contracts/interfaces/IXGTFreezer.sol

// AGPL-3.0
pragma solidity 0.7.6;

interface IXGTFreezer {
    function freeze(uint256 _amount) external;

    function freezeFor(address _recipient, uint256 _amount) external;

    function thaw() external;
}

// File: contracts/rewards/StakingModule_v2.sol

// AGPL-3.0
pragma solidity 0.7.6;
contract StakingModule_v2 is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    struct UserInfo {
        uint256 stake;
        uint256 lastDepositedTime;
        uint256 lastUserActionTime;
        uint256 debt;
        uint256[] referralIDs;
    }

    struct Referral {
        address referring;
        address referral;
        uint256 date;
        bool counted;
        bool rewarded;
    }

    // Tokens & Contracts
    IERC20 public xgt;
    IERC20[] public rewardTokens;
    IERC20 public stakeToken;
    IXGTFreezer public freezer;
    IRewardChest public rewardChest;

    // Addresses
    address public feeWallet;

    // Authorization & Access
    mapping(address => bool) public authorized;

    // Reward balances
    mapping(address => uint256) public rewardedTokenBalances;
    uint256 public rewardPerStakedToken;
    bool public withdrawRewardsOnHarvest;

    // User Specific Info
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(address => uint256)) public userRewards;

    // Tracking Variables
    uint256 public totalStaked;
    uint256 public lastHarvestedTime;

    // Constants
    uint256 public constant YEAR_IN_SECONDS = 31536000;
    uint256 public constant BP_DECIMALS = 10000;

    // Fees and Percentage Values
    uint256 public performanceFee;
    uint256 public harvestReward;
    uint256 public withdrawFee;
    uint256 public withdrawFeePeriod;

    // APY related Variables
    bool public fixedAPYPool;
    APYDetail[] public apyDetails;

    struct APYDetail {
        uint256 apy;
        uint256 priceModifier;
        uint256 calcApy;
    }

    // Time Variables
    uint256 public start;
    uint256 public end;

    // Referral System
    Referral[] public referrals;
    uint256 public referralMinTime;
    uint256 public referralMinAmount;
    mapping(address => uint256) public referralMinAmountSince;

    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 lastDepositedTime
    );
    event Withdraw(address indexed sender, uint256 amount);
    event Harvest(address indexed sender, uint256 performanceFee);

    function initialize(
        address[] calldata _rewardTokens,
        address _stakeToken,
        address _freezer,
        address _rewardChest,
        bool _fixedAPYPool,
        uint256[] calldata _stakingAPYs,
        uint256 _poolStart,
        uint256 _poolEnd
    ) public initializer {
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            rewardTokens.push(IERC20(_rewardTokens[i]));
        }
        stakeToken = IERC20(_stakeToken);

        xgt = IERC20(0xC25AF3123d2420054c8fcd144c21113aa2853F39);
        if (_freezer != address(0)) {
            freezer = IXGTFreezer(_freezer);
            xgt.approve(_freezer, 2**256 - 1);
        }

        rewardChest = IRewardChest(_rewardChest);

        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        if (_rewardChest != address(0)) {
            transferOwnership(rewardChest.owner());
        }

        fixedAPYPool = _fixedAPYPool;
        for (uint256 j = 0; j < _stakingAPYs.length; j++) {
            apyDetails.push(
                APYDetail(_stakingAPYs[j], 10**18, _stakingAPYs[j].div(10**2))
            );
        }

        if (_poolStart > 0 && _poolEnd > 0) {
            require(
                _poolStart < _poolEnd && _poolEnd > block.timestamp,
                "XGT-REWARD-MODULE-WRONG-DATES"
            );
            start = _poolStart;
            end = _poolEnd;
            lastHarvestedTime = start;
        } else {
            lastHarvestedTime = block.timestamp;
        }

        performanceFee = 200; // 2%
        harvestReward = 25; // 0.25%
        withdrawFee = 10; // 0.1%
        withdrawFeePeriod = 72 hours;
        withdrawRewardsOnHarvest = true;

        referralMinTime = 604800; // 1 week
        referralMinAmount = 100; // 100 stake tokens
    }

    function setAuthorized(address _addr, bool _authorized) external onlyOwner {
        authorized[_addr] = _authorized;
    }

    function setWithdrawRewardsOnHarvest(bool _withdrawRewardsOnHarvest)
        external
        onlyOwner
    {
        withdrawRewardsOnHarvest = _withdrawRewardsOnHarvest;
    }

    function setReferralVariables(uint256 _minTime, uint256 _minAmount)
        external
        onlyOwner
    {
        referralMinTime = _minTime;
        referralMinAmount = _minAmount;
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        performanceFee = _performanceFee;
    }

    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        withdrawFee = _withdrawFee;
    }

    function setWithdrawFeePeriod(uint256 _withdrawFeePeriod)
        external
        onlyOwner
    {
        withdrawFeePeriod = _withdrawFeePeriod;
    }

    function setStakingAPYs(bool _fixedAPYPool, uint256[] calldata _stakingAPYs)
        external
        onlyOwner
    {
        require(
            apyDetails.length == _stakingAPYs.length,
            "XGT-REWARD-MODULE-ARRAY-MISMATCH"
        );
        fixedAPYPool = _fixedAPYPool;
        for (uint256 j = 0; j < apyDetails.length; j++) {
            apyDetails[j].apy = _stakingAPYs[j];
            apyDetails[j].calcApy = apyDetails[j]
                .apy
                .mul(apyDetails[j].priceModifier)
                .div(10**20); // 10^18 * 100 because of the percent value
        }
    }

    function setPriceModifiers(uint256[] calldata _priceModifiers)
        external
        onlyAuthorized
    {
        for (uint256 j = 0; j < apyDetails.length; j++) {
            apyDetails[j].priceModifier = _priceModifiers[j];
            apyDetails[j].calcApy = apyDetails[j]
                .apy
                .mul(apyDetails[j].priceModifier)
                .div(10**20); // 10^18 * 100 because of the percent value
        }
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            require(
                _token != address(rewardTokens[i]),
                "XGT-REWARD-MODULE-TOKEN-CANT-BE-REWARD-TOKEN"
            );
        }

        require(
            _token != address(stakeToken),
            "XGT-REWARD-MODULE-TOKEN-CANT-BE-REWARD-TOKEN"
        );

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function cleanUp() external onlyOwner {
        if (block.timestamp > end) {
            // this will withdraw any reward tokens that have not been
            // allocated for rewards
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                uint256 rewardRemainder = balanceOfRewardToken(
                    address(rewardTokens[i])
                ).sub(rewardedTokenBalances[address(rewardTokens[i])]);
                if (rewardRemainder > 0) {
                    rewardTokens[i].transfer(msg.sender, rewardRemainder);
                }
            }
        }
        // This will only withdraw any exess staked tokens (accidental sends etc.)
        uint256 stakeRemainder = balanceOf().sub(totalStaked);
        if (stakeRemainder > 0) {
            stakeToken.transfer(msg.sender, stakeRemainder);
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function deposit(uint256 _amount, address _referrer)
        external
        whenNotPaused
        notContract
    {
        _deposit(msg.sender, _referrer, _amount, false);
    }

    function depositForUser(
        address _user,
        uint256 _amount,
        bool _skipLastDepositUpdate
    ) external whenNotPaused onlyAuthorized {
        _deposit(_user, address(0), _amount, _skipLastDepositUpdate);
    }

    function _deposit(
        address _user,
        address _referrer,
        uint256 _amount,
        bool _skipLastDepositUpdate
    ) internal {
        _harvest(true);
        require(
            block.timestamp >= start && block.timestamp < end,
            "XGT-REWARD-MODULE-POOL-NOT-OPEN"
        );
        require(_amount > 0, "XGT-REWARD-MODULE-CANT-DEPOSIT-ZERO");

        stakeToken.transferFrom(_user, address(this), _amount);

        UserInfo storage user = userInfo[_user];

        if (
            _referrer != address(0) &&
            user.lastUserActionTime == 0 &&
            userInfo[_referrer].stake > referralMinAmount
        ) {
            Referral memory newRef = Referral(
                _referrer,
                _user,
                block.timestamp,
                false,
                false
            );
            referrals.push(newRef);
            // add the index/id of the referral to both of the users referral id array
            user.referralIDs.push(referrals.length - 1);
            userInfo[_referrer].referralIDs.push(referrals.length - 1);
        }

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 rewardTilNow = _getUserReward(_user, i);

            userRewards[_user][address(rewardTokens[i])] = userRewards[_user][
                address(rewardTokens[i])
            ].add(rewardTilNow);
        }

        user.stake = user.stake.add(_amount);
        if (
            user.stake >= referralMinAmount &&
            referralMinAmountSince[_user] == 0
        ) {
            referralMinAmountSince[_user] = block.timestamp;
        }
        if (totalStaked == 0) {
            lastHarvestedTime = block.timestamp;
        }
        totalStaked = totalStaked.add(_amount);
        user.debt = user.stake.mul(rewardPerStakedToken).div(10**18);
        user.lastUserActionTime = block.timestamp;
        if (!_skipLastDepositUpdate) {
            user.lastDepositedTime = block.timestamp;
        }

        emit Deposit(_user, _amount, block.timestamp);
    }

    function withdraw(uint256 _shares) external notContract {
        _withdraw(msg.sender, _shares);
    }

    function withdrawForUser(address _user, uint256 _shares)
        external
        onlyAuthorized
    {
        _withdraw(_user, _shares);
    }

    function withdrawAll() external notContract {
        _withdraw(msg.sender, userInfo[msg.sender].stake);
    }

    function withdrawAllForUser(address _user) external onlyAuthorized {
        _withdraw(_user, userInfo[_user].stake);
    }

    function _withdraw(address _user, uint256 _withdrawAmount) internal {
        // harvest so the rewards are up to date for the withdraw
        _harvest(true);

        // check all referrals of the user on whether they are due/matured
        _countDueReferrals(_user);

        UserInfo storage user = userInfo[_user];
        require(
            _withdrawAmount <= user.stake,
            "XGT-REWARD-MODULE-CANT-WITHDRAW-MORE-THAN-MAXIMUM"
        );

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 amount = _getUserReward(_user, i);
            if (userRewards[_user][address(rewardTokens[i])] > 0) {
                amount = amount.add(
                    userRewards[_user][address(rewardTokens[i])]
                );
                userRewards[_user][address(rewardTokens[i])] = 0;
            }
            rewardedTokenBalances[
                address(rewardTokens[i])
            ] = rewardedTokenBalances[address(rewardTokens[i])].sub(amount);

            rewardTokens[i].transfer(_user, amount);
        }

        uint256 withdrawAmount = _withdrawAmount;
        user.stake = user.stake.sub(withdrawAmount);
        totalStaked = totalStaked.sub(withdrawAmount);
        user.debt = user.stake.mul(rewardPerStakedToken).div(10**18);

        if (
            user.stake < referralMinAmount && referralMinAmountSince[_user] != 0
        ) {
            referralMinAmountSince[_user] = 0;
        }

        user.lastUserActionTime = block.timestamp;

        if (withdrawAmount > 0) {
            if (
                block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)
            ) {
                uint256 currentWithdrawFee = withdrawAmount
                    .mul(withdrawFee)
                    .div(BP_DECIMALS);
                if (stakeToken == xgt) {
                    freezer.freeze(currentWithdrawFee);
                } else if (feeWallet != address(0)) {
                    stakeToken.transfer(feeWallet, currentWithdrawFee);
                }
                withdrawAmount = withdrawAmount.sub(currentWithdrawFee);
            }

            stakeToken.transfer(_user, withdrawAmount);

            emit Withdraw(_user, withdrawAmount);
        }
    }

    function harvest() public whenNotPaused {
        if (userInfo[msg.sender].stake > 0) {
            _harvest(true);
            if (withdrawRewardsOnHarvest) {
                _withdraw(msg.sender, 0); // withdrawing 0 is equal to withdrawing just the rewards
            }
        } else {
            _harvest(false);
        }
    }

    function _harvest(bool _storeHarvestReward) internal {
        if (lastHarvestedTime < block.timestamp) {
            (uint256 diff, uint256 harvestTime) = _getHarvestDiffAndTime();
            uint256 baseHarvestAmount = _getHarvestAmount(diff);
            if (baseHarvestAmount == 0) return;
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                uint256 harvestAmount = baseHarvestAmount
                    .mul(apyDetails[i].calcApy)
                    .div(apyDetails[0].calcApy);

                if (rewardTokens[i] == xgt) {
                    require(
                        rewardChest.sendInstantClaim(
                            address(this),
                            harvestAmount
                        ),
                        "XGT-REWARD-MODULE-INSTANT-CLAIM-FROM-CHEST-FAILED"
                    );
                }

                uint256 currentPerformanceFee = harvestAmount
                    .mul(performanceFee)
                    .div(BP_DECIMALS);
                if (rewardTokens[i] == xgt) {
                    freezer.freeze(currentPerformanceFee);
                } else if (feeWallet != address(0)) {
                    IERC20(address(rewardTokens[i])).transfer(
                        feeWallet,
                        currentPerformanceFee
                    );
                }

                uint256 currentHarvestReward = harvestAmount
                    .mul(harvestReward)
                    .div(BP_DECIMALS);
                if (_storeHarvestReward) {
                    userRewards[msg.sender][
                        address(rewardTokens[i])
                    ] = userRewards[msg.sender][address(rewardTokens[i])].add(
                        currentHarvestReward
                    );

                    rewardedTokenBalances[
                        address(rewardTokens[i])
                    ] = rewardedTokenBalances[address(rewardTokens[i])].add(
                        (currentHarvestReward)
                    );
                } else {
                    IERC20(address(rewardTokens[i])).transfer(
                        msg.sender,
                        currentHarvestReward
                    );
                }

                uint256 netHarvest = harvestAmount
                    .sub(currentPerformanceFee)
                    .sub(currentHarvestReward);

                rewardedTokenBalances[
                    address(rewardTokens[i])
                ] = rewardedTokenBalances[address(rewardTokens[i])].add(
                    (netHarvest)
                );

                if (i == 0) {
                    if (totalStaked > 0) {
                        rewardPerStakedToken = rewardPerStakedToken.add(
                            netHarvest.mul(10**18).div(totalStaked)
                        );
                    } else {
                        rewardPerStakedToken = 0;
                    }
                }

                require(
                    balanceOfRewardToken(address(rewardTokens[i])) >=
                        rewardedTokenBalances[address(rewardTokens[i])],
                    "XGT-REWARD-MODULE-NOT-ENOUGH-REWARDS"
                );

                emit Harvest(msg.sender, currentPerformanceFee);
            }
            lastHarvestedTime = harvestTime;
        }
    }

    function currentHarvestAmount(uint256 _rewardTokenIndex)
        public
        view
        returns (uint256)
    {
        (uint256 diff, ) = _getHarvestDiffAndTime();
        uint256 harvestAmount = _getHarvestAmount(diff);
        harvestAmount = harvestAmount
            .mul(apyDetails[_rewardTokenIndex].calcApy)
            .div(apyDetails[0].calcApy);
        return harvestAmount;
    }

    function _getHarvestAmount(uint256 _diff) internal view returns (uint256) {
        uint256 harvestAmount = 0;
        if (fixedAPYPool) {
            // for fixed pools the calcApy variable
            // contains a percentage-like value
            // to ensure a fixed amount of rewards
            harvestAmount = totalStaked
                .mul(apyDetails[0].calcApy)
                .mul(_diff)
                .div(YEAR_IN_SECONDS)
                .div(10**18);
        } else {
            // for dynamic pools, the calcApy variable
            // contains the token amount rewarded to the
            // pool for each second
            // so it is high for low participation
            // and low for high participation
            harvestAmount = apyDetails[0].calcApy.mul(_diff);
        }
        return harvestAmount;
    }

    function _getHarvestDiffAndTime() internal view returns (uint256, uint256) {
        uint256 until = block.timestamp;
        if (until > end) {
            until = end;
        }
        return (until.sub(lastHarvestedTime), until);
    }

    function getCurrentUserReward(address _user, uint256 _rewardTokenIndex)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 newHarvestAmount = currentHarvestAmount(_rewardTokenIndex);
        newHarvestAmount = newHarvestAmount.sub(
            newHarvestAmount.mul(
                (performanceFee.add(harvestReward)).div(BP_DECIMALS)
            )
        );

        uint256 newRewardPerStakedToken = rewardPerStakedToken.add(
            newHarvestAmount.mul(10**18).div(totalStaked)
        );

        uint256 reward = (
            (user.stake.mul(newRewardPerStakedToken).div(10**18)).sub(user.debt)
        ).mul(apyDetails[_rewardTokenIndex].calcApy).div(apyDetails[0].calcApy);

        reward = reward.add(
            userRewards[_user][address(rewardTokens[_rewardTokenIndex])]
        );

        return reward;
    }

    function _getUserReward(address _user, uint256 _rewardTokenIndex)
        internal
        view
        returns (uint256)
    {
        return
            (
                (userInfo[_user].stake.mul(rewardPerStakedToken).div(10**18))
                    .sub(userInfo[_user].debt)
            ).mul(apyDetails[_rewardTokenIndex].calcApy).div(
                    apyDetails[0].calcApy
                );
    }

    function balanceOf() public view returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    function balanceOfRewardToken(address _rewardToken)
        public
        view
        returns (uint256)
    {
        return IERC20(_rewardToken).balanceOf(address(this));
    }

    function redeemReferrals(address _user)
        external
        onlyRewardChest
        returns (uint256 redeemedOfReferrals)
    {
        for (uint256 i = 0; i < userInfo[_user].referralIDs.length; i++) {
            (bool foundDue, ) = _checkReferral(
                referrals[userInfo[_user].referralIDs[i]],
                _user
            );
            if (foundDue) {
                referrals[userInfo[_user].referralIDs[i]].rewarded = true;
                redeemedOfReferrals++;
            }
        }
    }

    function userHasDueReferral(address _user) external view returns (bool) {
        for (uint256 i = 0; i < userInfo[_user].referralIDs.length; i++) {
            (bool foundDue, ) = _checkReferral(
                referrals[userInfo[_user].referralIDs[i]],
                _user
            );
            if (foundDue) {
                return true;
            }
        }
        return false;
    }

    function _countDueReferrals(address _user) internal {
        for (uint256 i = 0; i < userInfo[_user].referralIDs.length; i++) {
            (bool foundDue, bool counted) = _checkReferral(
                referrals[userInfo[_user].referralIDs[i]],
                _user
            );
            if (foundDue && !counted) {
                referrals[userInfo[_user].referralIDs[i]].counted = true;
            }
        }
    }

    function _checkReferral(Referral storage referral, address _user)
        internal
        view
        returns (bool, bool)
    {
        if (
            (referral.referring == _user && // referring user was/is the user
                !referral.rewarded && // the referral has not been rewarded yet
                referral.counted) || // the referral has either been counted already
            (referralMinAmountSince[_user] >= referralMinTime && // or: the referring user did the min time &
                referralMinAmountSince[referral.referral] >= // the referred user did the min time
                referralMinTime)
        ) {
            return (true, referral.counted);
        }
        return (false, false);
    }

    // Only for compatibility with reward chest
    function claimModule(address _user) external pure {
        return;
    }

    // Only for compatibility with reward chest
    function getClaimable(address _user) external pure returns (uint256) {
        return 0;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(
            !_isContract(msg.sender),
            "XGT-REWARD-MODULE-NO-CONTRACTS-ALLOWED"
        );
        require(
            msg.sender == tx.origin,
            "XGT-REWARD-MODULE-PROXY-CONTRACT-NOT-ALLOWED"
        );
        _;
    }

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender],
            "XGT-REWARD-MODULE-CALLER-NOT-AUTHORIZED"
        );
        _;
    }

    modifier onlyRewardChest() {
        require(
            msg.sender == address(rewardChest),
            "XGT-REWARD-CHEST-NOT-AUTHORIZED"
        );
        _;
    }
}