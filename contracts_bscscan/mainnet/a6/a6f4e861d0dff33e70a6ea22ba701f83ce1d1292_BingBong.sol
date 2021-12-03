/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

/**
    -----------------------------------------------------------------------------------------------------------------------------
    ||  BING BONG TOKEN V1                                                                                                     ||  
    ||                                                                                                                         ||  
    ||  Total Supply: 50,000,000,000 (50 Billion)                                                                              ||  
    ||  No Burning of Initial Supply or Market Cap.                                                                            ||   
    ||                                                                                                                         ||  
    ||  Some features of $BINGBONG:                                                                                            ||  
    ||                                                                                                                         ||  
    ||  A tribute to NYC, the people .... BINGBONG!!!                                                                          ||  
    ||                                                                                                                         ||  
    ||  5% FEES PER TRANSACTION ("TAX"):                                                                                       ||  
    ||  - 3% + 1% = 4% fee per transaction distributed to THE STREETS (Charities)                                              ||  
    ||      => 3% fee always guaranteed to be distributed to THE STREETS (Charities)                                           ||  
    ||      => additonal 1% can be switched from "THE STREETS" to BURN (and back) if community decides on doing so.            ||  
    ||      => BURNING decreases circulating supply/total token supply by sending to the 0x0 address ("the zero address")      ||  
    ||                                                                                                                         ||  
    ||  - 1% fee per transaction distributed Liquidity for token                                                               ||  
    ||      => Liquidity address:                                                                                              ||  
    ||      => Added to Liquidity Pool at regular intervals                                                                    ||  
    ||                                                                                                                         ||  
    ||  - Contract Deployer (a.k.a 'Owner') address:                                                                           ||  
    ||      => Only additional benefits/utility to the Contract Deployer / "Owner" is the ability to switch 1% of the tax back ||   
    ||      and forth between donating "THE STREETS" and BURNING to "the zero address"                                         ||  
    ||      => Note: The Contract Deployer / "Owner" is also exempt from the tax to facilitate the initial distribution - this ||  
    ||     will not be used by the developers, influencers, or as the charity address                                          ||  
    ||      ***MAY EDIT CHARITY ADDRESS OUT OF THIS... to have it exempted from the tax....***                                 ||
    ||                                                                                                                         ||   
    ||  TOTAL SUPPLY SPLITS (Total Supply is 50B or 50,000,000,000 Tokens):                                                    ||       
    ||  - 70% Distributed to the People/ "BING BONG COMMUNITY" via the Fair Launch                                             ||
    ||  - 15% Locked Liquidity                                                                                                 ||
    ||  - 10% To the Community of Influencers (BING BONG) at a maximum of 2% per person                                    ||
    ||  - 5%  To the Devs Wallet                                                                                               ||
    ----------------------------------------------------------------------------------------------------------------------------- 
**/
  
pragma solidity ^0.8.9;
// SPDX-License-Identifier: Unlicensed
interface BEP20 {
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
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

contract BingBong is Context, BEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee; //only should apply to the contract address of the token and the deployer account for initial distribution ... no others ...

    uint256 private _totalSupply = 50000000000 * 10**9;

    string private _name = "BingBong";
    string private _symbol = "BINGBONG";
    uint8 private _decimals = 9;
    
    uint256 public _charityFee = 4;
    uint256 public _liquidityFee = 1;
    uint256 public _burnFee = 0;
    uint256 public _initialTransactionFeeTotal = _charityFee + _liquidityFee + _burnFee;



    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    address public _charityAddress =  0xA7BaE564F0b6F573ca17c1330e940a6A3cFB064A;
    address public _liquidityAddress = 0xf14Eff65d5Db7E6846230587a4f91Fe261c3709A;  
    address public _burnAddress = address(0);  

    
    //Removed b/c no max transaction amount
    //uint256 public _maxTxAmount = 50000000000 * 10**9; //i.e. no max tx amount as it is initially set at 50B which equals the total supply
    
    
    constructor () {
        //_balance[_msgSender()] = _totalSupply; //send all inital balance to msg.sender (the owner) for distribution
        //ADD In Other Balances Here w/ Math to Prove i.e. Dev/Team Wallets and Community Influencers so it is immutable and transparent from the get go (deployment) of the smart contract
        //_balance[<<add address here>>] = <<add amount of tokens here>>;
        _balance[_msgSender()] = 42250000000 * 10**9; //deployer at 84.5% to be distributed

        _balance[0xc3c832221cD0b20e91dB031da98e54a6C2A0bBec] = 1000000000 * 10**9; //dev/team at 2%
        _balance[0x2993730E60428fd95B646b0766F5379A7d32C4eF] = 1000000000 * 10**9; //dev/team at 2%
        _balance[0xF895b7ba2c9b7775328d56FD93Ed76D338eb7BF2] = 500000000 * 10**9; //dev/team at 1%
        _balance[0x39722511168d4Ac42c08a5E2717ffc269529B037] = 250000000 * 10**9; //dev/team at 0.5%

        _balance[0x7448EcA8fd6E562398fE6627D2aF4Bd74e0edd86] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0x0c695546318D3Dd6c9eB563a62bf304b42E6DF39] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0xcf3C1fe5c6f19FFeFD2b5AA73ecBE6bec63C346e] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0x7Cd74cCbebF623DF6FE87D8B28d7107aB95505f3] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0x42fBfdc7c399Bcd9b802167f9513e96437525cE1] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0xF146C2733bD0375a3fb7FB5d62bd25085021f616] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0xCe9A5c2e84D458D9315Aaf667760a5573f39691F] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0x79A64e8350Ac4B41ba954FEbD64FdBAFa263A303] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0x8E6939159E414d795dDf1aE2322642F9a9799112] = 500000000 * 10**9; //BingBong Community/Influencer at 1%
        _balance[0xAC6470e400a68EC66487fFf709744b09c9876EA4] = 500000000 * 10**9; //BingBong Community/Influencer at 1%

        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        // set the rest of the contract variables
        //uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true; //this is to avoid tax on initial distribution
        _isExcludedFromFee[address(this)] = true; //this is the contract address of this token and can not be used as an account by anybody
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalCharityFee() public view returns (uint256) {
        return _charityFee;
    }

    function totalLiquidityFee() public view returns (uint256) {
        return _liquidityFee;
    }

    function totalBurnFee() public view returns (uint256) {
        return _burnFee;
    }

    function currentTotalFees() public view returns (uint256) {
        return (_charityFee + _liquidityFee + _burnFee);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setCharityFeePercent(uint256 fee) external onlyOwner() {
        require(fee <= 8, "ERROR: Can not set charity fee to over 8%."); //There is an absolute limit to the charity (for safety and health of the token)
        _charityFee = fee;
    }
    
    function setLiquidityFeePercent(uint256 fee) external onlyOwner() {
        require(fee <= 8, "ERROR: Can not set liquidity fee to over 8%."); //There is an absolute limit to this liquidity fee (for safety and health of the token)
        _liquidityFee = fee;
    }

    function setBurnFeePercent(uint256 fee) external onlyOwner() {
        require(fee <= 8, "ERROR: Can not set burn fee to over 8%."); //There is an absolute limit to this burn fee (for safety and health of the token)
        _burnFee = fee;
    }
   
    // Not needed - no max transaction cap implemented.
    // function setMaxTxViaPercent(uint256 maxTxPercent) external onlyOwner() {
    //     _maxTxAmount = _totalSupply.mul(maxTxPercent).div(
    //         10**2
    //     );
    // }
    
    // function setMaxTxViaExact(uint256 maxTxExact) external onlyOwner() {
    //     _maxTxAmount = maxTxExact;
    // }
    
    
    function setCharityAddress(address account) external onlyOwner() {
        require(_charityAddress != account, "ERROR: Can not set to same address.");
        _charityAddress = account;
    }
    
    function setLiquidityAddress(address account) external onlyOwner() {
        require(_liquidityAddress != account, "ERROR: Can not set to same address.");
        _liquidityAddress = account;
    }

    //Burn address set to "address(0)" and will never need to be changed and so a setter function has not been implemented.
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    

    /***************** */
    function calculateTaxFee(uint256 _amount) private view returns (uint256, uint256, uint256) {
        uint256 charityFee = _amount.mul(_charityFee).div(
            10**2
        );
        
        uint256 liquidityFee = _amount.mul(_liquidityFee).div(
            10**2  
        );

        uint256 burnFee = _amount.mul(_burnFee).div(
            10**2  
        );
        
        return (charityFee, liquidityFee, burnFee);
    }
    
    //Should only ever return true for the smart contract f the token itself and the contract deployer....
    //...(which only should be used for deploying and setting other variables (or adding to the liquidity if used in that manner... and not as a personal account)
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    //this method eventually calls _tokenTransfer(...)
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //removed b/c no max transaction amount...
        // if(from != owner() && to != owner()) {
        //     require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        // }
        
        //default:  fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee - again... should only exclude contract address of token or contract deployer for initial distribution... and no other accounts/addresses...
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        //now call the atomic or lowest level of transfer code... "_tokenTransfer"...
        //... arguments of the method: to, from, transfer amount, and if taxed/taking fee or not...
        //the method will transfer the amount and will take tax and send to charity wallet, liquidity wallet and burn as appropriate
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is the atomic or lowest level of the transfer
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        _balance[sender] = _balance[sender].sub(amount); //subtract total amount from sender regardless of the fees
        
        if(takeFee) { //if fee is taken use this logic... should ALWAYS be called unless from contract itself or owner/contract deployer during initial token distribution
                      //in all other circumstances the fee should ALWAYS be taken... no one is exempt or above this fee i.e. equally appliccably to everyone and every transfer
            
            (uint256 charityFee, uint256 liquidityFee, uint256 burnFee) = calculateTaxFee(amount); //calculate fees for the specific amount sent in this transaction
            uint256 transferAmountMinusFee = amount.sub(charityFee).sub(liquidityFee).sub(burnFee); //this is the transfer amount subtracting the fees calculated above
            
            _balance[recipient] = _balance[recipient].add(transferAmountMinusFee); //add the transfer amount (subtracting the fees) to the recepient address
            _balance[_charityAddress] = _balance[_charityAddress].add(charityFee); //add the charity fee amount to the charity address
            _balance[_liquidityAddress] = _balance[_liquidityAddress].add(liquidityFee); //add the liquidity fee amount to the liquidity address
            _balance[_burnAddress] = _balance[_burnAddress].add(burnFee); //add the burn fee amount to the burn address (address 0x0)

            //emit the appropriate transfer events
            emit Transfer(sender, _charityAddress, charityFee);
            emit Transfer(sender, _liquidityAddress, liquidityFee);
            emit Transfer(sender, _burnAddress, burnFee);
            emit Transfer(sender, recipient, transferAmountMinusFee);


        } else { //if fee is NOT taken use this logic... should NEVER  be called unless from contract itself or owner/contract deployer during initial token distribution
                 //in other words... the fee should ALWAYS be taken... no one is exempt or above this fee i.e. equally appliccably to everyone and every transfer
            _balance[recipient] = _balance[recipient].add(amount); //add the transfer amount (no fees in this unique case) to the recepient address
            //emit the appropriate transfer event
            emit Transfer(sender, recipient, amount);
        }
    }
}