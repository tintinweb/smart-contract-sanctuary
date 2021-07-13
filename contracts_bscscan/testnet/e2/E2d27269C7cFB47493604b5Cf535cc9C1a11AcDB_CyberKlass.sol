/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: MIT

interface IBEP20 {

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



interface IPancakeRouter02 is IPancakeRouter01 {
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

contract CyberKlass is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 21000000000 * 10**18;
    uint256 private _rTotal = MAX - (MAX % _tTotal);
    uint256 private _tRewardFeeTotal;

    string private constant _name = "CyberKlass";
    string private constant _symbol = "KT04";
    uint8 private constant _decimals = 18;

    uint256 public _defaultRewardTaxRate = 3;
    uint256 public _sellerRewardTaxRate = 9;

    uint256 public _defaultDevelopmentTaxRate = 2;
    uint256 public _sellerDevelopmentTaxRate = 6;

    uint256 public _defaultLiquidityTaxRate = 5;
    uint256 public _sellerLiquidityTaxRate = 15;

    IPancakeRouter02 public _pancakeRouter;
    address public _pancakePair;

    bool _inSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = false;

    // 1.1% of total supply is the maximum transaction amount
    uint256 public constant _maxTxAmount = 231000000 * 10**18;

    // threshold to trigger auto LP supply
    uint256 public _numTokensSellToAddToLiquidity = 5000000 * 10**18;
    
    // LP token lock release time
    uint256 public constant _releaseTime = 1626192000;   // Tuesday, July 13, 2021 11:00:00 PM GMT+07:00
    
    address public _developmentFeeHolder = 0xF33751E60647C3c6f3525CdA3A80995a86Ee3811;
    address public _liquidityFeeHolder = 0x7b18D2Be18f31ab13c3D89d86680742eaBD95519;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqiudity
    );

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor () {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        // Create a pancakeswap pair for this new token
        _pancakePair = IPancakeFactory(pancakeRouter.factory())
        .createPair(address(this), pancakeRouter.WETH());

        // set the rest of the contract variables
        _pancakeRouter = pancakeRouter;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude burn address from reward
        _isExcludedFromReward[address(0)] = true;
        _excludedFromReward.push(address(0));

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalRewardFees() external view returns (uint256) {
        return _tRewardFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, bool isNoFee, bool isSelling) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (uint256 rAmount, uint256 rTransferAmount,,,,,) = _getValues(isNoFee, isSelling, tAmount);
        if (!deductTransferFee) {
            return rAmount;
        } else {
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) external onlyOwner {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }

    // make the router and pair updatable to change liquidity pool if deprecated
    function setRouter(address routerAddress) external onlyOwner {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);
        IPancakeFactory pancakeFactory = IPancakeFactory(pancakeRouter.factory());
        address pairAddress = pancakeFactory.getPair(address(this), pancakeRouter.WETH());
        if (pairAddress == address(0)) {
            _pancakePair = pancakeFactory.createPair(address(this), pancakeRouter.WETH());
        } else {
            _pancakePair = pairAddress;
        }

        // set the rest of the contract variables
        _pancakeRouter = pancakeRouter;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }
    
    function excludeAccountsFromReward(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            excludeFromReward(accounts[i]);
        }
    }

    function includeInReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }
    
    function includeAccountsInReward(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            includeInReward(accounts[i]);
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function excludeAccountsFromFee(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            excludeFromFee(accounts[i]);
        }
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function includeAccountsInFee(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            includeInFee(accounts[i]);
        }
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    function setDefaultTaxRates(uint256 rewardTaxRate, uint256 developmentTaxRate, uint256 liquidityTaxRate) external onlyOwner {
        _defaultRewardTaxRate = rewardTaxRate;
        _defaultDevelopmentTaxRate = developmentTaxRate;
        _defaultLiquidityTaxRate = liquidityTaxRate;
    }

    function setSellerTaxRates(uint256 rewardTaxRate, uint256 developmentTaxRate, uint256 liquidityTaxRate) external onlyOwner {
        _sellerRewardTaxRate = rewardTaxRate;
        _sellerDevelopmentTaxRate = developmentTaxRate;
        _sellerLiquidityTaxRate = liquidityTaxRate;
    }
    
    function releaseLP() public onlyOwner {
        require(block.timestamp >= _releaseTime, "Current time is before release time");

        IBEP20 lpToken = IBEP20(_pancakePair);

        uint256 amount = lpToken.balanceOf(address(this));
        require(amount > 0, "No tokens to release");

        lpToken.transfer(owner(), amount);
    }
    
    function setDevelopmentFeeHolder(address developmentFeeHolder) external onlyOwner {
        _developmentFeeHolder = developmentFeeHolder;
    }
    
    function setLiquidityFeeHolder(address liquidityFeeHolder) external onlyOwner {
        _liquidityFeeHolder = liquidityFeeHolder;
    }

    // to receive BNB from pancakeswap router when swapping
    receive() external payable {}

    function _reflectRewardFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tRewardFeeTotal = _tRewardFeeTotal.add(tFee);
    }

    function _getValues(bool isNoFee, bool isSelling, uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tRewardFee, uint256 tDevelopmentFee, uint256 tLiquidityFee) = _getTValues(isNoFee, isSelling, tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee) = _getRValues(tAmount, tRewardFee, tDevelopmentFee, tLiquidityFee, _getRate());
        return (rAmount, rTransferAmount, rRewardFee, tTransferAmount, tRewardFee, tDevelopmentFee, tLiquidityFee);
    }

    function _getTaxRates(bool isNoFee, bool isSelling) private view returns(uint256, uint256, uint256) {
        if (isNoFee) {
            return (0, 0, 0);
        }

        if (isSelling) {
            return (_sellerRewardTaxRate, _sellerDevelopmentTaxRate, _sellerLiquidityTaxRate);
        } else {
            return (_defaultRewardTaxRate, _defaultDevelopmentTaxRate, _defaultLiquidityTaxRate);
        }
    }

    function _getTValues(bool isNoFee, bool isSelling, uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 rewardTaxRate, uint256 developmentTaxRate, uint256 liquidityTaxRate) = _getTaxRates(isNoFee, isSelling);
        uint256 tRewardFee = calculateFee(tAmount, rewardTaxRate);
        uint256 tDevelopmentFee = calculateFee(tAmount, developmentTaxRate);
        uint256 tLiquidityFee = calculateFee(tAmount, liquidityTaxRate);
        uint256 tTotalFee = tRewardFee.add(tDevelopmentFee).add(tLiquidityFee);
        uint256 tTransferAmount = tAmount.sub(tTotalFee);
        return (tTransferAmount, tRewardFee, tDevelopmentFee, tLiquidityFee);
    }

    function _getRValues(uint256 tAmount, uint256 tRewardFee, uint256 tDevelopmentFee, uint256 tLiquidityFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRewardFee = tRewardFee.mul(currentRate);
        uint256 rDevelopmentFee = tDevelopmentFee.mul(currentRate);
        uint256 rLiquidityFee = tLiquidityFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRewardFee).sub(rDevelopmentFee).sub(rLiquidityFee);
        return (rAmount, rTransferAmount, rRewardFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeFee(uint256 tFee, address feeHolder) private {
        uint256 currentRate =  _getRate();
        uint256 rFee = tFee.mul(currentRate);
        
        _rOwned[feeHolder] = _rOwned[feeHolder].add(rFee);
        if (_isExcludedFromReward[feeHolder]) {
            _tOwned[feeHolder] = _tOwned[feeHolder].add(tFee);
        }
    }

    function calculateFee(uint256 _amount, uint256 taxRate) private pure returns (uint256) {
        return _amount.mul(taxRate).div(
            10**2
        );
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        // only owner can transfer to zero address to burn tokens
        if (from != owner()) {
            require(to != address(0), "BEP20: transfer to the zero address");
        }
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !_inSwapAndLiquify &&
            from != _pancakePair &&
            _swapAndLiquifyEnabled &&
            !(from == address(this) && to == _pancakePair)
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            // add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _approve(address(this), address(_pancakeRouter), tokenAmount);

        // make the swap
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_pancakeRouter), tokenAmount);

        // add the liquidity
        _pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // this method is responsible for taking all fees
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        bool isNoFee = _isExcludedFromFee[sender] || _isExcludedFromFee[recipient];
        bool isSelling = recipient == _pancakePair;

        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tDevelopmentFee, uint256 tLiquidityFee) = _getValues(isNoFee, isSelling, tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (_isExcludedFromReward[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        if (_isExcludedFromReward[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }

        // take development fee
        _takeFee(tDevelopmentFee, _developmentFeeHolder);

        // in case of supplying liquidity to another pool, save liquidity fee to the external wallet if _swapAndLiquifyEnabled is false
        address liquidityFeeSavingAddress = _swapAndLiquifyEnabled ? address(this) : _liquidityFeeHolder;
        // take liquidity fee
        _takeFee(tLiquidityFee, liquidityFeeSavingAddress);

        _reflectRewardFee(rRewardFee, tRewardFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }
}