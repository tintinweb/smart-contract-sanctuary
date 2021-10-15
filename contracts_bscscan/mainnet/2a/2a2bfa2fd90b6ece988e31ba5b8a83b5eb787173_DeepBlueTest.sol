/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;
/**
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |  ________    | || |  _________   | || |  _________   | || |   ______     | || |   ______     | || |   _____      | || | _____  _____ | || |  _________   | |
| | |_   ___ `.  | || | |_   ___  |  | || | |_   ___  |  | || |  |_   __ \   | || |  |_   _ \    | || |  |_   _|     | || ||_   _||_   _|| || | |_   ___  |  | |
| |   | |   `. \ | || |   | |_  \_|  | || |   | |_  \_|  | || |    | |__) |  | || |    | |_) |   | || |    | |       | || |  | |    | |  | || |   | |_  \_|  | |
| |   | |    | | | || |   |  _|  _   | || |   |  _|  _   | || |    |  ___/   | || |    |  __'.   | || |    | |   _   | || |  | '    ' |  | || |   |  _|  _   | |
| |  _| |___.' / | || |  _| |___/ |  | || |  _| |___/ |  | || |   _| |_      | || |   _| |__) |  | || |   _| |__/ |  | || |   \ `--' /   | || |  _| |___/ |  | |
| | |________.'  | || | |_________|  | || | |_________|  | || |  |_____|     | || |  |_______/   | || |  |________|  | || |    `.__.'    | || | |_________|  | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
 **/
interface IERC20 {

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
    function _msgSender() internal view virtual returns (address payable) {
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
    address private _gateKeeper;

    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _gateKeeper = msgSender; 

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

    modifier onlyGateKeeper() {
        require(_gateKeeper == _msgSender(), "Ownable: caller is not the gatekeeper");
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
        _previousOwner=address(0); // no more lock unlock tricks to regain ownership
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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


contract DeepBlueTest is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

   
    uint256 private constant MAX = ~uint256(0);


    string private constant _name = "Deepblue Test";
    string private constant _symbol = "DEEPTEST";
    uint8 private constant _decimals = 18;
    uint256 public _crowdPool;

    uint256 public _liquidityFee = 0; // in basis points
    uint256 public _crowdingRate = 0; // in basis points
    
    uint256 public _liquidtyTokens = 0;
    uint256 public _distributedTokens = 0;
    uint256 public _pendingT=0;
    uint256 public _liquidityProvided=0;
    uint256 public _tokensSwapped =0;
    uint256 public _bnbProvided=0;   

    IUniswapV2Router02 public  pancakeSwapV2Router;
    address public  pancakeSwapV2Pair;
    
    address private gateKeeper; //gatekeeper is the deployer of the contract. In case we denounce the ownership, gatekeeper can call some utility functions
    bool inLiquidityProvision;
    bool public LiquidityProvisionEnabled = false;
    
    uint256 private  _tTotal                   = 1000000000   * 10**18;
    uint256 public   maxTxAmount               =   10000000   * 10**18; // 1 pct of the total supply  100  bps
    uint256 public   liquidityThreshold        =   10000000   * 10**18; // 1 pct of the total supply  100 bps
    uint256 public   secondPhaseLiquidity      =  200000000   * 10**18; 
    uint256 public   hard_cap                  =  10000000   * 10**18; // 1 pct of the total supply  

    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    //PRESALE
    uint256 constant BP = 10000;

    // sale params
    bool    public started;
    uint256 public price;
    uint256 public ends;
    bool    public paused;
    uint256 public minimum;
    uint256 public preSaleTokens=0;
    uint256 public _preSaleTokensr=0;
    uint256 public weiRaised=0;
    uint256 public tokensSold=0;

    modifier lockTheLiquidityProvision
    {
        inLiquidityProvision = true;
        _;
        inLiquidityProvision = false;
    }
    
    constructor () public 
    {




        
        IUniswapV2Router02 _pancakeSwapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //LIVE ENABLE
        pancakeSwapV2Pair = IUniswapV2Factory(_pancakeSwapV2Router.factory()).createPair(address(this), _pancakeSwapV2Router.WETH()); //LIVE ENABLE
        pancakeSwapV2Router = _pancakeSwapV2Router; //LIVE ENABLE
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        gateKeeper=_msgSender();
        _isExcludedFromFee[gateKeeper] = true;


        _crowdPool=_tTotal.mul(5).div(10);
        uint256 init_rate=_rTotal.div(_tTotal);
        uint256 _crowdPoolr=_crowdPool.mul(init_rate);
        preSaleTokens=_tTotal.sub(_crowdPool).sub(secondPhaseLiquidity);
        _preSaleTokensr=preSaleTokens.mul(init_rate);
        _rOwned[address(this)]=_rOwned[address(this)].add(_crowdPoolr);
        _rOwned[address(this)]=_rOwned[address(this)].add(_preSaleTokensr);
        _rOwned[address(msg.sender)]=_rTotal.sub(_crowdPoolr).sub(_preSaleTokensr);
        
        // Plans:
        // Issue 1B
        // 500M on crowding pool
        // 300M on presale
        // 200M on afterSaleLiquidity

        // After the sale
        // Unsold transfered to Crowding Pool Automatically
        // 100M will be put on Pancake as initial liquidty using BNB collected in initial sale
        // (Proportinal to the tokens sold, to ensure the initial price is double the presale price )
        // Remaining 100 M will be burned 
        // Contract functionality will be activated
        // Contract ownership will be denounced

        //AFTER PRESALE ENDED
        // set crowding rate to 500
        // set setLiquidityFeePercent to 500
        // enable LiquidityProvisionEnabled

    }

    function setStarted(bool _started)         public onlyOwner { started = _started;}
    function setPause(bool _paused)            public onlyOwner { paused = _paused;}
    function setPrice(uint256 _price)       public onlyOwner { price = _price; }
    function setMinimum(uint256 _minimum)   public onlyOwner { minimum = _minimum; }
    function setEnds(uint256 _ends)         public onlyOwner  {ends = _ends;}

    

    event PreSaleStarted(uint256 _ends);
    function startPresale(uint256 _ends) public onlyOwner {
        require(!started, "already started!");
        require(price > 0, "set price first!");
        require(minimum > 0, "set minimum first!");

        started = true;
        paused = false;
        ends = _ends;
        emit PreSaleStarted(_ends);

    }


    function calculateAmountPurchased(uint256 _value) public view returns (uint256) 
    {
        return _value.mul(BP).div(price).mul(1e18).div(BP);
    }

    event RateChangeByBurn(uint256 old_rate,uint256 new_rate);
    function burnReflection(uint256 tokens_to_burn) public onlyOwner 
    {
        uint256 init_rate=_rTotal.div(_tTotal);
        uint256 reflection_to_burn=tokens_to_burn.mul(init_rate);
        require(_rOwned[address(msg.sender)] >= reflection_to_burn, "amount too small");
        require(_tTotal >= tokens_to_burn, "amount too small");

        //reduce the total supply
        //reduce the rOwned of the sender
        _rOwned[address(msg.sender)]=_rOwned[address(msg.sender)].sub(reflection_to_burn);
        _tTotal=_tTotal.sub(tokens_to_burn);
        uint256 new_rate=_rTotal.div(_tTotal);
        emit RateChangeByBurn(init_rate,new_rate);
        //burns will increase the rate so that allocations will be much more abundant
    }

    function buy_presale() public  payable {
        require(paused==false, "presale is ended");
        require(msg.value >= minimum, "amount too small");
        require(block.timestamp < ends, "presale is ended");
        
        uint256 init_rate=_rTotal.div(_tTotal);
        uint256 tokensToPurchase=calculateAmountPurchased(msg.value);
        uint256 amount = tokensToPurchase.mul(init_rate);
        
        require(_preSaleTokensr.sub(amount) >= 0, "sold out check1");
        require(_rOwned[address(this)].sub(amount) >= 0, "sold out check2");
        require(tokensToPurchase <= hard_cap, "amount too large try smaller");
        require(preSaleTokens.sub(tokensToPurchase)>=0, "sold out check3");

        preSaleTokens=preSaleTokens.sub(tokensToPurchase);
        _preSaleTokensr=_preSaleTokensr.sub(amount);
        _rOwned[address(msg.sender)]=_rOwned[address(msg.sender)].add(amount);
        _rOwned[address(this)]=_rOwned[address(this)].sub(amount);
        weiRaised = weiRaised.add(msg.value);
        tokensSold = tokensSold.add(tokensToPurchase);

        emit Transfer(address(this), address(msg.sender), tokensToPurchase);

    }

    event PreSaleEnded(uint256 amount_transfered_to_pool);
    function endPresale() public onlyOwner 
    { 
        ends = 0; 
        paused = true;
        uint256 transferTokens=0;
        if (preSaleTokens>0)
        {
            transferTokens= preSaleTokens;
            _crowdPool=_crowdPool.add(transferTokens);
            preSaleTokens=0;
        }

        emit PreSaleEnded(transferTokens);
    }

    function name() public pure  returns (string memory) 
    {
        return _name;
    }
 

    function symbol() public pure  returns (string memory) 
    {
        return _symbol;
    }

    function getPresaleTokensR() public view  returns (uint256) 
    {
        return _preSaleTokensr;
    }

    function getPresaleTokens() public view  returns (uint256) 
    {
        return getTokenFromReflection(_preSaleTokensr);
    }  
    
    function decimals() public pure  returns (uint8) 
    {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) 
    {
        return _tTotal;
    }

    function totalCrowdPool() public view returns (uint256) 
    {
        return _crowdPool;
    }

    function getRtotal() public view  returns (uint256) 
    {
        return _rTotal;
    }
    
    function getTotalDistributed() public view  returns (uint256) 
    {
        return _distributedTokens;
    }

    function getCrowdingPool() public view  returns (uint256) 
    {
        return _crowdPool;
    }

    function getRemainingCrowdingPool() public view  returns (uint256) 
    {
        return _crowdPool.sub(_distributedTokens);
    }

    function getPendingPool() public view  returns (uint256) 
    {
        //amount pending and to be distributed when it is accumulated enough
        return _pendingT;
    }

    function getAccumulatedLiquidtyPool() public view  returns (uint256) 
    {
        // total tokens burned in distribution process
        return _liquidtyTokens;
    }
    
    function getPoolDecay() public view returns(uint256) 
    {        
        uint256 remaining_pool=_crowdPool.sub(_distributedTokens);
        return remaining_pool.mul(10**4).div(_crowdPool);   
        
    }
    
    function getRate() public view returns(uint256) 
    {
        return  _rTotal.div(_tTotal);
    }
    
    function getLiquidityThreshold() public view returns(uint256) 
    {
        return  liquidityThreshold;
    }
    
    function getMaxTxThreshold() public view returns(uint256) 
    {
        return  maxTxAmount;
    }

    function getLiquidityProvided() public view returns(uint256)
    {
        return _liquidityProvided;
    }

    function getTokensSwapped() public view returns(uint256)
    {
        return _tokensSwapped;
    }

    function getBnbProvided() public view returns(uint256)
    {
        return _bnbProvided;
    }
   
    function balanceOf(address account) public view override returns (uint256) 
    {   
        return getTokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) 
    {
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function getTokenFromReflection(uint256 rAmount) public view returns(uint256) 
    {
        return rAmount.div(getRate());

    }

    event LiquidityFeePercentSet(uint256 liquidityFee);
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() 
    {
        // once ownership is denounced, this can't be changed.
        _liquidityFee = liquidityFee;
        emit LiquidityFeePercentSet(liquidityFee);

    }
    event CrowdRatePercentSet(uint256 crowdRate);

    function setCrowdRatePercent(uint256 crowdRate) external onlyOwner() 
    {
        // once ownership is denounced, this can't be changed.
        _crowdingRate = crowdRate;
        emit CrowdRatePercentSet(crowdRate);

    }

    event MaxTxAmountSet(uint256 maxTxAmount);

    function setMaxTxThreshold(uint256 bpOfTotalSupply) external onlyOwner() 
    {
        // once ownership is denounced, this can't be changed.
        // in basis points
        maxTxAmount = _tTotal.mul(bpOfTotalSupply).div(10**4);
        emit MaxTxAmountSet(maxTxAmount);

    }


    event liquidityThresholdSet(uint256 liquidityThreshold);

    function setLiquidityThreshold(uint256 bpOfTotalSupply) external onlyOwner() 
    {
        // once ownership is denounced, this can't be changed.
        liquidityThreshold = bpOfTotalSupply;
        emit liquidityThresholdSet(liquidityThreshold);

    }

    event LiquidityProvisionEnabledUpdated(bool enabled);

    function setLiquidityProvisionEnabled(bool _enabled) public onlyGateKeeper 
    {
        LiquidityProvisionEnabled = _enabled;
        emit LiquidityProvisionEnabledUpdated(_enabled);
    }
    
     //to recieve BNB from pancakeSwapV2Router when swapping
    receive() external payable {}



    function _approve(address owner, address spender, uint256 amount) private 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    function _transfer(address from,address to,uint256 amount) private 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "Cannot Transfer More Than Balance");

        
        if(from != owner() && to != owner())
        {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
            
        
        //get the amount accumulated for liquidty provision
        uint256 contractTokenBalance =_liquidtyTokens;
        
        bool overMinTokenBalance = contractTokenBalance >= liquidityThreshold;
        
        if (overMinTokenBalance && !inLiquidityProvision && from != pancakeSwapV2Pair &&  LiquidityProvisionEnabled   )   //LIVE ENABLE
        {
            contractTokenBalance = liquidityThreshold;
            //add liquidity
            LiquidityProvision(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        
        bool distributeAndBurn = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        // if liquidty provision is not enabled, we won't be distributing from pool
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || LiquidityProvisionEnabled==false)
        {
            distributeAndBurn = false;
        }


        
        //transfer amount, it will take tax, burn, liquidity fee
        
        _tokenTransfer(from,to,amount,distributeAndBurn);
        
    }

    function getBNBBalance() public view returns(uint256) 
    {
        //accumulated BNB balance due to swap 
        return address(this).balance;
    }

    function getStuckBNB()  external payable onlyGateKeeper returns(bool) 
    {
        //there mighrt be small accumulation of BNB while providing liquidity. 


        payable(gateKeeper).transfer(address(this).balance);
        return true;

    }

    event LiquidityProvisionEvent(uint256 tokensSwapped,uint256 bnbReceived,uint256 tokensIntoLiquidity);

    function LiquidityProvision(uint256 contractTokenBalance) private lockTheLiquidityProvision 
    {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        _liquidtyTokens=_liquidtyTokens.sub(half);
        _liquidtyTokens=_liquidtyTokens.sub(otherHalf);
        // at this point _liquidtyTokens should set itself to 0. 

        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half); 
        _tokensSwapped=_tokensSwapped.add(half);
        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        _bnbProvided=_bnbProvided.add(newBalance);
        // add liquidity to pancakeSwap
        addLiquidity(otherHalf, newBalance);
        
        _liquidityProvided=_liquidityProvided.add(otherHalf);
  
        emit LiquidityProvisionEvent(half, newBalance, otherHalf);

    }

    function swapTokensForBnb(uint256 tokenAmount) private {
       
        address[] memory path = new address[](2);
        path[0] = address(this);
       
        path[1] = pancakeSwapV2Router.WETH(); //LIVE ENABLE

        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);  //LIVE ENABLE     
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0, path,address(this),block.timestamp); //LIVE ENABLE
    


    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount); //LIVE ENABLE

        // add the liquidity No RUG RULLS, LIQUIDITY IS LOCKED AND OWNED BY CONTRACT
        
        address liquidity_owner=owner();

        if (owner()==address(0))
        {
            //contract is  renounced
            liquidity_owner= address(this);    
        }
        pancakeSwapV2Router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0, liquidity_owner, block.timestamp); //LIVE ENABLE
        
    }

    
    function setRouterAddress(address newRouter) public onlyGateKeeper() 
    {
        //change the router address 
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        pancakeSwapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        pancakeSwapV2Router = _newPancakeRouter;
    }
    


    //this method is responsible for taking all fee, if distributeAndBurn is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool distributeAndBurn) private 
    {

        _transferStandard(sender, recipient, amount,distributeAndBurn);
                      
    }

    function _get_tokens_to_distribute(uint256 tAmount, uint256 crowding_rate_in_use) private returns (uint256) 
    {
        uint256 init_pending_T=_pendingT;
        //pending T enables token owners to get their distribtion from previous small transactions that wasn't significant enough to generate distributable coins
        //nothing get lost in rounding in this contract.  

        uint256 distribution_base=init_pending_T.add(tAmount);  
        uint256 pool_rate=getPoolDecay();
        uint256 supply_rate=distribution_base.mul(10**15).div(_tTotal);
               
        uint256 to_distribute_gross=distribution_base.mul(supply_rate).mul(pool_rate).mul(crowding_rate_in_use);//dist_amount*supply_rate*pool_rate
        uint256 to_distribute_net=to_distribute_gross.div(10**23);

        //zero count 
        //add 4 for pool
        //add 15 for supply
        //add 4 for crowding rate adjustment
        
        if (to_distribute_net==0 && tAmount>0 && crowding_rate_in_use>0 )
        {
            // t is too small to distribute something so it gets added to pending T
            _pendingT=_pendingT.add(tAmount);
            // add the balance to the pending T so next time when tokens accumulate there will be more distribution
        }
        else if (to_distribute_net>0 && tAmount>0 && crowding_rate_in_use>0 && init_pending_T>0)
        {
            _pendingT=_pendingT.sub(init_pending_T);
            //deduct the distributed pending T so it wont be distributed again
        }
        
        return to_distribute_net;
    } 


    function _transferStandard(address sender, address recipient, uint256 tAmount,bool distributeAndBurn) private 
    {
        uint256 liqudity_fee_in_use=_liquidityFee;
        uint256 crowding_rate_in_use=_crowdingRate; 
        if (distributeAndBurn==false)
        {
            //this is only for the contract and the owner and init stage for all users where the pool distribution is not enabled
            liqudity_fee_in_use=0;
            crowding_rate_in_use=0;

        }

        uint256 currentRate=getRate();
        uint256 tLiquidity=tAmount.mul(liqudity_fee_in_use).div(10**4);
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidity);
        uint256 tTransferAmount=tAmount.sub(tLiquidity);
        //r amount transfered and liquidty fee deducted

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        _liquidtyTokens=_liquidtyTokens.add(tLiquidity); //this is what is checked when providing liquidity
        
        //calculate tokens to be distributed

        uint256 tokens_to_distribute=0;
        if (distributeAndBurn)
        {
            if (getRemainingCrowdingPool()>6969) //6969 tokens is legacy tokens and will be in the pool forever
            {
                uint256 beforeDistContractTokens=balanceOf(address(this));
                tokens_to_distribute=_get_tokens_to_distribute(tAmount,crowding_rate_in_use);

                //everybody gets tokens they deserve
                _distributedTokens=_distributedTokens.add(tokens_to_distribute);
                uint256 _rDist=tokens_to_distribute.mul(currentRate);
                _rTotal=_rTotal.sub(_rDist);
                _rOwned[address(this)]=_rOwned[address(this)].sub(_rDist);

                //compensating the distribution that goes into contract
                uint256 afterDistContractTokens=balanceOf(address(this));
                uint256 realDistribution=beforeDistContractTokens.sub(afterDistContractTokens);
                uint256 distributedtoContract=tokens_to_distribute.sub(realDistribution);
                tokens_to_distribute=realDistribution;
                _distributedTokens=_distributedTokens.sub(distributedtoContract);
            }
            
        }
        
        emit Transfer(sender, recipient, tTransferAmount);
    }





    




}