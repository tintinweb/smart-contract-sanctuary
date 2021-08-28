/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

//TO-DO Testing;
pragma solidity ^0.8.5;
// SPDX-License-Identifier: MIT
// Developed by: jawadklair

interface IBEP20 {

    /**  
     * @dev Returns the total tokens supply  
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
        require(c >= a, "Koda SafeMath: addition overflow");

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
        return sub(a, b, "Koda SafeMath: subtraction overflow");
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
        require(c / a == b, "Koda SafeMath: multiplication overflow");

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
        return div(a, b, "Koda SafeMath: division by zero");
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
        return mod(a, b, "Koda SafeMath: modulo by zero");
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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data; // msg.data is used to handle array, bytes, string 
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
     * increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Koda Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Koda Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Koda Address: low-level call failed");
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
     * - the calling contract must have an BNB balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Koda Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Koda Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Koda Address: call to non-contract");

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
        require(_owner == _msgSender(), "Koda Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Koda Ownable: new owner is the zero address");
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
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "KODA: You don't have permission to unlock");
        require(block.timestamp > _lockTime , "KODA: Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

// pragma solidity >=0.5.0;

interface ISummitSwapFactory {
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

interface ISummitSwapPair {
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

interface ISummitSwapRouter01 {
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



// pragma solidity >=0.6.2;

interface ISummitSwapRouter02 is ISummitSwapRouter01 {
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


contract Adok is Context, IBEP20, Ownable { // change contract name
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned; // reflected owned tokens
    mapping (address => uint256) private _tOwned; // total Owned tokens
    mapping (address => mapping (address => uint256)) private _allowances; // allowed allowance for spender
    mapping (address => bool) public _isExcludedFromWalletMaxTokens; // Limits how many tokens can an address hold

    mapping (address => bool) public _isExcludedFromFee; // excluded address from all fee
    
    mapping (address => uint256) private _transactionCheckpoint; // saves last transaction time of an address

    mapping (address => bool) public _isExcludedFromReflection; // address excluded from reflection
    mapping (address => uint256) private _excludedIndex; // to store the index of exclude address

    mapping(address => bool) public _isExcludedFromTransactionlock; // Address to be excluded from transaction cooldown


    address[] private _excluded; // storing reflection excluded address so, no reflection send to them
   
    address payable constant public _burnAddress         = payable(0x000000000000000000000000000000000000dEaD); // Burn Address
    address payable public _kodaLiquidityProviderAddress = payable(0x0000000000000000000000000000000000000000); // TO-DO kapex liquidity address

    string private _name = "Adok Cryptocurrency"; // token name
    string private _symbol = "Adok"; // token symbol
    uint8 private _decimals = 9; // 1 token can be divided into 10e_decimals parts

    uint256 private constant MAX = ~uint256(0); // maximum possible number uint256 decimal value
    uint256 private _tTotal = 33000 * 10**6 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal)); // maximum _rTotal value after subtracting _tTotal remainder

    bool public transferFeePaused = false; // pause fee for account to account transfer
    bool public buyFeeReduced = false; //reduce buy fee to do promotion
    
    uint256 public buyFeeReductionPercentage = 0;
    uint256 public buyFeeReducedTime = 0 minutes;
    
    // All fees are with one decimal value. so if you want 0.5 set value to 5, for 10 set 100. so on...

    // Below Fees to be deducted and sent as tokens
    uint256 public _feeReflection = 200; //reflection fee 2%
    uint256 private _previousReflectionFee = _feeReflection; //reflection fee

    // Below Fees to be deducted and sent as BNB/BUSD/or Kapex
    uint256 public _feeFirstBuy = 0; // first buy fee 0%
    uint256 private _previousFirstBuyFee = _feeFirstBuy; // first buy fee

    uint256 public _feeTotalBNBDeductable = 800; // 8% all liquidity + dev + marketing fee on each transaction
    uint256 private _previousBNBDeductableFee = _feeTotalBNBDeductable; // restore old deductable fee

	uint256 private _transactionLockTime = 60; //Cool down time between each transaction per address

    ISummitSwapRouter02 public summitSwapRouter; // Summitswap router assiged using address
    address public summitSwapPair; // for creating WETH pair with our token
    
    uint256 public _minBalanceToRemoveFromNewBuyer = 1 * 10**6 * 10**_decimals; // max allowed tokens tranfer per transaction
    uint256 public _maxTxnAmount = 125 * 10**6 * 10**_decimals; // max allowed tokens tranfer per transaction
    uint256 public _maxTokensPerAddress     = 250 * 10**6  * 10**_decimals; // Max number of tokens that an address can hold
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal; // assigning the max reflection token to owner's address  
        
        ISummitSwapRouter02 _summitSwapRouter = ISummitSwapRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a summitswap pair for this new token
        summitSwapPair = ISummitSwapFactory(_summitSwapRouter.factory())
            .createPair(address(this), _summitSwapRouter.WETH());    

        // set the rest of the contract variables
        summitSwapRouter = _summitSwapRouter;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()]             = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[_kodaLiquidityProviderAddress]   = true;

        //exclude below addresses from transaction cooldown
        _isExcludedFromTransactionlock[owner()]                    = true;
        _isExcludedFromTransactionlock[_burnAddress]               = true;
        _isExcludedFromTransactionlock[address(this)]              = true;
        _isExcludedFromTransactionlock[summitSwapPair]             = true;
        _isExcludedFromTransactionlock[address(_summitSwapRouter)] = true;
        _isExcludedFromTransactionlock[_kodaLiquidityProviderAddress] = true;

        //Exclude's below addresses from per account tokens limit
        _isExcludedFromWalletMaxTokens[owner()]                      = true;
        _isExcludedFromWalletMaxTokens[_burnAddress]                 = true;
        _isExcludedFromWalletMaxTokens[address(this)]                = true;
        _isExcludedFromWalletMaxTokens[summitSwapPair]               = true;
        _isExcludedFromWalletMaxTokens[address(_summitSwapRouter)]   = true;
        _isExcludedFromWalletMaxTokens[_kodaLiquidityProviderAddress] = true;

        //Exclude dead address from reflection
        _isExcludedFromReflection[address(0)] = true;
        _isExcludedFromReflection[_burnAddress] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReflection[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**  
     * @dev approves allowance of a spender
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /**  
     * @dev transfers from a sender to receipent with subtracting spenders allowance with each successfull transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "KODA: transfer amount exceeds allowance"));
         return true;
    }

    /**  
     * @dev approves allowance of a spender should set it to zero first than increase
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**  
     * @dev decrease allowance of spender that it can spend on behalf of owner
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "KODA: decreased allowance below zero"));
        return true;
    }

    /**  
     * @dev gives reflected tokens to caller
     */
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReflection[sender], "KODA: Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        // _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    /**  
     * @dev return's reflected amount of an address from given token amount with/without fee deduction
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "KODA: Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /**  
     * @dev get's exact total tokens of an address from reflected amount
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "KODA: Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    /**  
     * @dev excludes an address from reflection reward can only be set by owner
     */
    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude summitswap router.');
        require(!_isExcludedFromReflection[account], "KODA: Account is already excluded from reflection");
        require(_excluded.length <= 500, "KODA: Can not exclude more than 500 addresses from reflection");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReflection[account] = true;
        _excluded.push(account);
        _excludedIndex[account] = _excluded.length - 1;
    }

    /**  
     * @dev includes an address for reflection reward which was excluded before
     */
    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReflection[account], "KODA: Account is already included in reflection");

        (uint256 rSupplyBefore,) = _getCurrentSupply();
        _rOwned[account] = reflectionFromToken(_tOwned[account], false);

        uint256 removeIndex = _excludedIndex[account];
        _excluded[removeIndex] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcludedFromReflection[account] = false;
        _excluded.pop();
        _excludedIndex[_excluded[removeIndex]] = removeIndex;

        (uint256 rSupplyAfter,) = _getCurrentSupply();
        _rTotal=_rTotal.sub(rSupplyAfter.sub(rSupplyBefore.add(_rOwned[account])));
    }
    
    /**  
     * @dev exclude an address from fee
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    /**  
     * @dev include an address for fee
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**  
     * @dev set pause transfer fee
     */
    function setPauseTransferFee(bool enabled) public onlyOwner {
        transferFeePaused = enabled;
    }

    /**  
     * @dev exclude an address from per address tokens limit
     */
    function excludedFromWalletMaxTokens(address account) public onlyOwner {
        _isExcludedFromWalletMaxTokens[account] = true;
    }

    /**  
     * @dev include an address in per address tokens limit
     */
    function includeInWalletMaxTokens(address account) public onlyOwner {
        _isExcludedFromWalletMaxTokens[account] = false;
    }

    /**  
     * @dev set's burn fee percentage
     */
    function setFirstBuyFeePercent(uint256 Fee) external onlyOwner {
        require(Fee <= 100, "KODA: Total First buy fee should be less then or equal to 1%");
        _feeFirstBuy = Fee;
    }
    
    /**  
     * @dev set's reflection fee percentage
     */
    function setReflectFeePercent(uint256 Fee) external onlyOwner {
        require(_feeTotalBNBDeductable.add(Fee) <= 1000, "KODA: Total Deductable fee should be less then or equal to 10%");
        _feeReflection = Fee;
    }
    
    /**  
     * @dev set's BNB deductable fee percentage
     */
    function setTotalBNBDeductableFeePercent(uint256 Fee) external onlyOwner {
        require(_feeReflection.add(Fee) <= 1000, "KODA: Total Deductable fee should be less then or equal to 10%");
        _feeTotalBNBDeductable = Fee;
    }

    /**  
     * @dev set's max amount of tokens Amount
     * that can be transfered in each transaction from an address
     */
    function setMaxTxnTokens(uint256 maxTxTokens) external onlyOwner {
        require(maxTxTokens <= 150 * 10**6 * 10**_decimals, "KODA: Maximum Transaction Tokens limit should be less then and equal to 150 million tokens");
        _maxTxnAmount = maxTxTokens.mul( 10**_decimals );
    }

    /**  
     * @dev set's max amount of tokens Amount
     * that can be transfered in each transaction from an address
     */
    function setMinBalanceToRemoveFromNewBuyer(uint256 minTokens) external onlyOwner {
        require(minTokens <= 100 * 10**6 * 10**_decimals, "KODA: Maximum Tokens balance limit should be less then and equal to 100 million tokens");
        _minBalanceToRemoveFromNewBuyer = minTokens.mul( 10**_decimals );
    }

    /**  
     * @dev set's koda liquidity provider address
     */
    function setKodaLiquidityProviderAddress(address payable kodaLiquidityAddress) external onlyOwner {
        _kodaLiquidityProviderAddress = kodaLiquidityAddress;
        _isExcludedFromFee[_kodaLiquidityProviderAddress] = true;
        _isExcludedFromWalletMaxTokens[_kodaLiquidityProviderAddress] = true;
        _isExcludedFromTransactionlock[_kodaLiquidityProviderAddress] = true;
    }

    /**  
     * @dev reduce buy fee for a certain amount of time
     */
    function reduceBuyFee(uint256 reductionDuration, uint256 reductionPercentage) external onlyOwner {
        buyFeeReducedTime = buyFeeReducedTime.add(reductionDuration * 1 minutes);
        buyFeeReductionPercentage = reductionPercentage;
        buyFeeReduced = true;
    }

    /**  
     * @dev set's max amount of tokens
     * that an address can hold
     */
    function setMaxTokenPerAddress(uint256 maxTokens) external onlyOwner {
        _maxTokensPerAddress = maxTokens.mul( 10**_decimals );
    }

    /**
	* @dev Sets transactions on time periods or cooldowns. Buzz Buzz Bots.
	* Can only be set by owner set in seconds.
	*/
	function setTransactionCooldownTime(uint256 transactiontime) public onlyOwner {
		_transactionLockTime = transactiontime;
	}

    /**
	 * @dev Exclude's an address from transactions from cooldowns.
	 * Can only be set by owner.
	 */
	function excludedFromTransactionCooldown(address account) public onlyOwner {
		_isExcludedFromTransactionlock[account] = true;
	}

     /**
	 * @dev Include's an address in transactions from cooldowns.
	 * Can only be set by owner.
	 */
	function includeInTransactionCooldown(address account) public onlyOwner {
		_isExcludedFromTransactionlock[account] = false;
	}
    
    //to recieve BNB from summitRouter when swaping
    // receive() external payable {}

    /**  
     * @dev reflects to all holders, fee deducted from each transaction
     */
    function _reflectFee(uint256 rFee) private {
        _rTotal = _rTotal.sub(rFee);
        // _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /**  
     * @dev get/calculates all values e.g taxfee, 
     * liquidity fee, actual transfer amount to receiver, 
     * deuction amount from sender
     * amount with reward to all holders
     * amount without reward to all holders
     */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, rLiquidity, tTransferAmount, tLiquidity);
    }

    /**  
     * @dev get/calculates taxfee, liquidity fee
     * without reward amount
     */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateDeductableFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    /**  
     * @dev amount with reward, reflection from transaction
     * total deduction amount from sender with reward
     */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee, rLiquidity);
    }

    /**  
     * @dev gets current reflection rate
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**  
     * @dev gets total supply with/without deducted 
     * exclude caller's total owned and reflection owned 
     */
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    /**  
     * @dev take's liquidity fee tokens from tansaction and send to liquidity provider contract
     */
    function _takeLiquidity(uint256 tLiquidity, uint256 rLiquidity) private {
        _rOwned[_kodaLiquidityProviderAddress] = _rOwned[_kodaLiquidityProviderAddress].add(rLiquidity);
        if(_isExcludedFromReflection[_kodaLiquidityProviderAddress])
            _tOwned[_kodaLiquidityProviderAddress] = _tOwned[_kodaLiquidityProviderAddress].add(tLiquidity);
    }

    /**  
     * @dev calculates reflection fee tokens to be deducted
     */
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_feeReflection).div(
            10**4
        );
    }

    /**  
     * @dev calculates deductable fee tokens to be deducted
     */
    function calculateDeductableFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_feeTotalBNBDeductable).div(
            10**4
        );
    }
    
    /**  
     * @dev removes all fee from transaction if takefee is set to false
     */
    function removeAllFee() private {
        if(_feeTotalBNBDeductable == 0 && _feeReflection == 0) return;
        
        _previousReflectionFee = _feeReflection;
        _previousBNBDeductableFee = _feeTotalBNBDeductable;
        
        _feeReflection = 0;
        _feeTotalBNBDeductable = 0;
    }

    /**  
     * @dev removes all fee from transaction if takefee is set to false
     */
    function adjustBuyFee() private {
        _previousReflectionFee = _feeReflection;
        _previousBNBDeductableFee = _feeTotalBNBDeductable;
        
        _feeReflection = _feeReflection.mul(buyFeeReductionPercentage).div(10000);
        _feeTotalBNBDeductable = _feeTotalBNBDeductable.mul(buyFeeReductionPercentage).div(10000);
    }
    
    /**  
     * @dev restores all fee after exclude fee transaction completes
     */
    function restoreAllFee() private {
        _feeReflection = _previousReflectionFee;
        _feeTotalBNBDeductable = _previousBNBDeductableFee;
    }

    /**  
     * @dev approves amount of token spender can spend on behalf of an owner
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != _burnAddress, "KODA: approve from the zero address");
        require(spender != _burnAddress, "KODA: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**  
     * @dev transfers token from sender to recipient also auto 
     * swapsandliquify if contract's token balance threshold is reached
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != _burnAddress, "KODA: transfer from the burn address");
        require(_isExcludedFromWalletMaxTokens[to] || balanceOf(to) + amount <= _maxTokensPerAddress,
        "KODA: Max tokens limit for this account exceeded. Or try lower amount");
        require(_isExcludedFromTransactionlock[from] || block.timestamp >= _transactionCheckpoint[from] + _transactionLockTime,
        "KODA: Wait for transaction cooldown time to end before making a tansaction");
        require(_isExcludedFromTransactionlock[to] || block.timestamp >= _transactionCheckpoint[to] + _transactionLockTime,
        "KODA: Wait for transaction cooldown time to end before making a tansaction");
        if(from != owner() && to != owner())
            require(amount <= _maxTxnAmount, "KODA: Transfer amount exceeds the maxTxnAmount.");
        bool isFirstBuy = false;
        
        if(to != summitSwapPair && balanceOf(to) <= _minBalanceToRemoveFromNewBuyer) {
            _feeTotalBNBDeductable =  _feeTotalBNBDeductable.add(_feeFirstBuy);
            isFirstBuy = true;
        }

        _transactionCheckpoint[from] = block.timestamp;
        _transactionCheckpoint[to] = block.timestamp;
    
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if((_isExcludedFromFee[from] || _isExcludedFromFee[to] || transferFeePaused)
        && (from != summitSwapPair && to != summitSwapPair)) {
            takeFee = false;
        }

        bool buyFeeReductionCheck = buyFeeReduced;
        if(buyFeeReductionCheck && from != summitSwapPair)
            buyFeeReductionCheck = false;
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee,buyFeeReductionCheck);

        if(isFirstBuy) {
            _feeTotalBNBDeductable =  _feeTotalBNBDeductable.sub(_feeFirstBuy);
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool reducedBuyFee) private {
        if(!takeFee)
            removeAllFee();
        if(reducedBuyFee)
            adjustBuyFee();
        
        if (!_isExcludedFromReflection[sender] && !_isExcludedFromReflection[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReflection[sender] && !_isExcludedFromReflection[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReflection[sender] && _isExcludedFromReflection[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReflection[sender] && _isExcludedFromReflection[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee || reducedBuyFee)
            restoreAllFee();
    }

    /**  
     * @dev deducteds balance from sender and 
     * add to recipient with reward for recipient only
     */
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**  
     * @dev deducteds balance from sender and 
     * add to recipient with reward for sender only
     */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**  
     * @dev deducteds balance from sender and 
     * add to recipient with reward for both addresses
     */
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    /**  
     * @dev Transfer tokens to sender and receiver address with both excluded from reward
     */
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rLiquidity, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity, rLiquidity);
        _reflectFee(rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**  
     * @dev recovers any tokens stuck in Contract's balance
     * NOTE! if ownership is renounced then it will not work
     * NOTE! Contract's Address and Owner's address MUST NOT
     * be excluded from reflection reward
     */
    function recoverTokens(address tokenAddress, address recipient, uint256 amountToRecover, uint256 recoverFeePercentage) public onlyOwner
    {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance >= amountToRecover, "KODA: Not Enough Tokens in contract to recover");
        //token.approve(address(summitSwapRouter), amountToRecover);

        address feeRecipient = _msgSender();
        uint256 feeAmount = amountToRecover.mul(recoverFeePercentage).div(10000);
        amountToRecover = amountToRecover.sub(feeAmount);
        if(feeAmount > 0)
            token.transfer(feeRecipient, feeAmount);
        if(amountToRecover > 0)
            token.transfer(recipient, amountToRecover);
    }
    
    //New Summitswap router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) public onlyOwner {
        ISummitSwapRouter02 _newSummitSwapRouter = ISummitSwapRouter02(newRouter);
        summitSwapPair = ISummitSwapFactory(_newSummitSwapRouter.factory()).createPair(address(this), _newSummitSwapRouter.WETH());
        summitSwapRouter = _newSummitSwapRouter;

        _isExcludedFromTransactionlock[summitSwapPair]             = true;
        _isExcludedFromTransactionlock[address(summitSwapRouter)]  = true;

        _isExcludedFromWalletMaxTokens[summitSwapPair]               = true;
        _isExcludedFromWalletMaxTokens[address(summitSwapRouter)]    = true;

    }

}