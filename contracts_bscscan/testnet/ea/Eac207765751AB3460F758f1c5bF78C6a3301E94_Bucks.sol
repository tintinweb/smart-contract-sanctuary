/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity ^0.8.4;


// // SPDX-License-Identifier:MIT

// interface IBEP20 {

//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }



// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


 
contract Ownable is Context {
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = payable(0x1dce55E0382A075dd8ADc7A726984122145964AC);
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public virtual onlyOwner {
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
        _owner = payable(address(0));
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until defined days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = payable(address(0));
    }
}


interface IPancakeFactory {
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


interface IPancakePair {
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

    // function DOMAIN_SEPARATOR() external view returns (bytes32);
    // function PERMIT_TYPEHASH() external pure returns (bytes32);
    // function nonces(address owner) external view returns (uint);

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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

    // function MINIMUM_LIQUIDITY() external pure returns (uint);
    // function factory() external view returns (address);
    // function token0() external view returns (address);
    // function token1() external view returns (address);
    // function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    // function price0CumulativeLast() external view returns (uint);
    // function price1CumulativeLast() external view returns (uint);
    // function kLast() external view returns (uint);

    // function mint(address to) external returns (uint liquidity);
    // function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    // function skim(address to) external;
    // function sync() external;

    // function initialize(address, address) external;
}

interface IPancakeRouter01 {
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
    // function removeLiquidityETH(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountToken, uint amountETH);
    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountA, uint amountB);
    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountToken, uint amountETH);
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

    // function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    // function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    // function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    // function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    // function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);
    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

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

 // Protocol by team BloctechSolutions.com 

contract Bucks is Context, Ownable {
    using SafeMath for uint256;
    // using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;

    address[] private _excluded;
    
    // mapping(uint256=>uint256)public transfertax;
    // mapping(uint256=>uint256)public rewardPercent;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 5000000000 *1e4;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "bucks";
    string private _symbol = "KIWI";
    uint8 private _decimals = 9;

    IPancakeRouter02 public pancakeRouter;
    address public immutable pancakePair;
    address payable public marketWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
     
     uint256 public rewardtokens;

    
    address public charityWallet;
    
    address public devWallet;
    
    uint256 public _maxTxAmount = _tTotal.mul(5).div(1000); // should be 0.5% percent per transaction
    bool public swapAndLiquifyEnabled = false; // should be true to turn on to liquidate the pool
    bool inSwapAndLiquify = false;
    bool reflectionFeesdiabled = false;
    
    uint256 public _taxFee = 100; // 5% will be distributed among holder as JOKER divideneds
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _rewardFee = 200; // 5% will be distributed among holder as JOKER divideneds
    uint256 private _previousRewardFee = _rewardFee;

    uint256 public _devFee = 95; // 5% will be distributed among holder as JOKER divideneds //1000
    uint256 private _previousdevFee = _devFee;


    uint256 public _liquidityFee = 200; // 3% will be added to the liquidity pool
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _charityFee = 50;  // 7% will go to the lottery pool 
    uint256 private _previouscharityFee = _charityFee;
    
    // uint256 public _marketFee = 20;  // 2% will go to the market address 
    // uint256 private _previousMarketFee = _marketFee;
    
    // uint256 public _burnFee = 20;  // 2% will go to the Dead address to deflate JOKER
    // uint256 private _previousBurnFee = _burnFee;
    
    uint256 minTokenNumberToSell = _tTotal.div(100000); // 0.001% max tx amount will trigger swap and add liquidity

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address payable _devWallet,address payable _charitywallet) {
        _rOwned[owner()] = _rTotal;
        devWallet = _devWallet;
        charityWallet=_charitywallet;
       
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
        .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[address(burnAddress)] = true;



        // emit Transfer(address(0), owner(), _tTotal);
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

    function totalSupply() public view  returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view  returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public  returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        // (uint256 rAmount,,,,,) = _getValues(tAmount);
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            // (uint256 rAmount,,,,,) = _getValues(tAmount);
            uint256 rAmount = tAmount.mul(_getRate());
            return rAmount;
        } else {
            // (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            uint256 rAmount = tAmount.mul(_getRate());
            uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(_getRate()));
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account].mul(_getRate());
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    // admin setter functions

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }
    
    function setrewardFeePercent(uint256 rewardFee) external onlyOwner {
        _rewardFee = rewardFee;
    }
    
    function setDevFeePercent(uint256 devFee) external onlyOwner {
        _devFee = devFee;
    }
    
    function setcharityFeePercent(uint256 charityFee) external onlyOwner {
        _charityFee = charityFee;
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }
    
    function setReflectionFees(bool _state) external onlyOwner {
        reflectionFeesdiabled = _state;
    }
    
    
    
    function setPancakeRouter(IPancakeRouter02 _pancakeRouter) external onlyOwner {
        pancakeRouter = _pancakeRouter;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}
    
    function totalFeePerTx(uint256 tAmount) internal view returns(uint256) {
        uint256 percentage = tAmount.mul(_taxFee.add(_liquidityFee).add(_rewardFee).add(_devFee).add(_charityFee)).div(1e4);
        return percentage;
    }
    
    // distribution to holders
    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = tAmount.mul(_taxFee).div(1e3);
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
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

    
    function _takeDevFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 tDevFee = tAmount.mul(_devFee).div(1e4);
        uint256 rDevFee = tDevFee.mul(currentRate);
        _rOwned[devWallet] = _rOwned[devWallet].add(rDevFee);
        if (_isExcluded[devWallet])
            _tOwned[devWallet] = _tOwned[devWallet].add(tDevFee);
        // emit Transfer(_msgSender(), devWallet, tDevFee);
    }
    
    function _takeCharityFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 charityFee = tAmount.mul(_charityFee).div(1e3);
        uint256 rcharityFee = charityFee.mul(currentRate);
        _rOwned[charityWallet] = _rOwned[charityWallet].add(rcharityFee);
        if (_isExcluded[charityWallet])
            _tOwned[charityWallet] = _tOwned[charityWallet].add(charityFee);
        // emit Transfer(_msgSender(), charityWallet, charityFee);
    }
    
    function takerewardFee(uint256 tAmount)internal{
        rewardtokens=rewardtokens.add(tAmount.mul(_rewardFee).div(1e4));
    }

    function removeAllFee() private {
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousRewardFee = _rewardFee;
        _previousdevFee = _devFee;
        _previouscharityFee = _charityFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _rewardFee = 0;
        _devFee = 0;
        _charityFee = 0;
    }
    
    function removeBuyFee() private {
        _previousLiquidityFee = _liquidityFee;
        _previousRewardFee = _rewardFee;
        _previousdevFee = _devFee;
        _previouscharityFee=_charityFee;
        _liquidityFee = 0;
        _rewardFee = 0;
        _devFee = 0;
        _charityFee=0;
    }
    
    function removeSellFee() private {
         _previousTaxFee = _taxFee;
        _previousdevFee = _devFee;
        _previouscharityFee=_charityFee;
        _taxFee = 0;
        _devFee = 0;
        
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previouscharityFee;
        _devFee = _previousdevFee;
        _rewardFee = _previousRewardFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        // emit Approval(owner, spender, amount);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount);
        // if(to == pancakePair)
            // require(_withdrawTime[from].add(24 hours) >= block.timestamp,"BEP20: cannot sell twice a day");

        // _withdrawTime[from] = block.timestamp;

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        amount=takeTransferFee(amount);
        
        uint256 _rewardtokens =giveTransferReward(rewardtokens);
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        
        
            uint256 initialBalance = address(this).balance;
            
            
        swapTokensForEth(_rewardtokens);
        
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        payable(msg.sender).transfer(newBalance);
        
        // bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            // overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            // contractTokenBalance = _numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }


    //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
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
    }  
    function takeTransferFee(uint256 amount)public pure returns(uint256){
        if(amount<100e4){
            return(amount.sub(amount.mul(10).div(100)));
        }
        else if(amount>=100e4 && amount < 500e4){
            return(amount.sub(amount.mul(9).div(100)));
        }
        else if(amount>=500e4 && amount < 1000e4){
            return(amount.sub(amount.mul(8).div(100)));
        }
        else if(amount>=1000e4 && amount < 10000e4){
            return(amount.sub(amount.mul(7).div(100)));
        }
        else if(amount>=10000e4 && amount < 100000e4){
            return(amount.sub(amount.mul(6).div(100)));
        }
        else{
            return(amount.sub(amount.mul(5).div(100)));
        }
        
    }
    
    function giveTransferReward(uint256 amount)public pure returns(uint256){
        if(amount<100e4){
            return(amount.mul(4).div(100));
        }
        else if(amount>=100e4 && amount < 500e4){
            return(amount.mul(36).div(1000));
        }
        else if(amount>=500e4 && amount < 1000e4){
            return(amount.mul(32).div(1000));
        }
        else if(amount>=1000e4 && amount < 10000e4){
            return(amount.mul(28).div(1000));
        }
        else if(amount>=10000e4 && amount < 100000e4){
            return(amount.mul(24).div(1000));
        }
        else{
            return(amount.mul(2).div(100));
        }
        
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeDevFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        takerewardFee(tAmount);
        _reflectFee(tAmount);
        // emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeDevFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        takerewardFee(tAmount);
        _reflectFee(tAmount);
        // emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeDevFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        takerewardFee(tAmount);
        _reflectFee(tAmount);
        // emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(totalFeePerTx(tAmount).mul(currentRate));
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeDevFee(tAmount, currentRate);
        _takeCharityFee(tAmount, currentRate);
        takerewardFee(tAmount);
        _reflectFee(tAmount);
        // emit Transfer(sender, recipient, tTransferAmount);
    }
 
    // for 1% input 100
    function setMaxTxPercent(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxAmount).div(10000);
    }
    
    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool value) public onlyOwner {
        _isExcludedFromMaxTx[_address] = value;
    }
    
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
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
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }


    // function swapAndLiquify(address from, address to) private {
    //     // is the token balance of this contract address over the min number of
    //     // tokens that we need to initiate a swap + liquidity lock?
    //     // also, don't get caught in a circular liquidity event.
    //     // also, don't swap & liquify if sender is pancake pair.
    //     uint256 contractTokenBalance = balanceOf(address(this));

    //     if (contractTokenBalance >= _maxTxAmount) {
    //         contractTokenBalance = _maxTxAmount;
    //     }

    //     bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

    //     if (
    //         !inSwapAndLiquify &&
    //         shouldSell &&
    //         from != pancakePair &&
    //         swapAndLiquifyEnabled &&
    //         !(from == address(this) && to == address(pancakePair)) // swap 1 time
    //     ) {
    //         // only sell for minTokenNumberToSell, decouple from _maxTxAmount
    //         // split the contract balance into 4 pieces
            
    //         contractTokenBalance = minTokenNumberToSell;
    //         // approve contract
    //         _approve(address(this), address(pancakeRouter), contractTokenBalance);

    //         uint256 totalPercent = _liquidityFee.add(_lotteryFee);
    //         uint256 liquidityPercent = _liquidityFee.mul(1e4).div(totalPercent).div(2);
    //         uint256 lotteryPercent = _lotteryFee.mul(1e4).div(totalPercent);
            
    //         // add liquidity
    //         // split the contract balance into 2 pieces
            
    //         uint256 otherPiece = contractTokenBalance.mul(liquidityPercent).div(1e4);
    //         uint256 tokenAmountToBeSwapped = contractTokenBalance.sub(otherPiece);
            
    //         uint256 initialBalance = address(this).balance;

    //         // now is to lock into staking pool
    //         Utils.swapTokensForEth(address(pancakeRouter), tokenAmountToBeSwapped);

    //         // how much BNB did we just swap into?

    //         // capture the contract's current BNB balance.
    //         // this is so that we can capture exactly the amount of BNB that the
    //         // swap creates, and not make the liquidity event include any BNB that
    //         // has been manually sent to the contract
    //         uint256 deltaBalance = address(this).balance.sub(initialBalance);
            
    //         totalPercent = liquidityPercent.add(lotteryPercent);

    //         uint256 bnbToBeAddedToLiquidity = deltaBalance.mul(liquidityPercent).div(totalPercent);

    //         // add liquidity to pancake
    //         Utils.addLiquidity(address(pancakeRouter), owner(), otherPiece, bnbToBeAddedToLiquidity);
            
    //         emit SwapAndLiquify(tokenAmountToBeSwapped, deltaBalance, otherPiece);
    //     }
    // }
    
    
}