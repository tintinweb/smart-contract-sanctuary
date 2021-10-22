/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// File: spac/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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
// File: spac/IUniswapV2Factory.sol



pragma solidity >=0.5.0;

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
// File: spac/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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
// File: spac/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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
// File: spac/IERC20.sol



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
// File: spac/Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: spac/Ownable.sol



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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
// File: spac/SafeMath.sol



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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: spac/spacBNB.sol



pragma solidity 0.8.0;







/**
 * $trumpBNB Token
 *
 * Every tx is subject to:
 * - a sell tax, at fixed tranches (see selling_taxes_tranches and selling_taxes_rates - above the last threshold, th tx revert).
      the sell tax is applicable on tx to the uni/pancake pool. This tax goes to the reward pool.
 * - 0.1% flat to the "flexible" wallet -> burn initialy, can be fitted to new projects on the long run
 * - 9.9% to the balancer (which, in turn, fill 2 internal "pools" via the pro_balances struct: reward and liquidity).
 * - a "check and trigger" on both liquidity and reward internal pools -> if they have more token than the threshold, swap is triggered
 *   and BNB are stored in the contract (for the reward subpool) or liquidity is added to the uni pool.
 *   The threshold is adapted to market conditions (via a nodeJS bot)
 *
 * Reward is claimable daily, and is based on the % of the circulating supply (defined as total_supply-dead address balance-pool balance)
 *  owned by the claimer; on the time since the last transfer into owner's wallet module 24; on the BNB balance of the contract :
 *
 *           reward in BNB = (token owned / circulating supply) * [(current time - last transfer in) % 24] / 1 day * BNB contract balance
 *
 * 
 *
 *                    -- Godspeed --
 */

contract spacBNB is Ownable, IERC20 {
    using SafeMath for uint256;

    struct past_tx {
      uint256 cum_transfer; //this is not what you think, you perv
      uint256 last_timestamp;
      uint256 last_claim;
    }

    struct prop_balances {
      uint256 reward_pool;
      uint256 liquidity_pool;
    }

    mapping (address => uint256) private _balances;
    mapping (address => past_tx) private _last_tx;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private excluded;

    uint8 private _decimals = 9;
    uint8 public pcs_pool_to_circ_ratio = 10;

    uint32 public reward_rate = 1 days;

    uint256 private _totalSupply = 10**15 * 10**_decimals;
    uint256 public swap_for_liquidity_threshold = 10**13 * 10**_decimals; //1%
    uint256 public swap_for_reward_threshold = 10**13 * 10**_decimals;

    uint8[4] public selling_taxes_rates = [2, 4, 6, 8];
    uint8[5] public claiming_taxes_rates = [2, 4, 6, 8, 15];
    uint16[5] public selling_taxes_tranches = [125, 250, 500, 750, 1000]; // % and div by 10**4 0.0125% -0.025% -(...)

    bool public circuit_breaker;
    bool private liq_swap_reentrancy_guard;
    bool private reward_swap_reentrancy_guard;

    string private _name = "iSPAC";
    string private _symbol = "iSPAC";

    address public LP_recipient;
    address public devWallet;

    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;

    prop_balances private balancer_balances;

    event TaxRatesChanged();
    event SwapForBNB(string);
    event BalancerPools(uint256,uint256);
    event RewardTaxChanged();
    event AddLiq(string);
    event balancerReset(uint256, uint256);

    constructor (address _router) {
         //create pair to get the pair address
         router = IUniswapV2Router02(_router);
         IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
         pair = IUniswapV2Pair(factory.createPair(address(this), router.WETH()));

         LP_recipient = address(0x000000000000000000000000000000000000dEaD); //LP token: burn
         devWallet = address(0x000000000000000000000000000000000000dEaD); //0.1%: burn

         excluded[msg.sender] = true;
         excluded[address(this)] = true;
         excluded[devWallet] = true; //exclude burn address from max_tx

         circuit_breaker = true; //ERC20 behavior by default/presale
         
         _balances[msg.sender] = _totalSupply;
         emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function decimals() public view returns (uint256) {
         return _decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 sell_tax;
        uint256 dev_tax;
        uint256 balancer_amount;
        
        //>1 day since last tx
        if(block.timestamp > _last_tx[sender].last_timestamp + 1 days) {
          _last_tx[sender].cum_transfer = 0; // a.k.a The Virgin
        }


        if(excluded[sender] == false && excluded[recipient] == false && circuit_breaker == false) {
        
          (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves(); // returns reserve0, reserve1, timestamp last tx
          if(address(this) != pair.token0()) { // 0 := spacBNB
            (_reserve0, _reserve1) = (_reserve1, _reserve0);
          }
          
        // ----  Sell tax  ----
          if(recipient == address(pair)) {
            sell_tax = sellingTax(sender, amount, _reserve0); //will update the balancer ledger too
          }
          
        // ------ "flexible"/dev tax 0.1% -------
          dev_tax = amount.div(1000);

        // ------ balancer tax 9.9% ------
          balancer_amount = amount.mul(99).div(1000);
          balancer(balancer_amount, _reserve0);

          //@dev every extra token are collected into address(this), it's the balancer job to then split them
          //between pool and reward, using the dedicated struct
          _balances[address(this)] += sell_tax.add(balancer_amount);
          _balances[devWallet] += dev_tax;
        }
        //else, by default:
        //  sell_tax = 0;
        //  dev_tax = 0;
        //  balancer_amount = 0;


        //reward reinit
        _last_tx[recipient].last_timestamp = block.timestamp;

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] += amount.sub(sell_tax).sub(dev_tax).sub(balancer_amount);

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, address(this), sell_tax);
        emit Transfer(sender, address(this), balancer_amount);
        emit Transfer(sender, devWallet, dev_tax);
    }

    //@dev take a selling tax if transfer from a non-excluded address or from the pair contract exceed
    //the thresholds defined in selling_taxes_thresholds on 24h floating window
    function sellingTax(address sender, uint256 amount, uint256 pool_balance) internal returns(uint256 sell_tax) {
        uint16[5] memory _tax_tranches = selling_taxes_tranches;
        past_tx memory sender_last_tx = _last_tx[sender];

        uint256 new_cum_sum = amount.add(_last_tx[sender].cum_transfer);

        if(new_cum_sum > pool_balance.mul(_tax_tranches[4]).div(10**4)) {
          revert("Selling tax: above max amount");
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[3]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[3]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[2]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[2]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[1]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[1]).div(100);
        }
        else if(new_cum_sum > pool_balance.mul(_tax_tranches[0]).div(10**4)) {
          sell_tax = amount.mul(selling_taxes_rates[0]).div(100);
        }
        else { sell_tax = 0; }

        _last_tx[sender].cum_transfer = sender_last_tx.cum_transfer.add(amount);

        balancer_balances.reward_pool += sell_tax; //sell tax is for reward:)

        return sell_tax;
    }

    //@dev take the 9.9% taxes as input, split it between reward and liq subpools
    //    according to pool condition -> circ-pool/circ supply closer to one implies
    //    priority to the reward pool
    function balancer(uint256 amount, uint256 pool_balance) internal {

        address DEAD = address(0x000000000000000000000000000000000000dEaD);
        uint256 unwght_circ_supply = totalSupply().sub(_balances[DEAD]);

        // we aim at a set % of liquidity pool (defaut 10% of circ supply), 100% in pancake swap is NOT a good news
        uint256 circ_supply = (pool_balance < unwght_circ_supply * pcs_pool_to_circ_ratio / 100) ? unwght_circ_supply * pcs_pool_to_circ_ratio / 100 : pool_balance;



        balancer_balances.liquidity_pool += (amount.mul(circ_supply.sub(pool_balance)).mul(10**9).div(circ_supply)).div(10**9);
        balancer_balances.reward_pool += (amount.mul(circ_supply.sub((circ_supply.sub(pool_balance)))).mul(10**9).div(circ_supply)).div(10**9);

        prop_balances memory _balancer_balances = balancer_balances;

        if(_balancer_balances.liquidity_pool >= swap_for_liquidity_threshold && !liq_swap_reentrancy_guard) {
            liq_swap_reentrancy_guard = true;
            uint256 token_out = addLiquidity(_balancer_balances.liquidity_pool);
            balancer_balances.liquidity_pool -= token_out; //not balanceOf, in case addLiq revert
            liq_swap_reentrancy_guard = false;
        }

        if(_balancer_balances.reward_pool >= swap_for_reward_threshold && !reward_swap_reentrancy_guard) {
            reward_swap_reentrancy_guard = true;
            uint256 token_out = swapForBNB(_balancer_balances.reward_pool, address(this));
            balancer_balances.reward_pool -= token_out;
            reward_swap_reentrancy_guard = false;
        }

        emit BalancerPools(_balancer_balances.liquidity_pool, _balancer_balances.reward_pool);
    }

    //@dev when triggered, will swap and provide liquidity
    //    BNBfromSwap being the difference between and after the swap, slippage
    //    will result in extra-BNB for the reward pool (free money for the guys:)
    function addLiquidity(uint256 token_amount) internal returns (uint256) {
      uint256 BNBfromReward = address(this).balance;

      address[] memory route = new address[](2);
      route[0] = address(this);
      route[1] = router.WETH();

      if(allowance(address(this), address(router)) < token_amount) {
        _allowances[address(this)][address(router)] = ~uint256(0);
        emit Approval(address(this), address(router), ~uint256(0));
      }
      
      //odd numbers management
      uint256 half = token_amount.div(2);
      uint256 half_2 = token_amount.sub(half);
      
      try router.swapExactTokensForETHSupportingFeeOnTransferTokens(half, 0, route, address(this), block.timestamp) {
        uint256 BNBfromSwap = address(this).balance.sub(BNBfromReward);
        router.addLiquidityETH{value: BNBfromSwap}(address(this), half_2, 0, 0, LP_recipient, block.timestamp); //will not be catched
        emit AddLiq("addLiq: ok");
        return token_amount;
      }
      catch {
        emit AddLiq("addLiq: fail");
        return 0;
      }
    }

    //@dev individual reward is growing linearly througout 24h, and is the portion of the reward pool
    //     weighted by the "free" (ie non-pool non-death) supply owned.
    //     reward = (balance/free supply) * [(now - lastClaim) / 1d] * BNB_balance
    //     If an extra-buy occurs in the last 24h, reset 24h timer (in sell tax)
    //     (frontend will automatize claim then buy)
    //     returns net reward and tax on the reward
    function computeReward() public view returns(uint256, uint256 tax_to_pay) {

      past_tx memory sender_last_tx = _last_tx[msg.sender];

      if(sender_last_tx.last_claim + reward_rate > block.timestamp) { // 1 claim every 24h max
        return (0, 0);//too soon (that's what she said)
      }

      address DEAD = address(0x000000000000000000000000000000000000dEaD);

      uint256 claimable_supply = totalSupply().sub(_balances[DEAD]).sub(_balances[address(pair)]);
      uint256 time_factor = (block.timestamp - sender_last_tx.last_timestamp) % reward_rate;

      uint256 _nom = _balances[msg.sender].mul(time_factor).mul(address(this).balance);
      uint256 _denom = claimable_supply.mul(1 days);
      uint256 gross_reward_in_BNB = _nom.div(_denom);
      tax_to_pay = taxOnClaim(gross_reward_in_BNB);
      return (gross_reward_in_BNB.sub(tax_to_pay), tax_to_pay);
    }

    //@dev Compute the tax on claimed reward - labelled in BNB (as per team agreement)
    function taxOnClaim(uint256 amount) internal view returns(uint256 tax){

      if(amount > 2 ether) { return amount.mul(claiming_taxes_rates[4]).div(100); }
      else if(amount > 1.50 ether) { return amount.mul(claiming_taxes_rates[3]).div(100); }
      else if(amount > 1 ether) { return amount.mul(claiming_taxes_rates[2]).div(100); }
      else if(amount > 0.5 ether) { return amount.mul(claiming_taxes_rates[1]).div(100); }
      else if(amount > 0.25 ether) { return amount.mul(claiming_taxes_rates[0]).div(100); }
      else { return 0; }

    }

    //@dev frontend integration
    function endOfPeriod() external view returns (uint256) {
      return _last_tx[msg.sender].last_claim + reward_rate;
    }

    //@dev computeReward check if last claim is less than 1d ago
    function claimReward() external {
      (uint256 claimable, uint256 tax) = computeReward();
      require(claimable > 0, "Claim: 0");
      _last_tx[msg.sender].last_claim = block.timestamp;
      emit Transfer(msg.sender, address(this), tax);
      safeTransferETH(msg.sender, claimable);
    }

    function swapForBNB(uint256 token_amount, address receiver) internal returns (uint256) {
      address[] memory route = new address[](2);
      route[0] = address(this);
      route[1] = router.WETH();

      if(allowance(address(this), address(router)) < token_amount) {
        _allowances[address(this)][address(router)] = ~uint256(0);
        emit Approval(address(this), address(router), ~uint256(0));
      }

      try router.swapExactTokensForETHSupportingFeeOnTransferTokens(token_amount, 0, route, receiver, block.timestamp) {
        emit SwapForBNB("Swap success");
        return token_amount;
      }
      catch Error(string memory _err) {
        emit SwapForBNB(_err);
        return 0;
      }
    }

    //@dev taken from uniswapV2 TransferHelper lib
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function excludeFromTaxes(address adr) external onlyOwner {
      require(!excluded[adr], "already excluded");
      excluded[adr] = true;
    }

    function includeInTaxes(address adr) external onlyOwner {
      require(excluded[adr], "already taxed");
      excluded[adr] = false;
    }

    function isExcluded(address adr) external view returns (bool){
      return excluded[adr];
    }

    function resetBalancer() external onlyOwner {
      uint256 _contract_balance = _balances[address(this)];
      balancer_balances.reward_pool = _contract_balance.div(2);
      balancer_balances.liquidity_pool = _contract_balance.div(2);
      emit balancerReset(balancer_balances.reward_pool, balancer_balances.liquidity_pool);
    }

    //@dev will bypass all the taxes and act as erc20.
    //     pools & balancer balances will remain untouched
    function setCircuitBreaker(bool status) external onlyOwner {
      circuit_breaker = status;
    }

    //@dev default = burn
    function setLPRecipient(address _LP_recipient) external onlyOwner {
      LP_recipient = _LP_recipient;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
      devWallet = _devWallet;
    }

    function setSwapFor_Liq_Threshold(uint128 threshold_in_token) external onlyOwner {
      swap_for_liquidity_threshold = threshold_in_token * 10**_decimals;
    }

    function setSwapFor_Reward_Threshold(uint128 threshold_in_token) external onlyOwner {
      swap_for_reward_threshold = threshold_in_token * 10**_decimals;
    }

    function setSellingTaxesTranches(uint16[5] memory new_tranches) external onlyOwner {
      selling_taxes_tranches = new_tranches;
      emit TaxRatesChanged();
    }

    function setSellingTaxesrates(uint8[4] memory new_amounts) external onlyOwner {
      selling_taxes_rates = new_amounts;
      emit TaxRatesChanged();
    }

    function setRewardTaxesTranches(uint8[5] memory new_tranches) external onlyOwner {
      claiming_taxes_rates = new_tranches;
      emit RewardTaxChanged();
    }

    function setRewardRate(uint32 new_periodicity) external onlyOwner {
      reward_rate = new_periodicity;
    }

    //@dev fallback in order to receive BNB from swapToBNB
    receive () external payable {}
}