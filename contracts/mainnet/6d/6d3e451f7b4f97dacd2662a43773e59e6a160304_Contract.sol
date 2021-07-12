/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

//SPDX-License-Identifier: MIT


/*

FairShare

I was testing some ideas on a fair lottery token on ropsten then i saw the EverShare contract. We have some similar ideas so i tweaked my token a bit.

This token save fees in the contract & send to a random single holder wallet in the community every 120-180 mins.

More info:

    - Stealth / fair launch with small liquidity.
    - There is a max tx (buy / sell) & 1 block cooldown to stop bots.
    - A wallet can not hold more than 1.5% total supply.
    - Fees of transactions will stay in the contract as lottery pool, the prize is sent out every 120-180 mins (appro.) to a random single holder wallet.
    - 2% burn fee
    - 8% dev fee (50% lottery pool, 50% shared wallet)

For traders:

    - Total supply: 1 000 000 000 000
    - Max tx (buy/sell): 3 000 000 000
    - Max wallet amount: 15 000 000 000
    - Slippage: 12-15%

Lottery rules:

    - Minimum amount of tokens to be eligible for lottery: 2 000 000 000
    - If you bought and have not sold, you are eligible.
    - Sellers are a part of the token so to be fair, i don't exclude them completely from the lottery prize but there are some punishments:
        - If you sell any amount and your final balance has less than 500 000 000 tokens, you are blacklisted from lottery
        - If you sell any amount and your final balance has more than 500 000 000 tokens, your wallet will be flagged, you can only win 5% of the prize if you are selected by the contract (next draw will have bigger prize, i like EuroMillions style)
        - A seller can only win once, then the wallet is blacklisted from lottery

This is a community token, I will lock LP & renounce ownership.

    - 100% tokens & 1.5-2 ETH will be put in liquidity, 0 dev tokens, 0 burnt. (why burn tokens if you can lower the initial supply on creation ...)
    - I will initially lock all LP in the contract for 7 days.
    - If this token takes off, i will extend the lock / burn liquidity.
    - If this token fails, i will remove the locked liquidity after it unlocks.

Little advertisement:

    - My friend created a new TG group for discussion about new ideas / tokenomics for meme coins: t.me/new_idea_meme, feel free to join & discuss.

Good luck & have fun
*/

pragma solidity ^0.6.12;


interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract Contract is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    struct PlayerInfo {
        bool included;
        bool reduced;
        uint256 index;
    }

    struct Payout {
        address addr;
        uint256 amount;
        uint256 time;
    }

    // uniswap & trading
    address internal constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool public tradingOpen = false;
    bool private _inSwap = false;
    mapping (address => uint256) private _timestamp;
    uint256 private _coolDown = 15 seconds;

    // token
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    uint256 public constant maxTxAmount = 3000 * 10 ** 6 * 10 ** 9;
    uint256 public constant maxWalletAmount = 15000 * 10 ** 6 * 10 ** 9;
    uint256 public constant minHoldForLottery = 2000 * 10 ** 6 * 10 ** 9;
    uint256 public constant minHoldSellerForLottery = 500 * 10 ** 6 * 10 ** 9;
    uint256 private constant _totalSupply = 1000000 * 10 ** 6 * 10 ** 9;
    string private constant _name = 'Fair Share';
    string private constant _symbol = 'FairShare';
    uint8 private constant _decimals = 9;
    uint256 public burnFee = 2; // 2% burn
    uint256 public devFee = 8; // 8% dev (50% lottery pool, 50% shared wallet)
    uint256 private _previousBurnFee = burnFee;
    uint256 private _previousDevFee = devFee;
    address payable private _sharedWallet;
    address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD;

    // for liquidity lock
    uint256 public releaseTime = block.timestamp;

    // lottery
    address[] private _lotteryPlayers;
    Payout[] public lotteryPayout;
    Payout public lastLotteryPayout;
    mapping(address => bool) public isBlacklistedFromLottery;
    mapping(address => PlayerInfo) private _lotteryPlayersInfo;
    uint256 public lotteryBalance = 0;
    uint256 public timeBetweenLotteryDraw = 180;
    uint256 public lastLotteryDraw = block.timestamp;

    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor() public {
        _sharedWallet = _msgSender();
        _balances[address(this)] = _totalSupply;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;

        // blacklist contract & burn addr from lottery
        isBlacklistedFromLottery[address(this)] = true;
        isBlacklistedFromLottery[_burnAddress] = true;

        emit Transfer(address(0), address(this), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true; 
    }
        
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function isReducedLotteryPrize(address account) public view returns(bool) {
        return _lotteryPlayersInfo[account].reduced;
    }

    function isLotteryPlayer(address account) public view returns(bool) {
        return _lotteryPlayersInfo[account].included;
    }

    function nbLotteryPlayer() external view returns(uint256) {
        return _lotteryPlayers.length;
    }

    function nbLotteryPayout() external view returns(uint256) {
        return lotteryPayout.length;
    }

    /**
     * @dev Return next lottery draw time
     */
    function nextLotteryDraw() external view returns (uint256) {
        return lastLotteryDraw + timeBetweenLotteryDraw * 1 minutes;
    }

    /**
     * @dev Extends the lock of LP in contract
     */
    function lockLp(uint256 newReleaseTime) external {
        require(_msgSender() == _sharedWallet || _msgSender() == owner(), "You are not allowed to call this function");
        require(newReleaseTime > releaseTime, "You can only extend LP lock time");

        releaseTime = newReleaseTime;
    }

    /**
     * @dev Release LP when its unlock
     */
    function releaseLp() external {
        require(_msgSender() == _sharedWallet || _msgSender() == owner(), "You are not allowed to call this function");
        require(releaseTime < now, "LP still locked");

        IERC20(uniswapV2Pair).transfer(_sharedWallet, IERC20(uniswapV2Pair).balanceOf(address(this)));
    }

    /**
     * @dev Burn LP when its unlock (send all LP to burn address)
     */
    function burnLp() external {
        require(_msgSender() == _sharedWallet || _msgSender() == owner(), "You are not allowed to call this function");

        IERC20(uniswapV2Pair).transfer(_burnAddress, IERC20(uniswapV2Pair).balanceOf(address(this)));
    }

    /**
     * @dev Create uniswap pair, add liquidity & open trading
     */
    function openTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already enabled / opened");

        uniswapV2Router = IUniswapV2Router02(ROUTER_ADDRESS);

        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        // blacklist uniswap addr from lottery
        isBlacklistedFromLottery[ROUTER_ADDRESS] = true;
        isBlacklistedFromLottery[uniswapV2Pair]  = true;

        // add liquidity
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, address(this), now + 600);

        // open trading
        tradingOpen = true;

        // lock liquidity
        releaseTime = now + 7 days;

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (! isExcludedFromFee[sender] && ! isExcludedFromFee[recipient]) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

            if (recipient != uniswapV2Pair) {
                require(amount.add(balanceOf(recipient)) <= maxWalletAmount, "Wallet amount exceeds the maxWalletAmount");
            }
        }

        if (sender == uniswapV2Pair) {
            //they just bought so add 1 block cooldown - fuck you frontrunners
            _timestamp[recipient] = block.timestamp.add(_coolDown);
        }

        if (! isExcludedFromFee[sender] && sender != uniswapV2Pair) {
            require(block.timestamp >= _timestamp[sender], "Cooldown");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 minOfTokensToExchangeForDev = _getMinOfTokensToExchangeForDev();

        if (minOfTokensToExchangeForDev > maxTxAmount) {
            minOfTokensToExchangeForDev = maxTxAmount;
        }

        if (!_inSwap && tradingOpen && sender!= uniswapV2Pair && contractTokenBalance >= minOfTokensToExchangeForDev) {
            _swapTokensForEth(minOfTokensToExchangeForDev);

            _sendETHToFee(address(this).balance);
        }

        bool takeFee = true;

        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]){
            takeFee = false;
        }

        _tokenTransfer(sender,recipient,amount,takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            _removeAllFee();

        _transferStandard(sender, recipient, amount);

        if(!takeFee)
            _restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tDev, uint256 tBurn) = _getValues(tAmount);

        _balances[sender]    = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);

        _takeAllFee(tDev);
        _sendBurnFee(sender, tBurn);

        // buyer has more than `minHoldForLottery` tokens
        if (_balances[recipient] >= minHoldForLottery) {
            // add new addr to lottery pool
            if (! isLotteryPlayer(recipient) && ! isBlacklistedFromLottery[recipient]) {
                _lotteryPlayers.push(recipient);
                _lotteryPlayersInfo[recipient] = PlayerInfo(true, false, _lotteryPlayers.length - 1);
            }
        }

        // seller has more than `minHoldSellerForLottery` tokens
        if (_balances[sender] >= minHoldSellerForLottery && ! isBlacklistedFromLottery[sender]) {
            if (! isLotteryPlayer(sender)) {
                _lotteryPlayers.push(sender);
                _lotteryPlayersInfo[sender] = PlayerInfo(true, true, _lotteryPlayers.length - 1);
            } else {
                _lotteryPlayersInfo[sender].reduced = true;
            }
        }

        // seller has lass than `minHoldSellerForLottery` tokens
        if (_balances[sender] < minHoldSellerForLottery && ! isBlacklistedFromLottery[sender]) {
            _blacklistFromLottery(sender);
        }

        // draw
        if (block.timestamp >= lastLotteryDraw + timeBetweenLotteryDraw * 1 minutes) {
            _sendLotteryPrize();
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _removeAllFee() private {
        if(burnFee == 0 && devFee == 0) return;

        _previousBurnFee = burnFee;
        _previousDevFee = devFee;
        burnFee = 0;
        devFee = 0;
    }

    function _restoreAllFee() private {
        burnFee = _previousBurnFee;
        devFee = _previousDevFee;
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            _approve(address(this), address(uniswapV2Router), tokenAmount);

            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function _sendETHToFee(uint256 amount) private lockTheSwap {
        if (amount > lotteryBalance) {
            uint256 change = amount.sub(lotteryBalance);

            _sharedWallet.transfer(change.div(2));
            lotteryBalance = lotteryBalance.add(change.div(2));
        }
    }

    function _sendLotteryPrize() private {
        if (_lotteryPlayers.length > 0 && lotteryBalance > 0) {
            uint256 prize = lotteryBalance;
            uint256 index = _semiRandom() % _lotteryPlayers.length;
            address winner = _lotteryPlayers[index];
            address payable target = payable(winner);

            if (isReducedLotteryPrize(winner)) {
                prize = lotteryBalance.div(20);
            }

            target.transfer(prize);

            lastLotteryPayout = Payout(winner, prize, block.timestamp);
            lotteryPayout.push(lastLotteryPayout);

            // reset lastdraw
            lastLotteryDraw = block.timestamp;

            // reset random time between draw
            timeBetweenLotteryDraw = _randtimeBetweenLotteryDraw();

            // seller can only win once
            if (isReducedLotteryPrize(winner)) {
                _blacklistFromLottery(winner);
            }

            // update lottery balance
            lotteryBalance = lotteryBalance.sub(prize);
        }
    }

    function _takeAllFee(uint256 tFee) private {
        if (tFee > 0) {
            _balances[address(this)] = _balances[address(this)].add(tFee);
        }
    }

    function _sendBurnFee(address sender, uint256 tFee) private {
        if (tFee > 0) {
            _balances[_burnAddress] = _balances[_burnAddress].add(tFee);

            emit Transfer(sender, _burnAddress, tFee);
        }
    }

    function _getMinOfTokensToExchangeForDev() private view returns (uint256) {
        (uint256 tokens, , ) = IUniswapV2Pair(uniswapV2Pair).getReserves();

        return tokens.div(100);
    }

    function _blacklistFromLottery(address addr) private {
        isBlacklistedFromLottery[addr] = true;

        if (_lotteryPlayers.length == 1) {
            _lotteryPlayers.pop();

            if (isLotteryPlayer(addr)) {
                _lotteryPlayersInfo[addr].included = false;
            }
        }

        if (_lotteryPlayers.length > 1 && isLotteryPlayer(addr)) {
            uint256 index   = _lotteryPlayersInfo[addr].index;
            address newAddr = _lotteryPlayers[_lotteryPlayers.length - 1];

            if (index < _lotteryPlayers.length) {
                _lotteryPlayers[index] = newAddr;
                
                if (isLotteryPlayer(newAddr)) {
                    _lotteryPlayersInfo[newAddr].index = index;
                }
            }

            _lotteryPlayers.pop();
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tDev = tAmount.mul(devFee).div(100);
        uint256 tBurn = tAmount.mul(burnFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tDev).sub(tBurn);

        return (tTransferAmount, tDev, tBurn);
    }

    function _semiRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                block.timestamp + block.difficulty +
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                block.gaslimit +
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
                block.number,
                _lotteryPlayers
            )));
    }

    /**
     * @dev return 120-180 randomly
     */
    function _randtimeBetweenLotteryDraw() private view returns(uint256) {
        uint256 seed = _semiRandom();

        return 120 + seed % 61;
    }

    receive() external payable {}
}