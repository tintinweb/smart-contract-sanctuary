/**
 *Submitted for verification at Etherscan.io on 2021-02-21
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

// File: contracts/strategies/StabilizeStrategyStablecoinArbV3.sol

pragma solidity ^0.6.6;

// This is iteration 3 of the strategy

// This is a strategy that takes advantage of arb opportunities for multiple stablecoins
// Users deposit various stables into the strategy and the strategy will sell into the lowest priced token
// In addition to that, the pool will earn interest in the form of aTokens from Aave
// Selling will occur via Curve and buying WETH via Sushiswap
// Half the profit earned from the sell and interest will be used to buy WETH and split it among the treasury, stakers and executor
// Half will remain as stables (in the form of aTokens)
// It will sell on withdrawals only when a non-contract calls it and certain requirements are met
// Anyone can be an executors and profit a percentage on a trade
// Gas cost is reimbursed, up to a percentage of the total WETH profit / stipend
// This strategy doesn't store stables but rather interest earning variants (aTokens)

interface StabilizeStakingPool {
    function notifyRewardAmount(uint256) external;
}

interface StabilizePriceOracle {
    function getPrice(address _address) external view returns (uint256);
}

interface CurvePool {
    function get_dy(int128, int128, uint256) external view returns (uint256); // Get quantity estimate
    function exchange(int128, int128, uint256, uint256) external; // Exchange tokens
}

interface TradeRouter {
    function swapExactETHForTokens(uint, address[] calldata, address, uint) external payable returns (uint[] memory);
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory); // For a value in, it calculates value out
}

interface AggregatorV3Interface {
  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

interface LendingPool {
  function withdraw(address, uint256, address) external returns (uint256);
  function deposit(address, uint256, address, uint16) external;
}

interface StrategyVault {
    function viewWETHProfit(uint256) external view returns (uint256);
    function sendWETHProfit() external;
}

contract StabilizeStrategyStablecoinArbV3 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public treasuryAddress; // Address of the treasury
    address public stakingAddress; // Address to the STBZ staking pool
    address public zsTokenAddress; // The address of the controlling zs-Token
    address public strategyVaultAddress; // This strategy stores interest aTokens in separate vault
    
    uint256 constant DIVISION_FACTOR = 100000;

    uint256 public lastTradeTime;
    uint256 public lastActionBalance; // Balance before last deposit, withdraw or trade
    uint256 public percentTradeTrigger = 90000; // 90% change in value will trigger a trade
    uint256 public percentSell = 50000; // 50% of the tokens are sold to the cheapest token
    uint256 public percentDepositor = 50000; // 1000 = 1%, depositors earn 50% of all gains (including interest)
    uint256 public percentExecutor = 10000; // 10000 = 10% of WETH goes to executor
    uint256 public percentStakers = 50000; // 50% of non-executor WETH goes to stakers, can be changed, rest goes to treasury
    uint256 public minTradeSplit = 20000; // If the balance of a stablecoin is less than or equal to this, it trades the entire balance
    uint256 public maxPercentStipend = 30000; // The maximum amount of WETH profit that can be allocated to the executor for gas in percent
    uint256 public gasStipend = 1000000; // This is the gas units that are covered by executing a trade taken from the WETH profit
    uint256 constant minGain = 1e16; // Minimum amount of stablecoin gain (about 0.01 USD) before buying WETH and splitting it
    
    // Token information
    // This strategy accepts multiple stablecoins
    // DAI, USDC, USDT, sUSD
    struct TokenInfo {
        IERC20 token; // Reference of token
        IERC20 aToken; // Reference to its aToken (Aave v2)
        uint256 decimals; // Decimals of token
        uint256 price; // Last price of token in USD
        uint256 lastATokenBalance; // The balance the last time the interest was calculated
    }
    
    TokenInfo[] private tokenList; // An array of tokens accepted as deposits
    StabilizePriceOracle private oracleContract; // A reference to the price oracle contract
    
    // Strategy specific variables
    address constant CURVE_DAI_SUSD = address(0xEB16Ae0052ed37f479f7fe63849198Df1765a733); // Curve pool for 2 tokens, asUSD, aDAI
    address constant CURVE_ATOKEN_3 = address(0xDeBF20617708857ebe4F679508E7b7863a8A8EeE); // Curve pool for 3 tokens, aDAI, aUSDT, aUSDC
    address constant SUSHISWAP_ROUTER = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); //Address of Sushiswap
    address constant WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant GAS_ORACLE_ADDRESS = address(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C); // Chainlink address for fast gas oracle
    address constant LENDING_POOL_ADDRESS_PROVIDER = address(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); // Provider for Aave addresses

    constructor(
        address _treasury,
        address _staking,
        address _zsToken,
        StabilizePriceOracle _oracle
    ) public {
        treasuryAddress = _treasury;
        stakingAddress = _staking;
        zsTokenAddress = _zsToken;
        oracleContract = _oracle;
        setupWithdrawTokens();
    }

    // Initialization functions
    
    function setupWithdrawTokens() internal {
        // Start with DAI
        IERC20 _token = IERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
        IERC20 _aToken = IERC20(address(0x028171bCA77440897B824Ca71D1c56caC55b68A3)); // aDAI
        tokenList.push(
            TokenInfo({
                token: _token,
                aToken: _aToken,
                decimals: _token.decimals(), // Aave tokens share decimals with normal tokens
                price: 1e18,
                lastATokenBalance: 0
            })
        );   
        
        // USDC
        _token = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        _aToken = IERC20(address(0xBcca60bB61934080951369a648Fb03DF4F96263C)); // aUSDC
        tokenList.push(
            TokenInfo({
                token: _token,
                aToken: _aToken,
                decimals: _token.decimals(),
                price: 1e18,
                lastATokenBalance: 0
            })
        );
        
        // USDT
        _token = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        _aToken = IERC20(address(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811)); // aUSDT
        tokenList.push(
            TokenInfo({
                token: _token,
                aToken: _aToken,
                decimals: _token.decimals(),
                price: 1e18,
                lastATokenBalance: 0
            })
        );
        
        // sUSD
        _token = IERC20(address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51));
        _aToken = IERC20(address(0x6C5024Cd4F8A59110119C56f8933403A539555EB)); //aSUSD
        tokenList.push(
            TokenInfo({
                token: _token,
                aToken: _aToken,
                decimals: _token.decimals(),
                price: 1e18,
                lastATokenBalance: 0
            })
        );
    }
    
    // Modifier
    modifier onlyZSToken() {
        require(zsTokenAddress == _msgSender(), "Call not sent from the zs-Token");
        _;
    }
    
    // Read functions
    
    // This excludes the interest earned before being processed
    // Show this on the user's 
    function effectivePricePerToken() external view returns (uint256) {
        if(zsTokenAddress == address(0)){
            return 0;
        }
        uint256 supply = IERC20(zsTokenAddress).totalSupply();
        if(supply == 0){
            return 1e18; // Shown in Wei units
        }else{
            return uint256(1e18).mul(lastActionBalance).div(supply);      
        }
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
    
    function getNormalizedTotalBalance(address _address) public view returns (uint256) {
        // Get the balance of the atokens+tokens at this address
        uint256 _balance = 0;
        uint256 _length = tokenList.length;
        for(uint256 i = 0; i < _length; i++){
            uint256 _bal = tokenList[i].aToken.balanceOf(_address).add(tokenList[i].token.balanceOf(_address));
            _bal = _bal.mul(1e18).div(10**tokenList[i].decimals);
            _balance = _balance.add(_bal); // This has been normalized to 1e18 decimals
        }
        return _balance;
    }
    
    function withdrawTokenReserves() public view returns (address, uint256) {
        // This function will return the address and amount of the token with the lowest price
        uint256 length = tokenList.length;
        uint256 targetID = 0;
        uint256 targetPrice = 0;
        for(uint256 i = 0; i < length; i++){
            if(tokenList[i].aToken.balanceOf(address(this)) > 0){
                uint256 _price = tokenList[i].price;
                if(targetPrice == 0 || _price <= targetPrice){
                    targetPrice = _price;
                    targetID = i;
                }
            }
        }
        if(targetPrice > 0){
            return (address(tokenList[targetID].token), tokenList[targetID].aToken.balanceOf(address(this)));
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
        
        // First the interest earned since the last call will be calculated
        // Some will sent to a strategy vault to be later processed when it becomes large enough
        calculateAndStoreInterest(); // This function will also call an update to lastATokenBalance
        
        // Then convert deposited stablecoins into their aToken equivalents and updates lastATokenBalance
        convertAllToAaveTokens();
        
        // No trading is performed on deposit
        if(nonContract == true){}
        lastActionBalance = balance(); // This action balance represents pool post stablecoin deposit
    }
    
    function withdraw(address _depositor, uint256 _share, uint256 _total, bool nonContract) public onlyZSToken returns (uint256) {
        require(balance() > 0, "There are no tokens in this strategy");
        // First the interest earned since the last call will be calculated and sent to vault
        calculateAndStoreInterest();
        
        // This is in case there are some leftover raw tokens
        convertAllToAaveTokens();
        
        if(nonContract == true){
            if(_share > _total.mul(percentTradeTrigger).div(DIVISION_FACTOR)){
                checkAndSwapTokens(address(0)); // This will also not call calculateAndHold due to 0 address
            }
        }
        
        uint256 withdrawAmount = 0;
        uint256 _balance = balance();
        if(_share < _total){
            uint256 _myBalance = _balance.mul(_share).div(_total);
            withdrawPerPrice(_depositor, _myBalance, false); // This will withdraw based on token price
            withdrawAmount = _myBalance;
        }else{
            // We are all shares, transfer all
            withdrawPerPrice(_depositor, _balance, true);
            withdrawAmount = _balance;
        }
        lastActionBalance = balance();
        
        return withdrawAmount;
    }
    
    // Get price from chainlink oracle
    function updateTokenPrices() internal {
        uint256 length = tokenList.length;
        for(uint256 i = 0; i < length; i++){
            uint256 price = oracleContract.getPrice(address(tokenList[i].token));
            if(price > 0){
                tokenList[i].price = price;
            }
        }        
    }
    
    // This will withdraw the tokens from the contract based on their price, from lowest price to highest
    function withdrawPerPrice(address _receiver, uint256 _withdrawAmount, bool _takeAll) internal {
        uint256 length = tokenList.length;
        uint256 _balance = 0;
        if(_takeAll == true){
            // We will empty out the strategy
            for(uint256 i = 0; i < length; i++){
                _balance = tokenList[i].aToken.balanceOf(address(this));
                if(_balance > 0){
                    // Convert the entire a tokens to token
                    convertFromAToken(i, _balance);
                    tokenList[i].lastATokenBalance = tokenList[i].aToken.balanceOf(address(this));
                }
                _balance = tokenList[i].token.balanceOf(address(this));
                if(_balance > 0){
                    // Now send the normal token back
                    tokenList[i].token.safeTransfer(_receiver, _balance);
                }
            }
            return;
        }
        bool[4] memory done;
        uint256 targetID = 0;
        uint256 targetPrice = 0;
        updateTokenPrices(); // Update the prices based on an off-chain Oracle
        for(uint256 i = 0; i < length; i++){
            targetPrice = 0; // Reset the target price
            // Find the lowest priced token to withdraw
            for(uint256 i2 = 0; i2 < length; i2++){
                if(done[i2] == false){
                    uint256 _price = tokenList[i2].price;
                    if(targetPrice == 0 || _price <= targetPrice){
                        targetPrice = _price;
                        targetID = i2;
                    }
                }
            }
            done[targetID] = true;
            
            // Determine the balance left
            uint256 _normalizedBalance = tokenList[targetID].aToken.balanceOf(address(this)).mul(1e18).div(10**tokenList[targetID].decimals);
            if(_normalizedBalance <= _withdrawAmount){
                // Withdraw the entire balance of this token
                if(_normalizedBalance > 0){
                    _withdrawAmount = _withdrawAmount.sub(_normalizedBalance);
                    _balance = tokenList[targetID].aToken.balanceOf(address(this));
                    convertFromAToken(targetID, _balance);
                    tokenList[i].lastATokenBalance = tokenList[i].aToken.balanceOf(address(this));
                    tokenList[targetID].token.safeTransfer(_receiver, _balance);                    
                }
            }else{
                // Withdraw a partial amount of this token
                if(_withdrawAmount > 0){
                    // Convert the withdraw amount to the token's decimal amount
                    _balance = _withdrawAmount.mul(10**tokenList[targetID].decimals).div(1e18);
                    _withdrawAmount = 0;
                    convertFromAToken(targetID, _balance);
                    tokenList[i].lastATokenBalance = tokenList[i].aToken.balanceOf(address(this));
                    tokenList[targetID].token.safeTransfer(_receiver, _balance);
                }
                break; // Nothing more to withdraw
            }
        }
    }
    
    function convertFromAToken(uint256 _id, uint256 amount) internal {
        // This will take the aToken and convert it to main token to be used for whatever
        // It will require that the amount returned is greater than or equal to amount requested
        uint256 _balance = tokenList[_id].token.balanceOf(address(this));
        LendingPool lender = LendingPool(LendingPoolAddressesProvider(LENDING_POOL_ADDRESS_PROVIDER).getLendingPool()); // Load the lending pool
        tokenList[_id].aToken.safeApprove(address(lender), 0);
        tokenList[_id].aToken.safeApprove(address(lender), amount);
        lender.withdraw(address(tokenList[_id].token), amount, address(this));
        require(amount >= tokenList[_id].token.balanceOf(address(this)).sub(_balance), "Aave failed to withdraw the proper balance");
    }
    
    function convertToAToken(uint256 _id, uint256 amount) internal {
        // This will take the token and convert it to atoken to be used for whatever
        // It will require that the amount returned is greater than or equal to amount requested
        uint256 _balance = tokenList[_id].aToken.balanceOf(address(this));
        LendingPool lender = LendingPool(LendingPoolAddressesProvider(LENDING_POOL_ADDRESS_PROVIDER).getLendingPool()); // Load the lending pool
        tokenList[_id].token.safeApprove(address(lender), 0);
        tokenList[_id].token.safeApprove(address(lender), amount);
        lender.deposit(address(tokenList[_id].token), amount, address(this), 0);
        require(amount >= tokenList[_id].aToken.balanceOf(address(this)).sub(_balance), "Aave failed to return proper amount of aTokens");
    }
    
    function convertAllToAaveTokens() internal {
        // Convert stables to interest earning variants
        uint256 length = tokenList.length;
        uint256 _balance = 0;
        for(uint256 i = 0; i < length; i++){
            _balance = tokenList[i].token.balanceOf(address(this));
            if(_balance > 0){
                // Convert the entire token to a token
                convertToAToken(i, _balance);
            }
            // Now update its balance
            tokenList[i].lastATokenBalance = tokenList[i].aToken.balanceOf(address(this));
        }        
    }
    
    function simulateExchange(address _inputToken, address _outputToken, uint256 _amount) internal view returns (uint256) {
        if(_outputToken != WETH_ADDRESS){
            // When not selling for WETH, we are only dealing with aTokens
            
            // aSUSD only can buy and sell for aDAI due to gas costs of deployment and loops
            // 0 - aDAI, 1 - aUSDC, 2 - aUSDT, 3 - aSUSD
            uint256 inputID = 0;
            uint256 outputID = 0;
            uint256 length = tokenList.length;
            for(uint256 i = 0; i < length; i++){
                if(_inputToken == address(tokenList[i].aToken)){
                    inputID = i;
                }
                if(_outputToken == address(tokenList[i].aToken)){
                    outputID = i;
                }
            }
            if(inputID == outputID){return 0;}
            if(inputID == 3 || outputID == 3){
                // Just 1 pool
                int128 inCurveID = 0; // aDAI in
                int128 outCurveID = 0; // aDAI out
                if(inputID == 3) {inCurveID = 1;} // aUSDT in
                if(outputID == 3){outCurveID = 1;} // aUSDC out
                CurvePool pool = CurvePool(CURVE_DAI_SUSD);
                _amount = pool.get_dy(inCurveID, outCurveID, _amount);
                return _amount;          
            }else{
                // Just 1 pool
                int128 inCurveID = 0; // aDAI in
                int128 outCurveID = 0; // aDAI out
                if(inputID == 1) {inCurveID = 1;} // aUSDC in
                if(inputID == 2) {inCurveID = 2;} // aUSDT in
                if(outputID == 1){outCurveID = 1;} // aUSDC out
                if(outputID == 2){outCurveID = 2;} // aUSDT out
                CurvePool pool = CurvePool(CURVE_ATOKEN_3);
                _amount = pool.get_dy(inCurveID, outCurveID, _amount);
                return _amount;
            }
        }else{
            // Simple Sushiswap route
            // When selling for WETH, we must have already converted aToken to token
            // All stables have liquid path to WETH
            TradeRouter router = TradeRouter(SUSHISWAP_ROUTER);
            address[] memory path = new address[](2);
            path[0] = _inputToken;
            path[1] = WETH_ADDRESS;
            uint256[] memory estimates = router.getAmountsOut(_amount, path);
            _amount = estimates[estimates.length - 1];
            return _amount;
        }
    }
    
    function exchange(address _inputToken, address _outputToken, uint256 _amount) internal {
        if(_outputToken != WETH_ADDRESS){
            // When not selling for WETH, we are only dealing with aTokens
            
            // aSUSD only can buy and sell for aDAI
            // 0 - aDAI, 1 - aUSDC, 2 - aUSDT, 3 - aSUSD
            uint256 inputID = 0;
            uint256 outputID = 0;
            uint256 length = tokenList.length;
            for(uint256 i = 0; i < length; i++){
                if(_inputToken == address(tokenList[i].aToken)){
                    inputID = i;
                }
                if(_outputToken == address(tokenList[i].aToken)){
                    outputID = i;
                }
            }
            if(inputID == outputID){return;}
            if(inputID == 3 || outputID == 3){
                // We are dealing with aSUSD
                int128 inCurveID = 0; // aDAI in
                int128 outCurveID = 0; // aDAI out
                if(inputID == 3) {inCurveID = 1;} // aUSDT in
                if(outputID == 3){outCurveID = 1;} // aUSDC out
                CurvePool pool = CurvePool(CURVE_DAI_SUSD);
                IERC20(_inputToken).safeApprove(CURVE_DAI_SUSD, 0);
                IERC20(_inputToken).safeApprove(CURVE_DAI_SUSD, _amount);
                pool.exchange(inCurveID, outCurveID, _amount, 1);
                return;
            }else{
                // Just 1 pool
                int128 inCurveID = 0; // DAI in
                int128 outCurveID = 0; // DAI out
                if(inputID == 1) {inCurveID = 1;} // USDC in
                if(inputID == 2) {inCurveID = 2;} // USDT in
                if(outputID == 1){outCurveID = 1;} // USDC out
                if(outputID == 2){outCurveID = 2;} // USDT out
                CurvePool pool = CurvePool(CURVE_ATOKEN_3);
                IERC20(_inputToken).safeApprove(CURVE_ATOKEN_3, 0);
                IERC20(_inputToken).safeApprove(CURVE_ATOKEN_3, _amount);
                pool.exchange(inCurveID, outCurveID, _amount, 1);
                return;
            }
        }else{
            // Simple Sushiswap route
            // When selling for WETH, we must have already converted aToken to token
            // All stables have liquid path to WETH
            TradeRouter router = TradeRouter(SUSHISWAP_ROUTER);
            address[] memory path = new address[](2);
            path[0] = _inputToken;
            path[1] = WETH_ADDRESS;
            IERC20(_inputToken).safeApprove(SUSHISWAP_ROUTER, 0);
            IERC20(_inputToken).safeApprove(SUSHISWAP_ROUTER, _amount);
            router.swapExactTokensForTokens(_amount, 1, path, address(this), now.add(60)); // Get WETH from token
            return;
        }
    }
    
    function getCheapestCurveToken() internal view returns (uint256) {
        // This will give us the ID of the cheapest token in the pool
        // And it will tell us if aDAI is higher valued than aSUSD
        // We will estimate the return for trading 1000 aDAI
        // The higher the return, the lower the price of the other token
        uint256 targetID = 0; // Our target ID is aDAI first
        uint256 aDaiAmount = uint256(1000).mul(10**tokenList[0].decimals);
        uint256 highAmount = aDaiAmount;
        uint256 length = tokenList.length;
        for(uint256 i = 1; i < length; i++){
            uint256 estimate = simulateExchange(address(tokenList[0].aToken), address(tokenList[i].aToken), aDaiAmount);
            // Normalize the estimate into DAI decimals
            estimate = estimate.mul(10**tokenList[0].decimals).div(10**tokenList[i].decimals);
            if(estimate > highAmount){
                // This token is worth less than the aDAI
                highAmount = estimate;
                targetID = i;
            }
        }
        return targetID;
    }
    
    function calculateAndStoreInterest() internal {
        // This function will take the difference between the last aToken balance and current and distribute some of it to the strategy vault
        uint256 length = tokenList.length;
        uint256 _balance = 0;
        for(uint256 i = 0; i < length; i++){
            _balance = tokenList[i].aToken.balanceOf(address(this)); // Get the current balance
            if(_balance > tokenList[i].lastATokenBalance){
                uint256 chargeableGain = _balance.sub(tokenList[i].lastATokenBalance).mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR);
                // Convert the chargeableGain to token then to WETH
                if(chargeableGain > 0){
                    // Instead of convert aTokens to weth right away, store them in a separate contract, saving gas
                    tokenList[i].aToken.safeTransfer(strategyVaultAddress, chargeableGain);
                }
            }
            tokenList[i].lastATokenBalance = tokenList[i].aToken.balanceOf(address(this)); // The the current aToken amount
        }
    }
    
    function calculateAndViewInterest() internal view returns (uint256) {
        // This function will take the difference between the last aToken balance and current and return the calculated normalized interest gain
        uint256 length = tokenList.length;
        uint256 _balance = 0;
        uint256 gain = 0; 
        for(uint256 i = 0; i < length; i++){
            _balance = tokenList[i].aToken.balanceOf(address(this)); // Get the current balance
            if(_balance > tokenList[i].lastATokenBalance){
                // Just normalize the difference into gain
                gain = gain.add(_balance.sub(tokenList[i].lastATokenBalance).mul(1e18).div(10**tokenList[i].decimals));
            }
        }
        
        // Gain will be normalized and represent total gain from interest
        return gain;
    }
    
    function getFastGasPrice() internal view returns (uint256) {
        AggregatorV3Interface gasOracle = AggregatorV3Interface(GAS_ORACLE_ADDRESS);
        ( , int intGasPrice, , , ) = gasOracle.latestRoundData(); // We only want the answer 
        return uint256(intGasPrice);
    }
    
    function checkAndSwapTokens(address _executor) internal {
        lastTradeTime = now;
        if(_executor != address(0)){
            calculateAndStoreInterest(); // It will send aTokens to strategy vault
        }
        
        StrategyVault vault = StrategyVault(strategyVaultAddress);
        vault.sendWETHProfit(); // This will request the vault convert and send WETH to the strategy to be distributed
        
        // Now find our target token to sell into
        uint256 targetID = getCheapestCurveToken(); // Curve may have a slightly different cheap token than Chainlink
        uint256 length = tokenList.length;
        
        // Now sell all the other tokens into this token
        uint256 _totalBalance = balance(); // Get the token balance at this contract, should increase
        bool _expectIncrease = false;
        for(uint256 i = 0; i < length; i++){
            if(i != targetID){
                uint256 localTarget = targetID;
                if(i == 0){
                    localTarget = 3; // aDAI will only sell for aSUSD as they switch often
                }else if(i == 3){
                    localTarget = 0; // aSUSD will only sell for aDAI
                }else{
                    if(localTarget == 3){continue;} // Other tokens can't buy aSUSD via curve
                }
                uint256 sellBalance = 0;
                uint256 _minTradeTarget = minTradeSplit.mul(10**tokenList[i].decimals);
                if(tokenList[i].aToken.balanceOf(address(this)) <= _minTradeTarget){
                    // We have a small amount of tokens to sell, so sell all of it
                    sellBalance = tokenList[i].aToken.balanceOf(address(this));
                }else{
                    sellBalance = tokenList[i].aToken.balanceOf(address(this)).mul(percentSell).div(DIVISION_FACTOR);
                }
                uint256 minReceiveBalance = sellBalance.mul(10**tokenList[localTarget].decimals).div(10**tokenList[i].decimals); // Change to match decimals of destination
                if(sellBalance > 0){
                    uint256 estimate = simulateExchange(address(tokenList[i].aToken), address(tokenList[localTarget].aToken), sellBalance);
                    if(estimate > minReceiveBalance){
                        _expectIncrease = true;
                        // We are getting a greater number of tokens, complete the exchange
                        exchange(address(tokenList[i].aToken), address(tokenList[localTarget].aToken), sellBalance);
                    }                        
                }
            }
        }
        uint256 _newBalance = balance();
        if(_expectIncrease == true){
            // There may be rare scenarios where we don't gain any by calling this function
            require(_newBalance > _totalBalance, "Failed to gain in balance from selling tokens");
        }
        uint256 gain = _newBalance.sub(_totalBalance);
        IERC20 weth = IERC20(WETH_ADDRESS);
        uint256 _wethBalance = weth.balanceOf(address(this));
        if(gain >= minGain || _wethBalance > 0){
            // Minimum gain required to buy WETH is about $0.01
            if(gain >= minGain){
                // Buy WETH from Sushiswap with stablecoin
                uint256 sellBalance = gain.mul(10**tokenList[targetID].decimals).div(1e18);
                uint256 holdBalance = sellBalance.mul(percentDepositor).div(DIVISION_FACTOR);
                sellBalance = sellBalance.sub(holdBalance); // We will buy WETH with this amount
                if(sellBalance <= tokenList[targetID].aToken.balanceOf(address(this))){
                    // Convert from aToken to Token
                    convertFromAToken(targetID, sellBalance);
                    // Buy WETH
                    exchange(address(tokenList[targetID].token), WETH_ADDRESS, sellBalance);
                    _wethBalance = weth.balanceOf(address(this));
                }
            }
            if(_wethBalance > 0){
                // This is pure profit, figure out allocation
                // Split the amount sent to the treasury, stakers and executor if one exists
                if(_executor != address(0)){
                    // Executors will get a gas reimbursement in WETH and a percent of the remaining
                    uint256 maxGasFee = getFastGasPrice().mul(gasStipend); // This is gas stipend in wei
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
                        weth.safeTransfer(_executor, executorAmount);
                        _wethBalance = weth.balanceOf(address(this)); // Recalculate WETH in contract           
                    }
                }
                if(_wethBalance > 0){
                    uint256 stakersAmount = _wethBalance.mul(percentStakers).div(DIVISION_FACTOR);
                    uint256 treasuryAmount = _wethBalance.sub(stakersAmount);
                    if(treasuryAmount > 0){
                        weth.safeTransfer(treasuryAddress, treasuryAmount);
                    }
                    if(stakersAmount > 0){
                        if(stakingAddress != address(0)){
                            weth.safeTransfer(stakingAddress, stakersAmount);
                            StabilizeStakingPool(stakingAddress).notifyRewardAmount(stakersAmount);                                
                        }else{
                            // No staking pool selected, just send to the treasury
                            weth.safeTransfer(treasuryAddress, stakersAmount);
                        }
                    }
                }
            }
        }
        for(uint256 i = 0; i < length; i++){
            // Now run this through again and update all the token balances to prevent being affected by interest calculator
            tokenList[i].lastATokenBalance = tokenList[i].aToken.balanceOf(address(this));
        }
    }
    
    function expectedProfit(bool inWETHForExecutor) external view returns (uint256) {
        // This view will return the expected profit in wei units that a trading activity will have on the pool
        
        uint256 interestGain = 0;
        if(inWETHForExecutor == true){
            interestGain = calculateAndViewInterest(); // Will return total gain (normalized)
            StrategyVault vault = StrategyVault(strategyVaultAddress);
            // The first param is used to determine if interest earned will bring it over threshold
            interestGain = interestGain.add(vault.viewWETHProfit(interestGain)); // Will return profit as WETH
        }

        // Now find our target token to sell into
        uint256 targetID = getCheapestCurveToken(); // Curve may have a slightly different cheap token than Chainlink
        uint256 length = tokenList.length;
        
        // Now sell all the other tokens into this token
        uint256 _normalizedGain = 0;
        for(uint256 i = 0; i < length; i++){
            if(i != targetID){
                uint256 localTarget = targetID;
                if(i == 0){
                    localTarget = 3; // aDAI will only sell for aSUSD as they switch often
                }else if(i == 3){
                    localTarget = 0; // aSUSD will only sell for aDAI
                }else{
                    if(localTarget == 3){continue;} // Other tokens can't buy aSUSD via curve
                }
                uint256 sellBalance = 0;
                uint256 _minTradeTarget = minTradeSplit.mul(10**tokenList[i].decimals);
                if(tokenList[i].aToken.balanceOf(address(this)) <= _minTradeTarget){
                    // We have a small amount of tokens to sell, so sell all of it
                    sellBalance = tokenList[i].aToken.balanceOf(address(this));
                }else{
                    sellBalance = tokenList[i].aToken.balanceOf(address(this)).mul(percentSell).div(DIVISION_FACTOR);
                }
                uint256 minReceiveBalance = sellBalance.mul(10**tokenList[localTarget].decimals).div(10**tokenList[i].decimals); // Change to match decimals of destination
                if(sellBalance > 0){
                    uint256 estimate = simulateExchange(address(tokenList[i].aToken), address(tokenList[localTarget].aToken), sellBalance);
                    if(estimate > minReceiveBalance){
                        uint256 _gain = estimate.sub(minReceiveBalance).mul(1e18).div(10**tokenList[localTarget].decimals); // Normalized gain
                        _normalizedGain = _normalizedGain.add(_gain);
                    }                        
                }
            }
        }
        if(inWETHForExecutor == false){
            return _normalizedGain.add(interestGain);
        }else{
            // Calculate WETH profit
            if(_normalizedGain.add(interestGain) == 0){
                return 0;
            }
            // Calculate how much WETH the executor would make as profit
            uint256 estimate = interestGain; // WETH earned from interest alone
            if(_normalizedGain > 0){
                uint256 sellBalance = _normalizedGain.mul(10**tokenList[targetID].decimals).div(1e18); // Convert to target decimals
                uint256 holdBalance = sellBalance.mul(percentDepositor).div(DIVISION_FACTOR);
                sellBalance = sellBalance.sub(holdBalance); // We will buy WETH with this amount
                // Estimate output
                estimate = estimate.add(simulateExchange(address(tokenList[targetID].token), WETH_ADDRESS, sellBalance));           
            }
            // Now calculate the amount going to the executor
            uint256 gasFee = getFastGasPrice().mul(gasStipend); // This is gas stipend in wei
            if(gasFee >= estimate.mul(maxPercentStipend).div(DIVISION_FACTOR)){ // Max percent of total
                return estimate.mul(maxPercentStipend).div(DIVISION_FACTOR); // The executor will get max percent of total
            }else{
                estimate = estimate.sub(gasFee); // Subtract fee from remaining balance
                return estimate.mul(percentExecutor).div(DIVISION_FACTOR).add(gasFee); // Executor amount with fee added
            }
        }
    }
    
    function executorSwapTokens(address _executor, uint256 _minSecSinceLastTrade) external {
        // Function designed to promote trading with incentive. Users get percentage of WETH from profitable trades
        require(now.sub(lastTradeTime) > _minSecSinceLastTrade, "The last trade was too recent");
        require(_msgSender() == tx.origin, "Contracts cannot interact with this function");
        checkAndSwapTokens(_executor);
        lastActionBalance = balance();
    }
    
    // Governance functions
    function governanceSwapTokens() external onlyGovernance {
        // This is function that force trade tokens at anytime. It can only be called by governance
        checkAndSwapTokens(_msgSender());
        lastActionBalance = balance();
    }
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[6] private _timelock_data;
    
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
    
    // Change the treasury address
    // --------------------
    function startChangeTreasury(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_address = _address;
    }
    
    function finishChangeTreasury() external onlyGovernance timelockConditionsMet(2) {
        treasuryAddress = _timelock_address;
    }
    // --------------------
    
    // Change the staking address
    // --------------------
    function startChangeStakingPool(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;
    }
    
    function finishChangeStakingPool() external onlyGovernance timelockConditionsMet(3) {
        stakingAddress = _timelock_address;
    }
    // --------------------
    
    // Change the zsToken address
    // --------------------
    function startChangeZSToken(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 4;
        _timelock_address = _address;
    }
    
    function finishChangeZSToken() external onlyGovernance timelockConditionsMet(4) {
        zsTokenAddress = _timelock_address;
    }
    // --------------------
    
    // Change the price oracle contract used, in case of upgrades
    // --------------------
    function startChangePriceOracle(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_address = _address;
    }
    
    function finishChangePriceOracle() external onlyGovernance timelockConditionsMet(5) {
        oracleContract = StabilizePriceOracle(_timelock_address);
    }
    // --------------------
    
    // Change the trading conditions used by the strategy
    // --------------------
    
    function startChangeTradingConditions(uint256 _pTradeTrigger, uint256 _pSellPercent,  uint256 _minSplit, uint256 _maxStipend, uint256 _pMaxStipend) external onlyGovernance {
        // Changes a lot of trading parameters in one call
        require(_pTradeTrigger <= 100000 && _pSellPercent <= 100000 && _pMaxStipend <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = now;
        _timelockType = 6;
        _timelock_data[0] = _pTradeTrigger;
        _timelock_data[1] = _pSellPercent;
        _timelock_data[2] = _minSplit;
        _timelock_data[3] = _maxStipend;
        _timelock_data[4] = _pMaxStipend;
    }
    
    function finishChangeTradingConditions() external onlyGovernance timelockConditionsMet(6) {
        percentTradeTrigger = _timelock_data[0];
        percentSell = _timelock_data[1];
        minTradeSplit = _timelock_data[2];
        gasStipend = _timelock_data[3];
        maxPercentStipend = _timelock_data[4];
    }
    // --------------------
    
    
    // Change the strategy allocations between the parties
    // --------------------
    
    function startChangeStrategyAllocations(uint256 _pDepositors, uint256 _pExecutor, uint256 _pStakers) external onlyGovernance {
        // Changes strategy allocations in one call
        require(_pDepositors <= 100000 && _pExecutor <= 100000 && _pStakers <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = now;
        _timelockType = 7;
        _timelock_data[0] = _pDepositors;
        _timelock_data[1] = _pExecutor;
        _timelock_data[2] = _pStakers;
    }
    
    function finishChangeStrategyAllocations() external onlyGovernance timelockConditionsMet(7) {
        percentDepositor = _timelock_data[0];
        percentExecutor = _timelock_data[1];
        percentStakers = _timelock_data[2];
    }
    // --------------------
    
    // Remove tokens not used in strategy from strategy
    // --------------------
    function startRecoverTrappedToken(address _token) external onlyGovernance {
        uint256 length = tokenList.length;
        // Can only remove non-strategy tokens
        for(uint256 i = 0; i < length; i++){
            require(_token != address(tokenList[i].token) && _token != address(tokenList[i].aToken), "Can only extract non-native tokens from strategy");
        }
        _timelockStart = now;
        _timelockType = 8;   
        _timelock_address = _token;
    }
    
    function finishRecoverTrappedToken() external onlyGovernance timelockConditionsMet(8) {
        IERC20 token = IERC20(_timelock_address);
        token.safeTransfer(governance(), token.balanceOf(address(this)));
    }
    // --------------------
    
    // Change the strategy vault address
    // --------------------
    function startChangeStrategyVault(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 9;
        _timelock_address = _address;
    }
    
    function finishChangeStrategyVault() external onlyGovernance timelockConditionsMet(9) {
        strategyVaultAddress = _timelock_address;
    }
    // --------------------
    
}