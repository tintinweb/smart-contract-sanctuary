/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 
  This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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

interface IRewardDistributor {
    function addRewardHolderShare(address rewardRecipient, uint256 amount) external;
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




contract shibloki is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    string constant _NAME = "Shibloki";
    string constant _SYMBOL = "SHIBLOKI";
    uint8 constant _DECIMALS = 9;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000000  * 10**9; 
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;


    

    uint8 public referralReward = 10;

    uint8 public liquidityFeeOnBuy = 5;
    uint8 public marketingFeeOnBuy = 4;
    uint8 public HuHdistributionFeeOnBuy = 3;
    

    uint8 public liquidityFeeOnWhiteListedBuy = 1;
    uint8 public marketingFeeOnBuyWhiteListed = 1;
    uint8 public HuHdistributionFeeOnBuyWhiteListed = 8;

    uint8 public liquidityFeeOnSell = 7;
    uint8 public marketingFeeOnSell = 3;
    uint8 public HuHdistributionFeeOnSell = 2;

    uint8 public liquidityFeeOnWhiteListedSell = 1;
    uint8 public marketingFeeOnWhiteListedSell = 1;
    uint8 public HuHdistributionFeeOnWhiteListedSell = 8;
    
    uint256 public launchedAt;

    // State data for statistical purposes ONLY
    uint256 private referralCount;
    uint256 private totalReferralReward;
    mapping(address => uint256) private userReferralCount;
    mapping(address => uint256) private userReferralReward;

    address public referralCodeRegistrator;  
    address public marketingWallet;
    address private constant _DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    mapping(address => bytes) public referCodeForUser;
    mapping(bytes => address) public referUserForCode;
    mapping(address => address) public referParent;
    mapping(address => address[]) public referralList;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isFirstBuy;

    IUniswapV2Router02 public pcsV2Router;
    address public pcsV2Pair;

    IRewardDistributor public rewardDistributor;

    bool public swapEnabled = true;
    uint256 public maxTxAmount = _tTotal.mul(1).div(10**2); // 1% of total supply
    uint256 public amountOfTokensToAddToLiquidityThreshold = 10*10*9; // 

    bool public swapAndLiquifyEnabled = true;
    bool private _inSwap;
    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    event UserWhitelisted(address account, address referee);
    event RegisterCode(address account, bytes code);
    event SwapAndLiquify(uint256 ethReceived, uint256 tokensIntoLiqudity);
    event UpdatePancakeSwapRouter(address pcsV2Router);
    event UpdateRewardDistributor(address newRewardDistributor);
    event UpdateSwapAndLiquifyEnabled(bool swapAndLiquifyEnabled);
    event SetSwapEnabled(bool swapEnabled);
    event ExcludeFromReflection(address account);
    event IncludeInReflection(address account);
    event SetIsExcludedFromFee(address account, bool flag);
    event ChangeFeesForNormalBuy(uint8 liquidityFeeOnBuy, uint8 marketingFeeOnBuy, uint8 HuHdistributionFeeOnBuy);
    event ChangeFeesForWhiteListedBuy(uint8 liquidityFeeOnBuy, uint8 marketingFeeOnBuy, uint8 HuHdistributionFeeOnBuy);
    event ChangeFeesForNormalSell(uint8 liquidityFeeOnSell, uint8 marketingFeeOnSell, uint8 HuHdistributionFeeOnSell);
    event ChangeFeesForWhitelistedSell(uint8 liquidityFeeOnSell, uint8 marketingFeeOnSell, uint8 HuHdistributionFeeOnSell);
    event ChangeReferralReward(uint8 referralReward);
    event UpdateMarketingWallet(address marketingWallet);
    event SetReferralCodeRegistrator(address referralCodeRegistrator);
    event UpdateAmountOfTokensToAddToLiquidityThreshold(uint256 amountOfTokensToAddToLiquidityThreshold);
    event SetMaxTxPercent(uint256 maxTxPercent);

    constructor() {
        IUniswapV2Router02 _pancakeswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        pcsV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pcsV2Router = _pancakeswapV2Router;
        _allowances[address(this)][address(pcsV2Router)] = _MAX;

        rewardDistributor = IRewardDistributor(0x54F0ef830815894b2E8Fc66B400511908bf162B2);
        _allowances[address(this)][address(rewardDistributor)] = _MAX;
        _allowances[address(rewardDistributor)][address(pcsV2Router)] = _MAX;

        marketingWallet = 0xDa31c78f32EC1BF3e878492B154b844D4e616439;

        _rOwned[msg.sender] = _rTotal;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(rewardDistributor)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _excludeFromReflection(address(rewardDistributor));
        _excludeFromReflection(marketingWallet);

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    receive() external payable {}

    fallback() external payable {}

    // Back-Up withdraw, in case BNB gets sent in here
    // NOTE: This function is to be called if and only if BNB gets sent into this contract. 
    // On no other occurence should this function be called. 
    function withdrawEthInWei(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), 'Invalid Recipient!');
        require(amount > 0, 'Invalid Amount!');
        recipient.transfer(amount);
    }

    // Withdraw BEP20 tokens sent to this contract
    // NOTE: This function is to be called if and only if BEP20 tokens gets sent into this contract. 
    // On no other occurence should this function be called. 
    function withdrawTokens(address token, address recipient) external onlyOwner {
        require(token != address(0), 'Invalid Token!');
        require(recipient != address(0), 'Invalid Recipient!');

        uint256 balance = IBEP20(token).balanceOf(address(this));
        if (balance > 0) {
            IBEP20(token).transfer(recipient, balance);
        }
    }

    //  -----------------------------
    //  SETTERS (PROTECTED)
    //  -----------------------------
    function excludeFromReflection(address account) public onlyOwner {
        _excludeFromReflection(account);
        emit ExcludeFromReflection(account);
    }

    function includeInReflection(address account) external onlyOwner {
        _includeInReflection(account);
        emit IncludeInReflection(account);
    }

    function setIsExcludedFromFee(address account, bool flag) external onlyOwner {
        _setIsExcludedFromFee(account, flag);
        emit SetIsExcludedFromFee(account, flag);
    }

    function changeFeesForNormalBuy(uint8 _liquidityFeeOnBuy, uint8 _marketingFeeOnBuy, uint8 _HuHdistributionFeeOnBuy) external onlyOwner {
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        marketingFeeOnBuy = _marketingFeeOnBuy;
        HuHdistributionFeeOnBuy = _HuHdistributionFeeOnBuy;
        emit ChangeFeesForNormalBuy(_liquidityFeeOnBuy, _marketingFeeOnBuy, _HuHdistributionFeeOnBuy);
    }

    function changeFeesForWhiteListedBuy(uint8 _liquidityFeeOnBuy, uint8 _marketingFeeOnBuy, uint8 _HuHdistributionFeeOnBuy) external onlyOwner {
        liquidityFeeOnWhiteListedBuy = _liquidityFeeOnBuy;
        marketingFeeOnBuyWhiteListed = _marketingFeeOnBuy;
        HuHdistributionFeeOnBuyWhiteListed = _HuHdistributionFeeOnBuy;
        emit ChangeFeesForWhiteListedBuy(_liquidityFeeOnBuy, _marketingFeeOnBuy, _HuHdistributionFeeOnBuy);
    }

    function changeFeesForNormalSell(uint8 _liquidityFeeOnSell, uint8 _marketingFeeOnSell, uint8 _HuHdistributionFeeOnSell) external onlyOwner {
        liquidityFeeOnSell = _liquidityFeeOnSell;
        marketingFeeOnSell = _marketingFeeOnSell;
        HuHdistributionFeeOnSell = _HuHdistributionFeeOnSell;
        emit ChangeFeesForNormalSell(_liquidityFeeOnSell, _marketingFeeOnSell, _HuHdistributionFeeOnSell);
    }

    function changeFeesForWhitelistedSell(uint8 _liquidityFeeOnSell, uint8 _marketingFeeOnSell, uint8 _HuHdistributionFeeOnSell) external onlyOwner {
        liquidityFeeOnWhiteListedSell = _liquidityFeeOnSell;
        marketingFeeOnWhiteListedSell = _marketingFeeOnSell;
        HuHdistributionFeeOnWhiteListedSell = _HuHdistributionFeeOnSell;
        emit ChangeFeesForWhitelistedSell(_liquidityFeeOnSell, _marketingFeeOnSell, _HuHdistributionFeeOnSell);
    }

    function changeReferralReward(uint8 _referralReward) external onlyOwner {
        referralReward = _referralReward;
        emit ChangeReferralReward(_referralReward);
    }

    function updateMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != address(0), "Zero address not allowed!");
        marketingWallet = _marketingWallet;
        emit UpdateMarketingWallet(_marketingWallet);
    }

    function setReferralCodeRegistrator(address _referralCodeRegistrator) external onlyOwner {
        require(_referralCodeRegistrator != address(0), "setReferralCodeRegistrator: Zero address not allowed!");
        referralCodeRegistrator = _referralCodeRegistrator;
        emit SetReferralCodeRegistrator(_referralCodeRegistrator);
    }

    function updateAmountOfTokensToAddToLiquidityThreshold(uint256 _amountOfTokensToAddToLiquidityThreshold) external onlyOwner {
        amountOfTokensToAddToLiquidityThreshold = _amountOfTokensToAddToLiquidityThreshold * (10 ** _DECIMALS);
        emit UpdateAmountOfTokensToAddToLiquidityThreshold(_amountOfTokensToAddToLiquidityThreshold);
    }

    function updatePancakeSwapRouter(address _pcsV2Router) external onlyOwner {
        require(_pcsV2Router != address(0), 'PancakeSwap Router Invalid!');
        require(address(pcsV2Router) != _pcsV2Router, 'PancakeSwap Router already exists!');
        pcsV2Router = IUniswapV2Router02(_pcsV2Router);
        pcsV2Pair = IUniswapV2Factory(pcsV2Router.factory()).createPair(address(this), pcsV2Router.WETH());
        _allowances[address(this)][address(pcsV2Router)] = _MAX;
        _allowances[address(rewardDistributor)][address(pcsV2Router)] = _MAX;
        emit UpdatePancakeSwapRouter(_pcsV2Router);
    }

    function updateRewardDistributor(address _rewardDistributor) external onlyOwner {
        require(address(rewardDistributor) != _rewardDistributor, 'Reward Distributor already exists!');
        rewardDistributor = IRewardDistributor(_rewardDistributor);
        _allowances[address(this)][address(rewardDistributor)] = _MAX;
        _allowances[address(rewardDistributor)][address(pcsV2Router)] = _MAX;
        _isExcludedFromFee[address(rewardDistributor)] = true;
        _excludeFromReflection(address(rewardDistributor));
        emit UpdateRewardDistributor(_rewardDistributor);
    }

    function updateSwapAndLiquifyEnabled(bool _swapAndLiquifyEnabled) external onlyOwner {
        require(swapAndLiquifyEnabled != _swapAndLiquifyEnabled, 'Value already exists!');
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
        emit UpdateSwapAndLiquifyEnabled(_swapAndLiquifyEnabled);
    }

    function setSwapEnabled(bool _swapEnabled) external onlyOwner {
        require(swapEnabled != _swapEnabled, 'Value already exists!');
        swapEnabled = _swapEnabled;
        emit SetSwapEnabled(_swapEnabled);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit SetMaxTxPercent(maxTxPercent);
    }

    function registerCodeForOwner(address account, string memory code) external {
        require(msg.sender == referralCodeRegistrator || msg.sender == owner(), "Not autorized!");

        bytes memory code_ = bytes(code);
        require(code_.length > 0, "Invalid code!");
        require(referUserForCode[code_] == address(0), "Code already used!");
        require(referCodeForUser[account].length == 0, "User already generated code!");

        _registerCode(account, code_);
    }

    function registerCode(string memory code) external {
        bytes memory code_ = bytes(code);
        require(code_.length > 0, "Invalid code!");
        require(referUserForCode[code_] == address(0), "Code already used!");
        require(referCodeForUser[msg.sender].length == 0, "User already generated code!");

        _registerCode(msg.sender, code_);
    }

    //  -----------------------------
    //  SETTERS
    //  -----------------------------
    function whitelist(string memory refCode) external {
        bytes memory refCode_ = bytes(refCode);
        require(refCode_.length > 0, "Invalid code!");
        require(!isWhitelisted[msg.sender], "Already whitelisted!");
        require(referUserForCode[refCode_] != address(0), "Non used code!");
        require(referUserForCode[refCode_] != msg.sender, "Invalid code, A -> A refer!");
        require(referParent[referUserForCode[refCode_]] != msg.sender, "Invalid code, A -> B -> A refer!");

        _whitelistWithRef(msg.sender, referUserForCode[refCode_]);
        referralCount = referralCount.add(1);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    //  -----------------------------
    //  GETTERS
    //  -----------------------------
    function name() public pure override returns (string memory) {
        return _NAME;
    }

    function symbol() public pure override returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];

        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcludedFromReflection(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount) public view returns (uint256) {
        uint256 rAmount = tAmount.mul(_getRate());
        return rAmount;
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function getTotalCommunityReflection() public view returns (uint256) {
        return _tFeeTotal;
    }

    function getTotalNumberOfCommunityReferral() public view returns (uint256) {
        return referralCount;
    }

    function getTotalCommunityReferralReward() public view returns (uint256) {
        return totalReferralReward;
    }

    function getReferralList(address account) public view returns (address[] memory) {
        return referralList[account];
    }

    function getTotalNumberOfUserReferral(address account) public view returns (uint256) {
        return userReferralCount[account];
    }

    function getTotalUserReferralReward(address account) public view returns (uint256) {
        return userReferralReward[account];
    }


    //  -----------------------------
    //  INTERNAL
    //  -----------------------------
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
                return (_rTotal, _tTotal);

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }

        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: Transfer amount must be greater than zero");

        require(swapEnabled == true, 'Swap Is Disabled!');

        if(sender != owner() && recipient != owner())
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount");

        if (_inSwap) {
            _basicTransfer(sender, recipient, amount);
            return;
        }

        if (_shouldSwapBack())
            _swapAndAddToLiquidity();

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            _basicTransfer(sender, recipient, amount);
        } else {
            if (recipient == pcsV2Pair) {
                if (isWhitelisted[sender]) {
                    _whitelistedSell(sender, recipient, amount);
                } else {
                    _normalSell(sender, recipient, amount);
                }
            } else if (sender == pcsV2Pair) {
                if (isWhitelisted[recipient] && isFirstBuy[recipient]) {
                    _whitelistedBuy(sender, recipient, amount);
                    isFirstBuy[recipient] = false;
                } else {
                    _normalBuy(sender, recipient, amount);
                }
            } else {
                _basicTransfer(sender, recipient, amount);
            }
        }

        if (launchedAt == 0 && recipient == pcsV2Pair) {
            launchedAt = block.number;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private {
        uint256 rAmount = reflectionFromToken(amount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _normalBuy(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnBuy).mul(currentRate);
        uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnBuy).mul(currentRate);
        uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnBuy).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rLiquidityFee.div(currentRate));

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), (rLiquidityFee).div(currentRate));

        _sendToMarketingWallet(sender, rMarketingFee.div(currentRate), rMarketingFee);
        _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
    }

    function _whitelistedBuy(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 tReferralRewardAmount = amount.div(100).mul(referralReward);
        uint256 rReferralRewardAmount = tReferralRewardAmount.mul(currentRate);
        uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnWhiteListedBuy).mul(currentRate);
        uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnBuyWhiteListed).mul(currentRate);
        uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnBuyWhiteListed).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReferralRewardAmount).sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityFee);

        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rLiquidityFee.div(currentRate));

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), rLiquidityFee.div(currentRate));
        
        _sendToRewardDistributor(sender, referParent[recipient], tReferralRewardAmount, rReferralRewardAmount);
        _sendToMarketingWallet(sender, rMarketingFee.div(currentRate), rMarketingFee);
        _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
    }

    function _normalSell(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnSell).mul(currentRate);
        uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnSell).mul(currentRate);
        uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnSell).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rLiquidityFee.div(currentRate));

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), rLiquidityFee.div(currentRate));

        _sendToMarketingWallet(sender, rMarketingFee.div(currentRate), rMarketingFee);
        _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
    }

    function _whitelistedSell(address sender, address recipient, uint256 amount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);
        uint256 rLiquidityFee = amount.div(100).mul(liquidityFeeOnWhiteListedSell).mul(currentRate);
        uint256 rHuhdistributionFee = amount.div(100).mul(HuHdistributionFeeOnWhiteListedSell).mul(currentRate);
        uint256 rMarketingFee = amount.div(100).mul(marketingFeeOnWhiteListedSell).mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidityFee).sub(rHuhdistributionFee).sub(rMarketingFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityFee);
        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(amount);
        if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient].add(rTransferAmount.div(currentRate));
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(rLiquidityFee.div(currentRate));

        emit Transfer(sender, recipient, rTransferAmount.div(currentRate));
        emit Transfer(sender, address(this), rLiquidityFee.div(currentRate));

        _sendToMarketingWallet(sender, rMarketingFee.div(currentRate), rMarketingFee);
        _reflectFee(rHuhdistributionFee, rHuhdistributionFee.div(currentRate));
    }

    function _sendToRewardDistributor(address sender, address rewardRecipient, uint256 tAmount, uint256 rAmount) private {
        _rOwned[address(rewardDistributor)] = _rOwned[address(rewardDistributor)].add(rAmount);
        if (_isExcluded[address(rewardDistributor)]) _tOwned[address(rewardDistributor)] = _tOwned[address(rewardDistributor)].add(tAmount);

        emit Transfer(sender, address(rewardDistributor), tAmount);
        try rewardDistributor.addRewardHolderShare(rewardRecipient, tAmount) {} catch {}
        userReferralReward[rewardRecipient] = userReferralReward[rewardRecipient].add(tAmount);
        totalReferralReward = totalReferralReward.add(tAmount);
    }

    function _sendToMarketingWallet(address sender, uint256 tMarketingFee, uint256 rMarketingFee) private {
        _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rMarketingFee);
        if (_isExcluded[marketingWallet]) _tOwned[marketingWallet] = _tOwned[marketingWallet].add(tMarketingFee);
        emit Transfer(sender, marketingWallet, tMarketingFee);
    }

    function _shouldSwapBack() private view returns (bool) {
        return msg.sender != pcsV2Pair
            && launchedAt > 0
            && !_inSwap
            && swapAndLiquifyEnabled
            && balanceOf(address(this)) >= amountOfTokensToAddToLiquidityThreshold;
    }

    function _swapAndAddToLiquidity() private swapping {
        uint256 tokenAmountForLiquidity = amountOfTokensToAddToLiquidityThreshold;
        uint256 amountToSwap = tokenAmountForLiquidity.div(2);
        uint256 amountAnotherHalf = tokenAmountForLiquidity.sub(amountToSwap);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pcsV2Router.WETH();

        uint256 balanceBefore = address(this).balance;

        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp.add(30)
        );

        uint256 differenceBnb = address(this).balance.sub(balanceBefore);

        pcsV2Router.addLiquidityETH{value: differenceBnb} (
            address(this),
            amountAnotherHalf,
            0,
            0,
            _DEAD_ADDRESS,
            block.timestamp.add(30)
        );

        emit SwapAndLiquify(differenceBnb, amountToSwap);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _excludeFromReflection(address account) private {
        // require(account !=  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude PancakeSwap router.');
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function _includeInReflection(address account) private {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = reflectionFromToken(_tOwned[account]);
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _setIsExcludedFromFee(address account, bool flag) private {
        _isExcludedFromFee[account] = flag;
    }

    function _whitelistWithRef(address account, address referee) private {
        isFirstBuy[account] = true;
        isWhitelisted[msg.sender] = true;
        referParent[msg.sender] = referee;
        referralList[referee].push(account);
        userReferralCount[referee] = userReferralCount[referee].add(1);
        emit UserWhitelisted(account, referee);
    }

    function _registerCode(address account, bytes memory code) private {
        referUserForCode[code] = account;
        referCodeForUser[account] = code;
        emit RegisterCode(account, code);
    }
}