//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interface/IFlashLoanReceiver.sol";
import "./interface/ILiquidityPool.sol";
import "./interface/IMarket.sol";
import "./interface/IPrice.sol";
import "./interface/IUniswapV3Router.sol";
import "./interface/IWeth.sol";
import "./interface/IxTokenManager.sol";
import "./lock/BlockLock.sol";

// we need to have swaps working for arbitrum uniswap, sushiswap, balancer
// will need to be able to approve on all three
contract xAssetLev is
    Initializable,
    IFlashLoanReceiver,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    BlockLock
{
    //--------------------------------------------------------------------------
    // State variables
    //--------------------------------------------------------------------------

    uint256 constant INITIAL_SUPPLY_MULTIPLIER = 10;
    uint256 internal constant MAX_UINT = 2**256 - 1;

    IERC20Metadata public baseToken;
    IERC20Metadata private usdc;
    IWeth private weth;

    ILiquidityPool private liquidityPool;
    IMarket private market;
    IPrice private priceFeed;
    IUniswapV3Router private uniswapV3Router;
    IxTokenManager private xTokenManager;

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }
    FeeDivisors public feeDivisors;

    uint256 public supplyCap;
    uint256 public userBalanceCap;
    uint256 public claimableFees;

    //--------------------------------------------------------------------------
    // Modifiers
    //--------------------------------------------------------------------------

    /**
     * @dev Enforce functions only called by management.
     */
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || xTokenManager.isManager(msg.sender, address(this)), "Non-admin caller");
        _;
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    /**
     * @dev Initializes this leverage asset
     *
     * @param _baseToken The asset to be leveraged
     * @param _usdc USDC that will be borrowed
     * @param _weth Weth token contract
     * @param _market The xtoken lending market contract
     * @param _liquidityPool The xtoken lending liquidity pool contract
     * @param _priceFeed The xtoken lending price feed contract
     * @param _uniswapV3Router The uniswap router
     * @param _xTokenManager The xtoken manager contract
     * @param _feeDivisors The fee divisors
     */
    function initialize(
        IERC20Metadata _baseToken,
        IERC20Metadata _usdc,
        IWeth _weth,
        IMarket _market,
        ILiquidityPool _liquidityPool,
        IPrice _priceFeed,
        IUniswapV3Router _uniswapV3Router,
        IxTokenManager _xTokenManager,
        FeeDivisors calldata _feeDivisors
    ) external initializer {
        __ERC20_init("xAssetLev", "xETH3x");
        __Ownable_init();
        __Pausable_init();

        market = _market;
        baseToken = _baseToken;
        usdc = _usdc;
        liquidityPool = _liquidityPool;
        uniswapV3Router = _uniswapV3Router;
        weth = _weth;
        xTokenManager = _xTokenManager;
        priceFeed = _priceFeed;

        feeDivisors = _feeDivisors;

        // token approvals for uniswap swap router
        usdc.approve(address(uniswapV3Router), MAX_UINT);
        baseToken.approve(address(uniswapV3Router), MAX_UINT);
        weth.approve(address(uniswapV3Router), MAX_UINT);

        // token approvals for xtoken lending
        baseToken.approve(address(market), MAX_UINT);
        usdc.approve(address(liquidityPool), MAX_UINT);

        // todo set supply/user caps
        supplyCap = 1_000_000 ether; // temp value
        userBalanceCap = 10_000 ether; // temp value
    }

    //--------------------------------------------------------------------------
    // For Investors
    //--------------------------------------------------------------------------

    /**
     * @dev Mint leveraged asset tokens with ETH
     *
     * @param minReturn The minimum return for the ETH trade
     */
    function mint(uint256 minReturn) external payable notLocked(msg.sender) {
        require(msg.value > 0, "Must send ETH");
        _lock(msg.sender);

        // make the deposit to weth
        uint256 ethAmount = msg.value;
        weth.deposit{ value: ethAmount }();

        // swap for base token if weth is not the base token
        uint256 baseTokenAmount;
        if (address(baseToken) == address(weth)) {
            baseTokenAmount = ethAmount;
        } else {
            baseTokenAmount = _swapExactInputForOutput(address(weth), address(baseToken), ethAmount, minReturn);
        }

        uint256 fee = baseTokenAmount / feeDivisors.mintFee;
        _incrementFees(fee);

        uint256 amountToMint = calculateMintAmount((baseTokenAmount - fee));
        require(totalSupply() + amountToMint <= supplyCap);
        require(balanceOf(msg.sender) + amountToMint < userBalanceCap);

        _mint(msg.sender, amountToMint);
    }

    /**
     * @dev Mint leveraged asset tokens with the base token
     */
    function mintWithToken(uint256 inputAssetAmount) external notLocked(msg.sender) {
        require(inputAssetAmount > 0, "Must send token");
        _lock(msg.sender);

        baseToken.transferFrom(msg.sender, address(this), inputAssetAmount);

        uint256 fee = inputAssetAmount / feeDivisors.mintFee;
        _incrementFees(fee);

        uint256 amountToMint = calculateMintAmount((inputAssetAmount - fee));
        require(totalSupply() + amountToMint <= supplyCap);
        require(balanceOf(msg.sender) + amountToMint < userBalanceCap);

        _mint(msg.sender, amountToMint);
    }

    /**
     * @dev Burns the leveraged asset token for the base token or ETH
     * @param xassetAmount The amount to burn
     */
    function burn(
        uint256 xassetAmount,
        bool redeemForEth,
        uint256 minReturn
    ) external notLocked(msg.sender) {
        require(xassetAmount > 0, "Must send token");
        _lock(msg.sender);
        uint256 nav = getNav();

        uint256 proRataTokens = (nav * xassetAmount) / totalSupply();
        require(proRataTokens <= getBufferBalance(), "Insufficient exit liquidity"); // we can make this more gas efficient by breaking up getnav calc into buffer and not buffer

        uint256 fee = proRataTokens / feeDivisors.burnFee;
        _incrementFees(fee);

        _burn(msg.sender, xassetAmount);

        if (redeemForEth) {
            if (address(baseToken) != address(weth)) {
                _swapExactInputForOutput(address(baseToken), address(weth), proRataTokens, minReturn);
            }
            weth.withdraw(proRataTokens);

            // Send eth
            (bool success, ) = msg.sender.call{ value: proRataTokens }(new bytes(0));
            require(success, "ETH  transfer failed");
        } else {
            baseToken.transfer(msg.sender, proRataTokens);
        }
    }

    /**
     * @notice Add block lock functionality to token transfers
     */
    function transfer(address recipient, uint256 amount) public override notLocked(msg.sender) returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @notice Add block lock functionality to token transfers
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notLocked(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    //--------------------------------------------------------------------------
    // View Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Returns the value in base token terms
     *
     * @return The nav
     */
    function getNav() public view returns (uint256) {
        uint256 baseTokenNav = market.collateral(address(this)) + getBufferBalance();
        uint256 usdDenominatedDebt = liquidityPool.updatedBorrowBy(address(this)); // 18 decimals?

        // Get the asset price in usdc
        uint256 assetUsdPrice = priceFeed.getPrice(); // 12 decimals
        uint256 assetUsdPriceAdjusted = assetUsdPrice * 10**6;

        // convert usd denominated debt to base token terms
        uint256 baseTokenMultiplier = 10**baseToken.decimals();
        uint256 baseTokenDenominatedDebt = (usdDenominatedDebt * baseTokenMultiplier) / assetUsdPriceAdjusted; // convert to baseToken decimals

        return (baseTokenNav - baseTokenDenominatedDebt);
    }

    /**
     * @dev Returns the buffer balance without including fees
     *
     * @return The buffer balance
     */
    function getBufferBalance() public view returns (uint256) {
        return baseToken.balanceOf(address(this)) - claimableFees;
    }

    /**
     * @dev Get the withdrawable fee amounts
     * @return feeAsset The fee asset
     * @return feeAmount The withdrawable amount
     */
    function getWithdrawableFees() public view returns (address feeAsset, uint256 feeAmount) {
        feeAsset = address(baseToken);
        feeAmount = claimableFees;
    }

    /**
     * @dev Calculates the mint amount based on current supply
     *
     * @param incrementalToken The amount of base tokens used for minting
     *
     * @return The mint amount
     */
    function calculateMintAmount(uint256 incrementalToken) public view returns (uint256) {
        if (totalSupply() == 0) {
            // todo figure out how to approach initial supply multiplier
            // maybe pass as a param
            return incrementalToken * INITIAL_SUPPLY_MULTIPLIER;
        }

        uint256 navBefore = getNav() - incrementalToken;
        return (incrementalToken * totalSupply()) / navBefore;
    }

    //--------------------------------------------------------------------------
    // Management
    //--------------------------------------------------------------------------

    /**
     * @dev Creates the leveraged position
     *
     * @param depositAmounts The amounts to be deposited. Needs to be same length as borrowAmounts.
     * @param borrowAmounts The amounts to be borroed. Needs to be same length as depositAmounts.
     */
    function lever(uint256[] calldata depositAmounts, uint256[] calldata borrowAmounts) public onlyOwnerOrManager {
        require(depositAmounts.length == borrowAmounts.length, "Invalid params length");
        for (uint256 i = 0; i < depositAmounts.length; i++) {
            require(depositAmounts[i] <= getBufferBalance(), "Deposit amount too large");
            market.collateralize(depositAmounts[i]);
            liquidityPool.borrow(borrowAmounts[i]);
            // => swap usdc for baseToken
            _swapExactInputForOutput(address(usdc), address(baseToken), borrowAmounts[i], 0);
        }
    }

    /**
     * @dev Unwinds the leveraged position through flash loan
     *
     * @param withdrawAmount The amount of collateral to be withdrawn
     */
    function delever(uint256 withdrawAmount) public onlyOwnerOrManager {
        // Get the amount of usd to borrow to cover withdrawAmount
        uint256 assetUsdPrice = priceFeed.getPrice(); // 12 decimals
        uint256 usdcAmount = withdrawAmount * assetUsdPrice;

        uint256 priceFeedDivisor = 10**12;
        uint256 baseTokenToUSDCDivisor = 10**(baseToken.decimals() - usdc.decimals());
        uint256 usdcAmountAdjusted = usdcAmount / priceFeedDivisor / baseTokenToUSDCDivisor;

        // encode amount to withdraw
        bytes memory params = abi.encodePacked(withdrawAmount);

        // Take a flash loan based on debt owed
        // Note function executeOperation is the callback
        liquidityPool.flashLoan(address(this), usdcAmountAdjusted, params);
    }

    /**
     * @dev Flash loan callback function.
     * Pay market debt with flash loan funds
     * Withdraw collateral (amount contained in _params)
     * Swap withdrawn collateral for USDC
     * Pay back flash loan
     *
     * @param _amount The amount borrowed from flash loan
     * @param _fee The flash loan fee
     * @param _params The flash loan params, will contain amount of ETH to withdraw
     */
    function executeOperation(
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        require(msg.sender == address(liquidityPool), "Only callable by flash loan provider");

        // Decode params
        uint256 withdrawAmount = abi.decode(_params, (uint256));

        // Pay back debt
        liquidityPool.repay(_amount);

        // Withdraw collateral + a bit extra to pay for flash loan fee
        // Determine how much to withdraw to cover fee
        // todo Is this the best way to cover fee?
        uint256 baseTokenUsdValue = priceFeed.getPrice();
        _withdraw(withdrawAmount + (_fee / baseTokenUsdValue));

        // Swap collateral for flash loan debt
        // todo Calculate exact amount of baseToken needed to make swap
        _swapInputForExactOutput(address(baseToken), address(usdc), weth.balanceOf(address(this)), _amount + _fee);
    }

    /**
     * @dev Withdraw collateral from xtoken lending
     *
     * @param withdrawAmount The amount to withdraw
     */
    function withdraw(uint256 withdrawAmount) public onlyOwnerOrManager {
        _withdraw(withdrawAmount);
    }

    /**
     * @dev Set the supply cap
     *
     * @param _supplyCap The new supply cap
     */
    function setSupplyCap(uint256 _supplyCap) external onlyOwnerOrManager {
        supplyCap = _supplyCap;
    }

    /**
     * @dev Set the user balance cap
     *
     * @param _userBalanceCap The new user balance cap
     */
    function setUserBalanceCap(uint256 _userBalanceCap) external onlyOwnerOrManager {
        userBalanceCap = _userBalanceCap;
    }

    /**
     * @dev Claim and withdraw fees
     * @notice Only callable by the revenue controller
     */
    function claimFees() external {
        require(xTokenManager.isRevenueController(msg.sender), "Callable only by Revenue Controller");
        // => transfer tokens
        uint256 totalFees = claimableFees;
        claimableFees = 0;
        baseToken.transfer(msg.sender, totalFees);
    }

    /**
     * @dev Exempts an address from blocklock
     * @param lockAddress The address to exempt
     */
    function exemptFromBlockLock(address lockAddress) external onlyOwnerOrManager {
        _exemptFromBlockLock(lockAddress);
    }

    /**
     * @dev Removes exemption for an address from blocklock
     * @param lockAddress The address to remove exemption
     */
    function removeBlockLockExemption(address lockAddress) external onlyOwnerOrManager {
        _removeBlockLockExemption(lockAddress);
    }

    //--------------------------------------------------------------------------
    // Private functions
    //--------------------------------------------------------------------------

    function _withdraw(uint256 _withdrawAmount) private {
        market.withdraw(_withdrawAmount);
    }

    function _incrementFees(uint256 _amount) private {
        claimableFees += _amount;
    }

    function _swapExactInputForOutput(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minReturn
    ) internal returns (uint256) {
        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: address(inputToken),
            tokenOut: address(outputToken),
            fee: 500, // todo Make this a configurable state variable
            recipient: address(this),
            deadline: MAX_UINT,
            amountIn: inputAmount,
            amountOutMinimum: minReturn,
            sqrtPriceLimitX96: 0
        });

        uint256 amountOut = uniswapV3Router.exactInputSingle(params);

        return amountOut;
    }

    function _swapInputForExactOutput(
        address inputToken,
        address outputToken,
        uint256 maxInput,
        uint256 exactReturn
    ) internal returns (uint256) {
        IUniswapV3Router.ExactOutputSingleParams memory params = IUniswapV3Router.ExactOutputSingleParams({
            tokenIn: address(inputToken),
            tokenOut: address(outputToken),
            fee: 500, // todo Make this configurable state variable
            recipient: address(this),
            deadline: MAX_UINT,
            amountOut: exactReturn,
            amountInMaximum: maxInput,
            sqrtPriceLimitX96: 0
        });

        uint256 amountIn = uniswapV3Router.exactOutputSingle(params);

        return amountIn;
    }
}

// Features required on Lending
// - blocklock exempt for several different contracts incl. comptroller, market, liquidityPool
// - sufficiently aggressive LTV to assure delever
// - liquidationExempt mapping for privileged internal xToken contracts
//
//
//

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
        return 18;
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IFlashLoanReceiver {
    function executeOperation(
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface ILiquidityPool {
    function updatedBorrowBy(address _borrower) external view returns (uint256);

    function borrow(uint256 _amount) external;

    function repay(uint256 _amount) external;

    function flashLoan(
        address _receiver,
        uint256 _amount,
        bytes memory _params
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IMarket {
    function getCollateralFactor() external view returns (uint256);

    function setCollateralFactor(uint256 _collateralFactor) external;

    function getCollateralCap() external view returns (uint256);

    function setCollateralCap(uint256 _collateralCap) external;

    function collateralize(uint256 _amount) external;

    function collateral(address _borrower) external view returns (uint256);

    function borrowingLimit(address _borrower) external view returns (uint256);

    function setComptroller(address _comptroller) external;

    function setCollateralizationActive(bool _active) external;

    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external;

    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Abstract Price Contract
/// @notice Handles the hassles of calculating the same price formula for each xAsset
/// @dev Not deployable. This has to be implemented by any xAssetPrice contract
abstract contract IPrice {
    /// @dev Specify the underlying asset of each xAssetPrice contract
    address public underlyingAssetAddress;
    address public underlyingPriceFeedAddress;
    address public usdcPriceFeedAddress;

    uint256 internal assetPriceDecimalMultiplier;
    uint256 internal usdcPriceDecimalMultiplier;

    uint256 private constant FACTOR = 1e18;
    uint256 private constant PRICE_DECIMALS_CORRECTION = 1e12;

    /// @notice Provides the amount of the underyling assets of xAsset held by the xAsset asset in wei
    function getAssetHeld() public view virtual returns (uint256);

    /// @notice Anyone can know how much certain xAsset is worthy in USDC terms
    /// @dev This relies on the getAssetHeld function implemented by each xAssetPrice contract
    /// @dev Prices are handling 12 decimals
    /// @return capacity (uint256) How much an xAsset is worthy on USDC terms
    function getPrice() external view returns (uint256) {
        uint256 assetHeld = getAssetHeld();
        uint256 assetTotalSupply = IERC20(underlyingAssetAddress).totalSupply();

        (
            uint80 roundIDUsd,
            int256 assetUsdPrice,
            ,
            uint256 timeStampUsd,
            uint80 answeredInRoundUsd
        ) = AggregatorV3Interface(underlyingPriceFeedAddress).latestRoundData();
        require(timeStampUsd != 0, "ChainlinkOracle::getLatestAnswer: round is not complete");
        require(answeredInRoundUsd >= roundIDUsd, "ChainlinkOracle::getLatestAnswer: stale data");
        uint256 usdPrice = (assetHeld * (uint256(assetUsdPrice)) * (assetPriceDecimalMultiplier)) / (assetTotalSupply);

        (
            uint80 roundIDUsdc,
            int256 usdcusdPrice,
            ,
            uint256 timeStampUsdc,
            uint80 answeredInRoundUsdc
        ) = AggregatorV3Interface(usdcPriceFeedAddress).latestRoundData();
        require(timeStampUsdc != 0, "ChainlinkOracle::getLatestAnswer: round is not complete");
        require(answeredInRoundUsdc >= roundIDUsdc, "ChainlinkOracle::getLatestAnswer: stale data");
        uint256 usdcPrice = ((usdPrice * (PRICE_DECIMALS_CORRECTION)) / (uint256(usdcusdPrice))) /
            (usdcPriceDecimalMultiplier);
        return usdcPrice;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

// Copied from:
// https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeth is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IxTokenManager {
    /**
     * @dev Add a manager to an xAsset fund
     */
    function addManager(address manager, address fund) external;

    /**
     * @dev Remove a manager from an xAsset fund
     */
    function removeManager(address manager, address fund) external;

    /**
     * @dev Check if an address is a manager for a fund
     */
    function isManager(address manager, address fund) external view returns (bool);

    /**
     * @dev Set revenue controller
     */
    function setRevenueController(address controller) external;

    /**
     * @dev Check if address is revenue controller
     */
    function isRevenueController(address caller) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address. 
 */
contract BlockLock {
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;
    mapping(address => bool) public blockLockExempt;

    function _lock(address lockAddress) internal {
        if (!blockLockExempt[lockAddress]) {
            lastLockedBlock[lockAddress] = block.number + BLOCK_LOCK_COUNT;
        }
    }

    function _exemptFromBlockLock(address lockAddress) internal {
        blockLockExempt[lockAddress] = true;
    }

    function _removeBlockLockExemption(address lockAddress) internal {
        blockLockExempt[lockAddress] = false;
    }

    modifier notLocked(address lockAddress) {
        require(lastLockedBlock[lockAddress] <= block.number, "Address is temporarily locked");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}