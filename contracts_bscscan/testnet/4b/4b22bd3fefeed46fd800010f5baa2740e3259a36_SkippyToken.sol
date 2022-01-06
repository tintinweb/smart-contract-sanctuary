/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// File: gist-71572af562f01852a1e328dba89471fe/skippy/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: gist-71572af562f01852a1e328dba89471fe/skippy/Context.sol


// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: gist-71572af562f01852a1e328dba89471fe/skippy/Ownable.sol


// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: gist-71572af562f01852a1e328dba89471fe/skippy/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: gist-71572af562f01852a1e328dba89471fe/skippy/Skippy-reflection.sol


pragma solidity ^0.8.0;






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



// pragma solidity >=0.6.2;

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


contract SkippyToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _rOwned;
    mapping (address => uint256) public _tOwned;

    //Token related variables
    uint256 public maxTxLimit = 10000000 * 10 ** 18;
    string _name = 'BTskippy';
    string _symbol = 'BTS';
    uint8 _decimals = 18;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    //Variables related to fees
    uint256 public liquidityThreshold = 10000000 * 10 ** 18;
    mapping (address => bool) private _isExcludedFromFee;

    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    mapping (address => uint) private _isTimeLimit;
    
    mapping (address => bool) private _excludeFromMaxTxLimit;
    mapping (address => bool) private _excludeFromTimeLimit;

    uint256 public _burnFee = 1;
    uint private previousBurnFee = _burnFee;
    uint256 public _charityFee = 1;
    uint private previousCharityFee = _charityFee;
    uint256 public _liquidityFee = 3;
    uint private previousLiquidityFee = _liquidityFee;
    uint256 public _rAndDFee = 2;
    uint private previousRAndDFee = _rAndDFee;
    uint256 public _marketingFee = 2;
    uint private previousMarketingFee = _marketingFee;
    uint256 public _rewardFee = 3;
    uint private previousRewardFee = _rewardFee;
    

    address private charity;
    address private rAndD;
    address private marketing;
    address private legal;
    address private team;
    
    struct Fees {
        uint burnFee;
        uint charityFee;
        uint liquidityFee;
        uint rAndDFee;
        uint marketingFee;
        uint rewardFee;
    }
    
    //Variables and events for swapping
    IUniswapV2Router02 public immutable uniswapV2Router;
    //address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event Received(address sender, uint amount);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    struct Tvalues {
        uint tTransferAmount;
        uint tCharity;
        uint tMarketing;
        uint tRandD;
        uint tReward;
        uint tBurn;
        uint tLiquidity;
    }
    
    struct Rvalues {
        uint rAmount;
        uint rTransferAmount;
        uint rCharity;
        uint rMarketing;
        uint rRandD;
        uint rReward;
        uint rBurn;
        uint rLiquidity;
    }

    event LogLockBoxDeposit(address sender, uint amount, uint releaseTime);   
    event LogLockBoxWithdrawal(address receiver, uint amount);

    uint8 public timeLimit = 1;
    mapping (address => uint) private _timeLock;
    mapping (address => bool) private _isToLock;

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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
    
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        ( , Rvalues memory rValues) = _getValues(tAmount);
        uint rAmount = rValues.rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            ( , Rvalues memory rValues) = _getValues(tAmount);
            return rValues.rAmount;
        } else {
            ( , Rvalues memory rValues) = _getValues(tAmount);
            return rValues.rTransferAmount;
        }
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function removeAllFee() private {
        if(_burnFee == 0 && _charityFee == 0 && _liquidityFee == 0 && _rAndDFee == 0 && _rewardFee == 0 &&_marketingFee == 0 ) return;
        
        previousBurnFee = _burnFee;
        previousCharityFee = _charityFee;
        previousRAndDFee = _rAndDFee;
        previousMarketingFee = _marketingFee;
        previousRewardFee = _rewardFee;
        previousLiquidityFee = _liquidityFee;
        
        _burnFee = 0;
        _charityFee = 0;
        _liquidityFee = 0;
        _rAndDFee = 0;
        _rewardFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _burnFee = previousBurnFee;
        _charityFee = previousCharityFee;
        _liquidityFee = previousLiquidityFee;
        _rAndDFee = previousRAndDFee;
        _marketingFee = previousMarketingFee;
        _rewardFee = previousRewardFee;
    }
    
    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount should be greater than zero");
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= maxTxLimit)
        {
            contractTokenBalance = maxTxLimit;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= liquidityThreshold;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            //sender != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = liquidityThreshold;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }


        bool takeFee = true;

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }

        _tokenTransfer(sender, recipient, amount, takeFee);

    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 60
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),//LP token receiving address
            block.timestamp + 60
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        require(balanceOf(sender) >= amount, 'Insufficient token balance');
        require(_timeLock[sender] <= block.timestamp, 'The from address is locked! Try transfering after locking period');
        
        //Total transcation amount should be less than the maximum transcation limit
        if(!_excludeFromMaxTxLimit[sender]) {
            require(amount <= maxTxLimit, 'Amount exceeds maximum transcation limit!');
        }

        if(!_excludeFromTimeLimit[sender]) {
            require(_isTimeLimit[sender] <= block.timestamp, 'Time limit error!');
        }

        if(!takeFee) {
            removeAllFee();
        }
        
        if(_tTotal <= 100000000 * 10 ** 18) {
            _burnFee = 0;
            previousBurnFee = 0;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
        _isTimeLimit[sender] = block.timestamp.add(timeLimit * 60);
            
    } 

    function _getValues(uint256 tAmount) private view returns (Tvalues memory, Rvalues memory) {
        Tvalues memory tValues = _getTValues(tAmount);
        Rvalues memory rValues = _getRValues(tAmount, tValues, _getRate());
        return (tValues, rValues);
    }

    function _getTValues(uint256 tAmount) private view returns (Tvalues memory) {
        Tvalues memory tValues;
        tValues.tCharity = tAmount.mul(_charityFee).div(10 ** 2);
        tValues.tLiquidity = tAmount.mul(_liquidityFee).div(10 ** 2);
        tValues.tRandD = tAmount.mul(_rAndDFee).div(10 ** 2);
        tValues.tMarketing = tAmount.mul(_marketingFee).div(10 ** 2);
        tValues.tReward = tAmount.mul(_rewardFee).div(10 ** 2);
        tValues.tBurn = tAmount.mul(_burnFee).div(10 ** 2);
        tValues.tTransferAmount = tAmount.sub(tValues.tCharity).sub(tValues.tLiquidity).sub(tValues.tRandD).sub(tValues.tReward).sub(tValues.tMarketing).sub(tValues.tBurn);
        return tValues;
    }

    function _getRValues(uint256 tAmount, Tvalues memory tValues, uint256 currentRate) private pure returns (Rvalues memory) {
        Rvalues memory rValues;
        rValues.rAmount = tAmount.mul(currentRate);
        rValues.rCharity = tValues.tCharity.mul(currentRate);
        rValues.rMarketing = tValues.tMarketing.mul(currentRate);
        rValues.rRandD = tValues.tRandD.mul(currentRate);
        rValues.rReward = tValues.tReward.mul(currentRate);
        rValues.rBurn = tValues.tBurn.mul(currentRate);
        rValues.rLiquidity = tValues.tLiquidity.mul(currentRate);
        rValues.rTransferAmount = rValues.rAmount.sub(rValues.rCharity).sub(rValues.rMarketing).sub(rValues.rRandD).sub(rValues.rReward).sub(rValues.rLiquidity).sub(rValues.rBurn);
        return rValues;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

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
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);        
        _takeLiquidity(sender, tValues.tLiquidity);
        _charityTransfer(sender, tValues.tCharity);
        _marketingTransfer(sender, tValues.tMarketing);
        _rAndDTransfer(sender, tValues.tRandD);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);
        _takeLiquidity(sender, tValues.tLiquidity);
        _charityTransfer(sender, tValues.tCharity);
        _marketingTransfer(sender, tValues.tMarketing);
        _rAndDTransfer(sender, tValues.tRandD);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);           
        _takeLiquidity(sender, tValues.tLiquidity);
        _charityTransfer(sender, tValues.tCharity);
        _marketingTransfer(sender, tValues.tMarketing);
        _rAndDTransfer(sender, tValues.tRandD);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (Tvalues memory tValues, Rvalues memory rValues) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rValues.rTransferAmount);   
        _takeLiquidity(sender, tValues.tLiquidity);
        _charityTransfer(sender, tValues.tCharity);
        _marketingTransfer(sender, tValues.tMarketing);
        _rAndDTransfer(sender, tValues.tRandD);
        _reflectFee(rValues.rReward, tValues.tReward);
        _burn(sender, tValues.tBurn);
        emit Transfer(sender, recipient, tValues.tTransferAmount);
        
    }

    function _burn(address account, uint256 amount) internal virtual {
        if(amount != 0) {
            uint rAmount = amount.mul(_getRate());
            _tTotal -= amount;
            _rTotal -= rAmount;
    
            emit Transfer(account, address(0), amount);
        }
    }
    
    function burn(uint256 amount) external onlyOwner returns(bool) {
        require(amount > 0, "Burn amount less than 0");
        address account = _msgSender();
        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        uint rAmount = amount.mul(_getRate());
        if(_isExcluded[account]) {
            _tOwned[account] = _tOwned[account].sub(amount);
        }
        
        _rOwned[account] = _rOwned[account].sub(rAmount);
        _tTotal -= amount;
        _rTotal -= rAmount;

        emit Transfer(account, address(0), amount);
        return true;
    }

    function _charityTransfer(address sender, uint256 tCharity) internal {
        if(tCharity != 0) {
            uint currentRate = _getRate();
            uint rCharity = tCharity.mul(currentRate);
            _rOwned[charity] = _rOwned[charity].add(rCharity);
            if(_isExcluded[charity])
                _tOwned[charity] = _tOwned[charity].add(tCharity);
                
            emit Transfer(sender, charity, tCharity);
        }
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        if(tLiquidity != 0) {
            uint256 currentRate =  _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
            emit Transfer(sender, address(this), tLiquidity);
        }
    }
    

    function _rAndDTransfer(address sender, uint256 tRandD) internal {
        if(tRandD != 0) {
            uint currentRate = _getRate();
            uint rRandD = tRandD.mul(currentRate);
            _rOwned[rAndD] = _rOwned[rAndD].add(rRandD);
            if(_isExcluded[rAndD])
                _tOwned[rAndD] = _tOwned[rAndD].add(tRandD);
            emit Transfer(sender, rAndD, tRandD);
        }
    }

    function _marketingTransfer(address sender, uint256 tMarketing) internal {
        if(tMarketing != 0) {
            uint currentRate = _getRate();
            uint rMarketing = tMarketing.mul(currentRate);
            _rOwned[marketing] = _rOwned[marketing].add(rMarketing);
            if(_isExcluded[marketing])
                _tOwned[marketing] = _tOwned[marketing].add(tMarketing);
            emit Transfer(sender, marketing, tMarketing);
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function excludeFromFee(address[] memory account) public onlyOwner {
        for(uint i = 0; i < account.length; i++) {
            _isExcludedFromFee[account[i]] = true;
        }
    }
    
    function includeInFee(address[] memory account) public onlyOwner {
        for(uint i = 0; i < account.length; i++) {
            _isExcludedFromFee[account[i]] = false;
        }
    }
    
    
    function transferOwnership(address newOwner) public override virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function setBurnFee(uint value) public onlyOwner {
        _burnFee = value;
        previousBurnFee = value;
    }

    function setLiquidityThreshold(uint value) public onlyOwner {
        liquidityThreshold = value;
    }
    
    function excludeFromMaxTxLimit(address addr) public onlyOwner {
        _excludeFromMaxTxLimit[addr] = true;
    }
    
    function excludeFromTimeLimit(address addr) public onlyOwner {
        _excludeFromTimeLimit[addr] = true;
    }
    
    function setTimeLimit(uint8 value) public onlyOwner {
        timeLimit = value;
    }

    function setTimeLock(address[] memory accounts, uint[] memory _timeInDays) public onlyOwner {
        require(accounts.length == _timeInDays.length, 'Account and timelength mismatch');
        for(uint i = 0; i < accounts.length; i++) {
            require(_isToLock[accounts[i]], 'Not a whitelisted wallet');
            require(_timeLock[accounts[i]] == 0, 'Time limit already added to specified address!');
            _timeLock[accounts[i]] = block.timestamp.add(_timeInDays[i].mul(86400));
        }
    }

    constructor(
        address _charity,  
        address _marketing, 
        address _rAndD, 
        address _legal, 
        address _team,
        address _orgDevelopment
      
        ) {
        _rOwned[_msgSender()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x5049Da20A96e87530eeA11b0a85b9dc8422e109B);
         // Create a uniswap pair for this new token
        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        charity = _charity;
        marketing = _marketing;
        rAndD = _rAndD;
        legal = _legal;
        team = _team;
        
        _isExcludedFromFee[msg.sender] = true;
        _excludeFromMaxTxLimit[msg.sender] = true;
        _excludeFromTimeLimit[msg.sender] = true;
        
        _isExcludedFromFee[address(this)] = true;
        _excludeFromTimeLimit[address(this)] = true;
        
        
        _isToLock[marketing] = true;
        _isToLock[rAndD] = true;
        _isToLock[legal] = true;
        _isToLock[team] = true;
        _isToLock[_orgDevelopment] = true;
        
        emit Transfer(address(0), msg.sender, _tTotal);
    }
}