/**
 *Submitted for verification at BscScan.com on 2021-07-08
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

// File: contracts/strategies/StandardStrategyArbV6.sol

pragma solidity =0.6.6;

interface StabilizeStakingPool {
    function notifyRewardAmount(uint256) external;
    function getTotalSTBB() external view returns (uint256);
    function getCurrentStrategy() external view returns (address);
}

interface PancakeRouter {
    function swapExactETHForTokens(uint, address[] calldata, address, uint) external payable returns (uint[] memory);
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory); // For a value in, it calculates value out
}

interface DodoExchange {
    function querySellBaseToken(uint256) external view returns (uint256);
    function queryBuyBaseToken(uint256) external view returns (uint256);
    function sellBaseToken(uint256, uint256, bytes calldata) external returns (uint256);
    function buyBaseToken(uint256, uint256, bytes calldata) external returns (uint256);
}

interface ValueLikeExchange{
    function calculateSwap(uint8, uint8, uint256) external view returns (uint256);
    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external returns (uint256);
}

interface CurveLikeExchange{
    function get_dy_underlying(int128, int128, uint256) external view returns (uint256);
    function get_dy(int128, int128, uint256) external view returns (uint256);
    function exchange_underlying(int128, int128, uint256, uint256) external; // Exchange tokens
    function exchange(int128, int128, uint256, uint256) external; // Exchange tokens
}

interface SmoothyExchange{
    function getSwapAmount(uint256 bTokenIdxIn, uint256 bTokenIdxOut, uint256 bTokenInAmount) external view returns (uint256 bTokenOutAmount);
    function swap(uint256 bTokenIdxIn, uint256 bTokenIdxOut, uint256 bTokenInAmount, uint256 bTokenOutMin) external;
    function getBalance(uint256 tid) external view returns (uint256);
}

interface StandardFlashModule{
    function checkFlashTrade(uint256) external view returns (uint256);
    function doFlashTrade(uint256) external;
}

// This will arb across multiple markets to find the best exchange and pair to trade. Designed to minimize gas costs for executors
// Will call the flash loan module for classic arbs

contract StandardStrategyArbV6 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    address public treasuryAddress; // Address of the treasury
    address public zsbTokenAddress; // The address of the controlling zsb-Token
    address public flashModuleAddress; // Proprietary flash loan module

    uint256 constant DIVISION_FACTOR = 100000;
    uint256 public gasPrice = 10e9; // Gas price in wei, changes sometimes on BSC

    uint256 public lastTradeTime;
    uint256 public lastActionBalance; // Balance before last deposit, withdraw or trade
    uint256 public percentTradeTrigger = 10000; // 10% change in value will trigger a trade
    uint256 public maxPercentSell = 100000; // 100% of the tokens are sold to the cheapest token
    uint256 public maxAmountSell = 500000; // The maximum amount of tokens that can be sold at once
    uint256 public percentDepositor = 50000; // 1000 = 1%, depositors earn 50% of all gains
    uint256 public percentFlashDepositor = 10000; // Depositors earn 10% from flash loan gains
    uint256 public percentExecutor = 10000; // 10000 = 10% of WBNB goes to executor on top of gas stipend
    uint256 public percentStakers = 50000; // 50000 = 50% of WBNB goes to strat stakers
    uint256 public maxPercentStipend = 50000; // The maximum amount of WBNB profit that can be allocated to the executor for gas in percent
    uint256 public gasStipend = 1000000; // This is the gas units that are covered by executing a trade taken from the WBNB profit    
    uint256 public minAmountProfit = 1e18; // Amount (normalized) profit needed to share profit with executors/treasury/stakers
    uint256 public minTradeSplit = 20000; // Minimum amount required before selling a percent of tokens

    // Token information
    // This strategy accepts multiple stablecoins
    // BUSD, DAI, USDC, USDT
    // All tokens are converted to BUSD when converted to WBNB
    struct TokenInfo {
        IERC20 token; // Reference of token
        uint256 decimals; // Decimals of token
        uint8 nerveID; // IDs for the different curve type exchanges
        int128 acryptoID;
        int128 ellipsisID;
        uint8[3] doppleID; // Dopple pools
    }
    
    TokenInfo[] private tokenList; // An array of tokens accepted as deposits
    
    // Strategy specific variables
    address constant WBNB_ADDRESS = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // WBNB address
    address constant PANCAKE_ROUTER = address(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Upgraded to version 2
    uint256 constant TEST_QUOTE = 10000;
    uint256 constant WBNB_TOKEN_ID = 4;
    
    // Exchanges
    address constant DODO_EXCHANGE_USDT_BUSD = address(0xBe60d4c4250438344bEC816Ec2deC99925dEb4c7);
    address constant DODO_EXCHANGE_BUSD_USDC = address(0x6064DBD0fF10BFeD5a797807042e9f63F18Cfe10);
    address constant NERVE_EXCHANGE = address(0x1B3771a66ee31180906972580adE9b81AFc5fCDc);
    address constant ACRYPTOS_EXCHANGE = address(0xb3F0C9ea1F05e312093Fdb031E789A756659B0AC);
    address constant ELLIPSIS_EXCHANGE = address(0x160CAed03795365F3A589f10C379FfA7d75d4E76);
    
    // The Dopple swaps addresses
    function getDopplePoolAddress(uint256 _id) internal pure returns (address) {
        address[3] memory dopplePools;
        dopplePools[0] = address(0x61f864a7dFE66Cc818a4Fd0baabe845323D70454);
        dopplePools[1] = address(0x830e287ac5947B1C0DA865dfB3Afd7CdF7900464);
        dopplePools[2] = address(0x449256e20ac3ed7F9AE81c2583068f7508d15c02);
        return dopplePools[_id];
    }
    
    // Exchange information
    uint256 constant EXCHANGE_COUNT = 8;
    
    constructor(
        address _treasury,
        address _zsbToken,
        address _flashModule
    ) public {
        treasuryAddress = _treasury;
        zsbTokenAddress = _zsbToken;
        flashModuleAddress = _flashModule;
        setupWithdrawTokens();
    }

    // Initialization functions
    
    function setupWithdrawTokens() internal {
        // Start with BUSD
        IERC20 _token = IERC20(address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                nerveID: 0,
                acryptoID: 0,
                ellipsisID: 0,
                doppleID: [0,1,0]
            })
        );   
        
        // DAI
        _token = IERC20(address(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                nerveID: 0,
                acryptoID: 2,
                ellipsisID: 0, // DAI not on Ellipsis
                doppleID: [0,0,0] // DAI not on Dopple
            })
        );
        
        // USDC
        _token = IERC20(address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                nerveID: 2,
                acryptoID: 3,
                ellipsisID: 1,
                doppleID: [0,0,0] // USDC not on Dopple
            })
        );
        
        // USDT
        _token = IERC20(address(0x55d398326f99059fF775485246999027B3197955));
        tokenList.push(
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                nerveID: 1,
                acryptoID: 1,
                ellipsisID: 2,
                doppleID: [1,2,1]
            })
        );
    }
    
    // Modifier
    modifier onlyZSBToken() {
        require(zsbTokenAddress == _msgSender(), "Call not sent from the zsb-Token");
        _;
    }
    
    // Read functions
    
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
            uint256 _bal = tokenList[i].token.balanceOf(_address);
            _bal = _bal.mul(1e18).div(10**tokenList[i].decimals);
            _balance = _balance.add(_bal); // This has been normalized to 1e18 decimals
        }
        return _balance;
    }
    
    function withdrawTokenReserves() public view returns (address, uint256) {
        // This function will return the address and amount of the token with the highest balance
        (uint256 targetID, uint256 _bal) = withdrawTokenReservesID();
        if(_bal == 0){
            return (address(0), _bal);
        }else{
            return (address(tokenList[targetID].token), _bal);
        }
    }
    
    function withdrawTokenReservesID() internal view returns (uint256, uint256) {
        // This function will return the address and amount of the token with the highest balance
        uint256 length = tokenList.length;
        uint256 targetID = 0;
        uint256 targetNormBalance = 0;
        for(uint256 i = 0; i < length; i++){
            uint256 _normBal = tokenList[i].token.balanceOf(address(this)).mul(1e18).div(10**tokenList[i].decimals);
            if(_normBal > 0){
                if(targetNormBalance == 0 || _normBal >= targetNormBalance){
                    targetNormBalance = _normBal;
                    targetID = i;
                }
            }
        }
        if(targetNormBalance > 0){
            return (targetID, tokenList[targetID].token.balanceOf(address(this)));
        }else{
            return (0, 0); // No balance
        }        
    }
    
    // Write functions
    
    function enter() external onlyZSBToken {
        deposit(false);
    }
    
    function exit() external onlyZSBToken {
        // The ZS token vault is removing all tokens from this strategy
        withdraw(_msgSender(),1,1, false);
    }
    
    function deposit(bool nonContract) public onlyZSBToken {
        // Only the ZS token can call the function
        
        // No trading is performed on deposit
        if(nonContract == true){}
        lastActionBalance = balance(); // This action balance represents pool post stablecoin deposit
    }
    
    function withdraw(address _depositor, uint256 _share, uint256 _total, bool nonContract) public onlyZSBToken returns (uint256) {
        require(balance() > 0, "There are no tokens in this strategy");
        if(nonContract == true){
            if(_share > _total.mul(percentTradeTrigger).div(DIVISION_FACTOR)){
                (uint256 _tokenID, ) = withdrawTokenReservesID(); // Get the most plentiful token
                (uint256 sellExchangeNum, uint256 targetID) = getExchanges(_tokenID);
                checkAndSwapToken(address(0), _tokenID, targetID, sellExchangeNum, false);
            }
        }
        
        uint256 withdrawAmount = 0;
        uint256 _balance = balance();
        if(_share < _total){
            uint256 _myBalance = _balance.mul(_share).div(_total);
            withdrawPerBalance(_depositor, _myBalance, false); // This will withdraw based on token balance
            withdrawAmount = _myBalance;
        }else{
            // We are all shares, transfer all
            withdrawPerBalance(_depositor, _balance, true);
            withdrawAmount = _balance;
        }       
        lastActionBalance = balance();
        
        return withdrawAmount;
    }
    
    // This will withdraw the tokens from the contract based on their balance, from highest balance to lowest
    function withdrawPerBalance(address _receiver, uint256 _withdrawAmount, bool _takeAll) internal {
        uint256 length = tokenList.length;
        if(_takeAll == true){
            // Send the entire balance
            for(uint256 i = 0; i < length; i++){
                uint256 _bal = tokenList[i].token.balanceOf(address(this));
                if(_bal > 0){
                    tokenList[i].token.safeTransfer(_receiver, _bal);
                }
            }
            return;
        }
        bool[] memory done = new bool[](length);
        uint256 targetID = 0;
        uint256 targetNormBalance = 0;
        for(uint256 i = 0; i < length; i++){
            
            targetNormBalance = 0; // Reset the target balance
            // Find the highest balanced token to withdraw
            for(uint256 i2 = 0; i2 < length; i2++){
                if(done[i2] == false){
                    uint256 _normBal = tokenList[i2].token.balanceOf(address(this)).mul(1e18).div(10**tokenList[i2].decimals);
                    if(targetNormBalance == 0 || _normBal >= targetNormBalance){
                        targetNormBalance = _normBal;
                        targetID = i2;
                    }
                }
            }
            done[targetID] = true;
            
            // Determine the balance left
            uint256 _normalizedBalance = tokenList[targetID].token.balanceOf(address(this)).mul(1e18).div(10**tokenList[targetID].decimals);
            if(_normalizedBalance <= _withdrawAmount){
                // Withdraw the entire balance of this token
                if(_normalizedBalance > 0){
                    _withdrawAmount = _withdrawAmount.sub(_normalizedBalance);
                    tokenList[targetID].token.safeTransfer(_receiver, tokenList[targetID].token.balanceOf(address(this)));                    
                }
            }else{
                // Withdraw a partial amount of this token
                if(_withdrawAmount > 0){
                    // Convert the withdraw amount to the token's decimal amount
                    uint256 _balance = _withdrawAmount.mul(10**tokenList[targetID].decimals).div(1e18);
                    _withdrawAmount = 0;
                    tokenList[targetID].token.safeTransfer(_receiver, _balance);
                }
                break; // Nothing more to withdraw
            }
        }
    }

    function simulateExchange(uint256 _idIn, uint256 _idOut, uint256 _amount, uint256 _exchangeNum) internal view returns (uint256) {
        if(_idOut == WBNB_TOKEN_ID){
            // We are trying to get WBNB
            PancakeRouter router = PancakeRouter(PANCAKE_ROUTER);
            address[] memory path;
            if(_idIn == 0){
                // Already BUSD
                path = new address[](2);
                path[0] = address(tokenList[_idIn].token);
                path[1] = WBNB_ADDRESS;
            }else{
                path = new address[](3);
                path[0] = address(tokenList[_idIn].token);
                path[1] = address(tokenList[0].token);
                path[2] = WBNB_ADDRESS;                
            }
            uint256[] memory estimates = router.getAmountsOut(_amount, path);
            _amount = estimates[estimates.length - 1]; // This is the amount of WETH returned
            return _amount;
        }else{
            
            // Current exchangess
            // 0 - DODO- USDT/BUSD
            // 1 - DODO- BUSD/USDC
            // 2 - NERVE - USDT/USDC/BUSD
            // 3 - ACRYPTOS - USDT/DAI/USDC/BUSD
            // 4 - ELLIPSIS - USDC/BUSD/USDT
            // 5 - DOPPLE
            // 6 - DOPPLE
            // 7 - DOPPLE

            if(_exchangeNum == 0){
                // This Dodex exchange has BUSD and USDT
                // Basetoken is BUSD
                if((_idIn != 0 && _idIn != 3) || (_idOut != 0 && _idOut != 3)){return 0;} // Can't trade
                DodoExchange router = DodoExchange(DODO_EXCHANGE_USDT_BUSD);
                if(_idIn == 0){
                    // Selling BUSD for USDT, straightforward
                    return router.querySellBaseToken(_amount);
                }else{
                    // Selling USDT for BUSD, use the inverse price
                    _amount = _amount.mul(10**tokenList[_idOut].decimals).div(10**tokenList[_idIn].decimals);
                    return _amount.mul(_amount).div(router.queryBuyBaseToken(_amount)).mul(99999).div(DIVISION_FACTOR);
                }
            }else if(_exchangeNum == 1){
                // This Dodex exchange has USDC and BUSD
                // Basetoken is USDC
                if((_idIn != 0 && _idIn != 2) || (_idOut != 0 && _idOut != 2)){return 0;} // Can't trade
                DodoExchange router = DodoExchange(DODO_EXCHANGE_BUSD_USDC);
                if(_idIn == 2){
                    // Selling USDC for BUSD, straightforward
                    return router.querySellBaseToken(_amount);
                }else{
                    // Selling BUSD for USDC, use the inverse price
                    _amount = _amount.mul(10**tokenList[_idOut].decimals).div(10**tokenList[_idIn].decimals);
                    return _amount.mul(_amount).div(router.queryBuyBaseToken(_amount)).mul(99999).div(DIVISION_FACTOR);
                }
            }else if(_exchangeNum == 2){
                // We use Nerve.fi which uses a form of Curve
                // Nerve doesn't support DAI
                if(_idIn == 1 || _idOut == 1){return 0;}
                ValueLikeExchange router = ValueLikeExchange(NERVE_EXCHANGE);
                return router.calculateSwap(tokenList[_idIn].nerveID, tokenList[_idOut].nerveID, _amount);
            }else if(_exchangeNum == 3){
                // We use Acryptos which uses a form of Curve
                CurveLikeExchange router = CurveLikeExchange(ACRYPTOS_EXCHANGE);
                return router.get_dy(tokenList[_idIn].acryptoID, tokenList[_idOut].acryptoID, _amount);
            }else if(_exchangeNum == 4){
                // This is for Ellipsis
                if(_idIn == 1 || _idOut == 1){return 0;} // Ellipsis doesn't support DAI
                CurveLikeExchange router = CurveLikeExchange(ELLIPSIS_EXCHANGE);
                return router.get_dy(tokenList[_idIn].ellipsisID, tokenList[_idOut].ellipsisID, _amount);
            }else if(_exchangeNum >= 5 && _exchangeNum <= 7){
                // We use Dopple which uses a derivative of Curve
                // All these pools are solo USDT/BUSD
                if(_idIn == 1 || _idOut == 1 || _idIn == 2 || _idOut == 2){return 0;} // DAI and USDC not supported
                uint256 _doppleID = _exchangeNum.sub(5);
                address doppleAddress = getDopplePoolAddress(_doppleID);
                ValueLikeExchange router = ValueLikeExchange(doppleAddress);
                return router.calculateSwap(tokenList[_idIn].doppleID[_doppleID], tokenList[_idOut].doppleID[_doppleID], _amount);
            }
        }            
    }
    
    function exchange(uint256 _idIn, uint256 _idOut, uint256 _amount, uint256 _exchangeNum) internal {
        if(_idOut == WBNB_TOKEN_ID){
            // We are trying to get WBNB
            PancakeRouter router = PancakeRouter(PANCAKE_ROUTER);
            address[] memory path;
            if(_idIn == 0){
                // Already BUSD
                path = new address[](2);
                path[0] = address(tokenList[_idIn].token);
                path[1] = WBNB_ADDRESS;
            }else{
                path = new address[](3);
                path[0] = address(tokenList[_idIn].token);
                path[1] = address(tokenList[0].token);
                path[2] = WBNB_ADDRESS;                
            }
            tokenList[_idIn].token.safeApprove(PANCAKE_ROUTER, 0);
            tokenList[_idIn].token.safeApprove(PANCAKE_ROUTER, _amount);
            router.swapExactTokensForTokens(_amount, 1, path, address(this), now.add(60)); // Get WBNB from token
            return; 
        }else{
            // Our route can take place on 6 exchanges
            if(_exchangeNum == 0){
                // Dodex exchange BUSD and USDT
                // Basetoken is BUSD
                if((_idIn != 0 && _idIn != 3) || (_idOut != 0 && _idOut != 3)){return;} // Can't trade
                DodoExchange router = DodoExchange(DODO_EXCHANGE_USDT_BUSD);
                tokenList[_idIn].token.safeApprove(DODO_EXCHANGE_USDT_BUSD, 0);
                tokenList[_idIn].token.safeApprove(DODO_EXCHANGE_USDT_BUSD, _amount);
                bytes memory nulldata;
                if(_idIn == 0){
                    // Selling BUSD for USDT, straightforward
                    router.sellBaseToken(_amount, 1, nulldata);
                }else{
                    // Selling USDT for BUSD, use the inverse price
                    // Reduce the buy amount slightly to allow it to sell
                    uint256 buyAmount = _amount.mul(10**tokenList[_idOut].decimals).div(10**tokenList[_idIn].decimals); // Convert to same decimals
                    buyAmount = buyAmount.mul(_amount).div(router.queryBuyBaseToken(buyAmount)).mul(99999).div(DIVISION_FACTOR);
                    router.buyBaseToken(buyAmount, _amount, nulldata);
                }
                return;
            }else if(_exchangeNum == 1){
                // Dodex exchange USDC and BUSD
                // Basetoken is USDC
                if((_idIn != 0 && _idIn != 2) || (_idOut != 0 && _idOut != 2)){return;} // Can't trade
                DodoExchange router = DodoExchange(DODO_EXCHANGE_BUSD_USDC);
                tokenList[_idIn].token.safeApprove(DODO_EXCHANGE_BUSD_USDC, 0);
                tokenList[_idIn].token.safeApprove(DODO_EXCHANGE_BUSD_USDC, _amount);
                bytes memory nulldata;
                if(_idIn == 2){
                    // Selling USDC for BUSD, straightforward
                    router.sellBaseToken(_amount, 1, nulldata);
                }else{
                    // Selling BUSD for USDC, use the inverse price
                    // Reduce the buy amount slightly to allow it to sell
                    uint256 buyAmount = _amount.mul(10**tokenList[_idOut].decimals).div(10**tokenList[_idIn].decimals); // Convert to same decimals
                    buyAmount = buyAmount.mul(_amount).div(router.queryBuyBaseToken(buyAmount)).mul(99999).div(DIVISION_FACTOR);
                    router.buyBaseToken(buyAmount, _amount, nulldata);
                }
                return;
            }else if(_exchangeNum == 2){
                // We use Nerve.fi which uses a form of Curve
                // Nerve doesn't support DAI
                if(_idIn == 1 || _idOut == 1){return;}
                ValueLikeExchange router = ValueLikeExchange(NERVE_EXCHANGE);
                tokenList[_idIn].token.safeApprove(NERVE_EXCHANGE, 0);
                tokenList[_idIn].token.safeApprove(NERVE_EXCHANGE, _amount);
                router.swap(tokenList[_idIn].nerveID, tokenList[_idOut].nerveID, _amount, 1, now.add(60));
                return;
            }else if(_exchangeNum == 3){
                // We use Acryptos which uses a form of Curve
                CurveLikeExchange router = CurveLikeExchange(ACRYPTOS_EXCHANGE);
                tokenList[_idIn].token.safeApprove(ACRYPTOS_EXCHANGE, 0);
                tokenList[_idIn].token.safeApprove(ACRYPTOS_EXCHANGE, _amount);
                router.exchange(tokenList[_idIn].acryptoID, tokenList[_idOut].acryptoID, _amount, 1);
                return;
            }else if(_exchangeNum == 4){
                // This is for Ellipsis
                if(_idIn == 1 || _idOut == 1){return;} // Ellipsis doesn't support DAI
                CurveLikeExchange router = CurveLikeExchange(ELLIPSIS_EXCHANGE);
                tokenList[_idIn].token.safeApprove(ELLIPSIS_EXCHANGE, 0);
                tokenList[_idIn].token.safeApprove(ELLIPSIS_EXCHANGE, _amount);
                router.exchange(tokenList[_idIn].ellipsisID, tokenList[_idOut].ellipsisID, _amount, 1);
                return;
            }else if(_exchangeNum >= 5 && _exchangeNum <= 7){
                // We use Dopple which uses a derivative of Curve
                // All these pools are solo USDT/BUSD
                if(_idIn == 1 || _idOut == 1 || _idIn == 2 || _idOut == 2){return;} // DAI and USDC not supported
                uint256 _doppleID = _exchangeNum.sub(5);
                address doppleAddress = getDopplePoolAddress(_doppleID);
                ValueLikeExchange router = ValueLikeExchange(doppleAddress);
                tokenList[_idIn].token.safeApprove(doppleAddress, 0);
                tokenList[_idIn].token.safeApprove(doppleAddress, _amount);
                router.swap(tokenList[_idIn].doppleID[_doppleID], tokenList[_idOut].doppleID[_doppleID], _amount, 1, now.add(60));
                return;
            }
        }
    }

    function getExchanges(uint256 _tokenID) internal view returns (uint256, uint256) {
        // Return values are best selling exchange, buying token
        // Get exchange and token with highest sell amount
        uint256 targetExchange = 0;
        uint256 targetToken = 0;
        uint256 mostTotalAmount = 0;
        uint256 length = tokenList.length;
        for(uint256 i = 0; i < length; i++){
            if(i == _tokenID){continue;}
            for(uint256 j = 0; j < EXCHANGE_COUNT; j++){
                uint256 estimate = simulateExchange(_tokenID, i, TEST_QUOTE * (10**tokenList[_tokenID].decimals), j);
                if(estimate > mostTotalAmount){
                    targetExchange = j;
                    targetToken = i;
                    mostTotalAmount = estimate;
                }
            }
        }
        return (targetExchange, targetToken);
    }
    
    // ---------------------
    
    function estimateSellAtMaximumProfit(uint256 originID, uint256 targetID, uint256 _tokenBalance, uint256 exchangeNum) internal view returns (uint256) {
        // This will estimate the amount that can be sold for the maximum profit possible
        // We discover the price then compare it to the actual return
        // The return must be positive to return a positive amount
        
        // Discover the price with near 0 slip
        uint256 _minAmount = _tokenBalance.mul(maxPercentSell.div(1000)).div(DIVISION_FACTOR);
        if(_minAmount == 0){ return 0; } // Nothing to sell, can't calculate
        uint256 _minReturn = _minAmount.mul(10**tokenList[targetID].decimals).div(10**tokenList[originID].decimals); // Convert decimals
        uint256 _return = simulateExchange(originID, targetID, _minAmount, exchangeNum);
        if(_return <= _minReturn){
            return 0; // We are not going to gain from this trade
        }
        _return = _return.mul(10**tokenList[originID].decimals).div(10**tokenList[targetID].decimals); // Convert to origin decimals
        uint256 _startPrice = _return.mul(1e18).div(_minAmount);
        
        // Now get the price at a higher amount, expected to be lower due to slippage
        uint256 _bigAmount = _tokenBalance.mul(maxPercentSell).div(DIVISION_FACTOR);
        _return = simulateExchange(originID, targetID, _bigAmount, exchangeNum);
        _return = _return.mul(10**tokenList[originID].decimals).div(10**tokenList[targetID].decimals); // Convert to origin decimals
        uint256 _endPrice = _return.mul(1e18).div(_bigAmount);
        if(_endPrice >= _startPrice){
            // Really good liquidity
            return _bigAmount;
        }
        
        // Else calculate amount at max profit
        uint256 scaleFactor = uint256(1).mul(10**tokenList[originID].decimals);
        uint256 _targetAmount = _startPrice.sub(1e18).mul(scaleFactor).div(_startPrice.sub(_endPrice).mul(scaleFactor).div(_bigAmount.sub(_minAmount))).div(2);
        if(_targetAmount > _bigAmount){
            // Cannot create an estimate larger than what we want to sell
            return _bigAmount;
        }
        return _targetAmount;
    }
    
    function checkAndSwapToken(address _executor, uint256 _tokenID, uint256 targetID, uint256 sellExchangeNum, bool doFlash) internal {
        require(_tokenID < tokenList.length && targetID < tokenList.length, "Token ID outside range");
        require(sellExchangeNum < EXCHANGE_COUNT, "Exchange number is outside range");
        if(doFlash == false){
            if(_tokenID == targetID){return;}
        }
        // To save even more gas, we require the executor to know which exchange they are selling tokens into
        lastTradeTime = now;
        
        // Now sell all the other tokens into this token
        uint256 _totalBalance = balance(); // Get the token balance at this contract, should increase

        bool _expectIncrease = false;
        uint256 _allocatedStipend = gasStipend;
        uint256 gain = 0;
        {
            if(doFlash == false){
                if(targetID != _tokenID){
                    // Just sell normally
                    uint256 sellBalance = 0;
                    uint256 _minTradeTarget = minTradeSplit.mul(10**tokenList[_tokenID].decimals);
                    uint256 _bal = tokenList[_tokenID].token.balanceOf(address(this));
                    if(_bal <= _minTradeTarget){
                        sellBalance = _bal;
                    }else{
                        sellBalance = estimateSellAtMaximumProfit(_tokenID, targetID, _bal, sellExchangeNum);
                    }
                    uint256 _maxTradeTarget = maxAmountSell.mul(10**tokenList[_tokenID].decimals);
                    if(sellBalance > _maxTradeTarget){
                        sellBalance = _maxTradeTarget;
                    }
                    if(sellBalance > 0){
                        uint256 minReceiveBalance = sellBalance.mul(10**tokenList[targetID].decimals).div(10**tokenList[_tokenID].decimals); // Change to match decimals of destination
                        uint256 estimate = simulateExchange(_tokenID, targetID, sellBalance, sellExchangeNum);
                        if(estimate > minReceiveBalance){
                            _expectIncrease = true;
                            // We are getting a greater number of tokens, complete the exchange
                            exchange(_tokenID, targetID, sellBalance, sellExchangeNum);
                        }
                    }
                }
            }else{
                _expectIncrease = true;
                StandardFlashModule(flashModuleAddress).doFlashTrade(_tokenID); // Outsource classic arbs
                targetID = _tokenID; // The gain will be in the same token we borrow
                _allocatedStipend = _allocatedStipend.mul(3); // Give more gas for flash loans
            }
        }
        
        uint256 _newBalance = balance();
        if(_expectIncrease == true){
            // There may be rare scenarios where we don't gain any by calling this function
            require(_newBalance > _totalBalance, "Failed to gain in balance from selling tokens");
        }
        
        gain = _newBalance.sub(_totalBalance);
        if(gain > minAmountProfit){
            uint256 sellBalance = gain.mul(10**tokenList[targetID].decimals).div(1e18);
            if(doFlash == false){
                sellBalance = sellBalance.mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR);
            }else{
                sellBalance = sellBalance.mul(DIVISION_FACTOR.sub(percentFlashDepositor)).div(DIVISION_FACTOR);
            }
            if(sellBalance <= tokenList[targetID].token.balanceOf(address(this))){
                exchange(targetID, WBNB_TOKEN_ID, sellBalance, 0); // This is params for WBNB buy
            }
        }
        
        // Now take some gain bnb and distribute it to executor, stakers and treasury
        IERC20 bnb = IERC20(WBNB_ADDRESS);
        uint256 bnbBalance = bnb.balanceOf(address(this));
        if(bnbBalance > 0){
            // This is pure profit, figure out allocation
            // Split the amount sent to the treasury, stakers and executor if one exists
            if(_executor != address(0)){
                uint256 gasFee = gasPrice.mul(_allocatedStipend);
                uint256 executorAmount = gasFee;
                if(gasFee >= bnbBalance.mul(maxPercentStipend).div(DIVISION_FACTOR)){
                    executorAmount = bnbBalance.mul(maxPercentStipend).div(DIVISION_FACTOR); // The executor will get the entire amount up to point
                }else{
                    // Add the executor percent on top of gas fee
                    executorAmount = bnbBalance.sub(gasFee).mul(percentExecutor).div(DIVISION_FACTOR).add(gasFee);
                }
                if(executorAmount > 0){
                    bnb.safeTransfer(_executor, executorAmount);
                    bnbBalance = bnb.balanceOf(address(this)); // Recalculate BNB in contract           
                }
            }
            if(bnbBalance > 0){
                uint256 stakersAmount = bnbBalance.mul(percentStakers).div(DIVISION_FACTOR);
                uint256 treasuryAmount = bnbBalance.sub(stakersAmount);
                if(treasuryAmount > 0){
                    bnb.safeTransfer(treasuryAddress, treasuryAmount);
                }
                if(stakersAmount > 0){
                    bool sendToStaking = true;
                    if(zsbTokenAddress == address(0)){
                        // No staking pool exists
                        sendToStaking = false;
                    }else{
                        // Staking pool exists
                        if(StabilizeStakingPool(zsbTokenAddress).getTotalSTBB() == 0){
                            // There are no tokens at the staking pool
                            sendToStaking = false;
                        }
                        if(StabilizeStakingPool(zsbTokenAddress).getCurrentStrategy() != address(this)){
                            // This strategy cannot send tokens to the token vault
                            sendToStaking = false;
                        }
                    }
                    if(sendToStaking == true){
                        bnb.safeTransfer(zsbTokenAddress, stakersAmount);
                        StabilizeStakingPool(zsbTokenAddress).notifyRewardAmount(stakersAmount);                                
                    }else{
                        bnb.safeTransfer(treasuryAddress, stakersAmount);
                    }
                }
            }
        }
    }
    
    // Accepts 1) bool whether to show us executor profit, 2) uint256 token ID to sell, 3) check if flash loan available
    // Returns 1) uint256 profit as wei units BNB or wei units total profit depending on inWBNBforExecutor
    // Returns 2) uint256 targetID to buy
    // Returns 3) uint256 exchangeID to buy token on
    // Returns 4) uint256 blocknumber of data returned
    function expectedProfit(bool inWBNBForExecutor, uint256 _tokenID, bool checkFlash) external view returns (uint256,uint256,uint256,uint256) {
        require(_tokenID < tokenList.length, "Token ID outside range");
        // This view will return the expected profit in wei units that a trading activity will have on the pool
        // It will also return the exchange to sell the token into the target token
        
        // Now sell all the other tokens into this token
        uint256 _normalizedGain = 0;
        uint256 sellExchangeNum;
        uint256 targetID;
        uint256 _allocatedStipend = gasStipend;

        {
            // Go through the token and find the best exchange to trade it
            (sellExchangeNum, targetID) = getExchanges(_tokenID);
            if(checkFlash == false){
                if(targetID != _tokenID){
                    // Just sell normally
                    uint256 sellBalance = 0;
                    uint256 _bal = tokenList[_tokenID].token.balanceOf(address(this));
                    if(_bal <= minTradeSplit.mul(10**tokenList[_tokenID].decimals)){
                        sellBalance = _bal;
                    }else{
                        sellBalance = estimateSellAtMaximumProfit(_tokenID, targetID, _bal, sellExchangeNum);
                    }
                    if(sellBalance > maxAmountSell.mul(10**tokenList[_tokenID].decimals)){
                        sellBalance = maxAmountSell.mul(10**tokenList[_tokenID].decimals);
                    }
                    if(sellBalance > 0){
                        uint256 minReceiveBalance = sellBalance.mul(10**tokenList[targetID].decimals).div(10**tokenList[_tokenID].decimals); // Change to match decimals of destination
                        uint256 estimate = simulateExchange(_tokenID, targetID, sellBalance, sellExchangeNum);
                        if(estimate > minReceiveBalance){
                            uint256 _gain = estimate.sub(minReceiveBalance).mul(1e18).div(10**tokenList[targetID].decimals); // Normalized gain
                            _normalizedGain = _normalizedGain.add(_gain);
                        }         
                    }
                }
                
                if(_normalizedGain <= minAmountProfit){
                    // Set to 0 if gain is not enough
                    _normalizedGain = 0;
                }
            }else{
                _normalizedGain = StandardFlashModule(flashModuleAddress).checkFlashTrade(_tokenID); // Gain in borrowed token
                targetID = _tokenID;
                _allocatedStipend = _allocatedStipend.mul(3);
            }
        }

        if(inWBNBForExecutor == false){
            return (_normalizedGain,  targetID, sellExchangeNum, block.number);
        }else{
            if(_normalizedGain == 0){
                return (0,  targetID, sellExchangeNum, block.number);
            }
            // Calculate how much BNB the executor would make as profit
            uint256 estimate = 0;
            if(_normalizedGain > 0){
                uint256 sellBalance = _normalizedGain.mul(10**tokenList[targetID].decimals).div(1e18); // Convert to target decimals
                if(checkFlash == false){
                    sellBalance = sellBalance.mul(DIVISION_FACTOR.sub(percentDepositor)).div(DIVISION_FACTOR);
                }else{
                    sellBalance = sellBalance.mul(DIVISION_FACTOR.sub(percentFlashDepositor)).div(DIVISION_FACTOR);
                }
                // Estimate output
                estimate = simulateExchange(targetID, WBNB_TOKEN_ID, sellBalance, 0);           
            }                
            // Now calculate the amount going to the executor
            uint256 gasFee = gasPrice.mul(_allocatedStipend); // This is gas stipend in wei
            if(gasFee >= estimate.mul(maxPercentStipend).div(DIVISION_FACTOR)){ // Max percent of total
                return (estimate.mul(maxPercentStipend).div(DIVISION_FACTOR),  targetID, sellExchangeNum, block.number); // The executor will get max percent of total
            }else{
                estimate = estimate.sub(gasFee); // Subtract fee from remaining balance
                return (estimate.mul(percentExecutor).div(DIVISION_FACTOR).add(gasFee),  targetID, sellExchangeNum, block.number); // Executor amount with fee added
            }
        }
    }
    
    // Accepts 1) address that profit will go to, 2) uint256 minimum amount of seconds required between this swap and last
    // 3) uint256 blocknumber that trade will expire after
    // 4) uint256 tokenID for token we want to sell, 5) uint256 tokenID of the token we want to buy, 6) uint256 exchange that we want to use to sell
    // 7) bool whether to execute via flash loan
    function executorSwapTokens(address _executor, uint256 _minSecSinceLastTrade, uint256 _deadlineBlock,
                                uint256 _sellToken, uint256 _buyToken, uint256 _sellExchangeNum, bool doFlash) external {
        require(block.number <= _deadlineBlock, "Deadline has expired, aborting trade");
        // Function designed to promote trading with incentive. Users get percentage of WBNB from profitable trades
        require(now.sub(lastTradeTime) >= _minSecSinceLastTrade, "The last trade was too recent");
        require(_msgSender() == tx.origin, "Contracts cannot interact with this function");
        checkAndSwapToken(_executor, _sellToken,  _buyToken, _sellExchangeNum, doFlash);
    }
    
    // Governance functions
    function governanceSwapTokens(uint256 _sellToken, uint256 _buyToken, uint256 _sellExchangeNum, bool doFlash) external onlyGovernance {
        // This is function that force trade tokens at anytime. It can only be called by governance
        checkAndSwapToken(_msgSender(), _sellToken,  _buyToken, _sellExchangeNum, doFlash);
    }
    
    // Change the trading conditions used by the strategy without timelock
    // --------------------
    function changeTradingConditions(uint256 _pTradeTrigger, 
                                    uint256 _pSellPercent, 
                                    uint256 _maxSell,
                                    uint256 _gasPrice,
                                    uint256 _pStipend,
                                    uint256 _maxStipend,
                                    uint256 _minProfit) external onlyGovernance {
        // Changes a lot of trading parameters in one call
        require(_pTradeTrigger <= 100000 && _pSellPercent <= 100000 && _pStipend <= 100000,"Percent cannot be greater than 100%");
        percentTradeTrigger = _pTradeTrigger;
        maxPercentSell = _pSellPercent;
        maxAmountSell = _maxSell;
        maxPercentStipend = _pStipend;
        gasStipend = _maxStipend;
        minAmountProfit = _minProfit;
        gasPrice = _gasPrice;
    }
    // --------------------
    
    // Timelock variables
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    address private _timelock_address;
    uint256[4] private _timelock_data;
    
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
    
    // Change the zsbToken address
    // --------------------
    function startChangeZSBToken(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_address = _address;
    }
    
    function finishChangeZSBToken() external onlyGovernance timelockConditionsMet(3) {
        zsbTokenAddress = _timelock_address;
    }
    // --------------------
    
    // Change the strategy allocations between the parties
    // --------------------
    
    function startChangeStrategyAllocations(uint256 _pDepositors, uint256 _pFDepositors, uint256 _pStakers, uint256 _pExecutor) external onlyGovernance {
        // Changes strategy allocations in one call
        require(_pDepositors <= 100000 && _pExecutor <= 100000 && _pStakers <= 100000 && _pFDepositors <= 100000,"Percent cannot be greater than 100%");
        _timelockStart = now;
        _timelockType = 4;
        _timelock_data[0] = _pDepositors;
        _timelock_data[1] = _pExecutor;
        _timelock_data[2] = _pStakers;
        _timelock_data[3] = _pFDepositors;
    }
    
    function finishChangeStrategyAllocations() external onlyGovernance timelockConditionsMet(4) {
        percentDepositor = _timelock_data[0];
        percentExecutor = _timelock_data[1];
        percentStakers = _timelock_data[2];
        percentFlashDepositor = _timelock_data[3];
    }
    // --------------------
    
    // Change the flash module
    // --------------------
    function startChangeFlashModule(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_address = _address;
    }
    
    function finishChangeFlashModule() external onlyGovernance timelockConditionsMet(5) {
        flashModuleAddress = _timelock_address;
    }
    // --------------------
}