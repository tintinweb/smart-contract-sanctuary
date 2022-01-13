/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: FNFB.sol



pragma solidity ^0.8.2;





// (Uni|Pancake)Swap libs are interchangeable





/*
    For lines that are marked ERC20 Token Standard, learn more at https://eips.ethereum.org/EIPS/eip-20. 
*/
contract ExtendedERC20 is Context, IERC20, Ownable, Pausable {

    // Keeps track of balances for address that are excluded from receiving reward.
    mapping (address => uint256) private _tokenBalances;

    // Keeps track of which address are excluded from fee.
    mapping (address => bool) private _isExcludedFromFee;

    // ERC20 Token Standard
    mapping (address => mapping (address => uint256)) private _allowances;

    // Liquidity pool provider router
    IUniswapV2Router02 internal _uniswapV2Router;

    // This Token and WETH pair contract address.
    address internal _uniswapV2Pair;

    // Where burnt tokens are sent to. This is an address that no one can have accesses to.
    address private constant burnAccount = 0x000000000000000000000000000000000000dEaD;

    address public marketingAddress;
    address public liquidityWallet;
    
    /*
        Tax rate = (_taxXXX / 10**_tax_XXXDecimals) percent.
        For example: if _taxBurn is 1 and _taxBurnDecimals is 2.
        Tax rate = 0.01%

        If you want tax rate for burn to be 5% for example,
        set _taxBurn to 5 and _taxBurnDecimals to 0.
        5 * (10 ** 0) = 5
    */

    // Decimals of taxLiquify. Used for have tax less than 1%.
    uint32 private _taxLiquifyDecimals;

    // Decimals of taxMarketing. Used for have tax less than 1%.
    uint32 private _taxMarketingDecimals;

    // Decimals of taxOwner. Used for have tax less than 1%.
    uint32 private _taxOwnerDecimals;

    uint32 public taxSellLiquify;
    uint32 public taxSellMarketing;
    uint32 public taxSellOwner;
    uint32 public taxBuyLiquify;
    uint32 public taxBuyOwner;
    uint32 public taxTransferMarketing; 

    uint256 private ownerTaxPending;
    uint256 private marketingTaxPending;

    // ERC20 Token Standard
    uint32 private _decimals;

    // ERC20 Token Standard
    uint256 private _totalSupply;

    uint256 private _maxSupply;

    // Current supply:= total supply - burnt tokens
    uint256 private _currentSupply;

    // Total amount of tokens burnt.
    uint256 private _totalBurnt;

    // Total amount of tokens locked in the LP (this token and WETH pair).
    uint256 private _totalTokensLockedInLiquidity;

    // Total amount of ETH locked in the LP (this token and WETH pair).
    uint256 private _totalETHLockedInLiquidity;

    // A threshold for swap and liquify.
    uint256 private _minTokensBeforeSwap;

    // ERC20 Token Standard
    string private _name;
    // ERC20 Token Standard
    string private _symbol;

    // Whether a previous call of SwapAndLiquify process is still in process.
    bool private _inSwapAndLiquify;

    bool private _autoSwapAndLiquifyEnabled;
    bool private _marketingRewardEnabled;
    bool private _ownerRewardEnabled;
    
    // Prevent reentrancy.
    modifier lockTheSwap {
        require(!_inSwapAndLiquify, "Currently in swap and liquify.");
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    // Return values of _getValues function.
    struct ValuesFromAmount {
        // Amount of tokens for to transfer.
        uint256 amount;
        // Amount tokens charged to add to liquidity.
        uint256 tLiquifyFee;

        uint256 tMarketingFee;

        uint256 tOwnerFee;
        // Amount tokens after fees.
        uint256 tTransferAmount;
    }

    /*
        Events
    */
    event Burn(address from, uint256 amount);
    event Mint(address to, uint256 amount);
    event TaxSellLiquifyUpdate(uint32 currentTax, uint32 currentDecimal);
    event TaxSellMarketingUpdate(uint32 currentTax, uint32 currentDecimal);
    event TaxSellOwnerUpdate(uint32 currentTax, uint32 currentDecimal);
    event TaxBuyLiquifyUpdate(uint32 currentTax, uint32 currentDecimal);
    event TaxBuyOwnerUpdate(uint32 currentTax, uint32 currentDecimal);
    event TaxTransferMarketingUpdate(uint32 currentTax, uint32 currentDecimal);
    event MinTokensBeforeSwapUpdated(uint256 previous, uint256 current);
    event MarketingAddressUpdated(address previous, address current);
    event AMMPairUpdated(address pair, bool value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensAddedToLiquidity
    );
    event ExcludeAccountFromFee(address account);
    event IncludeAccountInFee(address account);
    event EnabledAutoSwapAndLiquify();
    event EnabledMarketingReward();
    event EnabledOwnerReward();
    event DisabledAutoSwapAndLiquify();
    event DisabledMarketingReward();
    event DisabledOwnerReward();
    
    constructor (string memory name_, string memory symbol_, uint32 decimals_, uint256 tokenSupply_, uint256 maxSupply_, address liquidityWallet_) {
        // Sets the values for `name`, `symbol`, `totalSupply`, `currentSupply`, and `rTotal`.
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = tokenSupply_ * (10 ** decimals_);
        _maxSupply = maxSupply_ * (10 ** decimals_);
        _currentSupply = _totalSupply;

        liquidityWallet = liquidityWallet_;

        changeMaxTransactionAmount(maxSupply_);
        changeMaxWalletAmount(maxSupply_);

        // exclude owner and this contract from fee.
        excludeAccountFromFee(owner());
        excludeAccountFromFee(address(this));
        excludeAccountFromFee(liquidityWallet);
        
        _tokenBalances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // allow the contract to receive ETH
    receive() external payable {}

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint32) {
        return _decimals;
    }

    /**
     * @dev Returns the address of this token and WETH pair.
     */
    function uniswapV2Pair() public view virtual returns (address) {
        return _uniswapV2Pair;
    }

    /**
     * @dev Returns the current liquify tax decimals.
     */
    function taxLiquifyDecimals() public view virtual returns (uint32) {
        return _taxLiquifyDecimals;
    }

    function taxMarketingDecimals() public view virtual returns (uint32) {
        return _taxMarketingDecimals;
    }

    function taxOwnerDecimals() public view virtual returns (uint32) {
        return _taxOwnerDecimals;
    }

    /**
     * @dev Returns true if auto swap and liquify feature is enabled.
     */
    function autoSwapAndLiquifyEnabled() public view virtual returns (bool) {
        return _autoSwapAndLiquifyEnabled;
    }


    function marketingRewardEnabled() public view virtual returns (bool) {
        return _marketingRewardEnabled;
    }

    function ownerRewardEnabled() public view virtual returns (bool) {
        return _ownerRewardEnabled;
    }

    /**
     * @dev Returns the threshold before swap and liquify.
     */
    function minTokensBeforeSwap() external view virtual returns (uint256) {
        return _minTokensBeforeSwap;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() external view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Returns current supply of the token. 
     * (currentSupply := totalSupply - totalBurnt)
     */
    function currentSupply() external view virtual returns (uint256) {
        return _currentSupply;
    }

    /**
     * @dev Returns the total number of tokens burnt. 
     */
    function totalBurnt() external view virtual returns (uint256) {
        return _totalBurnt;
    }

    /**
     * @dev Returns the total number of tokens locked in the LP.
     */
    function totalTokensLockedInLiquidity() external view virtual returns (uint256) {
        return _totalTokensLockedInLiquidity;
    }

    /**
     * @dev Returns the total number of ETH locked in the LP.
     */
    function totalETHLockedInLiquidity() external view virtual returns (uint256) {
        return _totalETHLockedInLiquidity;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _tokenBalances[account];
    }

    /**
     * @dev Returns whether an account is excluded from fee. 
     */
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Burn} event indicating the amount burnt.
     * Emits a {Transfer} event with `to` set to the burn address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual whenNotPaused {
        require(!isBlacklisted[account], "ERC20: blacklisted address");
        require(account != burnAccount, "ERC20: burn from the burn address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _tokenBalances[account] -= amount;
        _tokenBalances[burnAccount] += amount;
        
        _currentSupply -= amount;
        _totalBurnt += amount;

        emit Burn(account, amount);
        emit Transfer(account, burnAccount, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual whenNotPaused {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + amount <= _maxSupply, "ERC20: cannot exceed max supply");

        _tokenBalances[account] += amount;
        _totalSupply += amount;
        _currentSupply += amount;

        emit Mint(account, amount);
        emit Transfer(address(0), account, amount);
    }
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual whenNotPaused {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!isBlacklisted[sender] && !isBlacklisted[recipient], "ERC20: blacklisted address");

        if (sender != owner() && recipient != owner())
            _beforeTokenTransfer();

        bool buying = false;

        if( // BUY
            AMMPairs[sender] &&
            recipient != address(_uniswapV2Router) //pair -> router is changing liquidity
        ) {
            buying = true;
        }

        bool selling = false;

        if ( // SELL
            AMMPairs[recipient] &&
            !_isExcludedFromFee[sender]
        ) {
            selling = true;
        }

        ValuesFromAmount memory values = _getValues(amount, !(!_isExcludedFromFee[sender] || (buying && !_isExcludedFromFee[recipient])), selling, buying);

        if (!_isExcludedFromFee[sender]) {
            require(values.tTransferAmount <= maxTransactionAmount, "Transaction amount exceeds max limit.");
        }
        if (!_isExcludedFromFee[recipient]) {
            require(values.tTransferAmount + _tokenBalances[recipient] <= maxWalletAmount, "Wallet amount exceeds max limit.");
        }

        _tokenBalances[sender] = _tokenBalances[sender] - values.amount;
        _tokenBalances[recipient] = _tokenBalances[recipient] + values.tTransferAmount;
        
        emit Transfer(sender, recipient, values.tTransferAmount);

        if (!_isExcludedFromFee[sender] || (buying && !_isExcludedFromFee[recipient])) {
            _afterTokenTransfer(values, selling, buying);
        }
    }

    function _beforeTokenTransfer() internal virtual {
        uint256 contractBalance = _tokenBalances[address(this)];
        bool overMinTokensBeforeSwap = contractBalance >= _minTokensBeforeSwap;

        if (overMinTokensBeforeSwap && _msgSender() != _uniswapV2Pair) {
            if (_marketingRewardEnabled && !_inSwapAndLiquify) {
                swapTokensForEth(marketingAddress, marketingTaxPending);
                marketingTaxPending = 0;
            }
            if (_ownerRewardEnabled && !_inSwapAndLiquify) {
                swapTokensForEth(owner(), ownerTaxPending);
                ownerTaxPending = 0;
            }
            if (_autoSwapAndLiquifyEnabled && !_inSwapAndLiquify) {
                swapAndLiquify(_tokenBalances[address(this)]);
            }
        }
    }

    /**
      * @dev Performs all the functionalities that are enabled.
      */
    function _afterTokenTransfer(ValuesFromAmount memory values, bool selling, bool buying) internal virtual {
        
        if (selling) {
            if (_marketingRewardEnabled) {
                marketingTaxPending += values.tMarketingFee;
                _tokenBalances[address(this)] += values.tMarketingFee;
            }

            if (_ownerRewardEnabled) {
                ownerTaxPending += values.tOwnerFee;
                _tokenBalances[address(this)] += values.tOwnerFee;
            }

            if (_autoSwapAndLiquifyEnabled) {
                _tokenBalances[address(this)] += values.tLiquifyFee;
            }
        } else if (buying) {
            if (_ownerRewardEnabled) {
                ownerTaxPending += values.tOwnerFee;
                _tokenBalances[address(this)] += values.tOwnerFee;
            }

            if (_autoSwapAndLiquifyEnabled) {
                _tokenBalances[address(this)] += values.tLiquifyFee;
            }
        } else {
            if (_marketingRewardEnabled) {
                marketingTaxPending += values.tMarketingFee;
                _tokenBalances[address(this)] += values.tMarketingFee;
            }
        }
    }

    /**
      * @dev Excludes an account from fee.
      *
      * Emits a {ExcludeAccountFromFee} event.
      *
      * Requirements:
      *
      * - `account` is included in fee.
      */
    function excludeAccountFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;

        emit ExcludeAccountFromFee(account);
    }

    /**
      * @dev Includes an account from fee.
      *
      * Emits a {IncludeAccountFromFee} event.
      *
      * Requirements:
      *
      * - `account` is excluded in fee.
      */
    function includeAccountInFee(address account) public onlyOwner {
        require(_isExcludedFromFee[account], "Account is already included.");

        _isExcludedFromFee[account] = false;
        
        emit IncludeAccountInFee(account);
    }

    /**
     * @dev Swap half of contract's token balance for ETH,
     * and pair it up with the other half to add to the
     * liquidity pool.
     *
     * Emits {SwapAndLiquify} event indicating the amount of tokens swapped to eth,
     * the amount of ETH added to the LP, and the amount of tokens added to the LP.
     */
    function swapAndLiquify(uint256 contractBalance) private {
        // Split the contract balance into two halves.
        uint256 tokensToSwap = contractBalance / 2;
        uint256 tokensAddToLiquidity = contractBalance - tokensToSwap;

        // Contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // Swap half of the tokens to ETH.
        swapTokensForEth(address(this), tokensToSwap);

        // Figure out the exact amount of tokens received from swapping.
        uint256 ethAddToLiquify = address(this).balance - initialBalance;

        // Add to the LP of this token and WETH pair (half ETH and half this token).
        addLiquidity(ethAddToLiquify, tokensAddToLiquidity);

        _totalETHLockedInLiquidity += address(this).balance - initialBalance;
        _totalTokensLockedInLiquidity += contractBalance - balanceOf(address(this));

        emit SwapAndLiquify(tokensToSwap, ethAddToLiquify, tokensAddToLiquidity);
    }


    /**
     * @dev Swap `amount` tokens for ETH.
     *
     * Emits {Transfer} event. From this contract to the token and WETH Pair.
     */
    function swapTokensForEth(address receiver, uint256 amount) private lockTheSwap {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), amount);

        // Swap tokens to ETH
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 
            0, 
            path, 
            receiver,
            block.timestamp + 60 * 1000
        );
    }
    
    /**
     * @dev Add `ethAmount` of ETH and `tokenAmount` of tokens to the LP.
     * Depends on the current rate for the pair between this token and WETH,
     * `ethAmount` and `tokenAmount` might not match perfectly. 
     * Dust(leftover) ETH or token will be refunded to this contract
     * (usually very small quantity).
     *
     * Emits {Transfer} event. From this contract to the token and WETH Pai.
     */
    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) private lockTheSwap {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // Add the ETH and token to LP.
        // The LP tokens will be sent to burnAccount.
        // No one will have access to them, so the liquidity will be locked forever.
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this), 
            tokenAmount, 
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp + 60 * 1000
        );
    }
    
    /**
     * @dev Returns fees and transfer amount in both tokens and reflections.
     * tXXXX stands for tokenXXXX
     * rXXXX stands for reflectionXXXX
     * More details can be found at comments for ValuesForAmount Struct.
     */
    function _getValues(uint256 amount, bool deductTransferFee, bool selling, bool buying) private view returns (ValuesFromAmount memory) {
        ValuesFromAmount memory values;
        values.amount = amount;
        _getTValues(values, deductTransferFee, selling, buying);
        return values;
    }

    /**
     * @dev Adds fees and transfer amount in tokens to `values`.
     * tXXXX stands for tokenXXXX
     * More details can be found at comments for ValuesForAmount Struct.
     */
    function _getTValues(ValuesFromAmount memory values, bool deductTransferFee, bool selling, bool buying) view private {
        
        if (deductTransferFee) {
            values.tTransferAmount = values.amount;
        } else {
            // calculate fee
            
            if (selling) {
                values.tLiquifyFee = _calculateTax(values.amount, taxSellLiquify, _taxLiquifyDecimals);
                values.tMarketingFee = _calculateTax(values.amount, taxSellMarketing, _taxMarketingDecimals);
                values.tOwnerFee = _calculateTax(values.amount, taxSellOwner, _taxOwnerDecimals);

                values.tTransferAmount = values.amount - values.tLiquifyFee - values.tMarketingFee - values.tOwnerFee;
            } else if (buying) {
                values.tLiquifyFee = _calculateTax(values.amount, taxBuyLiquify, _taxLiquifyDecimals);
                values.tOwnerFee = _calculateTax(values.amount, taxBuyOwner, _taxOwnerDecimals);

                values.tTransferAmount = values.amount - values.tLiquifyFee - values.tOwnerFee;
            } else {
                values.tMarketingFee = _calculateTax(values.amount, taxTransferMarketing, _taxMarketingDecimals);

                values.tTransferAmount = values.amount - values.tMarketingFee;
            }
            
        }
    }

    /**
     * @dev Returns fee based on `amount` and `taxRate`
     */
    function _calculateTax(uint256 amount, uint32 tax, uint32 taxDecimals_) private pure returns (uint256) {
        return amount * tax / (10 ** taxDecimals_) / (10 ** 2);
    }

    /*
        Owner functions
    */

    function initSwap(address routerAddress) public onlyOwner {
        // init Router
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress);

        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());

        if (_uniswapV2Pair == address(0)) {
            _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        }
        
        _uniswapV2Router = uniswapV2Router;

        excludeAccountFromFee(routerAddress);

        _setAMMPair(_uniswapV2Pair, true);
    }

    /**
      * @dev Enables the auto swap and liquify feature.
      * Swaps half of transaction amount * `taxLiquify_` amount of tokens 
      * to ETH and pair with the other half of tokens to the LP each transaction when enabled.
      *
      * Emits a {EnabledAutoSwapAndLiquify} event.
      *
      * Requirements:
      *
      * - auto swap and liquify feature mush be disabled.
      * - tax must be greater than 0.
      * - tax decimals + 2 must be less than token decimals. 
      * (because tax rate is in percentage)
      */
    function enableAutoSwapAndLiquify(uint32 taxSellLiquify_, uint32 taxBuyLiquify_, uint32 taxLiquifyDecimals_, address routerAddress, uint256 minTokensBeforeSwap_) public onlyOwner {
        require(!_autoSwapAndLiquifyEnabled, "Auto swap and liquify feature is already enabled.");
        require(taxBuyLiquify_ > 0, "Tax must be greater than 0.");
        require(taxSellLiquify_ > 0, "Tax must be greater than 0.");
        require(taxLiquifyDecimals_ + 2  <= decimals(), "Tax decimals must be less than token decimals - 2");

        _minTokensBeforeSwap = minTokensBeforeSwap_;

        initSwap(routerAddress);

        // enable
        _autoSwapAndLiquifyEnabled = true;
        setTaxLiquify(taxSellLiquify_, taxBuyLiquify_, taxLiquifyDecimals_);
        
        emit EnabledAutoSwapAndLiquify();
    }

    function enableMarketingTax(uint32 taxSellMarketing_, uint32 taxTransferMarketing_, uint32 taxMarketingDecimals_, address marketingAddress_) public onlyOwner {
        require(!_marketingRewardEnabled, "Marketing tax feature is already enabled.");
        require(taxTransferMarketing_ > 0, "Tax must be greater than 0.");
        require(taxSellMarketing_ > 0, "Tax must be greater than 0.");
        require(taxMarketingDecimals_ + 2  <= decimals(), "Tax decimals must be less than token decimals - 2");

        _marketingRewardEnabled = true;
        setMarketingTax(taxSellMarketing_, taxTransferMarketing_, taxMarketingDecimals_);
        setMarketingAddress(marketingAddress_);

        emit EnabledMarketingReward();
    }

    function enableOwnerTax(uint32 taxSellOwner_, uint32 taxBuyOwner_, uint32 taxOwnerDecimals_) public onlyOwner {
        require(!_ownerRewardEnabled, "Owner tax feature is already enabled.");
        require(taxBuyOwner_ > 0, "Tax must be greater than 0.");
        require(taxSellOwner_ > 0, "Tax must be greater than 0.");
        require(taxOwnerDecimals_ + 2  <= decimals(), "Tax decimals must be less than token decimals - 2");

        _ownerRewardEnabled = true;
        setOwnerTax(taxSellOwner_, taxBuyOwner_, taxOwnerDecimals_);

        emit EnabledOwnerReward();
    }

    /**
      * @dev Disables the auto swap and liquify feature.
      *
      * Emits a {DisabledAutoSwapAndLiquify} event.
      *
      * Requirements:
      *
      * - auto swap and liquify feature mush be enabled.
      */
    function disableAutoSwapAndLiquify() public onlyOwner {
        require(_autoSwapAndLiquifyEnabled, "Auto swap and liquify feature is already disabled.");

        setTaxLiquify(0, 0, 0);
        _autoSwapAndLiquifyEnabled = false;
         
        emit DisabledAutoSwapAndLiquify();
    }


    function disableMarketingTax() public onlyOwner {
        require(_marketingRewardEnabled, "Marketing reward feature is already disabled.");

        setMarketingTax(0, 0, 0);
        setMarketingAddress(address(0x0));
        _marketingRewardEnabled = false;
        
        emit DisabledMarketingReward();
    }

    function disableOwnerTax() public onlyOwner {
        require(_ownerRewardEnabled, "Owner reward feature is already disabled.");

        setOwnerTax(0, 0, 0);
        _ownerRewardEnabled = false;
        
        emit DisabledOwnerReward();
    }

     /**
      * @dev Updates `_minTokensBeforeSwap`
      *
      * Emits a {MinTokensBeforeSwap} event.
      *
      * Requirements:
      *
      * - `minTokensBeforeSwap_` must be less than _currentSupply.
      */
    function setMinTokensBeforeSwap(uint256 minTokensBeforeSwap_) public onlyOwner {
        require(minTokensBeforeSwap_ < _currentSupply, "minTokensBeforeSwap must be lower than current supply.");

        uint256 previous = _minTokensBeforeSwap;
        _minTokensBeforeSwap = minTokensBeforeSwap_;

        emit MinTokensBeforeSwapUpdated(previous, _minTokensBeforeSwap);
    }

    /**
      * @dev Updates taxLiquify
      *
      * Emits a {TaxLiquifyUpdate} event.
      *
      * Requirements:
      *
      * - auto swap and liquify feature must be enabled.
      * - total tax rate must be less than 100%.
      */
    function setTaxLiquify(uint32 taxSellLiquify_, uint32 taxBuyLiquify_, uint32 taxLiquifyDecimals_) public onlyOwner {
        require(_autoSwapAndLiquifyEnabled, "Auto swap and liquify feature must be enabled. Try the EnableAutoSwapAndLiquify function.");

        taxBuyLiquify = taxBuyLiquify_;
        taxSellLiquify = taxSellLiquify_;
        _taxLiquifyDecimals = taxLiquifyDecimals_;

        emit TaxBuyLiquifyUpdate(taxBuyLiquify_, taxLiquifyDecimals_);
        emit TaxSellLiquifyUpdate(taxSellLiquify_, taxLiquifyDecimals_);
    }

    function setMarketingTax(uint32 taxSellMarketing_, uint32 taxTransferMarketing_, uint32 taxMarketingDecimals_) public onlyOwner {
        require(_marketingRewardEnabled, "Marketing reward feature must be enabled. Try the EnableMarketingTax function.");

        taxTransferMarketing = taxTransferMarketing_;
        taxSellMarketing = taxSellMarketing_;
        _taxMarketingDecimals = taxMarketingDecimals_;

        emit TaxTransferMarketingUpdate(taxTransferMarketing_, taxMarketingDecimals_);
        emit TaxSellMarketingUpdate(taxSellMarketing_, taxMarketingDecimals_);
    }

    function setMarketingAddress(address marketingAddress_) public onlyOwner {
        address previous = marketingAddress;
        marketingAddress = marketingAddress_;
        excludeAccountFromFee(marketingAddress_);

        emit MarketingAddressUpdated(previous, marketingAddress_);
    }

    function setOwnerTax(uint32 taxSellOwner_, uint32 taxBuyOwner_, uint32 taxOwnerDecimals_) public onlyOwner {
        require(_ownerRewardEnabled, "Owner reward feature must be enabled. Try the enableOwnerTax function.");

        taxBuyOwner = taxBuyOwner_;
        taxSellOwner = taxSellOwner_;
        _taxOwnerDecimals = taxOwnerDecimals_;

        emit TaxBuyOwnerUpdate(taxBuyOwner_, taxOwnerDecimals_);
        emit TaxSellOwnerUpdate(taxSellOwner_, taxOwnerDecimals_);
    }

    // ##############
    // Features added
    // ##############

    uint256 public maxTransactionAmount;
    uint256 public maxWalletAmount;

    mapping (address => bool) public AMMPairs;
    mapping (address => bool) public isBlacklisted;

    function setAMMPair(address pair, bool value) public onlyOwner {
        require(pair != _uniswapV2Pair, "The PancakeSwap pair cannot be removed from AMMPairs.");

        _setAMMPair(pair, value);
    }

    function _setAMMPair(address pair, bool value) private {
        AMMPairs[pair] = value;

        if(value) {
            excludeAccountFromFee(pair);
        }

        emit AMMPairUpdated(pair, value);
    }

    function changeMaxTransactionAmount(uint256 amount) public onlyOwner {
        maxTransactionAmount = amount * (10 ** _decimals);
    }

    function changeMaxWalletAmount(uint256 amount) public onlyOwner {
        maxWalletAmount = amount * (10 ** _decimals);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
contract Smartzworld is ExtendedERC20 {

    uint256 private _tokenSupply = 1000000; // 1M
    uint256 private _maxSupply = 1000000000; // 1B

    uint32 private _taxSellMarketing = 4;
    uint32 private _taxSellLiquify = 2;
    uint32 private _taxSellOwner = 1;

    uint32 private _taxBuyLiquify = 2;
    uint32 private _taxBuyOwner = 1;

    uint32 private _taxTransferMarketing = 4;

    uint32 private _taxDecimals = 0;
    uint32 private _decimals = 18;

    uint256 private _minTokensBeforeSwap = 5000 * (10 ** _decimals);

    /**
     * @dev Choose proper router address according to your network:
     * Ethereum mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D (Uniswap)
     * BSC mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E (PancakeSwap)
     * BSC testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
     * BSC testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
     */
    address private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private _marketingAddress = 0x6e445645f19c60f2eD1b53c1978a4C756086A9ac;
    address private _liquidityWallet = 0xD7F58165E9eE0590fEc2184eFF58B9b9993aA63C;

    constructor () ExtendedERC20("Smartzworld", "SW", _decimals, _tokenSupply, _maxSupply, _liquidityWallet) {
        enableOwnerTax(_taxSellOwner, _taxBuyOwner, _taxDecimals);
        enableMarketingTax(_taxSellMarketing, _taxTransferMarketing, _taxDecimals, _marketingAddress);
        enableAutoSwapAndLiquify(_taxSellLiquify, _taxBuyLiquify, _taxDecimals, _routerAddress, _minTokensBeforeSwap);
    }
}