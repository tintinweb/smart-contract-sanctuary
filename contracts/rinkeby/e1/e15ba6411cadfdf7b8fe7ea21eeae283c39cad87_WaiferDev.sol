/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts/proxy/utils/UUPS.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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







/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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


contract WaiferDev is Context, IERC20, IERC20Metadata, Ownable, Pausable {

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) public _isExcludedFromDexFee;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 2000000000000000 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Waifer";
    string private constant _symbol = "Waifer";
    uint8 private constant _decimals = 18;

    bool public marketingFeeEnabled = true;
    uint256 public marketingWalletAmount = 0;
    address public marketingWalletAddress = 0x6eCAD13bFf29A0Adcb8C4C2Cc4BCEe3466E689d5;

    
    uint256 public taxFee = 4;
    uint256 private previousTaxFee = taxFee;

    bool public taxDisableInLiquidity;

    uint256 public liquidityFee = 4;
    uint256 private previousLiquidityFee = liquidityFee;
    uint256 public liquidityPercentageAmount = 0;
    
    uint256 public marketingFee = 2;
    uint256 private previousMarketingFee = marketingFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    address UNISWAPV2ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool public enableFee;
    bool public liquidityFeeEnabled = true;

    uint256 public minimumTokensBeforeSwap = 10 * 10 ** 18;

    event FeeEnabled(bool enableFee);
    event SetTaxFeePercent(uint256 taxFeePercent);
    event SetMarketingFeePercent(uint256 marketingFeePercent);
    event SetLiquidityFeePercent(uint256 liquidityFeePercent);
    event SetMarketingFeeEnabled(bool enabled);
    event UpdateMarketingWallet(address marketingWalletAddress);
    event SetLiquidityFeeEnabled(bool enabled);
    event SetMinimumTokensBeforeSwap(uint256 maximumContractAmount);
    event TokenFromContractTransfered(address externalAddress,address toAddress, uint256 amount);
    event BnbFromContractTransferred(uint256 amount);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);


        /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    // function initialize() public initializer {

    //       // initializing
    //     __Pausable_init_unchained();  
    //     __Ownable_init_unchained();  
    //     __Context_init_unchained();

    //     _rOwned[_msgSender()] = _rTotal;

    //     // marketingWallet = _marketingWallet;
    //      IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPV2ROUTER);
    //     // Create a uniswap pair for this new token
    //     uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
    //         .createPair(address(this), _uniswapV2Router.WETH());

    //     // set the rest of the contract variables
    //     uniswapV2Router = _uniswapV2Router;

    //     emit Transfer(address(0), _msgSender(), _tTotal);
    // }

     constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPV2ROUTER);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        emit Transfer(address(0), _msgSender(), _tTotal);  

    }

    // function _authorizeUpgrade(address) internal override onlyOwner {}

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
    function totalSupply() external view virtual override returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function isExcludedFromDexFee(address account) external view returns(bool) {
        return _isExcludedFromDexFee[account];
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override whenNotPaused returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override whenNotPaused returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) external virtual whenNotPaused returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

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
     * @dev unPause `contract` - unpause events.
     *
     * See {BEP20Pausable-_unpause}.
     */
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

       /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) external virtual onlyOwner whenNotPaused returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function excludeFromReward(address account) external onlyOwner whenNotPaused {
        require(!_isExcluded[account], "Account is already included");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner whenNotPaused {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromDexFee(address account) external onlyOwner whenNotPaused {
        _isExcludedFromDexFee[account] = true;
    }
    
    function includeInDexFee(address account) external onlyOwner whenNotPaused {
        _isExcludedFromDexFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 fee) external onlyOwner whenNotPaused {
        taxFee = fee;
        emit SetTaxFeePercent(taxFee);
    }

    /**
     * @dev marketing fee percentage setting function.
     * @param fee Number's for marketing percentage.
     */
    function setMarketingFeePercent(uint256 fee) external onlyOwner whenNotPaused {
        marketingFee = fee;
        emit SetMarketingFeePercent(marketingFee);
    }

    /**
     * @dev liquidity fee percentage setting function.
     * @param fee Number's for marketing percentage.
     */
    function setLiquidityFeePercent(uint256 fee) external onlyOwner whenNotPaused {
        liquidityFee = fee;
        emit SetLiquidityFeePercent(liquidityFee);
    }

    function setMarketingFeeEnabled(bool enable) external onlyOwner whenNotPaused {
        marketingFeeEnabled = enable;
        emit SetMarketingFeeEnabled(marketingFeeEnabled);
    }

    function setLiquidityFeeEnabled(bool enable) external onlyOwner whenNotPaused {
        liquidityFeeEnabled = enable;
        emit SetLiquidityFeeEnabled(liquidityFeeEnabled);
    }
    
    /**
     * @dev minimum swap limit.
     * @param swapLimit.
     */
    function setMinimumTokensBeforeSwap(uint256 swapLimit) external onlyOwner whenNotPaused {
        minimumTokensBeforeSwap = swapLimit;
        emit SetMinimumTokensBeforeSwap(minimumTokensBeforeSwap);
    }

     function updateMarketingWallet(address marketingWallet) external onlyOwner whenNotPaused {
        marketingWalletAddress = marketingWallet;
        emit UpdateMarketingWallet(marketingWalletAddress);
    }

    function setEnableFee(bool enableTax) external onlyOwner whenNotPaused {
        enableFee = enableTax;
        emit FeeEnabled(enableTax);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner whenNotPaused  {
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit TokenFromContractTransfered(_tokenContract, msg.sender, _amount);
    }

    function withdrawBNBFromContract(uint256 amount) external onlyOwner whenNotPaused {
        require(amount <= address(this).balance);        
        address payable _owner = payable(msg.sender);        
        _owner.transfer(amount);        
        emit BnbFromContractTransferred(amount);
    }

    //to recieve BNB from uniswapV2Router when swaping
    receive() external payable {}

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 senderBalance = balanceOf(from);
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");

               //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isIncludedInFee account then take fee
        //else remove fee
        if(!enableFee){
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMaxTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if(overMaxTokenBalance && marketingFeeEnabled) {
            if(enableFee){
                enableFee = false;
                taxDisableInLiquidity = true;
            }
                 // swap tokens in contract address to eth
                swapTokensForEth(marketingWalletAmount, address(this));
                address(this).balance - marketingWalletAmount;
                // Send eth to Marketing address
                transferBNBToAddress(payable(marketingWalletAddress), marketingWalletAmount);

                if(taxDisableInLiquidity){
                    enableFee = true;
                    taxDisableInLiquidity = false;
                }
        }

         if(liquidityFeeEnabled && from != uniswapV2Pair){
                if(enableFee){
                    enableFee = false;
                    taxDisableInLiquidity = true;
                }
                swapAndLiquify(liquidityPercentageAmount, owner());
                if(taxDisableInLiquidity){
                    enableFee = true;
                    taxDisableInLiquidity = false;
                }
        }   
         
         //transfer amount, it will take tax, burn and charity amount
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 liquidityTokenBalance, address account) private {
        // split the contract balance into halves
        uint256 half = liquidityTokenBalance / 2;
        uint256 otherHalf = liquidityTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half,address(this)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = liquidityTokenBalance - initialBalance;

        liquidityPercentageAmount = 0;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance, account);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount, address account) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            account,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, address account) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            account,
            block.timestamp
        );
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
        require(amount < balanceOf(account), "BEP20: burn amount exceeds balance");

        uint256 rAmount = amount * getRate();
        _rOwned[account] = _rOwned[account] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tTotal = _tTotal - amount;
        if(_isExcluded[account]){
            _tOwned[account] = _tOwned[account] - amount;
        }
        emit Transfer(account, address(0), amount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) internal {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }
  
    function _transferStandard(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tLiquidityFee) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketingFee, uint256 rLiquidityFee) = getRValues(tAmount, tFee, tMarketingFee, tLiquidityFee);

        {
            address from = sender;
            address to = recipient;
            _rOwned[from] = _rOwned[from] - rAmount;
            _rOwned[to] = _rOwned[to] + rTransferAmount;
        }
        takeReflectionFee(rFee, tFee);
        takeMarketingFee(sender, rMarketingFee, tMarketingFee);
        takeLiquidityFee(sender, rLiquidityFee, tLiquidityFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tLiquidityFee) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketingFee, uint256 rLiquidityFee) = getRValues(tAmount, tFee, tMarketingFee, tLiquidityFee);
        {
            address from = sender;
            address to = recipient;
            _tOwned[from] = _tOwned[from] - tAmount;
            _rOwned[from] = _rOwned[from] - rAmount;
            _tOwned[to] = _tOwned[to] + tTransferAmount;
            _rOwned[to] = _rOwned[to] + rTransferAmount; 
        }      
        takeReflectionFee(rFee, tFee);
        takeMarketingFee(sender, rMarketingFee, tMarketingFee);
        takeLiquidityFee(sender, rLiquidityFee, tLiquidityFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) internal {
       (uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tLiquidityFee) = getTValues(tAmount);
       (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketingFee, uint256 rLiquidityFee) = getRValues(tAmount, tFee, tMarketingFee, tLiquidityFee);
        {
            address from = sender;
            address to = recipient;
            _rOwned[from] = _rOwned[from] - rAmount;
            _tOwned[to] = _tOwned[to] + tTransferAmount;
            _rOwned[to] = _rOwned[to] + rTransferAmount; 
        }          
        takeReflectionFee(rFee, tFee);
        takeMarketingFee(sender, rMarketingFee, tMarketingFee);
        takeLiquidityFee(sender, rLiquidityFee, tLiquidityFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketingFee, uint256 tLiquidityFee) = getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketingFee, uint256 rLiquidityFee) = getRValues(tAmount, tFee, tMarketingFee, tLiquidityFee);
        {
            address from = sender;
            address to = recipient;
            _tOwned[from] = _tOwned[from] - tAmount;
            _rOwned[from] = _rOwned[from] - rAmount;
            _rOwned[to] = _rOwned[to] + rTransferAmount;
        } 
        takeReflectionFee(rFee, tFee);
        takeMarketingFee(sender, rMarketingFee, tMarketingFee);
        takeLiquidityFee(sender, rLiquidityFee, tLiquidityFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function getTValues(uint256 amount) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 tAmount = amount;
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tMarketingFee = calculateMarketingFee(tAmount);
        uint256 tLiquidityFee = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tMarketingFee;
        return (tTransferAmount, tFee, tMarketingFee, tLiquidityFee);
    }

    function getRValues(uint256 amount, uint256 tFee, uint256 tMarketingFee, uint256 tLiquidityFee) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 currentRate = getRate();
        uint256 tAmount = amount;
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rMarketingFee = tMarketingFee * currentRate;
        uint256 rLiquidityFee = tLiquidityFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rMarketingFee - rLiquidityFee;
        return (rAmount, rTransferAmount, rFee, rMarketingFee, rLiquidityFee);
    }

    function calculateTaxFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * taxFee) / 10**2;
    }

    function calculateMarketingFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * marketingFee) / 10**2;
    }

    function calculateLiquidityFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * liquidityFee) / 10**2;
    }

    function takeReflectionFee(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function takeMarketingFee(address sender, uint256 rMarketingFee, uint256 tMarketingFee) internal {
        _rOwned[address(this)] = _rOwned[address(this)] + rMarketingFee; 
        if(_isExcluded[address(this)]){
             _tOwned[address(this)] = _tOwned[address(this)] + tMarketingFee;
        }
        marketingWalletAmount += tMarketingFee;
        if(tMarketingFee > 0) emit Transfer(sender, address(this), tMarketingFee);
    }

    function takeLiquidityFee(address sender, uint256 rLiquidityFee, uint256 tLiquidityFee) internal {
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidityFee; 
        if(_isExcluded[address(this)]){
             _tOwned[address(this)] = _tOwned[address(this)] + tLiquidityFee;
        }
        liquidityPercentageAmount += tLiquidityFee;
        if(tLiquidityFee > 0) emit Transfer(sender, address(this), tLiquidityFee);
    }

    function removeAllFee() internal {
        if(taxFee == 0 && marketingFee == 0 && liquidityFee == 0) return;
        
        previousTaxFee = taxFee;
        taxFee = 0;

        previousMarketingFee = marketingFee;
        marketingFee = 0;

        previousLiquidityFee = liquidityFee;
        liquidityFee = 0;
    }
 
    function restoreAllFee() internal {
        taxFee = previousTaxFee;
        marketingFee = previousMarketingFee;
        liquidityFee = previousLiquidityFee;
    }

    function transferBNBToAddress(address payable recipient, uint256 amount) internal {
        marketingWalletAmount = 0;
        recipient.transfer(amount);
    }

    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  getRate();
        return rAmount / currentRate;
    }

    function getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply / tSupply;
    }

    function getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < (_rTotal / _tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

}