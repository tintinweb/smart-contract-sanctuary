/**
 *Submitted for verification at arbiscan.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

// File: @openzeppelin/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _governance;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_governance == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_governance, newOwner);
        _governance = newOwner;
    }
}

// File: contracts/strategies/StabilizeStrategyWBTCTraderV2.sol

pragma solidity =0.6.6;

// This is a strategy that takes advantage of volatility in the volatile token
// Users deposit wbtc into the strategy and the strategy will see into usdt when it is above its average price and buy when it is below its average price
// Trades will occur via Curve
// Executors can execute trades only during certain intervals determined by governance. They obtain a percentage of profit from each trade

interface SushiLikeRouter {
    function swapExactETHForTokens(uint, address[] calldata, address, uint) external payable returns (uint[] memory);
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory); // For a value in, it calculates value out
}

interface AggregatorV3Interface {
  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface CurveTriExchange{
    function get_dy(uint256, uint256, uint256) external view returns (uint256);
    function exchange(uint256, uint256, uint256, uint256) external; // Exchange tokens
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface StabilizeBank{
    function depositSTBZ(address _credit, uint256 amount) external;
}


contract StabilizeStrategyWBTCTraderV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public bankAddress; // Address to the STBZ buyback bank
    address public zsTokenAddress; // The address of the controlling zs-Token
    
    uint256 constant DIVISION_FACTOR = 100000;

    // Trade info
    uint256 public lastPrice;
    int256 public priceDirection; // 0 - Neutral, 1 = Up, -1 = Down
    uint256 public lastTimePriceTaken;
    uint256 public lastTradeTime;
    uint256 public lastTradeTimeSellVolatile; // Used to determine cool offs from trading
    uint256 public lastTradeTimeBuyVolatile; // Used to determine cool offs from trading

    // Configurable Trade info
    uint256 public coolDownTime = 1 hours; // Executor must wait this amount of time before trying to trade again in same direction
    uint256 public lastPricePeriod = 24 hours;
    uint256 public minTradeVolatility = 500; // 0.5% price deviation from last price will lead to trade
    uint256 public priceAverageMethod = 0; // 0 = Set to chainlink price, 1 = Average with chainlink price, 2 = Average to spot price
    uint256 public percentSell = 25000; // 25% of balance is sold during deviation events
    uint256 public minSellAmount = 10000e18; // The normalized USD amount of the minimum sell amount
    uint256 public testTradeMultiplier = 2; // Used to determine spot price
    uint256 public kFactor = 2; // Modification to the percent sell based on price direction
    uint256 private _maxOracleLag = 12 hours; // Maximum amount of lag the oracle can have before reverting the price

    // Depositor info
    uint256 public percentDepositor = 99950; // 1000 = 1%, depositors keep 99.95% from trades
    
    // Executor info
    uint256 public percentExecutor = 50000; // 50% of converted weth goes to executor, 
    uint256 public maxPercentStipend = 90000; // The maximum amount of WETH profit that can be allocated to the executor for gas in percent
    uint256 public gasPrice = 2000000000; // 2 Gwei, governance can change
    uint256 public gasStipend = 1600000; // This is the gas units that are covered by executing a trade taken from the WETH profit

    // Token information
    // This strategy accepts wbtc and usdt
    struct TokenInfo {
        IERC20 token; // Reference of token
        uint256 decimals; // Decimals of token
        uint256 curveID; // Curve ID
    }
    
    TokenInfo[] private tokenList; // An array of tokens accepted as deposits

    // Strategy specific variables
    address constant USDT_ADDRESS = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9); // USDT address
    address constant WBTC_ADDRESS = address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f); // WBTC
    address constant WBTC_PRICE_ORACLE = address(0x6ce185860a4963106506C203335A2910413708e9);
    address constant CURVE_TRIPOOL = address(0x960ea3e3C7FB317332d990873d354E18d7645590);
    address constant WETH_ADDRESS = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address constant STBZ_ADDRESS = address(0x2C110867CA90e43D372C1C2E92990B00EA32818b);
    address constant SUSHI_ROUTER = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    uint256 constant WETH_ID = 2;

    constructor(
        address _bank,
        address _zsToken
    ) public {
        bankAddress = _bank;
        zsTokenAddress = _zsToken;
        setupWithdrawTokens();
        lastPrice = getBTCUSDPrice();
        lastTimePriceTaken = block.timestamp;
    }

    // Initialization functions
    
    function setupWithdrawTokens() internal {
        // Start with wBTC
        IERC20 _token = IERC20(address(WBTC_ADDRESS));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                curveID: 1
            })
        );
        
        // USDT
        _token = IERC20(address(USDT_ADDRESS));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                curveID: 0
            })
        );
    }

    receive() external payable {
        
    }
    
    // Modifier
    modifier onlyZSToken() {
        require(zsTokenAddress == _msgSender(), "Call not sent from the zs-Token");
        _;
    }
    
    // Read functions

    function getBTCUSDPrice() public view returns (uint256) {
        AggregatorV3Interface priceOracle = AggregatorV3Interface(WBTC_PRICE_ORACLE);
        ( , int256 intPrice, , uint256 lastUpdateTime, ) = priceOracle.latestRoundData(); // We only want the answer 
        require(block.timestamp.sub(lastUpdateTime) < _maxOracleLag, "Price data is too old to use"); // Prevent use of stale oracle data
        return uint256(intPrice).mul(10**10); // Give it 10^18 decimals
    }

    function getSpotBTCPrice() public view returns (uint256) {
        // Calculated from Curve price
        uint256 spotPrice = simulateExchange(0, 1, 1e8 * testTradeMultiplier).div(testTradeMultiplier); // Get the spot price of wBTC in USDT units for a large amount of tokens
        spotPrice = spotPrice.mul(1e18).div(10**tokenList[1].decimals);
        return spotPrice;
    }
    
    function rewardTokensCount() external view returns (uint256) {
        return tokenList.length;
    }
    
    function rewardTokenAddress(uint256 _pos) external view returns (address) {
        require(_pos < tokenList.length,"No token at that position");
        return address(tokenList[_pos].token);
    }
    
    function balance() public view returns (uint256) {
        return getNormalizedTotalBalance(address(this));
    }
    
    function usdtInWBTCUnits(uint256 _amount) internal view returns (uint256) {
        if(_amount == 0){return 0;}
        uint256 wbtcPrice = getBTCUSDPrice();
        _amount = _amount.mul(10**tokenList[0].decimals).div(10**tokenList[1].decimals); // Convert to wbtc decimals
        _amount = _amount.mul(1e18).div(wbtcPrice);
        return _amount;
    }
    
    function wbtcInUSDTUnits(uint256 _amount) internal view returns (uint256) {
        if(_amount == 0){return 0;}
        uint256 wbtcPrice = getBTCUSDPrice();
        _amount = _amount.mul(10**tokenList[1].decimals).div(10**tokenList[0].decimals); // Convert to usdt decimals
        _amount = _amount.mul(wbtcPrice).div(1e18);
        return _amount;
    }
    
    function getNormalizedTotalBalance(address _address) public view returns (uint256) {
        // Get wbtc at address and usdt in wbtc units based on price oracle
        uint256 _balance = 0;
        for(uint256 i = 0; i < tokenList.length; i++){
            uint256 _bal = tokenList[i].token.balanceOf(_address);
            if(i > 0){
                _bal = usdtInWBTCUnits(_bal); // Convert to wbtc units
            }
            _bal = _bal.mul(1e18).div(10**tokenList[0].decimals);
            _balance = _balance.add(_bal); // This has been normalized to 1e18 decimals
        }
        return _balance;
    }
    
    function withdrawTokenReserves() public view returns (address, uint256) {
        // This function will return the address and amount of the token of main token, and if none available, the collateral asset
        if(tokenList[0].token.balanceOf(address(this)) > 0){
            return (address(tokenList[0].token), tokenList[0].token.balanceOf(address(this)));
        }else if(tokenList[1].token.balanceOf(address(this)) > 0){
            return (address(tokenList[1].token), tokenList[1].token.balanceOf(address(this)));
        }else{
            return (address(0), 0); // No balance
        }
    }
    
    // Write functions
    
    function enter() external onlyZSToken {
        deposit(false);
    }
    
    function exit() external onlyZSToken {
        // The ZS token vault is removing all tokens from this strategy
        withdraw(_msgSender(),1,1, false);
    }
    
    function deposit(bool nonContract) public onlyZSToken {
        // Only the ZS token can call the function
        updateLastPrice(false);
        
        // No trading is performed on deposit
        if(nonContract == true){ }
    }
    
    function withdraw(address _depositor, uint256 _share, uint256 _total, bool nonContract) public onlyZSToken returns (uint256) {
        require(balance() > 0, "There are no tokens in this strategy");
        updateLastPrice(false);
        bool convertToMainToken = true;
        if(_depositor == zsTokenAddress){ convertToMainToken == false; } // Do not convert anything if the strategy itself is withdrawing
        if(nonContract == true){ }
        
        uint256 withdrawAmount = 0;
        uint256 _balance = balance(); // Returns the normalized balance
        if(_share < _total){
            uint256 _myBalance = _balance.mul(_share).div(_total);
            withdrawPerOrderWithOracleSwap(_depositor, _myBalance, false, convertToMainToken); // This will withdraw based on order
            withdrawAmount = _myBalance;
        }else{
            // We are all shares, transfer all
            withdrawPerOrderWithOracleSwap(_depositor, _balance, true, convertToMainToken);
            withdrawAmount = _balance;
        }
        
        return withdrawAmount;
    }
    
    function exchangeUSDTForWBTC(uint256 amount, address receiver) internal {
        uint256 _bal = tokenList[0].token.balanceOf(address(this));
        exchange(1, 0, amount);
        amount = tokenList[0].token.balanceOf(address(this)).sub(_bal); // Get the amount of wbtc returned
        tokenList[0].token.safeTransfer(receiver, amount);
    }
    
    // This will withdraw the tokens from the contract based on order, essentially main token then collateral
    function withdrawPerOrderWithOracleSwap(address _receiver, uint256 _withdrawAmount, bool _takeAll, bool convert) internal {
        uint256 length = tokenList.length;
        if(_takeAll == true){
            // Send the entire balance
            for(uint256 i = 0; i < length; i++){
                uint256 _bal = tokenList[i].token.balanceOf(address(this));
                if(_bal > 0){
                    if(i == 0){
                        tokenList[i].token.safeTransfer(_receiver, _bal);
                    }else{
                        if(convert == false){
                            tokenList[i].token.safeTransfer(_receiver, _bal);
                        }else{
                            exchangeUSDTForWBTC(_bal, _receiver); // Will convert USDT to WBTC
                        }
                    }
                    
                }
            }
            return;
        }

        for(uint256 i = 0; i < length; i++){
            // Determine the balance left
            uint256 _normalizedBalance = tokenList[i].token.balanceOf(address(this));
            if(i == 0){
                _normalizedBalance = _normalizedBalance.mul(1e18).div(10**tokenList[0].decimals); // Convert wbtc to normalized
            }else if(i == 1){
                // USDT
                _normalizedBalance = usdtInWBTCUnits(_normalizedBalance); // Convert USDT to wbtc units
                // Then normalize WBTC units
                _normalizedBalance = _normalizedBalance.mul(1e18).div(10**tokenList[0].decimals);
            }
            if(_normalizedBalance <= _withdrawAmount){
                // Withdraw the entire balance of this token
                if(_normalizedBalance > 0){
                    _withdrawAmount = _withdrawAmount.sub(_normalizedBalance);
                    if(i == 0){
                        tokenList[i].token.safeTransfer(_receiver, tokenList[i].token.balanceOf(address(this)));
                    }else{
                        if(convert == false){
                            tokenList[i].token.safeTransfer(_receiver, tokenList[i].token.balanceOf(address(this)));
                        }else{
                            // Convert whatever is left to WBTC
                            exchangeUSDTForWBTC(tokenList[i].token.balanceOf(address(this)), _receiver); // Will convert USDT to WBTC
                        }
                    }              
                }
            }else{
                // Withdraw a partial amount of this token
                if(_withdrawAmount > 0){
                    // Convert the withdraw amount to the wbtc decimal amount
                    uint256 _balance = _withdrawAmount.mul(10**tokenList[0].decimals).div(1e18);
                    if(i == 1){
                        // If usdt then convert WBTC units to USDT
                        _balance = wbtcInUSDTUnits(_balance);
                    }
                    _withdrawAmount = 0;
                    if(i == 0){
                        tokenList[i].token.safeTransfer(_receiver, _balance);
                    }else{
                        if(convert == false){
                            tokenList[i].token.safeTransfer(_receiver, _balance);
                        }else{
                            exchangeUSDTForWBTC(_balance, _receiver); // Will convert USDT to WBTC
                        }
                    }
                }
                break; // Nothing more to withdraw
            }
        }
    }
    
    /*
    function testDeposit(uint256 _tokenID) external payable {
        // Must interface: function swapExactETHForTokens(uint, address[] calldata, address, uint) external payable returns (uint[] memory);
        SushiLikeRouter router = SushiLikeRouter(SUSHI_ROUTER);
        address[] memory path = new address[](2);
        path[0] = WETH_ADDRESS;
        path[1] = address(tokenList[_tokenID].token);
        router.swapExactETHForTokens{value: msg.value}(1, path, address(this), now.add(60));            
    }
    */

    function calculateTokenAndAmountToSell() internal view returns (uint256, uint256) {
        // This will determine how much to sell of a particular token based on the current trading conditions and restrictions
        // Get the spot price and compare it to chainlink price
        uint256 tradeType = 0; // 0 = Nothing, 1 = Sell volatile, 2 = sell stable
        {
            uint256 currentPrice = lastPrice;
            uint256 spotPrice = getSpotBTCPrice();
            if(spotPrice > currentPrice){
                uint256 volatility = spotPrice.sub(currentPrice).mul(DIVISION_FACTOR).div(currentPrice);
                if(volatility > minTradeVolatility){
                    tradeType = 1;
                }
            }else if(spotPrice < currentPrice){
                uint256 volatility = currentPrice.sub(spotPrice).mul(DIVISION_FACTOR).div(currentPrice);
                if(volatility > minTradeVolatility){
                    tradeType = 2;
                }
            }
        }

        if(tradeType == 0){
            return (0, 0); // Do nothing
        }
        if(tradeType == 1){
            // We are selling the volatile since the price spiked
            if(block.timestamp < lastTradeTimeSellVolatile.add(coolDownTime)) { return (0, 0); } // Too soon, in cool down
            uint256 sellAmount = percentSell;
            if(priceDirection == 1){
                // Market is moving up, sell less volatile
                sellAmount = sellAmount.div(kFactor);
            }else if(priceDirection == -1){
                // Market is moving down, sell more volatile
                sellAmount = sellAmount.mul(kFactor);
            }
            uint256 _bal = tokenList[0].token.balanceOf(address(this));
            sellAmount = _bal.mul(sellAmount).div(DIVISION_FACTOR);
            uint256 minBTC = usdtInWBTCUnits(minSellAmount.mul(10**tokenList[1].decimals).div(1e18)); // Get the minBTC sell amount
            if(_bal <= minBTC){
                // If we have less than a certain amount of tokens in the contract, sell it all
                sellAmount = _bal;
            }else if(sellAmount < minBTC &&  _bal > minBTC){
                // We want to sell a minimum amount of BTC even if our balance is slightly greater
                sellAmount = minBTC;
            }
            // Now make sure we don't sell more than the test amount
            uint256 maxSell = 1e8 * testTradeMultiplier;
            if(sellAmount > maxSell){
                sellAmount = maxSell;
            }
            return (0, sellAmount);
        }else if(tradeType == 2){
            // We are buying the volatile, since price dipped
            if(block.timestamp < lastTradeTimeBuyVolatile.add(coolDownTime)) { return (0, 0); } // Too soon, in cool down
            uint256 sellAmount = percentSell;
            if(priceDirection == -1){
                // Market is moving down, sell less stable
                sellAmount = sellAmount.div(kFactor);
            }else if(priceDirection == 1){
                // Market is moving up, sell more stable
                sellAmount = sellAmount.mul(kFactor);
            }
            uint256 _bal = tokenList[1].token.balanceOf(address(this));
            sellAmount = _bal.mul(sellAmount).div(DIVISION_FACTOR);
            uint256 minUSDT = minSellAmount.mul(10**tokenList[1].decimals).div(1e18);
            if(_bal <= minUSDT){
                // If we have less than a certain amount of tokens in the contract, sell it all
                sellAmount = _bal;
            }else if(sellAmount < minUSDT &&  _bal > minUSDT){
                sellAmount = minUSDT;
            }
            // Now make sure we don't sell more than the test amount
            uint256 maxSell = wbtcInUSDTUnits(1e8 * testTradeMultiplier);
            if(sellAmount > maxSell){
                sellAmount = maxSell;
            }
            return (1, sellAmount);
        }
    }
    
    function simulateExchange(uint256 _inID, uint256 _outID, uint256 _amount) internal view returns (uint256) {
        CurveTriExchange curve = CurveTriExchange(CURVE_TRIPOOL);
        if(_outID == WETH_ID){
            _amount = curve.get_dy(tokenList[_inID].curveID, WETH_ID, _amount); // So happens WETH_ID is same as curve ID
        }else{
            _amount = curve.get_dy(tokenList[_inID].curveID, tokenList[_outID].curveID, _amount);
        }
        return _amount;
    }

    function exchange(uint256 _inID, uint256 _outID, uint256 _amount) internal {
        CurveTriExchange curve = CurveTriExchange(CURVE_TRIPOOL);
        tokenList[_inID].token.safeApprove(address(curve), 0);
        tokenList[_inID].token.safeApprove(address(curve), _amount);
        if(_outID == WETH_ID){
            curve.exchange(tokenList[_inID].curveID, WETH_ID, _amount, 1); // So happens WETH_ID is same as curve ID
        }else{
            curve.exchange(tokenList[_inID].curveID, tokenList[_outID].curveID, _amount, 1);
        }
        return;           
    }
    
    function expectedProfit() external view returns (uint256) {
        // This view will return the amount of gain a forced swap will make on next call for the executor

        (uint256 sellToken, uint256 sellAmount) = calculateTokenAndAmountToSell();
        if(sellAmount == 0){
            return 0;
        }
        uint256 wethGain = 0;
        if(sellToken == 0){
            // We will sell wBTC for USDT
            uint256 estimate = simulateExchange(0, 1, sellAmount);
            wethGain = estimate.mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR); // Take percentage from USDT gain
            if(wethGain > 0){
                wethGain = simulateExchange(1, WETH_ID, wethGain);
            }
        }else if(sellToken == 1){
            // We will sell USDT for wbtc
            uint256 estimate = simulateExchange(1, 0, sellAmount);
            wethGain = estimate.mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR); // Take percentage from USDT gain
            if(wethGain > 0){
                wethGain = simulateExchange(0, WETH_ID, wethGain);
            }
        }
        
        if(wethGain == 0){
            return 0;
        }
        // Now calculate the amount going to the executor
        uint256 gasFee = gasPrice.mul(gasStipend); // This is gas stipend in wei
        if(gasFee >= wethGain.mul(maxPercentStipend).div(DIVISION_FACTOR)){ // Max percent of total
            return (wethGain.mul(maxPercentStipend).div(DIVISION_FACTOR)); // The executor will get max percent of total
        }else{
            wethGain = wethGain.sub(gasFee); // Subtract fee from remaining balance
            return (wethGain.mul(percentExecutor).div(DIVISION_FACTOR).add(gasFee)); // Executor amount with fee added
        }
    }
    
    function checkAndSwapTokens(address _executor) internal {

        (uint256 sellToken, uint256 sellAmount) = calculateTokenAndAmountToSell();
        if(sellAmount == 0){
            return;
        }

        if(sellToken == 0){
            // We will sell wBTC for USDT
            lastTradeTimeSellVolatile = block.timestamp;

            uint256 gainAmount = tokenList[1].token.balanceOf(address(this));
            exchange(0, 1, sellAmount);
            gainAmount = tokenList[1].token.balanceOf(address(this)).sub(gainAmount);
            uint256 forWeth = gainAmount.mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR); // Take percentage from USDT gain
            if(forWeth> 0){
                exchange(1, WETH_ID, forWeth);
            }
        }else if(sellToken == 1){
            // We will sell USDT for wbtc
            lastTradeTimeBuyVolatile = block.timestamp;

            uint256 gainAmount = tokenList[0].token.balanceOf(address(this));
            exchange(1, 0, sellAmount);
            gainAmount = tokenList[0].token.balanceOf(address(this)).sub(gainAmount);
            uint256 forWeth = gainAmount.mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR); // Take percentage from wBTC gain
            if(forWeth > 0){
                exchange(0, WETH_ID, forWeth);
            }
        }

        // Update the price oracle
        updateLastPrice(true);
        lastTradeTime = block.timestamp;

        IERC20 weth = IERC20(WETH_ADDRESS);
        uint256 _wethBalance = weth.balanceOf(address(this));
        if(_wethBalance > 0){
            // Split the rest between the executor and buyback
            // This is pure profit, figure out allocation
            if(_executor != address(0)){
                // Executors will get a gas reimbursement in WETH and a percent of the remaining
                uint256 maxGasFee = gasPrice.mul(gasStipend); // This is gas stipend in wei
                uint256 gasFee = tx.gasprice.mul(gasStipend); // This is gas fee requested
                if(gasFee > maxGasFee){
                    gasFee = maxGasFee; // Gas fee cannot be greater than the maximum
                }
                uint256 executorAmount = gasFee;
                if(gasFee >= _wethBalance.mul(maxPercentStipend).div(DIVISION_FACTOR)){
                    executorAmount = _wethBalance.mul(maxPercentStipend).div(DIVISION_FACTOR); // The executor will get the entire amount up to point
                }else{
                    // Add the executor percent on top of gas fee
                    executorAmount = _wethBalance.sub(gasFee).mul(percentExecutor).div(DIVISION_FACTOR).add(gasFee);
                }
                if(executorAmount > 0){
                    // Convert to ETH
                    WETH(WETH_ADDRESS).withdraw(executorAmount); // Convert some WETH into 
                    _wethBalance = weth.balanceOf(address(this)); // Recalculate WETH in contract
                    payable(_executor).transfer(executorAmount); // Transfer to executor
                }
            }
            if(_wethBalance > 0){
                doSTBZBuyback(_wethBalance); // Buy STBZ with the WETH
            }     
        }
    }

    function doSTBZBuyback(uint256 _amount) internal {
        SushiLikeRouter router = SushiLikeRouter(SUSHI_ROUTER);
        address[] memory path = new address[](2);
        path[0] = WETH_ADDRESS;
        path[1] = STBZ_ADDRESS;
        IERC20(WETH_ADDRESS).safeApprove(address(router), 0);
        IERC20(WETH_ADDRESS).safeApprove(address(router), _amount);
        router.swapExactTokensForTokens(_amount, 1, path, address(this), now.add(60)); // Get STBZ
        uint256 _bal = IERC20(STBZ_ADDRESS).balanceOf(address(this));
        if(_bal > 0){
            IERC20(STBZ_ADDRESS).safeApprove(bankAddress, 0);
            IERC20(STBZ_ADDRESS).safeApprove(bankAddress, _bal);  
            StabilizeBank(bankAddress).depositSTBZ(zsTokenAddress, _bal); // This will pull the balance
        }
        return;
    }

    function updateLastPrice(bool forced) public {
        // This will update the last price if necessary
        if(forced == false){
            if(block.timestamp < lastTimePriceTaken.add(lastPricePeriod)) {return;} // Too soon to update the price
        }
        lastTimePriceTaken = block.timestamp;

        uint256 oldPrice = lastPrice;

        if(priceAverageMethod == 0){
            lastPrice = getBTCUSDPrice();
        }else if(priceAverageMethod == 1){
            // Use averages
            uint256 price = getBTCUSDPrice();
            lastPrice = lastPrice.add(price).div(2);
        }else if(priceAverageMethod == 2){
            // Use averages
            uint256 price = getSpotBTCPrice();
            lastPrice = lastPrice.add(price).div(2);            
        }

        // Now determine market direction
        uint256 deviation = 0;
        if(lastPrice > oldPrice){
            deviation = lastPrice.sub(oldPrice).mul(DIVISION_FACTOR).div(oldPrice);
        }else if(lastPrice < oldPrice){
            deviation = oldPrice.sub(lastPrice).mul(DIVISION_FACTOR).div(oldPrice);
        }

        if(deviation > minTradeVolatility){
            if(lastPrice > oldPrice){
                priceDirection = 1;
            }else{
                priceDirection = -1;
            }
        }else{
            priceDirection = 0;
        }
    }
    
    function executorSwapTokens(address _executor, uint256 _minSecSinceLastTrade, uint256 _deadlineTime) external {
        // Function designed to promote trading with incentive
        require(now <= _deadlineTime, "Deadline has expired, aborting trade");
        require(now.sub(lastTradeTime) >= _minSecSinceLastTrade, "The last trade was too recent");
        require(_msgSender() == tx.origin, "Contracts cannot interact with this function");
        checkAndSwapTokens(_executor);
    }
    
    // Governance functions
    function governanceSwapTokens() external onlyGovernance {
        // This is function that force trade tokens at anytime. It can only be called by governance
        checkAndSwapTokens(governance());
    }

    // --------------------
    function changeTradingConditions(uint256 _cooldown, 
                                    uint256 _pricePeriod,
                                    uint256 _minVolatility,
                                    uint256 _minSellAmount,
                                    uint256 _percentSell,
                                    uint256 _kFactor,
                                    uint256 _tradeMultiplier,
                                    uint256 _averageMethod) external onlyGovernance {
        // Changes a lot of trading parameters in one call
        require( _percentSell <= 100000,"Percent cannot be greater than 100%");
        require(_cooldown > 5 minutes, "Cool down must be greater than 5 minutes");
        coolDownTime = _cooldown;
        lastPricePeriod = _pricePeriod;
        minTradeVolatility = _minVolatility;
        percentSell = _percentSell;
        minSellAmount = _minSellAmount;
        kFactor = _kFactor;
        testTradeMultiplier = _tradeMultiplier;
        priceAverageMethod = _averageMethod;
    }
    // --------------------

    // --------------------
    function changeExecutorConditions(uint256 _percentExecutor,
                                    uint256 _pStipend,
                                    uint256 _gasPrice,
                                    uint256 _maxStipend) external onlyGovernance {
        // Changes a lot of parameters in one call
        require(_percentExecutor <= 100000 && _pStipend <= 100000,"Percent cannot be greater than 100%");
        percentExecutor = _percentExecutor;
        maxPercentStipend = _pStipend;
        gasPrice = _gasPrice;
        gasStipend = _maxStipend;
    }
    // --------------------
    
    // Remove a stuck token that is non-native
    function governanceRemoveStuckToken(address _token, uint256 _amount) external onlyGovernance {
        uint256 length = tokenList.length;
        for(uint256 i = 0; i < length; i++){
            require(_token != address(tokenList[i].token), "Cannot remove native token");
        }
        IERC20(_token).safeTransfer(governance(), _amount);
    }
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[3] private _timelock_data;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        if(balance() > 0){ // Timelock only applies when balance exists
            require(now >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
        }
        _;
    }
    
    // Change the owner of the token contract
    // --------------------
    function startGovernanceChange(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external onlyGovernance timelockConditionsMet(1) {
        transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the bank address
    // --------------------
    function startChangeBank(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeBank() external onlyGovernance timelockConditionsMet(2) {
        bankAddress = _timelock_address;
    }
    // --------------------
    
    // Change the zsToken address
    // --------------------
    function startChangeZSToken(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;
    }
    
    function finishChangeZSToken() external onlyGovernance timelockConditionsMet(3) {
        zsTokenAddress = _timelock_address;
    }
    // --------------------
    
    // Change the strategy allocations between the parties
    // --------------------
    
    function startChangeStrategyAllocation(uint256 _pDepositors) external onlyGovernance {
        // Changes strategy allocations in one call
        require(_pDepositors <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = now;
        _timelockType = 4;
        _timelock_data[0] = _pDepositors;
    }
    
    function finishChangeStrategyAllocation() external onlyGovernance timelockConditionsMet(4) {
        percentDepositor = _timelock_data[0];
    }
    // --------------------

    // Change the amount of max lag for the oracle
    // --------------------
    function startChangeOracleLag(uint256 _lag) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_data[0] = _lag;
    }
    
    function finishChangeOracleLag() external onlyGovernance timelockConditionsMet(5) {
        _maxOracleLag = _timelock_data[0];
    }
    // -------------------
}