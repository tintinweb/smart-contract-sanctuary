// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TierIDOPool.sol";
import "./AsvaInvestmentsInfo.sol";

/// @title AsavaPoolFactory
/// @notice Factory contract to create PreSale
/// Useful for launching new NewIDO
contract AsavaPoolFactory is Ownable {
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
     * @param _round1Start Timestamp of when round1 starts
     * @param _round1End Timestamp of when round1 ends
     * @param _round2Start Timestamp of when round2 starts
     * @param _round2End Timestamp of when round2 ends
     * @param _releaseTime Timestamp of when the token will be released
     * @param _price Price of the token for the IDO
     * @param _totalAmount The total amount for the IDO
     * @param _maxAmountThatCanBeInvestedInTier1 Max investment amount in tier1
     * @param _maxAmountThatCanBeInvestedInTier2 Max investment amount in tier2
     * @param _maxAmountThatCanBeInvestedInTier3 Max investment amount in tier3
     * @param _maxAmountThatCanBeInvestedInTier4 Max investment amount in tier4
     * @param _presaleProjectID The PreSale project ID
     * @param _whitelistedAddressesTier1 An array of whitelist addresses for tier1
     * @param _whitelistedAddressesTier2 An array of whitelist addresses for tier2
     * @param _whitelistedAddressesTier3 An array of whitelist addresses for tier3
     * @param _whitelistedAddressesTier4 An array of whitelist addresses for tier4
     * @param _tiersAllocation An array of amounts as per tiers
     */
    struct IDOInfo {
        address _token;
        address _currency;
        uint256 _round1Start;
        uint256 _round1End;
        uint256 _round2Start;
        uint256 _round2End;
        uint256 _releaseTime;
        uint256 _price;
        uint256 _totalAmount;
        uint256 _maxAmountThatCanBeInvestedInTier1;
        uint256 _maxAmountThatCanBeInvestedInTier2;
        uint256 _maxAmountThatCanBeInvestedInTier3;
        uint256 _maxAmountThatCanBeInvestedInTier4;
        uint256 _presaleProjectID;
        address[] _whitelistedAddressesTier1;
        address[] _whitelistedAddressesTier2;
        address[] _whitelistedAddressesTier3;
        address[] _whitelistedAddressesTier4;
        uint256[] _tiersAllocation;
    }

    uint256 public nextPoolId;
    IDOPoolInfo[] public poolList;

    //solhint-disable-next-line var-name-mixedcase
    AsvaInvestmentsInfo public immutable AsvaInfo;

    IERC20 public platformToken; // Platform token

    event PoolCreated(
        uint256 indexed asvaId,
        uint256 presaleDbID,
        address indexed _token,
        address indexed _currency,
        address pool,
        address creator
    );

    /**
     * @dev Sets the values for {_asvaInfoAddress, _platformToken}
     *
     * All two of these values are immutable: they can only be set once during construction.
     */
    constructor(address _asvaInfoAddress, address _platformToken) public {
        AsvaInfo = AsvaInvestmentsInfo(_asvaInfoAddress);
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
    function createPoolPublic(IDOInfo calldata poolInfo) external onlyOwner {
        require(poolInfo._token != poolInfo._currency, "Currency and Token can not be the same");
        require(poolInfo._token != address(0), "PoolInfo token cannot be address zero");
        require(poolInfo._currency != address(0), "PoolInfo currency cannot be address zero");
        uint256 sumOfAmtOfAllTiers = 0;
        for (uint256 i = 0; i < poolInfo._tiersAllocation.length; i++) {
            sumOfAmtOfAllTiers = sumOfAmtOfAllTiers.add(poolInfo._tiersAllocation[i]);
        }
        require(
            poolInfo._totalAmount == sumOfAmtOfAllTiers,
            "PoolInfo totalAmount & sumOfAmtOfAllTiers must be the same"
        );
        // AsvaInvestmentsPresale presale = new AsvaInvestmentsPresale(address(this), AsvaInfo.owner());
        IERC20 tokenIDO = IERC20(poolInfo._token);

        TierIDOPool _idoPool = new TierIDOPool(
            poolInfo._token,
            poolInfo._currency,
            poolInfo._round1Start,
            poolInfo._round1End,
            poolInfo._round2Start,
            poolInfo._round2End,
            poolInfo._releaseTime,
            poolInfo._price,
            poolInfo._totalAmount,
            poolInfo._maxAmountThatCanBeInvestedInTier1,
            poolInfo._maxAmountThatCanBeInvestedInTier2,
            poolInfo._maxAmountThatCanBeInvestedInTier3,
            poolInfo._maxAmountThatCanBeInvestedInTier4
        );

        tokenIDO.transferFrom(msg.sender, address(_idoPool), poolInfo._totalAmount);

        poolList.push(IDOPoolInfo(address(_idoPool), poolInfo._currency, poolInfo._token));

        uint256 asvaId = AsvaInfo.addPresaleAddress(address(_idoPool), poolInfo._presaleProjectID);

        _idoPool.setPlatformTokenAddress(address(platformToken));

        initializeWhitelistedAddresses(_idoPool, poolInfo._whitelistedAddressesTier1, 1);
        initializeWhitelistedAddresses(_idoPool, poolInfo._whitelistedAddressesTier2, 2);
        initializeWhitelistedAddresses(_idoPool, poolInfo._whitelistedAddressesTier3, 3);
        initializeWhitelistedAddresses(_idoPool, poolInfo._whitelistedAddressesTier4, 4);

        setIDOTierInfo(_idoPool, poolInfo._tiersAllocation);

        _idoPool.transferOwnership(owner());

        emit PoolCreated(
            asvaId,
            poolInfo._presaleProjectID,
            poolInfo._token,
            poolInfo._currency,
            address(_idoPool),
            msg.sender
        );
    }

    /**
     * @dev To set tier information in IDO contract
     * @param _pool The TierIDOPool contract object
     * @param _tiersAllocation An array of tiers allocation
     */
    function setIDOTierInfo(TierIDOPool _pool, uint256[] calldata _tiersAllocation) internal {
        _pool.setTierInfo(_tiersAllocation);
    }

    /**
     * @dev To initialize whitelsited addresses
     * @param _pool The TierIDOPool contract object
     * @param _whitelistedAddresses An array of addresses
     * @param _tier Tier to which the addresses belong
     */
    function initializeWhitelistedAddresses(
        TierIDOPool _pool,
        address[] calldata _whitelistedAddresses,
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

/// @title TierIDOPool
/// @notice IDO contract useful for launching NewIDO
//solhint-disable-next-line max-states-count
contract TierIDOPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum Type {
        MOON,
        PLANET,
        RIDER,
        KNIGHT
    }

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
    // Round 1 start time
    uint256 public round1Start;
    // Round 1 end time
    uint256 public round1End;
    // Round 2 start time
    uint256 public round2Start;
    // Round 1 end time
    uint256 public round2End;
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
    // Whitelist addresses
    mapping(address => bool) public poolWhiteList;
    address[] private listWhitelists;
    // Tier to which white list address belongs
    mapping(address => uint8) public addressBelongsToTier;

    // Number of investors
    uint256 public numberParticipants;
    // Tiers allocations
    mapping(uint8 => uint256) public tierAllocations;
    // Amount of tokens remaining w.r.t Tier
    mapping(uint8 => uint256) public tokensAvailableInTier;

    mapping(uint8 => uint256) public tierMaxAmountThatCanBeInvested;

    event Buy(address indexed _user, uint256 _amount, uint256 _tokenAmount);
    event Claim(address indexed _user, uint256 _amount);
    event Withdraw(address indexed _user, uint256 _amount);
    event EmergencyWithdraw(address indexed _user, uint256 _amount);
    event Burn(address indexed _burnAddress, uint256 _amount);

    modifier publicSaleActive() {
        require(
            (block.timestamp >= round1Start && block.timestamp <= round1End) ||
                (block.timestamp >= round2Start && block.timestamp <= round2End),
            "Public sale is not yet activated"
        );
        _;
    }

    modifier publicSaleEnded() {
        require((block.timestamp >= round2End || availableTokens == 0), "Public sale not yet ended");
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
     * @param _round1Start Timestamp of when round1 starts
     * @param _round1End Timestamp of when round1 ends
     * @param _round2Start Timestamp of when round2 starts
     * @param _round2End Timestamp of when round2 ends
     * @param _releaseTime Timestamp of when the token will be released
     * @param _price Price of the token for the IDO
     * @param _totalAmount The total amount for the IDO
     * @param _maxAmountThatCanBeInvestedInTier1 Max investment amount in tier1
     * @param _maxAmountThatCanBeInvestedInTier2 Max investment amount in tier2
     * @param _maxAmountThatCanBeInvestedInTier3 Max investment amount in tier3
     * @param _maxAmountThatCanBeInvestedInTier4 Max investment amount in tier4
     */
    //solhint-disable-next-line function-max-lines
    constructor(
        address _token,
        address _currency,
        uint256 _round1Start,
        uint256 _round1End,
        uint256 _round2Start,
        uint256 _round2End,
        uint256 _releaseTime,
        uint256 _price,
        uint256 _totalAmount,
        uint256 _maxAmountThatCanBeInvestedInTier1,
        uint256 _maxAmountThatCanBeInvestedInTier2,
        uint256 _maxAmountThatCanBeInvestedInTier3,
        uint256 _maxAmountThatCanBeInvestedInTier4
    ) public {
        require(_token != address(0), "Token address cannot be address zero");
        require(_currency != address(0), "Currency address cannot be address zero");
        require(_round1Start < _round1End, "Round1 start time > Round1 end time");
        require(_round1End <= _round2Start, "Round1 end time > Round2 start time");
        require(_round2Start < _round2End, "Round1 start time > Round2 end time");
        require(_totalAmount > 0, "Total amount must be > 0");

        token = IERC20(_token);
        currency = IERC20(_currency);
        round1Start = _round1Start;
        round1End = _round1End;
        round2Start = _round2Start;
        round2End = _round2End;
        releaseTime = _releaseTime;
        price = _price;
        totalAmount = _totalAmount;
        availableTokens = _totalAmount;

        tierMaxAmountThatCanBeInvested[1] = _maxAmountThatCanBeInvestedInTier1;
        tierMaxAmountThatCanBeInvested[2] = _maxAmountThatCanBeInvestedInTier2;
        tierMaxAmountThatCanBeInvested[3] = _maxAmountThatCanBeInvestedInTier3;
        tierMaxAmountThatCanBeInvested[4] = _maxAmountThatCanBeInvestedInTier4;
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
        uint8 tier = getAddressTier(msg.sender);
        require(tier > 0, "You are not whitelisted");

        uint256 remainingAllocation = tokensAvailableInTier[tier];

        if (block.timestamp >= round2Start) {
            remainingAllocation = availableTokens;
        }

        require(amount <= remainingAllocation && amount <= availableTokens, "Not enough tokens to buy");

        Sale storage sale = sales[msg.sender];

        // If round 1 is running then we check maxInvest amount as per tier
        if (block.timestamp <= round1End) {
            uint256 maxPurchase = tierMaxAmountThatCanBeInvested[tier];
            require(amount <= maxPurchase.sub(sale.amount), "Buy exceeds amount");
            tokensAvailableInTier[tier] = tokensAvailableInTier[tier].sub(amount);
        }

        uint256 currencyAmount = amount.mul(price).div(1e18);

        require(currency.balanceOf(msg.sender) >= currencyAmount, "Insufficient currency balance of caller");

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
     * Returns array of investor addresses, their invested funds, nextOffset and total
     */
    function getInvestors(uint offset, uint limit) external view returns
        (address[] memory, uint256[] memory, uint nextOffset, uint total) {

        if(limit == 0) {
            limit = 1;
        }

        if (limit > numberParticipants- offset) {
            limit = numberParticipants - offset;
        }

        address[] memory addrs = new address[](limit);
        uint256[] memory funds = new uint256[](limit);


        for (uint256 i = 0; i < limit; i++) {
            Investor storage investor = investorInfo[offset + i];
            addrs[i] = investor.investor;
            funds[i] = investor.amount;
        }

        return (addrs, funds, offset + limit, numberParticipants);
    }

    /**
     * @dev To add users and tiers to the contract storage
     * @param _users An array of addresses
     */
    function addToPoolWhiteList(address[] memory _users, uint8 _tier) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _users.length; i++) {
            if (!poolWhiteList[_users[i]]) {
                poolWhiteList[_users[i]] = true;
                addressBelongsToTier[_users[i]] = _tier;
                listWhitelists.push(address(_users[i]));
            }
        }
        return true;
    }

    /**
     * @dev To add users and tiers to the contract storage
     * @param _tiersAllocation An array of tiers
     */
    function setTierInfo(uint256[] memory _tiersAllocation) external onlyOwner returns (bool) {
        for (uint8 i = 0; i < _tiersAllocation.length; i++) {
            require(_tiersAllocation[i] > 0, "Tier allocation amount must be > 0");
            // Since we have named Tier1, Tier2, Tier3 & Tier4
            tierAllocations[i + 1] = _tiersAllocation[i];
            tokensAvailableInTier[i + 1] = _tiersAllocation[i];
        }
        return true;
    }

    /**
     * @dev To get the whitelisted addresses
     */
    function getPoolWhiteLists() external view returns (address[] memory) {
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
import "@openzeppelin/contracts/access/AccessControl.sol";


/// @title AsvaInvestmentsInfo
/// @notice AsvaInvestmentsInfo gives infromation regarding  IDO contract which is launch by ASVAFACTORY contract.
/// Ref: https://testnet.bscscan.com/address/0x3109bf9e73f50209Cf92D2459B5Da0E38D8890C1#code
contract AsvaInvestmentsInfo is AccessControl {
    address[] private presaleAddresses;

    mapping(address => bool) public alreadyAdded;
    mapping(uint256 => address) public presaleAddressByProjectID;

      /// @dev  Add admin roke to msg,sender
     constructor () public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

      // @dev Restricted to user role.
    modifier onlyAdminUser() {
        require(isAdmin(msg.sender), "Restricted to admin.");
        _;
    }

     /// @dev Return `true` if the `account` belongs to the community.
    function isAdmin(address account)
        public virtual view returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add a admin user.
    function addAdmin(address account) public virtual onlyAdminUser {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Remove oneself as a admin.
    function leaveAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev To add presale address
     *
     * Requirements:
     * - presale address cannot be address zero.
     * - presale should not be already added
     */
    function addPresaleAddress(address _presale, uint256 _presaleProjectID) external onlyAdminUser returns (uint256) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}