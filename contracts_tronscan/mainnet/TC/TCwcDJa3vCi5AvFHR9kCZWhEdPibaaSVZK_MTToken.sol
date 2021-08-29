//SourceUnit: MT.sol

/*
    SPDX-License-Identifier: MIT
*/


pragma solidity ^0.6.0;

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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IJustswapFactory {
    event NewExchange(address indexed token, address indexed exchange);
    function initializeFactory(address template) external;
    function createExchange(address token) external returns (address payable);
    function getExchange(address token) external view returns (address payable);
    function getToken(address token) external view returns (address);
    function getTokenWihId(uint256 token_id) external view returns (address);
}

interface IJustswapExchange {
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed
    tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256
    indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256
    indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256
    indexed token_amount);

    receive() external payable;

    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256
    output_reserve) external view returns (uint256);
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256
    output_reserve) external view returns (uint256);
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable
    returns (uint256);
    function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address
    recipient) external payable returns(uint256);
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external
    payable returns(uint256);
    function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address
    recipient) external payable returns (uint256);
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline)
    external returns (uint256);
    function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256
    deadline, address recipient) external returns (uint256);
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256
    deadline) external returns (uint256);
    function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256
    deadline, address recipient) external returns (uint256);
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought,
    uint256 min_trx_bought, uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought,
    uint256 min_trx_bought, uint256 deadline, address recipient, address token_addr) external
    returns (uint256);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold,
    uint256 max_trx_sold, uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold,
    uint256 max_trx_sold, uint256 deadline, address recipient, address token_addr) external
    returns (uint256);
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought,
    uint256 min_trx_bought, uint256 deadline, address exchange_addr) external returns
    (uint256);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256
    min_tokens_bought, uint256 min_trx_bought, uint256 deadline, address recipient, address
    exchange_addr) external returns (uint256);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256
    max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address exchange_addr)
    external returns (uint256);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256
    max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address recipient, address
    exchange_addr) external returns (uint256);
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns
    (uint256);
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);
    function tokenAddress() external view returns (address);
    function factoryAddress() external view returns (address);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
    external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256
    deadline) external returns (uint256, uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
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
    
        function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    //Added function
    // 1 minute = 60
    // 1h 3600
    // 24h 86400
    // 1w 604800
    
    function getTime() public view returns (uint256) {
        return now;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface ITRC20Metadata is ITRC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract TRC20 is Context, ITRC20, ITRC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract MTToken is TRC20, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint for uint256;
    
    mapping(address => uint256) private _rewardBalances;
    uint256 private _rewardTotal;
    
    IJustswapExchange public justswapExchange;

    bool private swapping;

    address public liquidityWallet;
    
    uint256 private constant MAX = ~uint256(0);
    
    uint256 private _total = 15000 * (10**8);

    uint256 public maxSellTransactionAmount = _total;
    uint256 public swapTokensAtAmount = 100 * (10**8);
    
    uint256 public  BNBRewardsFee;
    uint256 public  UsersFee;
    uint256 public  totalFees;
    
    uint256 public bindAmount = 1 * (10**6);
    
    uint256 public user1Fee = 5;
    uint256 public user2Fee = 3;
    uint256 public user3Fee = 2;
    
    uint256 public buyBackAmounts;
    
    address public _deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    bool public swapEnabled = true;
    
    uint256 public keepDisableSellTimes = 0;
    
    uint256 public openTime;
    
    mapping(address => bool) private _isBlackList;
    
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    mapping (address => bool) public fixedSaleEarlyParticipants;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    
    mapping (address => address) public binderList;
    
    bool public openReward = true;
    
    mapping (address => bool) public _excludeFromDividends;
    
    uint256 public claimWait = 600;
    
    address public _factoryAdd;
    
    uint256 public totalDividendsDistributed;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    mapping (address => uint256) public lastClaimTimes;
    
    
    uint256 public minimumTokenBalanceForDividends = 5 * (10**8);
    
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event FixedSaleEarlyParticipantsAdded(address[] participants);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);
    
    event UpdatesListener();
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
    
    constructor(address factoryAdd) public TRC20("MT", "MT") {
        _factoryAdd = factoryAdd;
        uint256 _BNBRewardsFee = 5;
        uint256 _UsersFee = user1Fee.add(user2Fee).add(user3Fee);

        BNBRewardsFee = _BNBRewardsFee;
        UsersFee = _UsersFee;
        totalFees = _BNBRewardsFee.add(_UsersFee);

    // 	dividendTracker = new MTDividendTracker();

    	liquidityWallet = owner();

    	
    	justswapExchange = IJustswapExchange(
            IJustswapFactory(factoryAdd).createExchange(address(this))
        );


        _setAutomatedMarketMakerPair(address(justswapExchange), true);
        
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(_deadWallet), true);
        excludeFromDividends(owner(), true);
        
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(_deadWallet), true);

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _total);
    }

    receive() external payable {

  	}
    
    function setOpenReward(bool value) external onlyOwner {
        openReward = value;
    }
    
    function setSwapTokensAtAmount(uint256 value) external onlyOwner {
        swapTokensAtAmount = value;
    }
    
    function setBNBRewardsFee(uint256 value) public onlyOwner {
        BNBRewardsFee = value;
        totalFees = BNBRewardsFee.add(UsersFee);
    }
    
    function setUsersFee(uint256 value) public onlyOwner {
        UsersFee = value;
        totalFees = BNBRewardsFee.add(UsersFee);
    }
    
    function setUser1Fee(uint256 value) public onlyOwner {
        user1Fee = value;
        UsersFee = user1Fee.add(user2Fee).add(user3Fee);
        totalFees = BNBRewardsFee.add(UsersFee);
    }
    
    function setUser2Fee(uint256 value) public onlyOwner {
        user2Fee = value;
        UsersFee = user1Fee.add(user2Fee).add(user3Fee);
        totalFees = BNBRewardsFee.add(UsersFee);
    }
    
    function setUser3Fee(uint256 value) public onlyOwner {
        user3Fee = value;
        UsersFee = user1Fee.add(user2Fee).add(user3Fee);
        totalFees = BNBRewardsFee.add(UsersFee);
    }
    
    function setDeadWallet(address wallet) public onlyOwner {
        _deadWallet = wallet;
    }
    
    function setSwapEnabled(bool enable) public onlyOwner {
        swapEnabled = enable;
    }
    
    function setMaxSellTransactionAmount(uint256 value) public onlyOwner {
        maxSellTransactionAmount = value;
    }
    
    function setKeepDisableSellTimes(uint256 value) public onlyOwner {
        keepDisableSellTimes = value;
    }
    
    function setOpenTime(uint256 value) public onlyOwner {
        openTime = value;
    }
    
    function setBlackList(address account, bool enable) public onlyOwner {
        _isBlackList[account] = enable;
    }
    
    function isBlackListFromAccount(address account) public view returns (bool) {
        return _isBlackList[account];
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "AK: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeFromDividends(address account, bool excluded) public onlyOwner {
        require(_excludeFromDividends[account] != excluded, "AK: Account is already the value of 'excluded'");
        _excludeFromDividends[account] = excluded;
        
    }
    
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function addFixedSaleEarlyParticipants(address[] calldata accounts) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            fixedSaleEarlyParticipants[accounts[i]] = true;
        }

        emit FixedSaleEarlyParticipantsAdded(accounts);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != address(justswapExchange), "AK: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "AK: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            excludeFromDividends(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "AK: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "AK: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "AK: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 600 && newClaimWait <= 86400, "AK_Dividend_Tracker: claimWait must be updated to between 0.5 and 24 hours");
        require(newClaimWait != claimWait, "AK_Dividend_Tracker: Cannot update claimWait to same value");
        claimWait = newClaimWait;
    }

    function getClaimWait() external view returns(uint256) {
        return claimWait;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return totalDividendsDistributed;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return accumulativeDividendOf(account).sub(withdrawnDividends[account], "sub failed withdrawnDividends[account]");
  	}
    
    function accumulativeDividendOf(address account) public view returns(uint256) {
        // return magnifiedDividendPerShare.mul(balanceOf(account)).toInt256Safe()
        // .add(magnifiedDividendCorrections[account]).toUint256Safe() / magnitude;
         return magnifiedDividendPerShare.mul(_rewardBalances[account]).toInt256Safe()
        .add(magnifiedDividendCorrections[account]).toUint256Safe() / magnitude;
    }
    
	function dividendTokenBalanceOf(address account) public view returns (uint256) {
	    if (_excludeFromDividends[account]) {
	        return 0;
	    }
		return super.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 _lastProcessedIndex) = process(gas);
		emit ProcessedDividendTracker(iterations, claims, _lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		processAccount(msg.sender, false);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return getNumberOfTokenHolders();
    }
    
      /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() private {
    _withdrawDividendOfUser(msg.sender);
  }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit UpdatesListener();
          
          super._transfer(address(this), user, _withdrawableDividend);
    
          return _withdrawableDividend;
        }
    
        return 0;
    }

    
    function launched() internal view returns (bool) {
        return openTime != 0;
    }

    function launch() internal {
        openTime = block.timestamp;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlackList[from]&&!_isBlackList[to], "this account is disabled");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if (!launched() && to == address(justswapExchange)) {
            launch();
        }
        
        if (to == address(justswapExchange) && !_isExcludedFromFees[from]) {
            
            require(openTime + keepDisableSellTimes <= block.timestamp, "Please try again later");
            
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
        
        swapping = false;
        
        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        
        if(takeFee && swapEnabled) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	amount = amount.sub(fees, "sub failed fees");
        	
        	uint256 userFees = fees.mul(UsersFee).div(totalFees);
        	
        	uint256 rewardFees = fees.sub(userFees, "sub failed userFees");
        	
        	uint256 user1Fees = userFees.mul(user1Fee).div(UsersFee);
        	uint256 user2Fees = userFees.mul(user2Fee).div(UsersFee);
        	uint256 user3Fees = userFees.sub(user1Fees).sub(user2Fees, "sub failed user3Fees");
        	
        	address beInviter = from;
        	
        	if (from == address(justswapExchange)) {
        	    beInviter = to;
        	}
        	
        	address sender = from;
        	
        	uint256 unFees = 0;
        	
        	address inviter1 = binderList[beInviter];
        	address inviter2 = binderList[inviter1];
        	address inviter3 = binderList[inviter2];
            
        	if (inviter1 != address(0)) {
        	    super._transfer(sender, inviter1, user1Fees);
        	} else {
        	    unFees = user1Fees;
        	}
        	
        	if (inviter2 != address(0)) {
        	    super._transfer(sender, inviter2, user2Fees);
        	} else {
        	    unFees = unFees.add(user2Fees);
        	}
        	
        	if (inviter3 != address(0)) {
        	    super._transfer(sender, inviter3, user3Fees);
        	} else {
        	    unFees = unFees.add(user3Fees);
        	}
        	
        	if (unFees > 0) {
        	   // super._transfer(sender, owner(), unFees);
        	   buyBackAmounts = buyBackAmounts.add(unFees);
        	   super._transfer(sender, address(owner()), unFees);
        	}
        	super._transfer(sender, address(this), rewardFees);
        	swapAndSendDividends(rewardFees);
        }
        
        if (from != address(justswapExchange) && to != address(justswapExchange) && from != address(_factoryAdd) && to != address(_factoryAdd)) {
            address bindAddress = binderList[to];
            address bindAddress2 = binderList[from];
            if (bindAddress2 != to && bindAddress == address(0)) {
                binderList[to] = from;
            }
        }
        
        super._transfer(from, to, amount);
        setBalance(payable(from), balanceOf(from));
        setBalance(payable(to), balanceOf(to));
        if (openReward) {
    
            if(!swapping) {
            	uint256 gas = gasForProcessing;
                (uint256 iterations, uint256 claims, uint256 _lastProcessedIndex) = process(gas);
                emit ProcessedDividendTracker(iterations, claims, _lastProcessedIndex, true, gas, tx.origin);
            }
        }
        
    }
    
    function swapAndSendDividends(uint256 tokens) private {
        uint256 currentBalance = tokens;
        // uint256 currentBalance = _swapTokensForETH(tokens);
        if (currentBalance > 0 && _rewardTotal > 0) {
          magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (currentBalance).mul(magnitude) / _rewardTotal
          );
    
          totalDividendsDistributed = totalDividendsDistributed.add(currentBalance);
        }
        
    }
    
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
    
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "This account is zero address");
        _mint(account, amount);
    }
    
    
    function getLastProcessedIndex() public view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() public view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        // index = tokenHoldersMap.getIndexOfKey(account);
        index = getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex, "sub failed lastProcessedIndex") :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
                
        uint256 tokenHolderIndex = mapSize();
    // 	if(index >= tokenHoldersMap.size()) {
    //         return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    //     }
        if(index >= tokenHolderIndex) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        // address account = tokenHoldersMap.getKeyAtIndex(index);
        address account = getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) private {
    	if(_excludeFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    // 		tokenHoldersMap.set(account, newBalance);
            set(account, newBalance);
    	}
    	else {
    	    _setBalance(account, 0);
    // 		tokenHoldersMap.remove(account);
            remove(account);
    	}

    	processAccount(account, true);
    }
    
    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _rewardBalances[account];
        if(newBalance > currentBalance) {
          uint256 mintAmount = newBalance.sub(currentBalance);
          _rewardBalances[account] = _rewardBalances[account].add(mintAmount);
          _rewardTotal = _rewardTotal.add(mintAmount);
          int256 subAmount = magnifiedDividendPerShare.mul(mintAmount).toInt256Safe();
          magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub(subAmount);
          
        } else if(newBalance < currentBalance) {
          uint256 burnAmount = currentBalance.sub(newBalance);
          _rewardBalances[account] = _rewardBalances[account].sub(burnAmount);
          _rewardTotal = _rewardTotal.sub(burnAmount);
          magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add( (magnifiedDividendPerShare.mul(burnAmount)).toInt256Safe() );
        }
  }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) private returns (bool) {
        automatic;
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit UpdatesListener();
    		return true;
    	}

    	return false;
    }
    
    function get(address key) public view returns (uint) {
        return tokenHoldersMap.values[key];
    }

    function getIndexOfKey( address key) public view returns (int) {
        if(!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int(tokenHoldersMap.indexOf[key]);
    }

    function getKeyAtIndex(uint index) public view returns (address) {
        return tokenHoldersMap.keys[index];
    }



    function mapSize() public view returns (uint) {
        return tokenHoldersMap.keys.length;
    }

    function set(address key, uint val) public {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {
            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    function remove(address key) public {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint index = tokenHoldersMap.indexOf[key];
        uint lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }
    
}