/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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
        return payable(msg.sender);
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
}

// pragma solidity >=0.5.0;

interface ISwapFactory {
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

interface ISwapPair {
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

interface ISwapRouter01 {
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

interface ISwapRouter02 is ISwapRouter01 {
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


contract Minority is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private reflectiveBalances;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    mapping (address => bool) private isExcludedFromFee;

    mapping (address => bool) private isExcluded;
    address[] private excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOTAL_SUPPLY = 2000000000 * 10**9; // 2 billion total supply
    uint256 private reflectiveTotal = (MAX - (MAX % TOTAL_SUPPLY));

    string private constant NAME = "Minority";
    string private constant SYMBOL = "MINORITY";
    uint8 private constant DECIMALS = 9;
    
    uint8 public reflectionFee = 2; // 2% of each transaction redistributed to all existing holders via reflection
    uint8 public liquidityFee = 2; // 2% of each transaction added to LP Pool. The LP adding is only executed when a sell occurs and the contract balance > MIN_CONTRACT_BALANCE_TO_ADD_LP
    uint8 public burnFee = 2; // 2% of each transaction sent to burn address
    uint8 public treasuryFee = 2; // 2% of each transaction sent to Treasury Wallet
    uint8 public rewardFee = 2; // 2% of each transaction sent to Reward Wallet
    uint256 public totalTxFees = uint256(reflectionFee).add(liquidityFee).add(burnFee).add(treasuryFee).add(rewardFee); // Makes some calculations easier. Capped at 25 in setFeePercentages
    
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; // NOTE: no quotes round the address
    address public treasuryWallet = BURN_ADDRESS; // needs to be decided - placeholder of burn address for testing purposes, check note on BURN_ADDRESS before changing
    address public rewardWallet = BURN_ADDRESS; // needs to be decided - placeholder of burn address for testing purposes, check note on BURN_ADDRESS before changing
    
    ISwapRouter02 public swapRouter;
    address public swapPair;
    
    address constant public USDC = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
    
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public maxTxAmount = TOTAL_SUPPLY.div(100); // needs to be decided - suggested 1% total supply (20,000,000 tokens)
    uint256 private constant MIN_CONTRACT_BALANCE_TO_ADD_LP = 20000; // suggested 20,000 tokens = $200 at initial Mcap - if the tokenomics are changed to reduce this mcap then would change accordingly
    
    bool test;
    bool test2;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event ExcludedFromReward(address indexed account);
    event IncludedInReward(address indexed account);
    event ExcludedFromFee(address indexed account);
    event IncludedInFee(address indexed account);
    event FeesChanged (uint256 oldReflectionFee, uint256 newReflectionFee, uint256 oldLiquidityFee, uint256 newLiquidityFee, 
                        uint256 oldTreasuryFee, uint256 newTreasuryFee, uint256 oldBurnFee, uint256 newBurnFee, uint256 oldRewardFee, uint256 newRewardFee);
    event MaxTxAmountChanged (uint256 oldMaxTxAmount, uint256 newMaxTxAmount);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        reflectiveBalances[_msgSender()] = reflectiveTotal;
        
        ISwapRouter02 _swapRouter = ISwapRouter02 (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // changed to quickswap router - 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
         // Create a pair for this new token
        swapPair = ISwapFactory (_swapRouter.factory()).createPair(address(this), USDC);
        swapRouter = _swapRouter;
        
        //exclude owner and this contract from fee
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[treasuryWallet] = true;
        isExcludedFromFee[rewardWallet] = true;
        isExcludedFromFee[BURN_ADDRESS] = true; // Manual burns exempt from fees
        isExcluded[swapPair] = true;
        excluded.push(swapPair); // Stop skimming
        
        emit Transfer (address(0), _msgSender(), TOTAL_SUPPLY);
    }
    
    function setTest(bool _test, bool _test2) public {
        test = _test;
        test2 = _test2;
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf (address account) public view override returns (uint256) {
        if (isExcluded[account]) return balances[account];
        return tokenFromReflection(reflectiveBalances[account]);
    }

    function transfer (address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance (address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve (address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance (address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance (address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward (address account) public view returns (bool) {
        return isExcluded[account];
    }
    
    function tokenFromReflection (uint256 reflectionAmount) public view returns (uint256) {
        require (reflectionAmount <= reflectiveTotal, "Amount must be less than total reflections");
        uint256 currentRate =  getRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeFromReward (address account) public onlyOwner() {
        require(!isExcluded[account], "Account is already excluded");
        
        if (reflectiveBalances[account] > 0)
            balances[account] = tokenFromReflection(reflectiveBalances[account]);
        
        isExcluded[account] = true;
        excluded.push(account);
        emit ExcludedFromReward(account);
    }

    function includeInReward (address account) external onlyOwner() {
        require (isExcluded[account], "Account is already included");
        
        for (uint256 i = 0; i < excluded.length; i++) {
            if (excluded[i] == account) {
                excluded[i] = excluded[excluded.length - 1];
                balances[account] = 0;
                isExcluded[account] = false;
                excluded.pop();
                break;
            }
        }
        
        emit IncludedInReward(account);
    }
    
    function excludeFromFee (address account) public onlyOwner {
        isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee (address account) public onlyOwner {
        isExcludedFromFee[account] = false;
        emit IncludedInFee(account);
    }
    
    function setFeePercentages (uint8 _reflectionFee, uint8 _liquidityFee, uint8 _treasuryFee, uint8 _burnFee, uint8 _rewardFee) external onlyOwner() {
        uint256 _totalTxFees = uint256(_reflectionFee).add(_liquidityFee).add(_treasuryFee).add(_burnFee).add(_rewardFee);
        require (_totalTxFees <= 25, "Total fees too high"); // Set a cap to protect users
        emit FeesChanged (reflectionFee, _reflectionFee, liquidityFee, _liquidityFee, treasuryFee, _treasuryFee, burnFee, _burnFee, rewardFee, _rewardFee);
        reflectionFee = _reflectionFee;
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        burnFee = _burnFee;
        rewardFee = _rewardFee;
        totalTxFees = _totalTxFees;
    }

    function setTreasuryWallet (address _treasuryWallet) external onlyOwner() {
        require (_treasuryWallet != address(0), "Wallet can't be set to the zero address"); // safety check - transfers to the 0 address fail
        treasuryWallet = _treasuryWallet;
    }

    function setRewardWallet (address _rewardWallet) external onlyOwner() {
        require (_rewardWallet != address(0), "Wallet can't be set to the zero address");
        rewardWallet = _rewardWallet;
    }
   
    function setMaxTxPercent (uint256 maxTxPercent) external onlyOwner() {
        require (maxTxPercent < 100, "Max Tx can't be > 100%");
        uint256 _maxTxAmount = TOTAL_SUPPLY.mul(maxTxPercent).div(100);
        emit MaxTxAmountChanged (maxTxAmount, _maxTxAmount);
        maxTxAmount = _maxTxAmount;
    }

    function setSwapAndLiquifyEnabled (bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from swapRouter when swaping
    receive() external payable {}

    function reflectFee (uint256 rReflectionFee) private {
        reflectiveTotal = reflectiveTotal.sub(rReflectionFee);
    }

    function getValues (uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflectionFee, uint256 tOtherFees) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflectionFee) = getRValues(tAmount, tReflectionFee, tOtherFees, getRate());
        return (rAmount, rTransferAmount, rReflectionFee, tTransferAmount, tOtherFees);
    }

    function getTValues (uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tReflectionFee = tAmount.mul(reflectionFee).div(100);
        uint256 tOtherFees = tAmount.mul(totalTxFees.sub(reflectionFee)).div(100); // Calculate other fees together as we don't need to separate these out until later
        uint256 tTransferAmount = tAmount.sub(tReflectionFee).sub(tOtherFees);
        return (tTransferAmount, tReflectionFee, tOtherFees);
    }

    function getRValues (uint256 tAmount, uint256 tReflectionFee, uint256 tOtherFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflectionFee = tReflectionFee.mul(currentRate);
        uint256 rOtherFees = tOtherFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReflectionFee).sub(rOtherFees);
        return (rAmount, rTransferAmount, rReflectionFee);
    }

    function getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = reflectiveTotal;
        uint256 tSupply = TOTAL_SUPPLY;    
        
        for (uint256 i = 0; i < excluded.length; i++) {
            if (reflectiveBalances[excluded[i]] > rSupply || balances[excluded[i]] > tSupply) 
                return (reflectiveTotal, TOTAL_SUPPLY);
                
            rSupply = rSupply.sub(reflectiveBalances[excluded[i]]);
            tSupply = tSupply.sub(balances[excluded[i]]);
        }
        
        if (rSupply < reflectiveTotal.div(TOTAL_SUPPLY)) 
            return (reflectiveTotal, TOTAL_SUPPLY);
            
        return (rSupply, tSupply);
    }
    
    function checkIfExcludedFromFee (address account) public view returns (bool) {
        return isExcludedFromFee[account];
    }

    function _approve (address owner, address spender, uint256 amount) private {
        require (owner != address(0), "ERC20: approve from the zero address");
        require (spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer (address sender, address recipient, uint256 amount) private {
        require (sender != address(0), "ERC20: transfer from the zero address");
        require (recipient != address(0), "ERC20: transfer to the zero address");
        require (amount > 0, "Transfer amount must be greater than zero");
        
        if (sender != owner() && recipient != owner())
            require(amount <= maxTxAmount, "Transfer amount exceeds the _maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= maxTxAmount)
            contractTokenBalance = maxTxAmount;
        
        // Only swap if the contract balance is over the minimum specified, it is a sell, and we're not already liquifying
        if (contractTokenBalance >= MIN_CONTRACT_BALANCE_TO_ADD_LP && !inSwapAndLiquify && sender != swapPair && swapAndLiquifyEnabled)
            swapAndLiquify(contractTokenBalance);
        
        //indicates if fee should be deducted from transfer
        bool feesEnabled = true;
        
        //if any account belongs to isExcludedFromFee account then remove the fee
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient])
            feesEnabled = false;
        
        //transfer amount, it will take all fees
        tokenTransfer (sender, recipient, amount, feesEnabled);
    }

    function swapAndLiquify (uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves, swap half for weth then add liquidity
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 usdcCreated = swapTokensForUSDC(half); 
        if (test && test2)
            addLiquidity (otherHalf, usdcCreated);
        emit SwapAndLiquify(half, usdcCreated, otherHalf);
    }

    function swapTokensForUSDC (uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = IERC20(USDC).balanceOf(address(this));
        
        // generate the swap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        _approve(address(this), address(swapRouter), tokenAmount);

        if (test) {
            // make the swap
            swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of USDC
                path,
                address(this),
                block.timestamp
            );
        } else if (test2) {
            // make the swap
            swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of USDC
                path,
                owner(),
                block.timestamp
            );
        }
        
        // Return how much eth we created
        return IERC20(USDC).balanceOf(address(this)).sub(initialBalance);
    }

    function addLiquidity (uint256 tokenAmount, uint256 usdcAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapRouter), tokenAmount);
        _approve(USDC, address(swapRouter), usdcAmount);

        // add the liquidity
        (,uint256 usdcFromLiquidity,) = swapRouter.addLiquidity(
            address(this),
            USDC,
            tokenAmount,
            usdcAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        
        if (usdcAmount - usdcFromLiquidity > 0)
            IERC20(USDC).transfer (treasuryWallet, usdcAmount - usdcFromLiquidity);
    }
    
    // Sends fees to their destination addresses, ensuring the result will be shown correctly on blockchain viewing sites (eg polygonscan)
    function takeFee (uint256 tFeeAmount, address feeWallet, address sender) private {
        uint256 rFeeAmount = tFeeAmount.mul(getRate());
        reflectiveBalances[feeWallet] = reflectiveBalances[feeWallet].add(rFeeAmount);
        
        if(isExcluded[feeWallet])
            balances[feeWallet] = balances[feeWallet].add(tFeeAmount);
            
        emit Transfer(sender, feeWallet, tFeeAmount);
    }
    
    // Splits tOtherFees into its constiuent parts and sends each of them
    function takeOtherFees (uint256 tOtherFees, address sender) private {
        uint256 otherFeesDivisor = totalTxFees.sub(reflectionFee);
        takeFee (tOtherFees.mul(liquidityFee).div(otherFeesDivisor), address(this), sender);
        takeFee (tOtherFees.mul(treasuryFee).div(otherFeesDivisor), treasuryWallet, sender);
        takeFee (tOtherFees.mul(rewardFee).div(otherFeesDivisor), rewardWallet, sender);
        takeFee (tOtherFees.mul(burnFee).div(otherFeesDivisor), BURN_ADDRESS, sender);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function tokenTransfer(address sender, address recipient, uint256 tAmount, bool feesEnabled) private {
        uint256 rAmount = 0;
        uint256 rTransferAmount = 0;
        uint256 rReflectionFee = 0;
        uint256 tTransferAmount = 0;
        uint256 tOtherFees = 0;
        
        if (!feesEnabled) {
            (rAmount,,,,) = getValues (tAmount);
            rTransferAmount = rAmount;
            tTransferAmount = tAmount;
        } else {
            (rAmount, rTransferAmount, rReflectionFee, tTransferAmount, tOtherFees) = getValues (tAmount);
        }
        
        reflectiveBalances[sender] = reflectiveBalances[sender].sub(rAmount);
        reflectiveBalances[recipient] = reflectiveBalances[recipient].add(rTransferAmount);
        
        if (isExcluded[sender])
            balances[sender] = balances[sender].sub(tAmount);
            
        if (isExcluded[recipient])
            balances[recipient] = balances[recipient].add(tTransferAmount);
        
        if (tOtherFees > 0)
            takeOtherFees (tOtherFees, sender);
        
        if (rReflectionFee > 0)
            reflectFee (rReflectionFee);
        
        emit Transfer (sender, recipient, tTransferAmount);
    }
}