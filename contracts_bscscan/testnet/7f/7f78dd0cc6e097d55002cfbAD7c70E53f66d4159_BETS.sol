/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// SPDX-License-Identifier: NO LICENSE
pragma solidity >=0.7.0 <0.9.0;

/**
 * BETSWAMP
 */

/**
 * SafeMath
 * Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 1;
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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

/**
 * @dev contract handles all ownership operations which provides
 * basic access control mechanism where an account (owner) is granted
 * exclusive access to specific functions
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev initializes the contract deployer as the initial owner
     */
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call function.");
        _;
    }

    /**
     *  Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev function returns the current owner of the contract
     */
    function displayOnwer() internal view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface implements the BEP20
 * token standard for the Euphoria token
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
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

// pragma solidity >=0.5.0;

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

// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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

/**
 * contract creates the Euphoria
 * platfrom token
 */

contract BETS is IBEP20, Ownable {
    // pancakeswap v2 router testnet address: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _betswamp_addresses;

    // addresses excluded from transaction fess
    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _full_withdrawal_betswamp_address;

    mapping(address => bool) private _autoMarketMakerPair;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _allowed_betswamp_address_spending;

    address payable private marketing_wallet_address;
    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    uint256 private _liquidity_buy_tax = 4;
    uint256 private _liquidity_sell_tax = 8;
    bool private _isTaxable = true; // tax on
    bool private _isSwapping = false;
    uint256 private swapTokensAtAmount = 25;
    bool private _launchedTax = false;

    // event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    // event ExcludeFromFees(address indexed account, bool isExcluded);
    // event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutoMaketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(
        address marketing,
        address airdrop,
        address operationAndInfrastructure,
        address privateSale,
        address presale,
        address liquidity,
        address advisors,
        address dev,
        address staking,
        address bonuses,
        address exchange
    ) {
        _name = "Betswamp";
        _symbol = "BETS";
        _decimals = 18;
        _totalSupply = 250000000 * 10**18;

        // init uniswap

        // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        // get currency pair
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            _uniswapV2Router.WETH(),
            address(this)
        );

        // pair not yet created - create pair
        if (pair == address(0)) {
            _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(_uniswapV2Router.WETH(), address(this));
        } else {
            _uniswapV2Pair = pair;
        }

        _setAutoMarketMakerPair(_uniswapV2Pair, true);

        marketing_wallet_address = payable(marketing);

        // allowed amount euphoria addresses are allowed to withdraw monthly after lock period
        _allowed_betswamp_address_spending = 2;

        // tokenomics

        _balances[msg.sender] = (_totalSupply / 100) * 5;
        _balances[marketing] = (_totalSupply / 100) * 10;
        _balances[airdrop] = (_totalSupply / 100) * 2;
        _balances[operationAndInfrastructure] = (_totalSupply / 100) * 8;
        _balances[privateSale] = (_totalSupply / 100) * 2;
        _balances[presale] = (_totalSupply / 100) * 12;
        _balances[liquidity] = (_totalSupply / 100) * 32;
        _balances[advisors] = (_totalSupply / 100) * 2;
        _balances[staking] = (_totalSupply / 100) * 15;
        _balances[bonuses] = (_totalSupply / 100) * 2;
        _balances[exchange] = (_totalSupply / 100) * 10;

        // exclude addresses from fees
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[dev] = true;
        _isExcludedFromFee[marketing] = true;
        _isExcludedFromFee[airdrop] = true;
        _isExcludedFromFee[operationAndInfrastructure] = true;
        _isExcludedFromFee[privateSale] = true;
        _isExcludedFromFee[presale] = true;
        _isExcludedFromFee[liquidity] = true;
        _isExcludedFromFee[advisors] = true;
        _isExcludedFromFee[staking] = true;
        _isExcludedFromFee[bonuses] = true;
        _isExcludedFromFee[exchange] = true;

        // betswamp wallet lock time
        _betswamp_addresses[marketing] = block.timestamp + 12 weeks;
        _betswamp_addresses[dev] = block.timestamp + 48 weeks;
        _betswamp_addresses[operationAndInfrastructure] =
            block.timestamp +
            32 weeks; // lock wallet for 8 months
        _betswamp_addresses[airdrop] = block.timestamp + 16 weeks;
        _betswamp_addresses[exchange] = block.timestamp + 8 weeks;
        _betswamp_addresses[bonuses] = block.timestamp + 2 weeks;

        // betswamp addresses permitted to perform full withdrawal
        _full_withdrawal_betswamp_address[privateSale] = true;
        _full_withdrawal_betswamp_address[presale] = true;
        _full_withdrawal_betswamp_address[liquidity] = true;
        _full_withdrawal_betswamp_address[staking] = true;
        _full_withdrawal_betswamp_address[bonuses] = true;
        _full_withdrawal_betswamp_address[advisors] = true;
        _full_withdrawal_betswamp_address[exchange] = true;

        emit Transfer(address(0), dev, (_totalSupply / 100) * 5);
        emit Transfer(address(0), advisors, (_totalSupply / 100) * 2);
        emit Transfer(address(0), staking, (_totalSupply / 100) * 15);
        emit Transfer(address(0), bonuses, (_totalSupply / 100) * 2);
        emit Transfer(address(0), exchange, (_totalSupply / 100) * 10);
        emit Transfer(address(0), marketing, (_totalSupply / 100) * 10);
        emit Transfer(address(0), airdrop, (_totalSupply / 100) * 2);
        emit Transfer(
            address(0),
            operationAndInfrastructure,
            (_totalSupply / 100) * 8
        );
        emit Transfer(address(0), privateSale, (_totalSupply / 100) * 2);
        emit Transfer(address(0), presale, (_totalSupply / 100) * 12);
        emit Transfer(address(0), liquidity, (_totalSupply / 100) * 32);
    }

    // Required to recieve ETH from uniswapV2Router on swaps
    receive() external payable {}

    /**
     * @dev modifier checks if euphoria address withdrawal time has reached
     * throws if the address withdrawal time isn't greater than
     * the value of block.timestamp
     */
    modifier checkWithdrwalAddressTime(address userAddress) {
        require(
            _betswamp_addresses[userAddress] < block.timestamp,
            "Address withdrawal time hasn't reached."
        );
        _;
    }

    /**
     * @dev returns the bep20 token owner.
     */
    function getOwner() external view override returns (address) {
        return displayOnwer();
    }

    /**
     * @dev returns the token name
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev returns the token symbol
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev returns the token decimal
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev returns the token total supply
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev returns the balance of the account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev returns true if the specified amount is transfered to the recipient
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        checkWithdrwalAddressTime(msg.sender)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev transfers [amount] from [sender] to [recipient]
     *
     * Emits a Transer event
     *
     * Requirement:
     * [sender] cannot be a zero address
     * [recipient] cannot be a zero address
     * [sender] balance must be equal or greater than amount
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            sender != address(0),
            "Transfer from zero address not allowed."
        );
        require(
            recipient != address(0),
            "Transfer to the zero address not allowed."
        );

        // check if tax is on is on
        if (
            _isTaxable &&
            !_isExcludedFromFee[sender] &&
            !_isExcludedFromFee[recipient]
        ) {
            uint256 fees = 0;
            if (_autoMarketMakerPair[recipient]) {
                // selling
                fees = (amount / 100) * _liquidity_sell_tax;
                amount = amount.sub(fees);
            } else if (_autoMarketMakerPair[sender]) {
                // buying
                fees = (
                    !_launchedTax
                        ? (amount / 100) * _liquidity_buy_tax
                        : (amount / 100) * 90
                );
                amount = amount.sub(fees);
            }

            if (fees > 0) {
                _balances[sender] = _balances[sender].sub(fees);
                _balances[address(this)] = _balances[address(this)].add(fees);
                emit Transfer(sender, address(this), fees);
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !_isSwapping &&
            !_autoMarketMakerPair[sender] &&
            !_isExcludedFromFee[sender] &&
            !_isExcludedFromFee[recipient]
        ) {
            _isSwapping = true;
            uint256 _liquidityTokens = (contractTokenBalance * 40) / 100;
            swapAndLiquify(_liquidityTokens);

            uint256 marketingTokens = balanceOf(address(this));
            swapAndSendFee(marketingTokens, marketing_wallet_address);

            _isSwapping = false;
        }

        // check if address is an betswamp address
        if (_betswamp_addresses[sender] != 0) {
            // check if euphoria address isn't presale, privateSale or liquidity wallet
            if (_full_withdrawal_betswamp_address[sender] != true) {
                // check if amount is less than 20% allowed spending
                if (amount > (_balances[sender] / 100) * 2) {
                    revert("Amount is greater than 20% allowed spending power");
                } else {
                    // next allowed withdrawal time is next month
                    _betswamp_addresses[sender] = block.timestamp + 4 weeks;
                }
            }
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient balance."
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev returns amount spender is allowed to spend on owner's behalf
     */
    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    /**
     * @dev approves a specific amount that spender is allowed to spend on owner's
     * behalf
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev function is similiar to approve function
     * [amount] is set that spender is allowed to spend on owners behalf
     *
     * Requirements:
     * [owner] cannot be a zero address
     * [spender] cannot be a zero address
     *
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal checkWithdrwalAddressTime(msg.sender) {
        require(
            owner != address(0),
            "Approval from a zero address not allowed"
        );
        require(
            spender != address(0),
            "Approval to the zero address not allowed"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev function conducts transfer on behalf of sender and transfers the funds to recipient
     *
     * Requirements:
     * the [amount] specified must be the same as the approved [amount]
     * approved for the spender to spend.
     */

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
            amount,
            "Amount exceeds allowance"
        );
        return true;
    }

    /**
     * @dev destroys [amount] tokens from caller account reducing the
     * total supply.
     *
     * Emits a {Transfer} event with [to] set to the zero address.
     *
     * Requirements
     *
     * - sender must have at least [amount] tokens.
     */
    function burn(uint256 amount)
        public
        checkWithdrwalAddressTime(msg.sender)
        returns (bool success)
    {
        _balances[msg.sender] = _balances[msg.sender].sub(
            amount,
            "Amount for burn exceeds balance."
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    /**
     * @dev destroys token on behalf of another account
     *
     * Requirements:
     *
     * the [amount] specified must be the same with the amount approved
     * for the spender to spend.
     */
    function burnFrom(address account, uint256 amount)
        public
        checkWithdrwalAddressTime(msg.sender)
        returns (bool success)
    {
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender].sub(
                amount,
                "Burn amount exceeds allowance"
            )
        );
        burn(amount);
        return true;
    }

    /**
     * @dev funcction is swaps BETS in the smart contract(tax) to BNB
     */
    function swapTokens(uint256 tokenAmount) private returns (uint256) {
        uint256 initBalance = address(this).balance; // contract initial balance

        // uniswap token pair path == BETS -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // any amount of BNB
            path,
            address(this),
            block.timestamp
        );

        return (address(this).balance - initBalance);
    }

    function swapAndSendFee(uint256 tokens, address feeAddress) private {
        uint256 initialBalance = address(this).balance;
        swapTokens(tokens);
        uint256 newBalance = address(this).balance - initialBalance;
        (bool success, ) = feeAddress.call{value: newBalance}("");
        require(success, "Betswamp: Payment to marketing wallet failed");
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // swap tokens for ETH
        uint256 newBalance = swapTokens(half);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        (, uint256 ethFromLiquidity, ) = _uniswapV2Router.addLiquidityETH{
            value: ethAmount
        }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        if (ethAmount - ethFromLiquidity > 0)
            payable(marketing_wallet_address).transfer(
                ethAmount - ethFromLiquidity
            );
    }

    /**
     * @dev function is used to exlude an address for Buy/Sell Fee
     */
    function _excludeFromFee(address _address) external onlyOwner {
        _isExcludedFromFee[_address] = true;
    }

    /**
     * @dev function is used to include an address to address to be charged Buy/Sell Fee
     */
    function _includeToFee(address _address) external onlyOwner {
        _isExcludedFromFee[_address] = false;
    }

    /**
     * @dev function changes uniswapV2Router address
     */
    function updateRouterAddress(address _router)
        external
        onlyOwner
        returns (bool)
    {
        _uniswapV2Router = IUniswapV2Router02(_router);
        return true;
    }

    /**
     * @dev function changes marketing address
     */
    function updateMarketingWalletAddress(address _marketing_wallet_address)
        external
        onlyOwner
        returns (bool)
    {
        marketing_wallet_address = payable(_marketing_wallet_address);
        return true;
    }

    /**
     * @dev function returns marketing wallet address
     */
    function getMarketingWalletAddress() external view returns (address) {
        return marketing_wallet_address;
    }

    /**
     * @dev function sets uniswapPair
     */
    function setAutoMarketMakerPair(address _pair, bool value)
        public
        onlyOwner
    {
        require(
            _pair != _uniswapV2Pair,
            "Betswamp: Pancakeswap pair cannot be removed."
        );
        _setAutoMarketMakerPair(_pair, value);
    }

    function _setAutoMarketMakerPair(address _pair, bool value) private {
        require(
            _autoMarketMakerPair[_pair] != value,
            "Betswamp: Pancakeswap automatic market maker pair already set to value"
        );
        _autoMarketMakerPair[_pair] = value;

        emit SetAutoMaketMakerPair(_pair, value);
    }

    /**
     * @dev function switches transaction tax on/off
     */
    function _taxSwitch(bool _status) private {
        _isTaxable = _status;
    }

    function switchTax(bool _status) external onlyOwner {
        _taxSwitch(_status);
    }

    // function denotes Pancakeswap launch timestamp
    function launch() external onlyOwner {
        if (_launchedTax) {
            _launchedTax = false;
        } else {
            _launchedTax = true;
        }
    }
    
    /**
     * @dev function is used to airdrop different amount of
     * tokens to the [_recipients]
    */
    function airdropDifferentTokenAmount(address _sender, address[] calldata _recipients, uint256[] calldata _airdropAmount) external onlyOwner {
        // check if sender is excluded from fees
        if(!_isExcludedFromFee[_sender])
            _isExcludedFromFee[_sender] = true;
        // loop through [_recipients] and airdrop tokens
        for(uint256 counter = 0; counter < _recipients.length; counter++) {
            _transfer(_sender, _recipients[counter], _airdropAmount[counter]);
        }
        
    }
    
    /**
     * @dev function is used to airdrop same amount of
     * tokens to all [_recipient]
    */
    function airdropSameTokenAmount(address _sender, address[] calldata _recipients, uint256 _airdropAmount) external onlyOwner {
        // check if [_sender] is excluded from fees
        if(!_isExcludedFromFee[_sender])
            _isExcludedFromFee[_sender] = true;
        // loop through [_recipients] and airdrop tokens
        for(uint256 counter = 0; counter < _recipients.length; counter++) {
            // airdrop token
            _transfer(_sender, _recipients[counter], _airdropAmount);
        }
        
    }
}