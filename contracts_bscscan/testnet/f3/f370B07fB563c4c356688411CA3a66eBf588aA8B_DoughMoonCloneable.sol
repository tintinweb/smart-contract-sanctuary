/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

// File: Doughpad-BackEnd/contracts/Utils/SharedStructures.sol



pragma solidity ^0.8.4;


/**
 * Collection of structs for use with the token launcher
 */
library SharedStructures {
    // General info about a created token used to launch it
    struct TokenInfo {
        string name;
        string symbol;
        string tokenType;
        uint256 totalSupplyWithoutDecimals;
        uint256 ethForLiquidity;
        uint8 decimals;
        uint8 initialMarketingPercent;
        uint8 initialBurnPercent;
        bool lockMarketingTokens;
        bool isFairLaunch; // If true then launch with ethForLiquidity, if false then its an IDO
        uint16 maxWalletPermille;
        uint16 maxTxPermille;
    }
    
    // Info about any other fees e.g. dividend trackers, used to auto-pay rewards, additional taxes, or reflections
    struct OtherFeeInfo {
        uint8[2] fee; // Used to store any "special" fees used by different token types e.g. rewards, reflections
        bool[2] feeInTokens; // Whether payments to any associated wallets should be made in native tokens or BNB
        address feeRecipient; // The address that receives the fee
        address rewardToken;
        uint24 claimWait; 
        uint256 minTokensForDividendsWithoutDecimals;
        string descriptor; // What the fee is for
    }
    
    // Info about any Tx fees payable
    struct FeeInfo {
        uint8 marketingFee;
        uint8 liquidityFee;
        uint8 burnFee;
        uint8 platformFee;
        bool marketingFundsInTokens; // Whether any payments to the marketing wallet should be made in native tokens or BNB
    }
    
    // Any relevant addresses needed to launch the token
    struct AddressInfo {
        address marketingWallet;
        address tokenCreator;
        address router;
        address tokenLocker;
        address lpLocker;
        address cloneFactory;
    }
    
    // Contains all information used to launch a token
    struct LaunchInfo {
        TokenInfo tokenInfo;
        AddressInfo addressInfo;
        FeeInfo[2] feeInfo;
        OtherFeeInfo[] otherFeeInfo;
    }
    
    // Info pertaining to a locker
    struct LockerInfo {
        address[] rewardTokens;
        address[2] lpTokenParts;
        address lockToken;
        bool isDoughLaunched;
        bool isLPToken;
        uint64 lockFee;
        address lockOwner;
        uint48 unlockTime;
        uint48 minLockPeriod;
        address platformWallet;
        uint16 rewardsClaimFeePermille;
        uint16 tokenLockFeePermille;
        bool isVesting;
        uint48 cliffEndTime;
        address lockCreator;
        uint256 lockedTokenAmount;
        string lockerType;
        uint48 minCliffPeriod;
    }

    function checkAddresses (AddressInfo storage toCheck) internal view returns (bool) {
        if (toCheck.marketingWallet == address (0))
            return false;
        
        if (toCheck.tokenCreator == address (0))
            return false;
        
        if (toCheck.router == address (0))
            return false;
        
        if (toCheck.router == address (0))
            return false;
        
        if (toCheck.cloneFactory == address (0))
            return false;
        
        // Don't check lockers as they may validly be 0x0
        return true;
    }

    /**
     * @dev Copies the contents of `from` into `to`, correctly initialising variable-length arrays
     *
     * NOTE: This makes no assumptions about the current state of to and reinitialises variable length arrays
     */
    function clone (OtherFeeInfo storage to, OtherFeeInfo memory from) internal {
        to.fee[0] = from.fee[0];
        to.fee[1] = from.fee[1];
        to.feeInTokens[0] = from.feeInTokens[0];
        to.feeInTokens[1] = from.feeInTokens[1];
        to.feeRecipient = from.feeRecipient;
        to.rewardToken = from.rewardToken;
        to.claimWait = from.claimWait;
        to.minTokensForDividendsWithoutDecimals = from.minTokensForDividendsWithoutDecimals;
        to.descriptor = from.descriptor;
    }

    /**
     * @dev Copies the contents of `from` into `to`, correctly initialising variable-length arrays
     *
     * NOTE: This makes no assumptions about the current state of to and reinitialises variable length arrays
     */
    function clone (LockerInfo storage to, LockerInfo memory from) internal {
        to.rewardTokens = new address[] (from.rewardTokens.length);

        for (uint256 i; i < from.rewardTokens.length; i++)
            to.rewardTokens[i] = from.rewardTokens[i];

        to.lpTokenParts[0] = from.lpTokenParts[0];
        to.lpTokenParts[1] = from.lpTokenParts[1];
        to.lockToken = from.lockToken;
        to.isDoughLaunched = from.isDoughLaunched;
        to.isLPToken = from.isLPToken;
        to.lockFee = from.lockFee;
        to.lockOwner = from.lockOwner;
        to.unlockTime = from.unlockTime;
        to.minLockPeriod = from.minLockPeriod;
        to.platformWallet = from.platformWallet;
        to.rewardsClaimFeePermille = from.rewardsClaimFeePermille;
        to.tokenLockFeePermille = from.tokenLockFeePermille;
        to.isVesting = from.isVesting;
        to.cliffEndTime = from.cliffEndTime;
        to.lockCreator = from.lockCreator;
        to.lockedTokenAmount = from.lockedTokenAmount;
        to.lockerType = from.lockerType;
        to.minCliffPeriod = from.minCliffPeriod;
    }
}
// File: Doughpad-BackEnd/contracts/Router/SwapInterfaces.sol



pragma solidity ^0.8.4;


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
// File: Doughpad-BackEnd/contracts/Factory/IGenericCloneFactory.sol



pragma solidity ^0.8.4;

interface IGenericCloneFactory {
    function create (string memory name) external returns (address instance);
    function create (string memory name, bytes32 salt) external returns (address instance);
    function predictCloneAddress (string memory name, bytes32 salt) external view returns (address instance);
    function getImplementation (string memory name) external view returns (address implementation);
    function getImplementationAndVersion (string memory name) external view returns (address implementation, string memory implementationVersion);
    function getVersion (address implementation) external view returns (string memory);
    function getProxy (string memory name) external view returns (address payable proxy);
}
// File: Doughpad-BackEnd/contracts/ERC20/IERC20.sol



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
// File: Doughpad-BackEnd/contracts/ERC20/IERC20Metadata.sol



pragma solidity ^0.8.4;


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
// File: Doughpad-BackEnd/contracts/Utils/IOwnable.sol



pragma solidity ^0.8.4;

interface IOwnable {
    function transferOwnership (address newOwner) external;
}
// File: Doughpad-BackEnd/contracts/Tokens/IDoughTokenCloneable.sol



pragma solidity ^0.8.4;




interface IDoughTokenCloneable is IERC20, IOwnable {
    function initialize (
        SharedStructures.TokenInfo memory _tokenInfo,
        SharedStructures.AddressInfo memory _addressInfo,
        SharedStructures.FeeInfo[2] memory _feeInfo,
        SharedStructures.OtherFeeInfo[] memory _otherFeeInfo
    ) external;
    
    function excludeFromFees (address account, bool excluded) external;
    function swapPair() external returns (address);
    function doughTokenLaunchedAt() external returns (uint48);
    function setLockerAddresses (address marketingTokenLocker, address lpLocker) external;
}
// File: Doughpad-BackEnd/contracts/Utils/Initializable.sol


// OpenZeppelin Contracts v4.4.0-rc.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
// File: Doughpad-BackEnd/contracts/Utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.0-rc.0 (utils/Context.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[20] private __gap;
}
// File: Doughpad-BackEnd/contracts/ERC20/ERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.0-rc.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;

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
    function __ERC20_init(string memory name_, string memory symbol_, uint8 decimals_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_, uint8 decimals_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
        return _decimals;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        require(currentAllowance >= subtractedValue, "ERC20: allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), "ERC20: transfer from 0 address");
        require(recipient != address(0), "ERC20: transfer to 0 address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        require(account != address(0), "ERC20: mint to 0 address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        require(account != address(0), "ERC20: burn from 0 address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        require(owner != address(0), "ERC20: approve from 0 address");
        require(spender != address(0), "ERC20: approve to 0 address");

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
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}
// File: Doughpad-BackEnd/contracts/Utils/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.0-rc.0 (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable, IOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    /**
     * @dev Throws if called by any account other than the owner. Modifier gas savings
     */
    function _onlyOwner() private view {
        require(_owner == _msgSender(), "Ownable: owner only");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
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
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: can't be 0 address");
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

    uint256[20] private __gap;
}
// File: Doughpad-BackEnd/contracts/Utils/AuthUpgradeable.sol



pragma solidity ^0.8.4;


abstract contract AuthUpgradeable is Initializable, OwnableUpgradeable {
    mapping(address => bool) private authorised;

    event AuthorisationChanged (address indexed account, bool isAuthorised);
    
    function __Auth_init() internal initializer {
        __Ownable_init();
        __Auth_init_unchained();
    }
    
    function __Auth_init_unchained() internal initializer {
        authorised[_msgSender()] = true;
    }
    
    function _onlyAuthorised() private view {
        require(authorised[_msgSender()], "Auth: not authorised");
    }
    
    modifier onlyAuthorised() {
        _onlyAuthorised();
        _;
    }
    
    function authorise (address account, bool isAuthorised) external onlyOwner {
        require (account != owner(), "Auth: can't remove owner");
        require (authorised[account] != isAuthorised, "Auth: already set to that");
        authorised[account] = isAuthorised;
        emit AuthorisationChanged (account, isAuthorised);
    }

    uint256[20] private __gap;
}
// File: Doughpad-BackEnd/contracts/Utils/VersionedUpgradeable.sol



pragma solidity ^0.8.4;



abstract contract VersionedUpgradeable is Initializable, AuthUpgradeable {
    string internal version;

    function __Versioned_init (string memory _version) internal initializer {
        __Versioned_init_unchained (_version);
        __Auth_init();
    }

    function __Versioned_init_unchained (string memory _version) internal initializer {
        version = _version;
    }

    function getVersion() external view returns (string memory) {
        return version;
    }

    function setVersion (string memory _version) external onlyAuthorised {
        version = _version;
    }
    
    uint256[20] private __gap;
}
// File: Doughpad-BackEnd/contracts/Utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// File: Doughpad-BackEnd/contracts/Tokens/DoughTokenCloneable.sol



pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;









/* 
 * Common base for any cloneable Dough token.
 */
contract DoughTokenCloneable is Initializable, ERC20Upgradeable, OwnableUpgradeable, VersionedUpgradeable, IDoughTokenCloneable  {
    using Address for address payable;
	  using SharedStructures for SharedStructures.AddressInfo;
	  using SharedStructures for SharedStructures.OtherFeeInfo;
    
    uint16[2] public totalFeePerMille;
    
    uint256[] internal otherTokens;
    uint256 internal marketingTokens; 
    uint256 internal liquidityTokens;
    uint256 internal platformTokens; 
    
    uint256 public maxWalletAmount;
    uint256 public maxTxAmount;

    address public override swapPair;
    address internal initialLiquidityAdder;
    uint48 public override doughTokenLaunchedAt;

    bool internal swapping;
    uint256 public swapContractTokensAtAmount;
    
    // exclude from fees and max transaction amount
    mapping(address => bool) public isExcludedFromFees;
    
    // store addresses that are AMM pairs. Any transfer to these addresses could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    SharedStructures.AddressInfo public addressInfo;
    SharedStructures.FeeInfo[2] public feeInfo;
    SharedStructures.OtherFeeInfo[] internal otherFeeInfo;

    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    uint8 internal constant BUY = 0;
    uint8 internal constant SELL = 1;
    
    string internal constant BUY_STRING = "Buy";
    string internal constant SELL_STRING = "Sell";
    string internal constant ZERO_ADDRESS_ISSUE = "Can't use 0 address";
    string internal constant MAX_PERMILLE_ISSUE = "Must be >1 & <=1000";
    string internal constant NOT_SUPPORTED = "Do not use";
    string internal constant FEES_TOO_HIGH = "Fees can't be > 25%";
    string internal constant WRONG_ARRAY_LENGTH = "Wrong array length";
    string internal constant ID_TOO_BIG = "ID too big";
    
    event SetAutomatedMarketMakerPair (address indexed pair, bool indexed value);
    event ExcludeFromFees (address indexed account, bool isExcluded);
    event MarketingWalletChanged (address indexed oldMarketingWallet, address indexed newMarketingWallet);
    event MaxWalletAmountChanged (uint256 oldMaxWalletAmount, uint256 newMaxWalletAmount);
    event MaxTxAmountChanged (uint256 oldMaxTxAmount, uint256 newMaxTxAmount);
    event MarketingFundsTypeChanged (bool[2] takeMarketingInNativeTokens);
    event FeesChanged (string feeType, uint8 oldLiquidityFee, uint8 newLiquidityFee, uint8 oldMarketingFee, uint8 newMarketingFee, uint8 oldBurnFee, uint8 newBurnFee);
    event AdditionalFeesChanged (string feeType, uint8[] oldOtherFees, uint8[] newOtherFees); 
    event SwapContractTokensAtAmountChanged (uint256 oldSwapAmount, uint256 newSwapAmount);
    
    receive() external payable {}
    
    /**
      * @dev Designed for use by a cloneable contract, this intialises the contract state
      *
      * NOTE: This function can only be called once per clone
      * 
      * @param _tokenInfo A struct containing general information about the token
      * @param _addressInfo A struct containing information about addresses relevant to the contract
      * @param _feeInfo A 2-length array of structs containing information about fees payable on transfer when buying and selling
      * @param _otherFeeInfo A variable-length array of structs containing information about any special fees inc. rewards distribution, reflection etc.
      */
    function initialize (
        SharedStructures.TokenInfo memory _tokenInfo,
        SharedStructures.AddressInfo memory _addressInfo,
        SharedStructures.FeeInfo[2] memory _feeInfo,
        SharedStructures.OtherFeeInfo[] memory _otherFeeInfo
    ) 
    external override initializer 
    {        
        // initialise inherited contracts
        __ERC20_init (_tokenInfo.name, _tokenInfo.symbol, _tokenInfo.decimals);
        __Ownable_init();
        
        // set wallets and other address state variables
        addressInfo = _addressInfo;
        initialLiquidityAdder = msg.sender;
		
        require (addressInfo.checkAddresses(), createErrorMessage (ZERO_ADDRESS_ISSUE));

        // initialise feeInfo
        feeInfo[BUY] = _feeInfo[BUY];
        feeInfo[SELL] = _feeInfo[SELL];

        // initialise otherFeeInfo and set-up to initialise fees
		    uint8[] memory otherBuyFees = new uint8[] (_otherFeeInfo.length);
        uint8[] memory otherSellFees = new uint8[] (_otherFeeInfo.length);

        for (uint256 i; i < _otherFeeInfo.length; i++) {
            otherFeeInfo.push();
            otherFeeInfo[i].clone (_otherFeeInfo[i]);
            otherBuyFees[i] = _otherFeeInfo[i].fee[BUY];
            otherSellFees[i] = _otherFeeInfo[i].fee[SELL];
		    }

        otherTokens = new uint256[] (_otherFeeInfo.length);
        
        // initialise all fees
        setFees (otherBuyFees, _feeInfo[BUY].liquidityFee, _feeInfo[BUY].marketingFee, _feeInfo[BUY].burnFee, BUY);
        setFees (otherSellFees, _feeInfo[SELL].liquidityFee, _feeInfo[SELL].marketingFee, _feeInfo[SELL].burnFee, SELL);
        
        // initialise pair
        address _swapPair = ISwapFactory(ISwapRouter02(_addressInfo.router).factory()).createPair (address(this), ISwapRouter02(_addressInfo.router).WETH());
        setAutomatedMarketMakerPair (_swapPair, true);
        swapPair = _swapPair;

        // exclude from paying fees or having max transaction amount
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[BURN_ADDRESS] = true;
        isExcludedFromFees[_addressInfo.marketingWallet] = true;
        isExcludedFromFees[_addressInfo.tokenCreator] = true;
        
        // swap (and possibly liquify) when contract balance is 0.01% total supply
        swapContractTokensAtAmount = _tokenInfo.totalSupplyWithoutDecimals * 10**_tokenInfo.decimals / 10_000; 
        
        // Calculate total supply and set wallet and Tx restrictions
        uint256 _totalSupply = _tokenInfo.totalSupplyWithoutDecimals * 10**_tokenInfo.decimals;
        setMaxWalletPermille (_tokenInfo.maxWalletPermille, _totalSupply);
        setMaxTxPermille (_tokenInfo.maxTxPermille, _totalSupply);
        
        // mint tokens to burn address and owner. _mint is an internal function that is only called here, and CANNOT be called ever again
        uint256 initialBurnTokens = _tokenInfo.initialBurnPercent * _totalSupply / 100;
        _totalSupply -= initialBurnTokens;
        _mint (BURN_ADDRESS, initialBurnTokens);
        _mint (msg.sender, _totalSupply);
        
        // allows for any custom initialisation by child contracts
        __DoughToken_init (_tokenInfo);
    }
    
    /**
      * @dev Designed for use by overriding contracts, allowing further customisation based on the inputs
      *
      * NOTE: This function is only called when the clone is initialised
      */
    function __DoughToken_init (SharedStructures.TokenInfo memory /*_tokenInfo*/) internal virtual {
        // Version set here to allow overriding token types to define their own version
        __Versioned_init ("0.4.0");
    }
    
    /**
      * @dev Allows the contract owner to include/exclude accounts from paying fees on transfer
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param account The address to include/exclude from paying fees
      * @param excluded Whether the account should be excluded (by default no accounts are excluded)
      */
    function excludeFromFees (address account, bool excluded) external override onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees (account, excluded);
    }
    
    /**
      * @dev Changes the marketing wallet address
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param wallet The address to change the marketing wallet to
      */
    function setMarketingWallet (address wallet) public onlyOwner {
        require (wallet != address(0), createErrorMessage (ZERO_ADDRESS_ISSUE));
        emit MarketingWalletChanged (addressInfo.marketingWallet, wallet);
        isExcludedFromFees[wallet] = true;
        emit ExcludeFromFees (wallet, true);
        addressInfo.marketingWallet = wallet;
    }
    
    /**
      * @dev Allows TokenLaunchManager to set the locker addresses for holder visibility
      *
      * NOTE: This function can only be called by the TokenLaunchManager
      * 
      * @param marketingTokenLocker The marketing token locker address (may be 0x0 if not locked)
      * @param lpLocker The LP token locker address (shouldn't be 0x0, but might be whilst an IDO is ongoing)
      */
    function setLockerAddresses (address marketingTokenLocker, address lpLocker) external {
        require (msg.sender == initialLiquidityAdder, createErrorMessage (NOT_SUPPORTED));
        addressInfo.tokenLocker = marketingTokenLocker;
        addressInfo.lpLocker = lpLocker;
    }
    
    /**
      * @dev Sets whether marketing fees are taken in native tokens or WETH
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param takeMarketingInNativeTokens Whether to take marketing fees in native tokens or not
      */
    function setMarketingFundsInTokens (bool[2] memory takeMarketingInNativeTokens) external onlyOwner {
        feeInfo[BUY].marketingFundsInTokens = takeMarketingInNativeTokens[0];
        feeInfo[SELL].marketingFundsInTokens = takeMarketingInNativeTokens[1];
        emit MarketingFundsTypeChanged (takeMarketingInNativeTokens);
    }
    
    /**
      * @dev Sets the max wallet holdings allowed as a permille of total supply. 
      * maxWalletPermille allows setting of 1dp percentages (e.g. 25 = a max wallet of 2.5%)
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param maxWalletPermille The max wallet holdings in permille of total supply
      */
    function setMaxWalletPermille (uint16 maxWalletPermille) external onlyOwner {
        setMaxWalletPermille (maxWalletPermille, totalSupply());
    }
    
    /**
      * @dev Sets the max wallet holdings allowed as a permille of total supply. 
      * maxWalletPermille allows setting of 1dp percentages (e.g. 25 = a max wallet of 2.5%)
      * 
      * @param maxWalletPermille The max wallet holdings in total supply permille
      * @param _totalSupply The total supply of the token
      */
    function setMaxWalletPermille (uint16 maxWalletPermille, uint256 _totalSupply) internal {
        require (maxWalletPermille >= 1 && maxWalletPermille <= 1000, createErrorMessage (MAX_PERMILLE_ISSUE));
        uint256 newMaxWalletAmount = _totalSupply * maxWalletPermille / 1000;
        emit MaxWalletAmountChanged (maxWalletAmount, newMaxWalletAmount);
        maxWalletAmount = newMaxWalletAmount;
    }
    
    /**
      * @dev Sets the max transfer amount allowed as a permille of total supply. 
      * maxTxPermille allows setting of 1dp percentages (e.g. 25 = a max wallet of 2.5%)
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param maxTxPermille The max transfer amount in permille of total supply
      */
    function setMaxTxPermille (uint16 maxTxPermille) external onlyOwner {
        setMaxTxPermille (maxTxPermille, totalSupply());
    }
    
    /**
      * @dev Sets the max transfer amount allowed as a permille of total supply. 
      * maxTxPermille allows setting of 1dp percentages (e.g. 25 = a max wallet of 2.5%)
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param maxTxPermille The max transfer amount in permille of total supply
      * @param _totalSupply The total supply of the token
      */
    function setMaxTxPermille (uint16 maxTxPermille, uint256 _totalSupply) internal {
        require (maxTxPermille >= 1 && maxTxPermille <= 1000, createErrorMessage (MAX_PERMILLE_ISSUE));
        uint256 newMaxTxAmount = _totalSupply * maxTxPermille / 1000;
        emit MaxTxAmountChanged (maxTxAmount, newMaxTxAmount);
        maxTxAmount = newMaxTxAmount;
    }
    
    /**
      * @dev Registers an AMM pair address with the contract.
      * Transfers to (selling) and from (buying) the AMM pair will be subject to fees specified in feeInfo
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param pair The LP pair contract address
      * @param value Whether this should be registered as an AMM pair
      */
    function setAutomatedMarketMakerPair (address pair, bool value) public virtual onlyOwner {
        require (pair != swapPair || value == true, createErrorMessage ("Pair can't be removed"));
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair (pair, value);
    }
    
    /**
      * @dev Creates an error message with a custom prefix generated by the contract's symbol
      * 
      * @param _message The error message to prefix
      */
    function createErrorMessage (string memory _message) internal view returns (string memory) {
        return string (abi.encodePacked (symbol(), ": ", _message));
    }
    
    /**
      * @dev Sets transfer fees applied to token buys
      *
      * NOTE: 
      * - This function can only be called by the contract owner
      * - This function is intended to be overridden by token types that inherit this base contract
      * 
      */
    function setBuyFees (uint8[] memory /*_otherFee*/, uint8 /*_liquidityFee*/, uint8 /*_marketingFee*/, uint8 /*_burnFee*/) external virtual onlyOwner {
        revert (createErrorMessage (NOT_SUPPORTED));
    }
    
    /**
      * @dev Sets transfer fees applied to token sells
      *
      * NOTE: 
      * - This function can only be called by the contract owner
      * - This function is intended to be overridden by token types that inherit this base contract
      */
    function setSellFees (uint8[] memory /*_otherFee*/, uint8 /*_liquidityFee*/, uint8 /*_marketingFee*/, uint8 /*_burnFee*/) external virtual onlyOwner {
        revert (createErrorMessage (NOT_SUPPORTED));
    }
    
    /**
      * @dev Sets transfer fees applied to token buys
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param _liquidityFee The fee apportioned for adding to the liquidity pool, in percent of transfer amount
      * @param _marketingFee The fee apportioned for sending to the marketing wallet, in percent of transfer amount
      * @param _burnFee The fee apportioned for sending to the burn address, in percent of transfer amount
      */
    function setBuyFees (uint8 _liquidityFee, uint8 _marketingFee, uint8 _burnFee) external onlyOwner {
        setFees (_liquidityFee, _marketingFee, _burnFee, BUY);
    }
    
    /**
      * @dev Sets transfer fees applied to token sells
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param _liquidityFee The fee apportioned for adding to the liquidity pool, in percent of transfer amount
      * @param _marketingFee The fee apportioned for sending to the marketing wallet, in percent of transfer amount
      * @param _burnFee The fee apportioned for sending to the burn address, in percent of transfer amount
      */
    function setSellFees (uint8 _liquidityFee, uint8 _marketingFee, uint8 _burnFee) external onlyOwner {
        setFees (_liquidityFee, _marketingFee, _burnFee, SELL);
    }
    
    /**
      * @dev Sets transfer fees
      *
      * NOTE: total fees must be <25% else this function reverts
      * 
      * @param _liquidityFee The fee apportioned for adding to the liquidity pool, in percent of transfer amount
      * @param _marketingFee The fee apportioned for sending to the marketing wallet, in percent of transfer amount
      * @param _burnFee The fee apportioned for sending to the burn address, in percent of transfer amount
      * @param _feeType 0 to modify buy fees, 1 to modify sell fees
      * @return totalFees the sum of all fees
      */
    function setFees (uint8 _liquidityFee, uint8 _marketingFee, uint8 _burnFee, uint8 _feeType) internal returns (uint256 totalFees) {
        totalFees = _liquidityFee + _marketingFee + _burnFee;

        require (totalFees <= 25, createErrorMessage (FEES_TOO_HIGH));

		    emit FeesChanged (
            _feeType == BUY ? BUY_STRING : SELL_STRING, 
            feeInfo[_feeType].liquidityFee, 
            _liquidityFee, 
            feeInfo[_feeType].marketingFee,
            _marketingFee, 
            feeInfo[_feeType].burnFee, 
            _burnFee
        );
               
        feeInfo[_feeType].liquidityFee = _liquidityFee;
        feeInfo[_feeType].marketingFee = _marketingFee;
        feeInfo[_feeType].burnFee = _burnFee;
        totalFeePerMille[_feeType] = uint16(totalFees * 10 + feeInfo[_feeType].platformFee);
    }
    
    /**
      * @dev Sets transfer fees including any special fees (feeInfo.otherFee)
      *
      * NOTE: total fees must be <25% else this function reverts
      * 
      * @param _otherFee A variable-length array of fees set by custom token types (e.g. reward token fees), in percent of transfer amount
      * @param _liquidityFee The fee apportioned for adding to the liquidity pool, in percent of transfer amount
      * @param _marketingFee The fee apportioned for sending to the marketing wallet, in percent of transfer amount
      * @param _burnFee The fee apportioned for sending to the burn address, in percent of transfer amount
      * @param _feeType 0 to modify buy fees, 1 to modify sell fees
      */
    function setFees (uint8[] memory _otherFee, uint8 _liquidityFee, uint8 _marketingFee, uint8 _burnFee, uint8 _feeType) internal {
        require (_otherFee.length == otherFeeInfo.length, createErrorMessage (WRONG_ARRAY_LENGTH));

        uint256 totalFees = setFees (_liquidityFee, _marketingFee, _burnFee, _feeType);
		    uint8[] memory currentFees = new uint8[] (_otherFee.length);
        
        for (uint256 i = 0; i < _otherFee.length; i++) {
			      currentFees[i] = otherFeeInfo[i].fee[_feeType];
            otherFeeInfo[i].fee[_feeType] = _otherFee[i];
            totalFees += _otherFee[i];
        }
        
        require (totalFees <= 25, createErrorMessage (FEES_TOO_HIGH));

        totalFeePerMille[_feeType] = uint16(totalFees * 10 + feeInfo[_feeType].platformFee);
		    emit AdditionalFeesChanged (_feeType == BUY ? BUY_STRING : SELL_STRING, currentFees, _otherFee);
    }
    
    /**
      * @dev Sets the amount at which the contract will swap owned tokens for WETH
      *
      * NOTE: 
      * - This function can only be called by the contract owner
      * - This function takes a token amount without decimals
      * 
      * @param tokenAmountWithoutDecimals The token amount (without decimals) at which to trigger the contract swap
      */
    function setSwapContractTokensAtAmount (uint256 tokenAmountWithoutDecimals) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        uint256 tokenAmount = tokenAmountWithoutDecimals * 10**decimals();
        require (tokenAmount >= _totalSupply / 1_000_000 && tokenAmount <= _totalSupply / 1000, createErrorMessage ("Must be >0.0001% & <0.1% supply"));
        emit SwapContractTokensAtAmountChanged (swapContractTokensAtAmount, tokenAmount);
        swapContractTokensAtAmount = tokenAmount;
    }
    
    /**
      * @dev Gets the impact of applying otherFee to the transfer
      *
      * NOTE: This function is deliberately left empty to be overriden by custom token contracts. The base token type has no otherFees.
      * 
      * @param amount The amount of tokens being transferred
      * @param feeType Whether this is a buy (0) or a sell (1)
      * @param from The address of the sender
      * @return feesToCollect The fees to send to the contract address, to swap later
      * @return amountModifier The fees already distributed by this function that should be removed from the transfer amount
      */
    function getOtherFeeImpact (uint256 amount, uint8 feeType, address from) internal virtual returns (uint256 feesToCollect, uint256 amountModifier) { }
    
    /**
      * @dev Calculates the fees taken by the contract and distributes them accordingly, storing the amount added to the contract for swapping into specific fee areas
      * 
      * @param amount The amount of tokens being transferred
      * @param feeType Whether this is a buy (0) or a sell (1)
      * @param from The address of the sender
      * @return The amount of tokens minus the fees taken. These tokens should be sent from the sender to the recipient
      */
    function getTransferAmountAndSendFees (uint256 amount, uint8 feeType, address from) internal returns (uint256) {
        // Calculate global fees
        uint256 _marketingTokens = (amount * feeInfo[feeType].marketingFee) / 100;
        uint256 _liquidityTokens = (amount * feeInfo[feeType].liquidityFee) / 100;
        uint256 _platformTokens = (amount * feeInfo[feeType].platformFee) / 1000;
        uint256 _burnTokens = (amount * feeInfo[feeType].burnFee) / 100;
        
        // Calculate other fees: their behaviour is different per token and so this is handled differently
        (uint256 _otherFeesToTake, uint256 _amountModifier) = getOtherFeeImpact (amount, feeType, from);
        amount -= _amountModifier;
        
        // Send fees to marketing wallet if applicable, else record them for when they're swapped
        if (feeInfo[feeType].marketingFundsInTokens) {
            super._transfer (from, addressInfo.marketingWallet, _marketingTokens);
            amount -= _marketingTokens;
            _marketingTokens = 0;
        } else {
            marketingTokens += _marketingTokens;
        }
        
        // Transfer burned token
        super._transfer (from, BURN_ADDRESS, _burnTokens);
        amount -= _burnTokens;
        
        // Keep track of balances so we can split the address balance when swapping
        liquidityTokens += _liquidityTokens;
        platformTokens += _platformTokens;
        
        // Transfer fees for swapping to the contract address, then return the transfer amount
        uint256 fees = _marketingTokens + _liquidityTokens + _otherFeesToTake + _platformTokens;

        super._transfer (from, address(this), fees);
        return (amount - fees);
    }
    
    /**
      * @dev Checks whether a transfer violates any limits, and whether fees should be taken
      * 
      * @param from The address of the sender
      * @param to The address of the recipient
      * @param amount The amount of tokens being transferred
      * @return transferAmount The amount of tokens to be sent from the sender to the recipient. This factors in transfer fees paid.
      */
    function checkTransferRequirementsAndSwap (address from, address to, uint256 amount) internal returns (uint256 transferAmount) {
        transferAmount = amount;
        
        if (!isExcludedFromFees[to]) {
            // Check max wallet
            if (from != owner() && from != initialLiquidityAdder && !automatedMarketMakerPairs[to])
                require (balanceOf(to) + amount <= maxWalletAmount, createErrorMessage ("Over max balance"));
                
            if (!isExcludedFromFees[from]) {
                require (amount <= maxTxAmount, createErrorMessage ("Over max Tx"));
                
        
                if (!swapping) {
                    if (balanceOf (address(this)) >= swapContractTokensAtAmount && !automatedMarketMakerPairs[from]) {
                        swapping = true;
                        swapRequiredFunds();
                        swapping = false;
                    }
            
                    // if any account belongs to isExcludedFromFee then there should be no fees, likewise if we're swapping
                    transferAmount = getTransferAmountAndSendFees (amount, automatedMarketMakerPairs[to] ? SELL : BUY, from);
                }
            }
        }
    }
    
    /**
      * @dev Calculates the number of tokens to swap from the contract address defined by the number set aside by otherFee
      * 
      * @param contractTokenBalance The current contract balance
      * @param _swapContractTokensAtAmount The current contract swap threshold (gas savings)
      * @return scaledOtherFeeTokens A variable-length array containing the number of tokens to be swapped for otherFees
      * @return otherTokensToSwap The sum of scaledOtherFeeTokens
      */
    function getScaledOtherTokensToSwap (uint256 contractTokenBalance, uint256 _swapContractTokensAtAmount) 
        internal 
        virtual 
        returns (uint256[] memory scaledOtherFeeTokens, uint256 otherTokensToSwap)
    { }
    
    /**
      * @dev Manages distribution of ETH created by the contract swap to otherFee recipients
      * 
      * @param tokensSwapped The number of tokens swapped to create ethAvailable
      * @param ethAvailable The total amount of ETH available - this needs to be portioned out using ethAvailable * scaledOtherFeeTokens[i] / tokensSwapped
      * @param scaledOtherFeeTokens A variable-length array containing the number of tokens swapped to create ETH for otherFees
      */
    function sendOtherEth (uint256 tokensSwapped, uint256 ethAvailable, uint256[] memory scaledOtherFeeTokens) internal virtual { }
    
    /**
      * @dev Swaps tokens stored by the contract to ETH and manages distribution based on stored token amounts associated with different fee types
      */
    function swapRequiredFunds() internal {
        uint256 contractTokenBalance = balanceOf (address(this));
        uint256 _swapContractTokensAtAmount = swapContractTokensAtAmount;
        uint256 scaledLiquidityTokens = liquidityTokens * _swapContractTokensAtAmount / contractTokenBalance;
        uint256 scaledMarketingTokens = marketingTokens * _swapContractTokensAtAmount / contractTokenBalance; // will be 0 if taken in native
        uint256 scaledPlatformTokens = platformTokens * _swapContractTokensAtAmount / contractTokenBalance;
        uint256 tokensToSwap = scaledLiquidityTokens / 2;
        uint256 tokensForLiquidity = scaledLiquidityTokens - tokensToSwap;
        tokensToSwap += scaledMarketingTokens + scaledPlatformTokens; 
        
        (uint256[] memory scaledOtherFeeTokens, uint256 otherTokensToSwap) = getScaledOtherTokensToSwap (contractTokenBalance, _swapContractTokensAtAmount);
        tokensToSwap += otherTokensToSwap;
        
        uint256 ethCreated = tokensToSwap > 0 ? swapTokensForEth (tokensToSwap) : 0;
        
        if (ethCreated > 0) {
            // Add Liquidity and modify stored token amount
            ethCreated = addLiquidity (tokensForLiquidity, ethCreated);
            tokensToSwap -= scaledLiquidityTokens / 2;
            liquidityTokens -= scaledLiquidityTokens;
            sendOtherEth (tokensToSwap, ethCreated, scaledOtherFeeTokens);
            
            if (scaledMarketingTokens + scaledPlatformTokens > 0) {
                // Pay marketing & platform wallet with any remaining ETH - this ensures rounding errors don't build up leaving ETH in the contract
                uint256 fundsForMarketing = address(this).balance * scaledMarketingTokens / (scaledMarketingTokens + scaledPlatformTokens);
                
                if (fundsForMarketing > 0) {
                    marketingTokens -= scaledMarketingTokens;
                    payable(addressInfo.marketingWallet).sendValue (fundsForMarketing);
                }
                
                if (address(this).balance > 0) {
                    platformTokens -= scaledPlatformTokens;
					address payable platformWallet = IGenericCloneFactory(addressInfo.cloneFactory).getProxy ("DoughPlatformWallet");
                    platformWallet.sendValue (address(this).balance);
                }
            }
        }
    }
    
    /**
      * @dev Swaps tokens for ETH
      * 
      * @param tokenAmount The number of tokens to swap for ETH
      * @return The amount of ETH created by the swap
      */
    function swapTokensForEth (uint256 tokenAmount) internal returns (uint256) {
        if (tokenAmount > 0) {
            uint256 initialBalance = address(this).balance;
            // generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ISwapRouter02(addressInfo.router).WETH();
    
            _approve (address(this), addressInfo.router, tokenAmount);
    
            // make the swap
            ISwapRouter02(addressInfo.router).swapExactTokensForETHSupportingFeeOnTransferTokens (
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
            
            return (address(this).balance - initialBalance);
        }
        
        return 0;
    }
    
    /**
      * @dev Adds liquidity to the token-WETH pool
      *
      * NOTE: addLiquidityETH adds the necessary amount of ETH based on tokenAmount (assuming it isn't the first LP addition) and 
      * returns the rest, so it is safe for us to send all created ETH to this function rather than trying to calculate the correct amount
      * 
      * @param tokenAmount The number of tokens to add to the pool
      * @param ethAmount The amount of ETH available to add to the pool
      * @return The amount of ETH left from ethAmount once liquidity has been added
      */
    function addLiquidity (uint256 tokenAmount, uint256 ethAmount) internal returns (uint256) {
        if (tokenAmount > 0 && ethAmount > 0) {
            // approve token transfer to cover all possible scenarios
            _approve (address(this), addressInfo.router, tokenAmount);
    
            // add the liquidity
            (,uint256 ethFromLiquidity,) = ISwapRouter02(addressInfo.router).addLiquidityETH {value: ethAmount} (
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            );
            
            return (ethAmount - ethFromLiquidity);
        }
        
        return 0;
    }
    
    /**
      * @dev Performs pre-transfer checks
      * 
      * @param from The address of the sender
      * @param to The address of the recipient
      * @param amount The amount of tokens being transferred
      * @return Whether there are additional transfer actions to perform
      */
    function preTransferActions (address from, address to, uint256 amount) internal virtual returns (bool) {
        require (to != address(0) && from != address(0), createErrorMessage (ZERO_ADDRESS_ISSUE));
        checkLaunched (from, to);
        
        if (amount == 0) {
            super._transfer (from, to, amount);
            return false;
        } 
        
        return true;
    }
    
    /**
      * @dev Checks whether the contract has been launched. If not, and the sender isn't the contract owner or the 
      * initial liquidity adder (TokenLaunchManager) then the contract reverts
      * 
      * @param from The address of the sender
      * @param to The address of the recipient
      */
    function checkLaunched (address from, address to) internal {
        // Need to allow TokenLaunchManager to add liquidity, otherwise prevent any snipers from buying for the first few blocks
        if ((block.timestamp <= doughTokenLaunchedAt || doughTokenLaunchedAt == 0) && from != initialLiquidityAdder && to != initialLiquidityAdder) {
            require (to == owner(), createErrorMessage ("Not launched"));
            
            if (doughTokenLaunchedAt == 0)
                doughTokenLaunchedAt = uint48(block.timestamp) + 10; // c. 3 block timeout
        }
    }
    
    /**
      * @dev Transfers tokens
      * 
      * @param from The address of the sender
      * @param to The address of the recipient
      * @param amount The amount of tokens being transferred
      */
    function _transfer (address from, address to, uint256 amount) internal virtual override {
        if (preTransferActions (from, to, amount)) {
            uint256 transferToAmount = checkTransferRequirementsAndSwap (from, to, amount);
            super._transfer (from, to, transferToAmount);
            postTransferActions (from, to, amount, transferToAmount);
        }
    }
    
    /**
      * @dev Performs any post-transfer actions. Allows overriding contracts to add customisation
      * 
      * @param from The address of the sender
      * @param to The address of the recipient
      * @param transferFromAmount The amount of tokens transferred from the sender (without any fee impact)
      * @param transferToAmount The amount of tokens transferred to the recipient (includes any fee impact)
      */
    function postTransferActions (address from, address to, uint256 transferFromAmount, uint256 transferToAmount) internal virtual { }

    /**
      * @dev Gets the description, buy and sell taxes for a specified fee ID, stored in the therFeeInfo array
      * 
      * @return description The description of the fee
      * @return buyFee The percentage fee on buys for this fee ID
      * @return sellFee The percentage fee on sells for this fee ID
      * @return recipient The recipient of the fee 
      */    
    function getOtherFeeDetails (uint256 ID) external view virtual returns (string memory description, uint8 buyFee, uint8 sellFee, address recipient) {
        require (ID < otherFeeInfo.length, createErrorMessage (ID_TOO_BIG));

        description = otherFeeInfo[ID].descriptor;
        buyFee = otherFeeInfo[ID].fee[BUY];
        sellFee = otherFeeInfo[ID].fee[SELL];
        recipient = otherFeeInfo[ID].feeRecipient;
    }
    
    uint256[20] private __gap;
}
// File: Doughpad-BackEnd/contracts/Tokens/DoughMoonCloneable.sol



pragma solidity ^0.8.4;



contract DoughMoonCloneable is DoughTokenCloneable  {
    using Address for address payable;
    
    mapping(address => uint256) private rBalances;
    mapping(address => uint256) private tBalances;
    
    mapping(address => bool) private isExcluded;
    address[] private excluded;
    
    uint256 private rTotal;
    
    event ExcludedFromReward (address excluded);
    event IncludedInReward (address included);

    constructor () { }
    
    function __DoughToken_init (SharedStructures.TokenInfo memory _tokenInfo) internal override { 
        require (otherFeeInfo.length == 1, createErrorMessage ("One otherFee required for reflection"));

        __Versioned_init ("0.0.2");
        uint256 _totalSupply = _tokenInfo.totalSupplyWithoutDecimals * 10**_tokenInfo.decimals;
        rTotal = type(uint256).max - (type(uint256).max % _totalSupply);
        uint256 currentRate = getRate (_totalSupply);
        rBalances[msg.sender] = ERC20Upgradeable.balanceOf (msg.sender) * currentRate;
        rBalances[BURN_ADDRESS] = ERC20Upgradeable.balanceOf (BURN_ADDRESS) * currentRate;
        address _swapPair = swapPair;
        isExcluded[_swapPair] = true;
        excluded.push (_swapPair);
    }
    
    /**
      * @dev Sets transfer fees applied to token buys
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param _reflectionFee Fee to be reflected to holders
      * @param _liquidityFee The fee apportioned for adding to the liquidity pool, in percent of transfer amount
      * @param _marketingFee The fee apportioned for sending to the marketing wallet, in percent of transfer amount
      * @param _burnFee The fee apportioned for sending to the burn address, in percent of transfer amount
      */
    function setBuyFees (uint8 _reflectionFee, uint8 _liquidityFee, uint8 _marketingFee, uint8 _burnFee) external onlyOwner {
        setFees (_reflectionFee, _liquidityFee, _marketingFee, _burnFee, BUY);
    }
    
    /**
      * @dev Sets transfer fees applied to token sells
      *
      * NOTE: This function can only be called by the contract owner
      * 
      * @param _reflectionFee Fee to be reflected to holders
      * @param _liquidityFee The fee apportioned for adding to the liquidity pool, in percent of transfer amount
      * @param _marketingFee The fee apportioned for sending to the marketing wallet, in percent of transfer amount
      * @param _burnFee The fee apportioned for sending to the burn address, in percent of transfer amount
      */
    function setSellFees (uint8 _reflectionFee, uint8 _liquidityFee, uint8 _marketingFee, uint8 _burnFee) external onlyOwner {
        setFees (_reflectionFee, _liquidityFee, _marketingFee, _burnFee, SELL);
    }
    
    /**
      * @dev Helper for fee-setting to avoid owners having to input arrays where it is not necessary
      * 
      * @param _reflectionFee Fee to be reflected to holders
      * @param _liquidityFee The fee apportioned for adding to the liquidity pool, in percent of transfer amount
      * @param _marketingFee The fee apportioned for sending to the marketing wallet, in percent of transfer amount
      * @param _burnFee The fee apportioned for sending to the burn address, in percent of transfer amount
      * @param _feeType Whether this is a BUY (0) or a SELL (1)
      */
    function setFees (uint8 _reflectionFee, uint8 _liquidityFee, uint8 _marketingFee, uint8 _burnFee, uint8 _feeType) private {
        uint256 length = otherFeeInfo.length;
        uint8[] memory _otherFees = new uint8[](length);

        for (uint256 i; i < length; i++)
            _otherFees[i] = _reflectionFee;

        setFees (_otherFees, _liquidityFee, _marketingFee, _burnFee, _feeType);
    }
    
    // Return the number of "normal" tokens an account has based on their reflective balance
    function tokenFromReflection (uint256 rAmount) private view returns (uint256) {
        require (rAmount <= rTotal, createErrorMessage ("rAmount > rTotal"));
        return rAmount / getRate (totalSupply());
    }


    // Get current token totals from wallets included in reflection
    // Get the current conversion rate from reflected token balance to "normal" token balance
    function getRate (uint256 _tTotal) private view returns (uint256) {
        uint256 rSupply = rTotal;
        uint256 _rTotal = rTotal;
        uint256 tSupply = _tTotal;
        
        for (uint256 i = 0; i < excluded.length; i++) {
            address _excluded = excluded[i];
            uint256 tBalance = tBalances[_excluded];
            uint256 rBalance = rBalances[_excluded];

            if (rBalance > rSupply || tBalance > tSupply) 
                return (_rTotal / _tTotal);
            
            rSupply -= rBalance;
            tSupply -= tBalance;
        }
        
        if (rSupply < _rTotal / _tTotal) 
            return (_rTotal / _tTotal);
            
        return (rSupply / tSupply);
    }
    
    // Allows us to exclude addresses from getting rewards - probably used with centralised exchanges and farms alongside fee exclusion
    function excludeFromReward (address account) external onlyOwner {
        require (account != address(this), createErrorMessage ("Can't exclude token address"));
        require (!isExcluded[account], createErrorMessage ("Account already excluded"));
        
        if(rBalances[account] > 0)
            tBalances[account] = tokenFromReflection (rBalances[account]);
        
        isExcluded[account] = true;
        excluded.push (account);
        emit ExcludedFromReward (account);
    }

    function includeInReward (address account) external onlyOwner() {
        require (isExcluded[account],  createErrorMessage ("Account already included"));

        for (uint256 i; i < excluded.length; i++) {
            if (excluded[i] == account) {
                excluded[i] = excluded[excluded.length - 1];
                isExcluded[account] = false;
                excluded.pop();
                break;
            }
        }
        emit IncludedInReward (account);
    }
    
    function balanceOf (address account) public view override returns (uint256) {
        if (isExcluded[account]) 
            return tBalances[account];
        
        return tokenFromReflection (rBalances[account]);
    }
    
    /**
      * @dev Gets the impact of applying otherFee to the transfer
      *
      * NOTE: This function is deliberately left empty to be overriden by custom token contracts. The base token type has no otherFees.
      * 
      * @param amount The amount of tokens being transferred
      * @param feeType Whether this is a buy (0) or a sell (1)
      * @return feesToCollect The fees to send to the contract address, to swap later
      * @return amountModifier The fees already distributed by this function that should be removed from the transfer amount
      */
    function getOtherFeeImpact (uint256 amount, uint8 feeType, address /*from*/) internal override returns (uint256 feesToCollect, uint256 amountModifier) { 
        otherTokens[0] = (amount * otherFeeInfo[0].fee[feeType]) / 100;
        amountModifier = otherTokens[0];
        feesToCollect = 0; // silence warning
    }
    
    /**
      * @dev Performs any post-transfer actions. Allows overriding contracts to add customisation
      * 
      * @param from The address of the sender
      * @param to The address of the recipient
      * @param transferFromAmount The amount of tokens transferred from the sender (without any fee impact)
      * @param transferToAmount The amount of tokens transferred to the recipient (includes any fee impact)
      */
    function postTransferActions (address from, address to, uint256 transferFromAmount, uint256 transferToAmount) internal override {
        uint256 currentRate = getRate (totalSupply());

        if (isExcluded[from])
            tBalances[from] -= transferFromAmount;

        rBalances[from] -= transferFromAmount * currentRate;

        if (isExcluded[to])
            tBalances[to] += transferToAmount;

        rBalances[to] += transferToAmount * currentRate;

        // Reflect fee
        rTotal -= otherTokens[0] * currentRate;
        otherTokens[0] = 0;
    }
}