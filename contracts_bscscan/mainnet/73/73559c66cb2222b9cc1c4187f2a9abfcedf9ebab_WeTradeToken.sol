/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Context from OpenZeppelin
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Ownable from OpenZeppelin
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SafeMath Library
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// IBEP20 interface
interface IBEP20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/// @title WeTrade Token
/// @author Helal Yosra
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects

contract WeTradeToken is IBEP20, Ownable {
    using SafeMath for uint256;

    // General Info WETRADE token
    string private _NAME = "Wetrade";
    string private _SYMBOL = "WETRADE";
    uint8 private _DECIMALS = 18;

    // Pancackeswap info
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // BUSD token on BSC
    address public constant BUSD =
        address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    // addresses
    address payable public _burnWalletAddress =
        payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a 1% of tokens
    address payable public _supplyWalletAddress =
        payable(0x0b8df1aE292723B90Fe556850Af447787b05260D); // Wallet Supply-team
    address payable public _formationWalletAddress =
        payable(0x2D84a8511D5e5299329BB17E386A9E37dA476746); // Wallet formation to receive BUSD rewards CF Wehold
    address payable public _teamWalletAddress =
        payable(0x641d6c8cA429A7587809863a408bE3956906d650); // Wallet Team to receive 1% of transaction fees
    address payable public _rewardsWalletAddress =
        payable(0xd785B74aC532a49627B244D23fd9AEFF14CF5dEC); // Wallet rewards to receive 1% of transcation fees
    address payable public _algoWalletAddress =
        payable(0x42502725Db3296cc28b85A374E1252b762445ED3); // Wallet Algo to receive 7% of transcation fees when price impact >= 2%

    // Token reflection
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**6 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalReflections; // Total reflections

    // Fees exlusion
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    // Token taxes
    uint256 public formationFee = 2;
    uint256 public rewardsFee    = 1;
    uint256 public reflectionFee = 1;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 1;
    uint256 public burnFee = 1;
    uint256 public totalFees = 8;
    uint256 public sellFee = 7;
    uint256 public priceImpact = 2;

    // Track original fees to bypass fees for excluded accounts or when price impact >= 2%
    uint256 private origin_formationFee = formationFee;
    uint256 private origin_rewardsFee   = rewardsFee;
    uint256 private origin_reflectionFee = reflectionFee;
    uint256 private origin_liquidityFee = liquidityFee;
    uint256 private origin_marketingFee = marketingFee;
    uint256 private origin_burnFee = burnFee;
    uint256 private origin_totalFees = totalFees;
    uint256 private origin_sellFee = sellFee;

    // Blacklisting for 2 days after a sell
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public isBlacklistedTo;
    uint256 public blacklistDeadline = 2 days;

    bool public  tradingEnabled;
    bool private currentlySwapping;

    // all events
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(
        address[] accounts,
        bool[] isExcluded
    );
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapAndSendToCFWehold(address to, uint256 tokens);
    event SwapAndSendDividends(address to, uint256 tokens);
    event SwapAndSendToTeam(address to, uint256 tokens);
    event SwapAndSendToAlgo(address to, uint256 tokens);

    modifier lockSwapping() {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }

    constructor() {
        // Mint the total reflection balance to the deployer of this contract (owner)
        _rOwned[_supplyWalletAddress] = _rTotal;

        // PancakeSwap router v2
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        // Create a uniswap pair for this new token (WETRADE/BUSD)
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), BUSD);

        // initialise Pair and Router
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // add new Pair to automatedMarketMakerPairs
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(_supplyWalletAddress, true);
        excludeFromFees(_formationWalletAddress, true);
        excludeFromFees(_teamWalletAddress, true);
        excludeFromFees(_rewardsWalletAddress,true);
        excludeFromFees(_algoWalletAddress, true);

        emit Transfer(address(0), _supplyWalletAddress, _tTotal);
    }

    /// @notice Required to recieve BNB from PancakeSwap V2 Router when swaping
    receive() external payable {}

    /// @notice required to withdraw BNB from this smart contract, only Owner can call this function
    /// @param amount number of BNB to be transfered
    function withdrawBNB(uint256 amount) public onlyOwner {
        if (amount == 0) payable(owner()).transfer(address(this).balance);
        else payable(owner()).transfer(amount);
    }

    /// @notice required to transfer BNB from this smart contract to recipient, only Owner can call this function
    /// @param recipient of BNB
    /// @param amount number of tokens to be transfered
    function transferBNBToAddress(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        recipient.transfer(amount);
    }

    /// @notice required to withdraw foreign tokens from this smart contract, only Owner can call this function
    /// @param token address of the token to withdraw
    function withdrawForeignToken(address token) public onlyOwner {
        require(
            address(this) != address(token),
            "Cannot withdraw native token"
        );
        IBEP20(address(token)).transfer(
            msg.sender,
            IBEP20(token).balanceOf(address(this))
        );
    }

    /// @notice required to withdraw WETRADE tokens from this smart contract, only Owner can call this function
    function withdrawTokens(uint256 _amount) public onlyOwner {
        _approve(address(this), owner(), _amount);
        transferFrom(address(this), owner(), _amount);
    }

    /// @notice name of the token
    /// @return returns name of the token
    function name() public view returns (string memory) {
        return _NAME;
    }

    /// @notice symbol of the token
    /// @return returns symbol of the token
    function symbol() public view returns (string memory) {
        return _SYMBOL;
    }

    /// @notice decimals of the token
    /// @return returns decimals of the token
    function decimals() public view returns (uint8) {
        return _DECIMALS;
    }

    /// @notice totalSupply of the token
    /// @return returns totalSupply of the token
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /// @notice balanceOf an account
    /// @return  Returns the amount of tokens owned by `account`
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /// @notice transfer  moves `amount` tokens from the caller's account to `recipient`.
    /// @param amount number of tokens to transfer
    /// @param recipient address where to send amount
    /// @return a boolean value indicating whether the operation succeeded. Emits a {Transfer} event.
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @notice value changes when {approve} or {transferFrom} are called.
    /// @param owner the owner of tokens
    /// @param spender the spender which will be allowed to spend
    /// @return the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /// @notice sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @param amount number of tokens to be spent
    /// @param spender the spender which will be allowed to spend
    /// @return a boolean value indicating whether the operation succeeded. Emits an {Approval} event.
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @notice sets `amount` as the allowance of `spender` over the caller's tokens.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice moves `amount` tokens from  `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
    /// @param sender the owner of tokens to send
    /// @param recipient address where to send amount
    /// @param amount number of tokens to transfer
    /// @return a boolean value indicating whether the operation succeeded. Emits a {Transfer} event.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "Transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /// @notice increase allowance
    /// @param spender the spender which will be allowed to spend
    /// @param addedValue number of tokens to add to allowance
    /// @return a boolean value indicating whether the operation succeeded.
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /// @notice decrease allowance
    /// @param spender the spender which will be allowed to spend
    /// @param subtractedValue number of tokens to subtract from allowance
    /// @return a boolean value indicating whether the operation succeeded.
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "Decreased allowance below zero"
            )
        );
        return true;
    }

    /// @notice burns a value of tokens, can be called only by owner
    function burn(uint256 _value) external onlyOwner {
        uint256 rFee = _value.mul(_getRate());
        _rOwned[_burnWalletAddress] = _rOwned[_burnWalletAddress].add(rFee);
        if (_isExcludedFromFees[_burnWalletAddress]) {
            _tOwned[_burnWalletAddress] = _tOwned[_burnWalletAddress].add(
                _value
            );
        }

        emit Transfer(owner(), _burnWalletAddress, _value);
    }

    /// @notice exluded from rewards
    /// @param account to check if exluded or not from rewards
    /// @return a boolean value indicating whether the operation succeeded.
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /// @notice Allows a user to voluntarily reflect their tokens to everyone else
    function reflect(uint256 tAmount) public {
        require(
            !_isExcludedFromFees[_msgSender()],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _totalReflections = _totalReflections.add(tAmount);
    }

    /// @notice get total of reflected tokens
    /// @return  Returns the total of tokens reflected
    function getTotalReflections() external view returns (uint256) {
        return _totalReflections;
    }

    /// @notice Converts a token value to a reflection value
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /// @notice Converts a reflection value to a token value
    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    /// @notice exclude from fees an address, only Owner can call this function
    /// @param account to be excluded
    /// @param excluded to be set to true or false
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    /// @notice exclude from fees multiple addresses, only Owner can call this function
    /// @param accounts to be excluded
    /// @param excluded to be set to true or false
    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool[] calldata excluded
    ) external onlyOwner {
        require(
            accounts.length == excluded.length,
            "The length of arrays should be equal"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded[i];
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    /// @notice return if an account is exluded from fees or not
    /// @param account to check
    /// @return returns bool
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /// @notice Excludes an address from receiving reflections
    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcludedFromFees[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromFees[account] = true;
        _excluded.push(account);
    }

    /// @notice Includes an address back into the reflection system
    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromFees[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromFees[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /// @notice set Automated Market Maker Pair to add or remove a pair, only Owner can call this function
    /// @param pair address for Pancackeswap
    /// @param value (true or false)
    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    /// @notice set trading, only Owner can call this function
    /// @param _enabled (true or false)
    function setTrading(bool _enabled) public onlyOwner {
        tradingEnabled = _enabled;
    }

    /// @notice blacklist address, only Owner can call this function
    /// @param account to be blacklisted
    /// @param value (true or false)
    /// @param deadline the limit of blacklisting
    function blacklistAddress(
        address account,
        bool value,
        uint256 deadline
    ) public onlyOwner {
        if (value) {
            require(
                block.timestamp < deadline,
                "The ability to blacklist accounts has been disabled."
            );
        }
        isBlacklisted[account] = value;
        isBlacklistedTo[account] = deadline;
    }

    /// @notice blacklist multiple address, only Owner can call this function
    /// @param accounts to be blacklisted
    /// @param value (true or false)
    /// @param deadlines the limit of blacklisting
    function blacklistMultipleAccounts(
        address[] calldata accounts,
        bool[] calldata value,
        uint256[] calldata deadlines
    ) public onlyOwner {
        require(
            accounts.length == value.length && value.length == deadlines.length,
            "Should be the same length."
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            if (value[i]) {
                require(
                    block.timestamp < deadlines[i],
                    "The ability to blacklist accounts has been disabled."
                );
            }
            isBlacklisted[accounts[i]] = value[i];
            isBlacklistedTo[accounts[i]] = deadlines[i];
        }
    }

    /// @notice whitelist address, only Owner can call this function
    /// @param account to be whitelisted
    function whitelistAddress(address account) public onlyOwner {
        isBlacklisted[account] = false;
        isBlacklistedTo[account] = 0;
    }

    /// @notice update PancakeSwap Router address, only Owner can call this function
    /// @param newAddress of router
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "The router already has that address"
        );
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    /// @notice Collects all the necessary transfer values
    /// @param tAmount token amount
    /// @return reflected amount, reflected transfer amount, reflected fee, token transfered and token fee
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            _getRate()
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    /// @notice Calculates transfer token values
    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = tAmount.mul(totalFees).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    /// @notice Calculates transfer reflection values
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /// @notice Calculates the rate of reflections to tokens
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /// @notice Gets the current supply values
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /// @notice update all fees, onlyOwner can call this function
    function updateFee(
        uint256 _formationFee,
        uint256 _rewardsFee,
        uint256 _reflectionFee,
        uint256 _liquidityFee,
        uint256 _marketingFee,
        uint256 _burnFee,
        uint256 _sellFee
    ) public onlyOwner {
        formationFee = _formationFee;
        rewardsFee = _rewardsFee;
        reflectionFee = _reflectionFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        burnFee = _burnFee;
        sellFee = _sellFee;

        totalFees = formationFee
            .add(rewardsFee)
            .add(reflectionFee)
            .add(liquidityFee)
            .add(marketingFee)
            .add(burnFee);

        origin_formationFee = formationFee;
        origin_rewardsFee = rewardsFee;
        origin_reflectionFee = reflectionFee;
        origin_liquidityFee = liquidityFee;
        origin_marketingFee = marketingFee;
        origin_burnFee = burnFee;
        origin_totalFees = totalFees;
        origin_sellFee = sellFee;
    }

    /// @notice remove all fees and stores their previous values to be later restored
    function removeAllFees() private {
        if (
            formationFee == 0 &&
            rewardsFee == 0 &&
            reflectionFee == 0 &&
            liquidityFee == 0 &&
            marketingFee == 0 &&
            burnFee == 0 &&
            sellFee == 0 &&
            totalFees == 0
        ) return;
        origin_formationFee = formationFee;
        origin_rewardsFee = rewardsFee;
        origin_reflectionFee = reflectionFee;
        origin_liquidityFee = liquidityFee;
        origin_marketingFee = marketingFee;
        origin_burnFee = burnFee;
        origin_totalFees = totalFees;
        origin_sellFee = sellFee;

        formationFee = 0;
        rewardsFee = 0;
        reflectionFee = 0;
        liquidityFee = 0;
        marketingFee = 0;
        burnFee = 0;
        totalFees = 0;
        sellFee = 0;
    }

    /// @notice Restores the fees
    function restoreAllFees() private {
        formationFee = origin_formationFee;
        rewardsFee = origin_rewardsFee;
        reflectionFee = origin_reflectionFee;
        liquidityFee = origin_liquidityFee;
        marketingFee = origin_marketingFee;
        burnFee = origin_burnFee;
        sellFee = origin_sellFee;
        totalFees = origin_totalFees;
    }

    /// @notice set price impact only from owner
    function setPriceImpact(uint256 _percent) external onlyOwner {
        priceImpact = _percent;
    }

    function calculPriceImpactLimit() internal view returns (uint256) {
        return ((uint256(100).sub(priceImpact)).mul(10**_DECIMALS)).div(100);
    }

    /// @notice handles the before and after of a token transfer, such as taking fees and firing off a swap and liquify event
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        if (!_isExcludedFromFees[from]) {
            require(tradingEnabled, "Is trading Disabled.");
        }

        _checkBlacklist(to);
        _checkBlacklist(from);

        if (!automatedMarketMakerPairs[from] && !_isExcludedFromFees[from]) {
            require(
                !isBlacklisted[from] && !isBlacklisted[to],
                "Is blacklisted"
            );
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);

        // Remove fees completely from the transfer if either wallet are excluded
        if (!takeFee) {
            removeAllFees();
        }

        // if sell
        if (takeFee && automatedMarketMakerPairs[to]) {
            if (_priceImpactTax(amount)) {
                totalFees = totalFees.add(sellFee);
            }

            // blacklist for 2 days
            isBlacklisted[from] = true;
            isBlacklistedTo[from] = block.timestamp.add(blacklistDeadline);
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);

        // If we removed the fees for this transaction, then restore them for future transactions
        if (!takeFee) {
            restoreAllFees();
        }

        // If this transaction was a sell, and we took a fee, restore the fee amount back to the original buy amount
        if (takeFee && automatedMarketMakerPairs[to]) {
            totalFees = origin_totalFees;
        }
    }

    /// @notice takes liquidity part to renforce the liquidity pool
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    /// @notice check if the address is blacklisted or not
    function _checkBlacklist(address _blacklisted) private {
        if (
            isBlacklisted[_blacklisted] &&
            isBlacklistedTo[_blacklisted] < block.timestamp &&
            isBlacklistedTo[_blacklisted] != 0
        ) {
            isBlacklisted[_blacklisted] = false;
            isBlacklistedTo[_blacklisted] = 0;
        }
    }

    /// @notice takes all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        // Calculate the values required to execute a transfer
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, ) = _getRValues(
            tAmount,
            tFee,
            _getRate()
        );

        // Transfer from sender to recipient
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (tFee > 0) {
            uint256 tPortion = tFee.div(totalFees);

            // Burn some of the taxed tokens
            _burnTokens(tPortion);

            // Reflect some of the taxed tokens
            _sendToHolder(tPortion, sender);
            _reflectTokens(tPortion);

            // Take the rest of the taxed tokens for the other functions
            _takeTokens(tFee.sub(tPortion).sub(tPortion));
        }

        // Emit an event
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /// @notice burns tokens
    function _burnTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rOwned[_burnWalletAddress] = _rOwned[_burnWalletAddress].add(rFee);
        if (_isExcludedFromFees[_burnWalletAddress]) {
            _tOwned[_burnWalletAddress] = _tOwned[_burnWalletAddress].add(tFee);
        }

        emit Transfer(tx.origin, _burnWalletAddress, tFee);
    }

    /// @notice Increases the rate of how many reflections each token is worth
    function _reflectTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _totalReflections = _totalReflections.add(tFee);
    }

    /// @notice send some 1% tokens to holder
    function _sendToHolder(uint256 tHolder, address sender) private {
        uint256 currentRate = _getRate();
        uint256 rHolder = tHolder.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].add(rHolder);
        _tOwned[sender] = _tOwned[sender].add(tHolder);

        emit Transfer(sender, sender, tHolder);
    }

    /// @notice The contract takes a portion of tokens from taxed transactions
    function _takeTokens(uint256 tTakeAmount) private {
        uint256 currentRate = _getRate();
        uint256 rTakeAmount = tTakeAmount.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTakeAmount);
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tTakeAmount);
        }

        emit Transfer(tx.origin, address(this), tTakeAmount);
    }

    /// @notice swap and liquify WeTrade tokens, only Owner can swap and liquify
    /// 2% liquidity pool (1% WeTrade 1% BUSD) sent to LP (WeTrade/BUSD)
    /// 2% CF Wehold formation to sent to _formationWalletAddress
    /// 1% holders sent to _rewardsWalletAddress
    /// 1% BUSD for team sent to _teamWalletAddress
    /// rest for _algoWalletAddress
    function swapAndLiquify() public onlyOwner lockSwapping {
        uint256 contractTokenBalance = balanceOf(address(this));

        // 2% liquidity and add Liquidity
        uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(100);
        swapAndLiquify(swapTokens);

        // swap the rest of tokens to BUSD
        uint256 initialBUSDBalance = IBEP20(BUSD).balanceOf(address(this));
        uint256 tokensToSwap = balanceOf(address(this));
        swapTokensForBUSD(tokensToSwap);
        uint256 newBalance = (IBEP20(BUSD).balanceOf(address(this))).sub(
            initialBUSDBalance
        );

        IBEP20(BUSD).approve(address(this), newBalance);

        // 2% BUSD for CF Wehold formation
        uint256 formationTokens = newBalance.mul(formationFee).div(100);
        bool success = IBEP20(BUSD).transferFrom(
            address(this),
            _formationWalletAddress,
            formationTokens
        );
        if (success)
            emit SwapAndSendToCFWehold(_formationWalletAddress, formationTokens);

        // 1 % reward holders
        uint256 dividendsTokens = newBalance.mul(rewardsFee).div(100);
        success = IBEP20(BUSD).transferFrom(
            address(this),
            _rewardsWalletAddress,
            dividendsTokens
        );
        if (success) emit SwapAndSendDividends(_rewardsWalletAddress, dividendsTokens);

        // 1 % team
        uint256 teamTokens = newBalance.mul(marketingFee).div(100);
        success = IBEP20(BUSD).transferFrom(
            address(this),
            _teamWalletAddress,
            teamTokens
        );
        if (success) emit SwapAndSendToTeam(_teamWalletAddress, teamTokens);

        // 7% algo
        uint256 sellTokens = newBalance.sub(formationTokens).sub(dividendsTokens).sub(teamTokens);
        success = IBEP20(BUSD).transferFrom(
            address(this),
            _algoWalletAddress,
            sellTokens
        );
        if (success) emit SwapAndSendToAlgo(_algoWalletAddress, sellTokens);
    }

    /// @notice Generates BNB by selling tokens and pairs some of the received BNB with tokens to add and grow the liquidity pool
    function swapAndLiquify(uint256 tokens) private lockSwapping {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBNB(half);

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        if (newBalance > 0) {
            addLiquidity(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    /// @notice Swap tokens for BNB storing the resulting BNB in the contract
    function swapTokensForBNB(uint256 tokenAmount) private lockSwapping {
        // Generate the Pancakeswap pair for token/WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH(); // WETH = WBNB on BSC

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Execute the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp.add(300)
        );
    }

    /// @notice Swaps BNB for tokens and immedietely burns them
    function swapBNBForTokens(uint256 amount) private lockSwapping {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // Accept any amount of RAINBOW
            path,
            _burnWalletAddress, // Burn address
            block.timestamp.add(300)
        );
    }

    /// @notice Adds liquidity to the PancakeSwap V2 LP
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Adds the liquidity and gives the LP tokens to the owner of this contract
        // The LP tokens need to be manually locked
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // Take any amount of tokens (ratio varies)
            0, // Take any amount of BNB (ratio varies)
            owner(),
            block.timestamp.add(300)
        );
    }

    /// @notice Swaps tokens for BUSD and immedietely burns them
    function swapTokensForBUSD(uint256 tokenAmount) private lockSwapping {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BUSD;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswapV2Pair)
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // Check for price impact before doing transfer
    function _priceImpactTax(uint256 amount) internal view returns (bool) {
        (uint256 _reserveA, uint256 _reserveB) = getReserves(
            address(this),
            BUSD
        );
        uint256 _constant = IUniswapV2Pair(uniswapV2Pair).kLast();
        uint256 _market_price = _reserveA.div(_reserveB);

        if (_reserveA == 0 && _reserveB == 0) {
            return false;
        } else {
            if (amount >= _reserveA) return false;

            uint256 _reserveA_new = _reserveA.sub(amount);
            uint256 _reserveB_new = _constant.div(_reserveA_new);

            if (_reserveB >= _reserveB_new) return false;
            uint256 receivedBUSD = _reserveB_new.sub(_reserveB);

            uint256 _new_price = (amount.div(receivedBUSD)).mul(10**18);
            uint256 _delta_price = _new_price.div(_market_price);
            uint256 _priceImpact = calculPriceImpactLimit();

            return (_delta_price < _priceImpact);
        }
    }
}