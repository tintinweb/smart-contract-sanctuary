// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDOPool.sol";
import "./CoinXPadInvestmentsInfo.sol";

/// @title CoinXPadPoolFactory
/// @notice Factory contract to create PreSale
contract CoinXPadPoolFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Struct to store the IDO Pool Information
     * @param contractAddr The contract address
     * @param currency The curreny used for the IDO
     * @param token The ERC20 token contract address
     */
    struct IDOPoolInfo {
        address contractAddr;
        address currency;
        address token;
    }

    /**
     * @dev Struct to store IDO Information
     * @param _token The ERC20 token contract address
     * @param _currency The curreny used for the IDO
     * @param _startTime Timestamp of when sale starts
     * @param _endTime Timestamp of when sale ends
     * @param _releaseTime Timestamp of when the token will be released
     * @param _fcfsStartTime Timestamp of when the token will be released for FCFS allocation
     * @param _price Price of the token for the IDO
     * @param _totalAmount The total amount for the IDO
     * @param _maxAmountThatCanBeInvestedInFCFS Max amount that can be invested in FCFS
     * @param _minAmountThatCanBeInvestedInFCFS Min amount that can be invested in FCFS
     * @param _balanceRequiredForInvestmentInFCFS Balance required for investment in FCFS
     * @param _fcfsAllocation Tokens allocated for FCFS
     * @param _maxAmountThatCanBeInvestedInTiers An array of max investments amount in tiers
     * @param _minAmountThatCanBeInvestedInTiers An array of min investments amount in tiers
     * @param _noOfWhiteListAddressesAsPerTiers An array indicating number of white list addresses as per tiers
     * @param _presaleProjectID The PreSale project ID
     * @param _whitelistedAddresses An array of whitelist addresses for all tiers
     * @param _tiersAllocation An array of amounts as per tiers
     * @param _tiersDuration An array of timestamps indication of duration of each tier
     * @param _canBuyAfterMinutes An array of minutes indication of after how many minutes of
       startTime buy can be executed
     */
    struct IDOInfo {
        address _token;
        address _currency;
        uint256 _startTime;
        uint256 _endTime;
        uint256 _releaseTime;
        uint256 _fcfsStartTime;
        uint256 _fcfsEndTime;
        uint256 _price;
        uint256 _totalAmount;
        uint256 _presaleProjectID;
        uint256 _maxAmountThatCanBeInvestedInFCFS;
        uint256 _minAmountThatCanBeInvestedInFCFS;
        uint256 _balanceRequiredForInvestmentInFCFS;
        uint256 _fcfsAllocation;
        uint256[] _maxAmountThatCanBeInvestedInTiers;
        uint256[] _minAmountThatCanBeInvestedInTiers;
        uint256[] _noOfWhiteListAddressesAsPerTiers;
        address[] _whitelistedAddresses;
        uint256[] _tiersAllocation;
    }

    uint256 public nextPoolId;
    IDOPoolInfo[] public poolList;

    //solhint-disable-next-line var-name-mixedcase
    CoinXPadInvestmentsInfo public immutable coinXPadInfo;

    IERC20 public platformToken; // Platform token

    event PoolCreated(
        uint256 indexed coinXPadId,
        uint256 presaleDbID,
        address indexed _token,
        address indexed _currency,
        address pool,
        address creator
    );

    /**
     * @dev Sets the values for {_coinxpadInfoAddress, _platformToken}
     *
     * All two of these values are immutable: they can only be set once during construction.
     */
    constructor(address _coinxpadInfoAddress, address _platformToken) public {
        coinXPadInfo = CoinXPadInvestmentsInfo(_coinxpadInfoAddress);
        platformToken = IERC20(_platformToken);
    }

    /**
     * @dev To create a pool
     *
     * Requirements:
     * - poolinfo token & currency cannot be the same
     * - poolinfo token cannot be address zero
     * - poolinfo currency cannot be address zero
     */
    //solhint-disable-next-line function-max-lines
    function createPoolPublic(IDOInfo calldata poolInfo) external onlyOwner returns (uint256, address) {
        require(poolInfo._token != poolInfo._currency, "Currency and Token can not be the same");
        require(poolInfo._token != address(0), "PoolInfo token cannot be address zero");
        require(poolInfo._currency != address(0), "PoolInfo currency cannot be address zero");
        uint256 sumOfAmtOfAllTiersAndFCFS = 0;
        uint256 tiersAllocLength = poolInfo._tiersAllocation.length;
        for (uint256 i = 0; i < tiersAllocLength; i++) {
            sumOfAmtOfAllTiersAndFCFS = sumOfAmtOfAllTiersAndFCFS.add(poolInfo._tiersAllocation[i]);
        }
        sumOfAmtOfAllTiersAndFCFS = sumOfAmtOfAllTiersAndFCFS.add(poolInfo._fcfsAllocation);
        require(
            poolInfo._totalAmount == sumOfAmtOfAllTiersAndFCFS,
            "PoolInfo totalAmount & sumOfAmtOfAllTiersAndFCFS are unequal"
        );

        //IERC20 tokenIDO = IERC20(poolInfo._token);

        IDOPool _idoPool = new IDOPool(
            poolInfo._token,
            poolInfo._currency,
            poolInfo._startTime,
            poolInfo._endTime,
            poolInfo._releaseTime,
            poolInfo._price,
            poolInfo._totalAmount
        );

        //tokenIDO.transferFrom(msg.sender, address(_idoPool), poolInfo._totalAmount);

        poolList.push(IDOPoolInfo(address(_idoPool), poolInfo._currency, poolInfo._token));

        uint256 coinXPadId = coinXPadInfo.addPresaleAddress(address(_idoPool), poolInfo._presaleProjectID);

        _idoPool.setPlatformTokenAddress(address(platformToken));

        uint256 k = 0;
        uint256 j = 0;
        for (uint256 i = 0; i < poolInfo._noOfWhiteListAddressesAsPerTiers.length; i++) {
            address[] memory whiteListAddresses = new address[](poolInfo._noOfWhiteListAddressesAsPerTiers[i]);
            for (j = 0; j < poolInfo._noOfWhiteListAddressesAsPerTiers[i]; j++) {
                whiteListAddresses[j] = poolInfo._whitelistedAddresses[i + j + k];
            }
            initializeWhitelistedAddresses(_idoPool, whiteListAddresses, uint8(i + 1));
            k = j - 1;
        }

        setIDOTierInfo(
            _idoPool,
            poolInfo._tiersAllocation,
            poolInfo._maxAmountThatCanBeInvestedInTiers,
            poolInfo._minAmountThatCanBeInvestedInTiers
        );

        _idoPool.setFCFSTime(
            poolInfo._fcfsStartTime,
            poolInfo._fcfsEndTime
        );

        _idoPool.setFCFSAllocInfo(
            poolInfo._maxAmountThatCanBeInvestedInFCFS,
            poolInfo. _minAmountThatCanBeInvestedInFCFS,
            poolInfo._balanceRequiredForInvestmentInFCFS,
            poolInfo._fcfsAllocation
        );

        _idoPool.transferOwnership(owner());

        emit PoolCreated(
            coinXPadId,
            poolInfo._presaleProjectID,
            poolInfo._token,
            poolInfo._currency,
            address(_idoPool),
            msg.sender
        );

         return (coinXPadId, address(_idoPool));
    }


    /**
     * @dev To set tier information in IDO contract
     * @param _pool The IDOPool contract object
     * @param _tiersAllocation An array of tiers allocation
     */
    function setIDOTierInfo(
        IDOPool _pool,
        uint256[] calldata _tiersAllocation,
        uint256[] calldata _maxAmountThatCanBeInvestedInTiers,
        uint256[] calldata _minAmountThatCanBeInvestedInTiers
    ) internal {
        _pool.setTierInfo(
            _tiersAllocation,
            _maxAmountThatCanBeInvestedInTiers,
            _minAmountThatCanBeInvestedInTiers
        );
    }

    /**
     * @dev To initialize whitelsited addresses
     * @param _pool The IDOPool contract object
     * @param _whitelistedAddresses An array of addresses
     * @param _tier Tier to which the addresses belong
     */
    function initializeWhitelistedAddresses(
        IDOPool _pool,
        address[] memory _whitelistedAddresses,
        uint8 _tier
    ) internal {
        _pool.addToPoolWhiteList(_whitelistedAddresses, _tier);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title IDOPool
/// @notice IDO contract useful for launching NewIDO
//solhint-disable-next-line max-states-count
contract IDOPool is Ownable, ReentrancyGuard {
    enum InvestorType {
        DIAMOND,
        PLATINUM,
        GOLD
    }

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Struct to store information of each Sale
     * @param investor Address of user/investor
     * @param amount Amount of tokens to be purchased
     * @param tokensWithdrawn Tokens Withdrawal status
     */
    struct Sale {
        address investor;
        uint256 amount;
        bool tokensWithdrawn;
    }

    /**
     * @dev Struct to store information of each Investor
     * @param investor Address of user/investor
     * @param amount Amount of tokens purchased
     */
    struct Investor {
        address investor;
        uint256 amount;
    }

    /**
     * @dev Struct to store properties of Tier
     * @param availableTokens Tokens available in a tier
     * @param totalAllocation Total tokens allocated to a tier
     * @param maxAmountThatCanBeInvested Maximum amount that can be invested in the tier
     * @param minAmountThatCanBeInvested Minimum amount that can be invested in the tier
     * @param duration The duration + startTime in which buy can be executed
     * @param canBuyAfterMinutes The minutes after which buy can be executed
     */
    struct TierInformation {
        uint256 availableTokens;
        uint256 totalAllocation;
        uint256 maxAmountThatCanBeInvested;
        uint256 minAmountThatCanBeInvested;
    }

    /**
     * @param maxAmountThatCanBeInvested Maximum amount that can be invested in FCFS
     * @param minAmountThatCanBeInvested Minimum amount that can be invested in FCFS
     * @param balanceRequiredForInvestment Balance required in CXPAD for making investments
     * @param totalAllocation Total tokens allocated for FCFS
     */
    struct FCFSAllocationInfo {
        uint256 maxAmountThatCanBeInvested;
        uint256 minAmountThatCanBeInvested;
        uint256 balanceRequiredForInvestment;
        uint256 totalAllocation;
    }

    mapping(uint8 => TierInformation) public tierInfo;
    mapping(uint8 => FCFSAllocationInfo) public fcfsInfo;

    // Platform token
    IERC20 public platformToken;
    // Token for sale
    IERC20 public token;
    // Token used to buy
    IERC20 public currency;

    // List investors
    Investor[] private investorInfo;
    // Info of each investor that buy tokens.
    mapping(address => Sale) public sales;
    // Sale start time
    uint256 public startTime;
    // Sale end time
    uint256 public endTime;
    // Price of each token
    uint256 public price;
    // Amount of tokens remaining
    uint256 public availableTokens;
    // Total amount of tokens to be sold
    uint256 public totalAmount;
    // Total amount sold
    uint256 public totalAmountSold;
    // Release time
    uint256 public releaseTime;
    // FCFS time
    uint256 public fcfsStartTime;
    // Sale end time
    uint256 public fcfsEndTime;

    // Total number of tiers
    uint8 public totalTiers;
    // Whitelist addresses
    mapping(address => bool) public poolWhiteList;
    address[] private listWhitelists;
    // Tier to which white list address belongs
    mapping(address => uint8) public addressBelongsToTier;

    // Number of investors
    uint256 public numberParticipants;

    // Number of Whitelisted
    uint256 public numOfWhitelisted;

    // Amount of tokens remaining w.r.t Tier
    mapping(uint8 => uint256) public tokensAvailableInTier;

    bool public tierAllocationMovedToFCFS;

    event Buy(address indexed _user, uint256 _amount, uint256 _tokenAmount);
    event Claim(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event EmergencyWithdraw(address indexed _user, uint256 _amount);
    event Burn(address indexed _burnAddress, uint256 _amount);

    modifier publicSaleActive() {
        require((block.timestamp >= startTime && block.timestamp <= endTime) ||
        (block.timestamp >= fcfsStartTime && block.timestamp <= fcfsEndTime)
        , "Public sale is not yet activated");
        _;
    }

    modifier publicSaleEnded() {
        require((block.timestamp >= fcfsEndTime || availableTokens == 0), "Public sale not yet ended");
        _;
    }

    modifier canClaim() {
        require(block.timestamp >= releaseTime, "Please wait until release time for claiming tokens");
        _;
    }

    /**
     * @dev Initialzes the TierIDO Pool contract
     * @param _token The ERC20 token contract address
     * @param _currency The curreny used for the IDO
     * @param _startTime Timestamp of when sale starts
     * @param _endTime Timestamp of when sale ends
     * @param _releaseTime Timestamp of when the token will be released
     * @param _price Price of the token for the IDO
     * @param _totalAmount The total amount for the IDO
     */
    //solhint-disable-next-line function-max-lines
    constructor(
        address _token,
        address _currency,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _releaseTime,
        uint256 _price,
        uint256 _totalAmount
    ) public {
        require(_token != address(0), "Token address cannot be address zero");
        require(_currency != address(0), "Currency address cannot be address zero");
        require(_startTime < _endTime, "Start time > End time");
        require(_totalAmount > 0, "Total amount must be > 0");

        token = IERC20(_token);
        currency = IERC20(_currency);
        startTime = _startTime;
        endTime = _endTime;
        releaseTime = _releaseTime;
        price = _price;
        totalAmount = _totalAmount;
        availableTokens = _totalAmount;
    }

    /**
     * @dev To buy tokens
     *
     * @param amount The amount of tokens to buy
     *
     * Requirements:
     * - can be invoked only when the public sale is active
     * - this call is non reentrant
     */
    function buy(uint256 amount) external publicSaleActive nonReentrant {
        require(availableTokens > 0, "All tokens were purchased");
        require(amount > 0, "Amount must be > 0");
        /*
        @TODO This will be uncommented when there's a need to check balance upon call to buy
        uint256 callerCXPADBalance = platformToken.balanceOf(msg.sender);
        InvestorType investorType = getInvestorType(callerCXPADBalance);
        require(isReleaseTimeCrossed(investorType), "Release time not yet crossed. Please wait.");
        */

        uint8 tier = getAddressTier(msg.sender);
        uint256 remainingAllocation = 0;
        uint256 minPurchase = 0;
        uint256 maxPurchase = 0;
        Sale storage sale = sales[msg.sender];
        TierInformation memory _tierInfo;
        FCFSAllocationInfo memory _fcfsInfo;

        // tier = 0 implies caller does not belong to any tier i.e. it should be FCFS caller
        if (now >= fcfsStartTime) {
            _fcfsInfo = fcfsInfo[0];
            if (!tierAllocationMovedToFCFS) {
                // Set totalAllocation for FCFS
                _fcfsInfo.totalAllocation = _fcfsInfo.totalAllocation.add(availableTokens);
                tierAllocationMovedToFCFS = true;
                fcfsInfo[0] = _fcfsInfo;
            }
            uint256 balanceRequiredForInvestment = _fcfsInfo.balanceRequiredForInvestment;
            minPurchase = _fcfsInfo.minAmountThatCanBeInvested;
            maxPurchase = _fcfsInfo.maxAmountThatCanBeInvested;
            remainingAllocation = _fcfsInfo.totalAllocation;
            require(
                (amount >= minPurchase) && (amount <= maxPurchase.sub(sale.amount)),
                "FCFS: amount must be >= minPurchase & <= maxPurchase"
            );
            require(platformToken.balanceOf(msg.sender) >= balanceRequiredForInvestment,
            "FCFS: insufficient balance of coinxpad token");

            _fcfsInfo.totalAllocation = _fcfsInfo.totalAllocation.sub(amount);
            fcfsInfo[0] = _fcfsInfo;
        } else {
            require(tier > 0, "You are not whitelisted");
            _tierInfo = tierInfo[tier];

            uint256 tierAvailableTokens = _tierInfo.availableTokens;
            minPurchase = _tierInfo.minAmountThatCanBeInvested;
            maxPurchase = _tierInfo.maxAmountThatCanBeInvested;
            remainingAllocation = tierAvailableTokens;

            require(
                (amount >= minPurchase) && (amount <= maxPurchase.sub(sale.amount)),
                "Tier: amount must be >= minPurchase & <= maxPurchase"
            );
            _tierInfo.availableTokens = tierAvailableTokens.sub(amount);
            // Write to storage
            tierInfo[tier] = _tierInfo;
        }

        require(amount <= remainingAllocation && amount <= availableTokens, "Not enough tokens to buy");

        uint256 currencyAmount = amount.mul(price).div(1e18);

        require(currency.balanceOf(msg.sender) >= currencyAmount, "Insufficient currency balance of caller");
        // Main available tokens
        availableTokens = availableTokens.sub(amount);

        currency.safeTransferFrom(msg.sender, address(this), currencyAmount);

        if (sale.amount == 0) {
            sales[msg.sender] = Sale(msg.sender, amount, false);
            numberParticipants += 1;
        } else {
            sales[msg.sender] = Sale(msg.sender, amount.add(sale.amount), false);
        }

        totalAmountSold = totalAmountSold.add(amount);
        investorInfo.push(Investor(msg.sender, amount));
        emit Buy(msg.sender, currencyAmount, amount);
    }

    /**
     * @dev To withdraw purchased tokens after release time
     *
     * Requirements:
     * - this call is non reentrant
     * - cannot claim within release time
     */
    function claimTokens() external canClaim nonReentrant {
        Sale storage sale = sales[msg.sender];
        require(!sale.tokensWithdrawn, "Already withdrawn");
        require(sale.amount > 0, "Only investors");
        sale.tokensWithdrawn = true;
        token.transfer(sale.investor, sale.amount);
        emit Claim(msg.sender, sale.amount);
    }

    /**
     * @dev To withdraw tokens after the sale ends and burns the remaining tokens
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     * - the public sale must have ended
     * - this call is non reentrant
     */
    function withdraw() external onlyOwner publicSaleEnded nonReentrant {
        if (availableTokens > 0) {
            availableTokens = 0;
        }
        transferIDOToken();
        transferCurrencyToken();
    }

    /**
     * @dev To withdraw in case of any possible hack/vulnerability
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     * - this call is non reentrant
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        if (availableTokens > 0) {
            availableTokens = 0;
        }
        transferIDOToken();
        transferCurrencyToken();
    }

    /**
     * @dev To set the platform token address
     *
     * Requirements:
     * - invocation can be done, only by the contract owner.
     */
    function setPlatformTokenAddress(address _platformToken) external onlyOwner returns (bool) {
        platformToken = IERC20(_platformToken);
        return true;
    }

    /**
     * @dev To get investor of the IDO
     * Returns array of investor addresses and their invested funds
     */
    function getInvestors() external view returns (address[] memory, uint256[] memory) {
        address[] memory addrs = new address[](numberParticipants);
        uint256[] memory funds = new uint256[](numberParticipants);

        for (uint256 i = 0; i < numberParticipants; i++) {
            Investor storage investor = investorInfo[i];
            addrs[i] = investor.investor;
            funds[i] = investor.amount;
        }

        return (addrs, funds);
    }

    /**
     * @dev To add users and tiers to the contract storage
     * @param _users An array of addresses
     */
    function addToPoolWhiteList(address[] memory _users, uint8 _tier) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < _users.length; i++) {
            if (poolWhiteList[_users[i]] != true) {
                poolWhiteList[_users[i]] = true;
                addressBelongsToTier[_users[i]] = _tier;
                numOfWhitelisted = numOfWhitelisted.add(1);
                listWhitelists.push(address(_users[i]));
            }
        }
        return true;
    }
     /**
     * @dev Allows campaign owner to remove from the whitelisted addresses.
     * @param _addresses - Array of addresses
     * @notice - Access control: Public, OnlyCampaignOwner
     */
    function removeWhitelisted(address[] memory _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        for (uint256 i=0; i<len; i++) {
            address a = _addresses[i];
            if (poolWhiteList[a] == true) {
                poolWhiteList[a] = false;
                numOfWhitelisted = numOfWhitelisted.sub(1);
            }
        }
    }
    /**
     * @dev To add users and tiers to the contract storage
     */
    function setTierInfo(
        uint256[] memory _tiersAllocation,
        uint256[] memory _maxAmountThatCanBeInvestedInTiers,
        uint256[] memory _minAmountThatCanBeInvestedInTiers
    ) public onlyOwner returns (bool) {
        for (uint8 i = 0; i < _tiersAllocation.length; i++) {
            require(_tiersAllocation[i] > 0, "Tier allocation amount must be > 0");
            tierInfo[i + 1] = TierInformation({
                availableTokens: _tiersAllocation[i],
                totalAllocation: _tiersAllocation[i],
                maxAmountThatCanBeInvested: _maxAmountThatCanBeInvestedInTiers[i],
                minAmountThatCanBeInvested: _minAmountThatCanBeInvestedInTiers[i]
            });
        }
        totalTiers = uint8(_tiersAllocation.length);
        return true;
    }

    /**
     * @dev To set FCFS allocation information
     * @param _maxAmountThatCanBeInvested Maximum amount that can be invested in FCFS
     * @param _minAmountThatCanBeInvested Minimum amount that can be invested in FCFS
     * @param _balanceRequiredForInvestment Balance required in CXPAD for making investments
     * @param _totalAllocation Total tokens allocated for FCFS
     */
    function setFCFSAllocInfo(
        uint256 _maxAmountThatCanBeInvested,
        uint256 _minAmountThatCanBeInvested,
        uint256 _balanceRequiredForInvestment,
        uint256 _totalAllocation
    ) public onlyOwner {
        require(_totalAllocation < totalAmount, "FCFS totalAllocation must be < totalAmount of IDO");

        fcfsInfo[0] = FCFSAllocationInfo({
            maxAmountThatCanBeInvested: _maxAmountThatCanBeInvested,
            minAmountThatCanBeInvested: _minAmountThatCanBeInvested,
            balanceRequiredForInvestment: _balanceRequiredForInvestment,
            totalAllocation: _totalAllocation
        });
    }
    /**
     * @dev To set FCFS Time information
     * @param _fcfsStartTime Timestamp of when the token will be available for FCFS
     * @param  _fcfsEndTime Timestamp of end time fcfs round
     */
    function setFCFSTime(
        uint256 _fcfsStartTime,
        uint256 _fcfsEndTime
    ) public onlyOwner {
        require(_fcfsStartTime > startTime, "FCFS round start must be > startTime of IDO");
        require(_fcfsEndTime > _fcfsStartTime, "FCFS must be > FCFS end time");

        fcfsStartTime = _fcfsStartTime;
        fcfsEndTime = _fcfsEndTime;
    }
    /**
     * @dev To get the whitelisted addresses
     */
    function getPoolWhiteLists() public view returns (address[] memory) {
        return listWhitelists;
    }

    /**
     * @dev To get user tier
     */
    function getAddressTier(address _user) public view returns (uint8) {
        return addressBelongsToTier[_user];
    }

    /**
     * @dev To transfer IDO token
     */
    function transferIDOToken() internal {
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, tokenBalance);
        emit Withdraw(msg.sender, tokenBalance);
    }

    /**
     * @dev To transfer Currency token
     */
    function transferCurrencyToken() internal {
        uint256 currencyBalance = currency.balanceOf(address(this));
        currency.safeTransfer(msg.sender, currencyBalance);
        emit Withdraw(msg.sender, currencyBalance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title CoinXPadInvestmentsInfo
/// @notice CoinXPadInvestmentsInfo gives infromation regarding  IDO contract which is launch by ASVAFACTORY contract.
/// Ref: https://testnet.bscscan.com/address/0x3109bf9e73f50209Cf92D2459B5Da0E38D8890C1#code
contract CoinXPadInvestmentsInfo is Ownable {
    address[] private presaleAddresses;

    mapping(address => bool) public alreadyAdded;
    mapping(uint256 => address) public presaleAddressByProjectID;

    /**
     * @dev To add presale address
     *
     * Requirements:
     * - presale address cannot be address zero.
     * - presale should not be already added
     */
    function addPresaleAddress(address _presale, uint256 _presaleProjectID) external returns (uint256) {
        require(_presale != address(0), "Address cannot be a zero address");
        require(!alreadyAdded[_presale], "Address already added");

        presaleAddresses.push(_presale);
        alreadyAdded[_presale] = true;
        presaleAddressByProjectID[_presaleProjectID] = _presale;
        return presaleAddresses.length - 1;
    }

    /**
     * @dev To return presale counts
     */
    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    /**
     * @dev To get presale contract address by DB id
     */
    function getPresaleAddressByDbId(uint256 asvaDbId) external view returns (address) {
        return presaleAddressByProjectID[asvaDbId];
    }

    /**
     * @dev To get presale contract address by asvaId
     *
     * Requirements:
     * - asvaId must be a valid id
     */
    function getPresaleAddress(uint256 asvaId) external view returns (address) {
        require(validAsvaId(asvaId), "Not a valid Id");
        return presaleAddresses[asvaId];
    }

    /**
     * @dev To get valid asva Id's
     */
    function validAsvaId(uint256 asvaId) public view returns (bool) {
        if (asvaId >= 0 && asvaId <= presaleAddresses.length - 1) return true;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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