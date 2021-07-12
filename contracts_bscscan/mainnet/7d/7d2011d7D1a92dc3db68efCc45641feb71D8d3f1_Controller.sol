// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./interfaces/IBundleFactory.sol";
import "./interfaces/IBundle.sol";
import "./interfaces/IUnbinder.sol";
import "./interfaces/IRebalancer.sol";

contract Controller is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event LogDefaultWhitelist(
        address indexed caller,
        address[]       swapWhitelist
    );

    /* ========== Constants ========== */

    uint256 internal constant MAX_DELAY = 14 days;
    uint256 internal constant INIT_DELAY = 7 days;
    uint256 internal constant MIN_DELAY = 1 days;

    /* ========== Storage ========== */

    struct BundleMetadata {
        address unbinder;
        bool    isInitialized;
        bool    isSetup;
        uint256 lastUpdateTime;
    }

    IBundleFactory private _factory;
    IRebalancer private _rebalancer;

    address private _router;
    uint256 private _delay;

    mapping(address => BundleMetadata) private _bundles;
    address[] private _swapWhitelist;

    /* ========== Initialization ========== */

    function initialize(address factory, address router)
        public
        initializer
    {
        __Ownable_init();
        _factory = IBundleFactory(factory);
        _router = router;
        _delay = INIT_DELAY;
    }

    function setRebalancer(address rebalancer)
        external
        onlyOwner
    {
        require(address(_rebalancer) == address(0), "ERR_REBALANCER_SET");
        _rebalancer = IRebalancer(rebalancer);
    }

    function setDefaultWhitelist(address[] calldata whitelist)
        external
        onlyOwner
    {
        _swapWhitelist = whitelist;
        emit LogDefaultWhitelist(msg.sender, _swapWhitelist);
    }

    function setDelay(uint256 delay)
        external
        onlyOwner
    {
        require(delay >= MIN_DELAY && delay <= MAX_DELAY, "ERR_BAD_DELAY");
        _delay = delay;
    }

    /* ========== Bundle Deployment ========== */

    function deploy(
        string calldata name,
        string calldata symbol
    ) 
        external
        onlyOwner
    {
        require(address(_rebalancer) != address(0), "ERR_REBALANCER_NOT_SET");

        // Deploy new proxies via factory
        (address bundle, address unbinder) = _factory.deploy(name, symbol);

        // Initialize contracts
        IBundle(bundle).initialize(address(this), address(_rebalancer), unbinder, name, symbol);
        IUnbinder(unbinder).initialize(bundle, _router, address(this), _swapWhitelist);

        _bundles[bundle] = BundleMetadata({
            unbinder: unbinder,
            isInitialized: true,
            isSetup: false,
            lastUpdateTime: 0
        });
    }

    function setup(
        address bundle,
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata denorms,
        address tokenProvider
    )
        external
        onlyOwner
    {
        require(_bundles[bundle].isInitialized && !_bundles[bundle].isSetup, "ERR_SETUP");
        IBundle(bundle).setup(tokens, balances, denorms, tokenProvider);
        _bundles[bundle].isSetup = true;
        _bundles[bundle].lastUpdateTime = block.timestamp;
        _rebalancer.setWhitelist(bundle, true);
    }

    /* ========== Rebalancer ========== */

    function setPremium(uint256 premium) external onlyOwner {
        _rebalancer.setPremium(premium);
    }

    function setWhitelist(address bundle, bool flag) external onlyOwner {
        _rebalancer.setWhitelist(bundle, flag);
    }

    function setRebalancerSwapWhitelist(address token, bool flag) external onlyOwner {
        _rebalancer.setSwapWhitelist(token, flag);
    }

    function setOracle(address oracle) external onlyOwner {
        _rebalancer.setOracle(oracle);
    }

    function setGap(uint256 gap) external onlyOwner {
        _rebalancer.setGap(gap);
    }

    /* ========== Unbinder ========== */

    function setUnbinderPremium(
        address[] calldata unbinders,
        uint256 premium
    ) 
        external 
        onlyOwner 
    {
        for (uint256 i = 0; i < unbinders.length; i++) {
            IUnbinder(unbinders[i]).setPremium(premium);
        }
    }

    function setUnbinderSwapWhitelist(
        address[] calldata unbinders,
        address token,
        bool flag
    ) 
        external
        onlyOwner
    {
        for (uint256 i = 0; i < unbinders.length; i++) {
            IUnbinder(unbinders[i]).setSwapWhitelist(token, flag);
        }
    }

    /* ========== Bundle ========== */

    function setSwapFee(address bundle, uint256 swapFee) external onlyOwner {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        IBundle(bundle).setSwapFee(swapFee);
    }

    function setRebalancable(address bundle, bool flag) external onlyOwner {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        IBundle(bundle).setRebalancable(flag);
    }

    function setMinBalance(
        address bundle, 
        address token,
        uint256 minBalance
    ) 
        external 
        onlyOwner 
    {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        IBundle(bundle).setMinBalance(token, minBalance);
    }

    function setStreamingFee(address bundle, uint256 streamingFee) external onlyOwner {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        IBundle(bundle).setStreamingFee(streamingFee);
    }

    function setExitFee(address bundle, uint256 exitFee) external onlyOwner {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        IBundle(bundle).setExitFee(exitFee);
    }

    function setTargetDelta(address bundle, uint256 targetDelta) external onlyOwner {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        IBundle(bundle).setTargetDelta(targetDelta);
    }

    function collectStreamingFee(address bundle) external onlyOwner {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        IBundle(bundle).collectStreamingFee();
    }

    /* ========== Bundle Asset Controls ========== */

    function reweighTokens(
        address bundle,
        address[] calldata tokens,
        uint256[] calldata targetDenorms
    )
        external
        onlyOwner
    {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        require(block.timestamp >= _bundles[bundle].lastUpdateTime.add(_delay), "ERR_DELAY");
        IBundle(bundle).reweighTokens(tokens, targetDenorms);
        _bundles[bundle].lastUpdateTime = block.timestamp;
    }

    function reindexTokens(
        address bundle,
        address[] calldata tokens,
        uint256[] calldata targetDenorms,
        uint256[] calldata minBalances
    )
        external
        onlyOwner
    {
        require(_bundles[bundle].isSetup, "ERR_BUNDLE_NOT_SETUP");
        require(block.timestamp >= _bundles[bundle].lastUpdateTime.add(_delay), "ERR_DELAY");
        IBundle(bundle).reindexTokens(tokens, targetDenorms, minBalances);
        _bundles[bundle].lastUpdateTime = block.timestamp;
    }

    /* ========== Getters ========== */

    function getBundleMetadata(
        address bundle
    ) 
        external view 
        returns (
            address unbinder, 
            bool isInitialized, 
            bool isSetup, 
            uint256 lastUpdateTime
        )
    {
        return (
            _bundles[bundle].unbinder,
            _bundles[bundle].isInitialized,
            _bundles[bundle].isSetup,
            _bundles[bundle].lastUpdateTime
        );
    }

    function getDelay() external view returns (uint256) {
        return _delay;
    }

    function getRebalancer() external view returns (address) {
        return address(_rebalancer);
    }

    function getDefaultWhitelist() external view returns (address[] memory) {
        return _swapWhitelist;
    }

    /* ========== Misc ========== */

    function collectTokens(
        address[] calldata tokens,
        uint256[] calldata balances,
        address to
    ) 
        external 
        onlyOwner 
    {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20Upgradeable(tokens[i]).safeTransfer(to, balances[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBundleFactory {
    function setController(address controller) external;

    function getController() external view returns (address);

    function deploy(
        string calldata name,
        string calldata symbol
    ) external returns (address bundle, address unbinder);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IUnbinder.sol";

interface IBundle {
    struct Record {
        bool bound;               // is token bound to pool
        bool ready;               // is token ready for swaps
        uint256 denorm;           // denormalized weight
        uint256 targetDenorm;     // target denormalized weight
        uint256 targetTime;      // target block to update by
        uint256 lastUpdateTime;  // last update block
        uint8 index;              // token index
        uint256 balance;          // token balance
    }

    /* ========== Events ========== */

    event LogSwap(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut
    );

    event LogJoin(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    event LogExit(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    event LogSwapFeeUpdated(
        address indexed caller,
        uint256         swapFee
    );

    event LogTokenReady(
        address indexed token
    );

    event LogPublicSwapEnabled();

    event LogRebalancable(
        address indexed caller,
        bool            rebalancable
    );

    event LogCollectFee(
        address indexed caller
    );

    event LogStreamingFee(
        address indexed caller,
        uint256         fee
    );

    event LogTokenBound(
        address indexed token
    );

    event LogTokenUnbound(
        address indexed token
    );

    event LogMinBalance(
        address indexed caller,
        address indexed token,
        uint256         minBalance
    );

    event LogTargetDelta(
        address indexed caller,
        uint256         targetDelta
    );

    event LogExitFee(
        address indexed caller,
        uint256         exitFee
    );

    event LogReindex(
        address indexed caller,
        address[]       tokens,
        uint256[]       targetDenorms,
        uint256[]       minBalances
    );

    event LogReweigh(
        address indexed caller,
        address[]       tokens,
        uint256[]       targetDenorms
    );

    /* ========== Initialization ========== */

    function initialize(
        address controller, 
        address rebalancer,
        address unbinder,
        string calldata name, 
        string calldata symbol
    ) external;

    function setup(
        address[] calldata tokens,
        uint256[] calldata balances,
        uint256[] calldata denorms,
        address tokenProvider
    ) external;

    function setSwapFee(uint256 swapFee) external;

    function setRebalancable(bool rebalancable) external;

    function setMinBalance(address token, uint256 minBalance) external;

    function setStreamingFee(uint256 streamingFee) external;

    function setExitFee(uint256 exitFee) external;

    function setTargetDelta(uint256 targetDelta) external;

    function collectStreamingFee() external;

    function isPublicSwap() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function isReady(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256) ;

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getStreamingFee() external view returns (uint256);

    function getExitFee() external view returns (uint256);

    function getController() external view returns (address);

    function getRebalancer() external view returns (address);

    function getRebalancable() external view returns (bool);

    function getUnbinder() external view returns (address);

    function getSpotPrice(
        address tokenIn, 
        address tokenOut
    ) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(
        address tokenIn, 
        address tokenOut
    ) external view returns (uint256 spotPrice);

    /* ==========  External Token Weighting  ========== */

    /**
     * @dev Adjust weights for existing tokens
     * @param tokens A set of token addresses to adjust
     * @param targetDenorms A set of denorms to linearly update to
     */

    function reweighTokens(
        address[] calldata tokens,
        uint256[] calldata targetDenorms
    ) external;

    /**
     * @dev Reindex the pool on a new set of tokens
     *
     * @param tokens A set of token addresses to be indexed
     * @param targetDenorms A set of denorms to linearly update to
     * @param minBalances Minimum balance thresholds for unbound assets
     */
    function reindexTokens(
        address[] calldata tokens,
        uint256[] calldata targetDenorms,
        uint256[] calldata minBalances
    ) external;

    function gulp(address token) external;

    function joinPool(uint256 poolAmountOut, uint[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@bundle-dao/pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";
import "./IBundle.sol";

interface IUnbinder {
    struct SwapToken {
        bool flag;
        uint256 index;
    }

    event TokenUnbound(address token);

    event LogSwapWhitelist(
        address indexed caller,
        address         token,
        bool            flag
    );

    event LogPremium(
        address indexed caller,
        uint256         premium
    );

    function initialize(address bundle, address router, address controller, address[] calldata whitelist) external;

    function handleUnboundToken(address token) external;

    function distributeUnboundToken(address token, uint256 amount, uint256 deadline, address[][] calldata paths) external;

    function setPremium(uint256 premium) external;

    function setSwapWhitelist(address token, bool flag) external;

    function getPremium() external view returns (uint256);

    function getController() external view returns (address);

    function getBundle() external view returns (address);

    function isSwapWhitelisted(address token) external view returns (bool);

    function getSwapWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRebalancer {
    struct SwapToken {
        bool flag;
        uint256 index;
    }

    event LogPremium(
        address indexed caller,
        uint256         premium
    );

    event LogWhitelist(
        address indexed caller,
        address         bundle,
        bool            flag
    );

    event LogSwapWhitelist(
        address indexed caller,
        address         token,
        bool            flag
    );

    event LogOracle(
        address indexed caller,
        address         oracle
    );

    event LogGap(
        address indexed caller,
        uint256         gap
    );

    function setPremium(uint256 premium) external;

    function setWhitelist(address pool, bool flag) external;

    function setSwapWhitelist(address token, bool flag) external;

    function setOracle(address oracle) external;

    function setGap(uint256 gap) external;

    function getController() external view returns (address);

    function getPremium() external view returns (uint256);

    function getSwapWhitelist() external view returns (address[] memory);

    function isWhitelisted(address pool) external view returns (bool);

    function isSwapWhitelisted(address token) external view returns (bool);

    function getOracle() external view returns (address);

    function getGap() external view returns (uint256);

    function swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 deadline,
        address[] calldata path
    ) external;
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}