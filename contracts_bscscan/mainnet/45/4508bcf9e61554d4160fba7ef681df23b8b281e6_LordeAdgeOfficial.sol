/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: none

 /**

Official twitter address : https://twitter.com/elonmusk
Website Platform : https://www.spacex.com/
Buy and hold on PancakeSwap

*/


pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
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

/**
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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
    modifier onlyOwner {
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
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
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
    constructor () {
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

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
abstract contract BEP20 is Context, IBEP20, IBEP20Metadata, Ownable, Pausable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private pausedAddress;
    mapping (address => bool) private _isIncludedInFee;
    mapping (address => uint256) private _transactionTime;

    string private constant _name = "Lorde Adge Official";
    string private constant _symbol = "Lorde Adge Official";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    
    uint256 public liquidityFeePercentage = 0;
    uint256 public transactionBurnPercentage = 0;
    uint256 public maxTxLimit = 1500000 * 10**18;
    uint256 public coolDownTimeBound = 3600;
    uint256 public liquidityFeeToSell = 10000 * 10**18;
    
    bool public enableFee = true;
    bool public enableLiquidityFee = true;
    bool public enableTransactionBurn = true;
    bool public enableCoolDown = true;
    bool public enableSellLimit = true;
    bool public enableTaxEvent = true;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    address PANCAKEV2ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IPancakeRouter02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;

    event ExternalTokenTransferred(address externalAddress, address toAddress, uint amount);
    event BnbFromContractTransferred(uint amount);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event EnableFee(bool enable);
    event EnableCoolDown(bool enable);
    event EnableLiquidityFee(bool enable);
    event EnableSellLimit(bool enable);
    event EnableTaxEvent(bool enable);
    event EnableTransactionBurn(bool enable);
    event SetLiquidityFeePercentage(uint256 percentage);
    event SetTransactionBurnPercentage(uint256 percentage);
    event SetCoolDownTimeBound(uint256 timeInSeconds);
    event SetLiquidityFeeToSell(uint256 limit);
    event SetSellLimit(uint256 limit);
    event IncludeInFee(address account, bool includeInFee);
    event ExcludeFromFee(address account, bool includeInFee);
    event PauseAddress(address account, bool paused);
    event UnPauseAddress(address account, bool paused);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(PANCAKEV2ROUTER);
        // Create a pancakeswap pair for this new token
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) external virtual onlyOwner returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) external virtual onlyOwner returns (bool) {
      _mint(_msgSender(), amount);
      return true;
    }

    /**
     * @dev Pause `contract` - pause events.
     *
     * See {BEP20Pausable-_pause}.
     */
    function pauseContract() external virtual onlyOwner {
        _pause();
    }
    
    /**
     * @dev Pause `contract` - pause events.
     *
     * See {BEP20Pausable-_pause}.
     */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Pause `contract` - pause events.
     *
     * See {BEP20Pausable-_pause}.
     */
    function pauseAddress(address account) external virtual onlyOwner {
        pausedAddress[account] = true;
        emit PauseAddress(account, true);
    }
    
    /**
     * @dev Pause `contract` - pause events.
     *
     * See {BEP20Pausable-_pause}.
     */
    function unPauseAddress(address account) external virtual onlyOwner {
        pausedAddress[account] = false;
        emit UnPauseAddress(account, false);
    }

    /**
     * @dev Returns true if the address is paused, and false otherwise.
     */
    function isAddressPaused(address account) external view virtual returns (bool) {
        return pausedAddress[account];
    }

    /**
     * Withdraw any token from contract address
     */
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address");
        IBEP20 tokenContract = IBEP20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit ExternalTokenTransferred(_tokenContract,msg.sender, _amount);
    }

    /**
     * Get BNB balance of contract address
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Withdraw BNB from contract address
     */
    function withdrawBnbFromContract(uint256 amount) external onlyOwner {
        require(amount <= getBalance());
        address payable _owner = payable(owner());
        _owner.transfer(amount);
        emit BnbFromContractTransferred(amount);
    }
    
    /**
     * Exclude an address from fee
     */
    function excludeFromFee(address account) external onlyOwner {
        _isIncludedInFee[account] = false;
        emit ExcludeFromFee(account, false);
    }
    
    /**
     * Include an address in fee
     */
    function includeInFee(address account) external onlyOwner {
        _isIncludedInFee[account] = true;
        emit IncludeInFee(account, true);
    }
    
    /**
     * Check if address is included in fee or not
     */
    function isIncludedInFee(address account) external view returns(bool) {
        return _isIncludedInFee[account];
    }
    
    /**
     * Update liquidity fee percentage
     */
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        liquidityFeePercentage = liquidityFee;
        emit SetLiquidityFeePercentage(liquidityFee);
    }
    
    /**
     * Update transaction burn percentage
     */
    function setTransactionBurnPercent(uint256 transactionBurn) external onlyOwner {
        transactionBurnPercentage = transactionBurn;
        emit SetTransactionBurnPercentage(transactionBurn);
    }
    
    /**
     * Update threshold limit to sell liquidity fee
     */
    function setLiquidityFeeToSell(uint256 limit) external onlyOwner {
        liquidityFeeToSell = limit;
        emit SetLiquidityFeeToSell(limit);
    }

    /**
     * Update max transaction limit to sell
     */
    function setMaxTxLimit(uint256 limit) external onlyOwner {
        maxTxLimit = limit;
        emit SetSellLimit(limit);
    }
    
    /** 
     * Update cool down time bound
     */
    function setCoolDownTimeBound(uint256 timeInSeconds) external onlyOwner {
        coolDownTimeBound = timeInSeconds;
        emit SetCoolDownTimeBound(timeInSeconds);
    }
    
    /**
     * enable / disable fee
     */
    function setEnableFee(bool enableTax) external onlyOwner {
        enableFee = enableTax;
        emit EnableFee(enableTax);
    }
    
    /**
     * enable / disable liquidity fee
     */
    function setEnableLiquidityFee(bool enableTax) external onlyOwner {
        enableLiquidityFee = enableTax;
        emit EnableLiquidityFee(enableTax);
    }
    
    /**
     * enable / disable transaction burn
     */
    function setEnableTransactionBurn(bool enableTax) external onlyOwner {
        enableTransactionBurn = enableTax;
        emit EnableTransactionBurn(enableTax);
    }
    
    /**
     * enable / disable cool down feature
     */
    function setEnableCoolDown(bool enable) external onlyOwner {
        enableCoolDown = enable;
        emit EnableCoolDown(enable);
    }

    /**
     * enable / disable sell limit
     */
    function setEnableSellLimit(bool enable) external onlyOwner {
        enableSellLimit = enable;
        emit EnableSellLimit(enable);
    }
    
    /**
     * enable / disable tax event
     */
    function setEnableTaxEvent(bool enable) external onlyOwner {
        enableTaxEvent = enable;
        emit EnableTaxEvent(enable);
    }
    
    /**
     * enable / disable swap and liquify
     */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /**
     * to recieve BNB from pancakeswapV2Router when swaping
     */
    receive() external payable {}
    
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        if(enableFee && (_isIncludedInFee[sender] || _isIncludedInFee[recipient])) {
            if(enableCoolDown && recipient == pancakeswapV2Pair) {
                require((block.timestamp - _transactionTime[sender]) > coolDownTimeBound, "BEP20: Transfer failed due to time bound");
                _transactionTime[sender] = block.timestamp;
            }
            
            if(enableSellLimit && recipient == pancakeswapV2Pair) {
                require(amount <= maxTxLimit, "BEP20: Transfer exceeds transaction limit");
            }

            _swapAndLiquify(sender);

            uint256 liquidityFee = enableLiquidityFee ? calculateLiquidityFee(amount) : 0;
            uint256 transactionBurn = enableTransactionBurn ? calculateTransactionBurn(amount) : 0;
            _balances[recipient] += amount - liquidityFee - transactionBurn;
            if(liquidityFee > 0) takeLiquidity(sender, liquidityFee);
            if(transactionBurn > 0) takeTransactionBurn(sender, transactionBurn);
            emit Transfer(sender, recipient, amount - liquidityFee - transactionBurn);
        } else {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }
    
    /**
     *  Calculate liquidity fee for given amount
     */
    function calculateLiquidityFee(uint256 _amount) internal view returns (uint256) {
        return _amount * liquidityFeePercentage / 10**2;
    }
    
    /**
     *  Calculate transaction burn for given amount
     */
    function calculateTransactionBurn(uint256 _amount) internal view returns (uint256) {
        return _amount * transactionBurnPercentage / 10**2;
    }
    
    /**
     *  Detect liquidity fee from a transaction
     */
    function takeLiquidity(address account, uint256 liquidityFee) internal {
        _balances[address(this)] += liquidityFee;
        if(enableTaxEvent) emit Transfer(account, address(this), liquidityFee);
    }
    
    /**
     *  Detect transction burn amount from a transaction
     */
    function takeTransactionBurn(address account, uint256 burnAmount) internal {
        _totalSupply -= burnAmount;
        if(enableTaxEvent) emit Transfer(account, address(0), burnAmount);
    }
    
    /**
     *  Validate if the liquidity fee can be added to pool
     */
    function _swapAndLiquify(address from) internal {
        uint256 contractTokenBalance = _balances[address(this)];
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.

        if(from != pancakeswapV2Pair && !inSwapAndLiquify && swapAndLiquifyEnabled && contractTokenBalance >= liquidityFeeToSell) {
            bool initialFeeState = enableFee;
            // remove fee if initialFeeState was true
            if(initialFeeState) enableFee = false;
            
            //add liquidity
            swapAndLiquify(contractTokenBalance, owner());

            // enable fee if initialFeeState was true
            if(initialFeeState) enableFee = true;
        }
    }
    
    /**
     *  Split Fee into two halves swap tokens for BNB and add to liquidity
     */
    function swapAndLiquify(uint256 contractTokenBalance, address account) internal lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(half, address(this)); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to pancakeswap
        addLiquidity(otherHalf, newBalance, account);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /**
     *  Swap tokens for BNB
     */
    function swapTokensForEth(uint256 tokenAmount, address swapAddress) internal {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            swapAddress,
            block.timestamp
        );
    }

    /**
     *  Add to liquidity
     */
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address account) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            account,
            block.timestamp
        );
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
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
    ) internal virtual {
        require(amount > 0, "BEP20: amount must be greater than 0");
        require(!paused(), "BEP20Pausable: token transfer while contract paused");
        require(!pausedAddress[from], "BEP20Pausable: token transfer while from-address paused");
        require(!pausedAddress[to], "BEP20Pausable: token transfer while to-address paused");
    }
}

/**
 * @dev Extension of {BEP20} that adds a cap to the supply of tokens.
 */
abstract contract BEP20Capped is BEP20 {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "BEP20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {BEP20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(BEP20.totalSupply() + amount <= cap(), "BEP20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

contract LordeAdgeOfficial is BEP20Capped {
    uint256 private constant _initialSupply = 10000000 * 10**18;
    uint256 private _cap = 10000000 * 10**18;
    constructor() BEP20() BEP20Capped(_cap) {
        BEP20._mint(_msgSender(), _initialSupply);
    }
}