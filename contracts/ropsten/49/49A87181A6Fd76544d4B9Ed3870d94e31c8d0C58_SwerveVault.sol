// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Detailed} from "./interfaces/IERC20Detailed.sol";
import {ISwerveGauge} from "./interfaces/swerve/ISwerveGauge.sol";
import {ISwerveMinter} from "./interfaces/swerve/ISwerveMinter.sol";
import {ISwervePool} from "./interfaces/swerve/ISwervePool.sol";
import {IUniswapRouter} from "./interfaces/uniswap/IUniswapRouter.sol";

contract SwerveVault is OwnableUpgradeable, ERC20Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MAX_BPS = 10_000;
    // used for swrv <> weth <> currency token route
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // NOTE: A four-century period will be missing 3 of its 100 Julian leap years, leaving 97.
    //       So the average year has 365 + 97/400 = 365.2425 days
    //       ERROR(Julian): -0.0078
    //       ERROR(Gregorian): -0.0003
    uint256 public constant SECS_PER_YEAR = 31_556_952;

    // ================ WARNING ==================
    // ===== THIS CONTRACT IS INITIALIZABLE ======
    // === STORAGE VARIABLES ARE DECLARED BELOW ==
    // REMOVAL OR REORDER OF VARIABLES WILL RESULT
    // ========= IN STORAGE CORRUPTION ===========

    IERC20Upgradeable public token;
    uint256 public tokenIndex;
    uint256 public precisionMultiplier;

    // Swerve Finance Protocol
    ISwerveGauge public swerveGauge;
    ISwerveMinter public swerveMinter;
    ISwervePool public swervePool;
    IERC20Upgradeable public swusdToken;
    IERC20Upgradeable public swrvToken;
    // Control slippage of add_liquidity & remove_liquidity_one_coin (in BPS, <= 10k)
    uint256 public swerveSlippage;
    
    IUniswapRouter public uniRouter;
    address[] public uniSWRV2TokenPath;

    // allow pausing of deposits
    bool public isJoiningPaused;

    mapping(address => uint256) public latestJoinBlock;

    // Limit for totalAssets the Vault can hold
    uint256 public depositLimit;
    // Debt ratio for the Vault (in BPS, <= 10k)
    uint256 public debtRatio;
    // Governance Fee ratio for management of Vault (given to `rewards`  in BPS, <= 10k)
    uint256 public managementFeeRatio;
    // Governance Fee ratio for performance of Vault (given to `rewards`  in BPS, <= 10k)
    uint256 public performanceFeeRatio;
    // block.timestamp of the last time a harvest occured
    uint256 public lastHarvest;
    // Rewards address where fees are sent to
    address public rewards;

    // ======= STORAGE DECLARATION END ============

    function initialize(
        address _swervePool,
        uint256 _tokenIndex,
        address _swerveGauge,
        address _uniRouter
    ) public initializer {
        __Ownable_init_unchained();

        swervePool = ISwervePool(_swervePool);
        swusdToken = IERC20Upgradeable(swervePool.token());
        address underlyingCoin = swervePool.underlying_coins(int128(int256(_tokenIndex)));
        token = IERC20Upgradeable(underlyingCoin);
        tokenIndex = _tokenIndex;
        string memory name = string(abi.encodePacked(IERC20Detailed(underlyingCoin).name(), " sVault"));
        string memory symbol = string(abi.encodePacked("sv", IERC20Detailed(underlyingCoin).symbol()));
        __ERC20_init(name, symbol);

        swerveGauge = ISwerveGauge(_swerveGauge);
        swerveMinter = swerveGauge.minter();
        swrvToken = IERC20Upgradeable(swerveMinter.token());
        uniRouter = IUniswapRouter(_uniRouter);
        uniSWRV2TokenPath = [address(swrvToken), WETH, address(token)];
        swerveSlippage = 50; // 0.5%

        precisionMultiplier = 10 ** (IERC20Detailed(swervePool.token()).decimals() - decimals());
        depositLimit = 100_000 * (10 ** decimals());  // 100K
        debtRatio = 9500; // 95% pool value
        managementFeeRatio = 200; // 2% per year
        performanceFeeRatio = 1000; // 10% of yield
        lastHarvest = block.timestamp;
        rewards = _msgSender();
    }

    // Modifiers

    /**
     * @dev Vault can only be joined when it's unpaused
     */
    modifier joiningNotPaused() {
        require(!isJoiningPaused, "Swift: Deposit is paused");
        _;
    }

    // Events

    /**
     * @dev Emitted when joining is paused or unpaused
     * @param isJoiningPaused New pausing status
     */
    event JoiningPauseStatusChanged(bool isJoiningPaused);

    // ERC20Upgradeable

    function decimals() public override view virtual returns (uint8) {
        return IERC20Detailed(address(token)).decimals();
    }

    // Vault

    /**
     * @dev Allow pausing of deposits in case of emergency
     * @param status New deposit status
     */
    function changeJoiningPauseStatus(bool status) external onlyOwner {
        isJoiningPaused = status;
        emit JoiningPauseStatusChanged(status);
    }

    function setSwerveSlippage(uint256 slippage) external onlyOwner {
        require(slippage <= MAX_BPS, "Swift: slippage > MAX_BPS");
        swerveSlippage = slippage;
    }

    function setDepositLimit(uint256 limit) external onlyOwner {
        depositLimit = limit;
    }

    function setDebtRatio(uint256 ratio) external onlyOwner {
        require(ratio <= MAX_BPS, "Swift: ratio > MAX_BPS");
        debtRatio = ratio;
    }

    function setManagementFeeRatio(uint256 ratio) external onlyOwner {
        require(ratio <= MAX_BPS, "Swift: ratio > MAX_BPS");
        managementFeeRatio = ratio;
    }

    function setPerformanceFeeRatio(uint256 ratio) external onlyOwner {
        require(ratio <= MAX_BPS, "Swift: ratio > MAX_BPS");
        performanceFeeRatio = ratio;
    }

    function setRewards(address _rewards) external onlyOwner {
        rewards = _rewards;
    }

    /**
     * @dev Get total balance of Swerve.fi pool tokens
     * @return Balance of swerve pool tokens in this contract
     */
    function swusdTokenBalance() public view returns (uint256) {
        return swusdToken.balanceOf(address(this)) + swerveGauge.balanceOf(address(this));
    }

    /**
     * @dev Virtual value of swUSD tokens in the pool
     * @return swusdToken in USD
     */
    function swusdTokenValue() public view returns (uint256) {
        uint256 value = swusdTokenBalance() * swervePool.curve().get_virtual_price();
        return value / (precisionMultiplier * 1e18);
    }

    /**
     * @dev Currency token balance
     * @return Currency token balance
     */
    function currencyBalance() internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Calculate pool value in USD
     * "virtual price" of entire pool - underlying tokens, swUSD tokens
     * @return pool value in USD
     */
    function poolValue() public view returns (uint256) {
        return currencyBalance() + swusdTokenValue();
    }

    /**
     * @notice Expected amount of minted Swerve.fi swUSD tokens
     * Can be used to control slippage
     * @param currencyAmount amount to calculate for
     * @param _deposit set True for deposits, False for withdrawals
     * @return expected amount minted given currency amount
     */
    function calcTokenAmount(
        uint256 currencyAmount,
        bool _deposit
    ) public view returns (uint256) {
        uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
        amounts[tokenIndex] = currencyAmount;
        return swervePool.curve().calc_token_amount(amounts, _deposit);
    }

    /**
     * @param depositedAmount Amount of currency deposited
     * @param recipient Receiver of minted tokens
     * @return amount minted from this transaction
     */
    function mint(uint256 depositedAmount, address recipient) internal returns (uint256) {
        uint256 mintedAmount = depositedAmount;
        if (mintedAmount == 0) {
            return mintedAmount;
        }

        // first staker mints same amount deposited
        if (totalSupply() > 0) {
            mintedAmount = totalSupply() * depositedAmount / poolValue();
        }
        // mint pool tokens
        _mint(recipient, mintedAmount);

        return mintedAmount;
    }

    /**
     * @dev ensure enough Swerve.fi pool tokens are available
     * Check if current available amount of swUSD is enough and
     * withdraw remainder from gauge
     * @param neededAmount amount of swUSD required
     * @return amount of swUSD ensured
     */
    function ensureEnoughTokensAreAvailable(uint256 neededAmount) internal returns (uint256) {
        uint256 availableAmount = swusdToken.balanceOf(address(this));
        if (availableAmount < neededAmount) {
            uint256 withdrawAmount = neededAmount - availableAmount;
            uint256 gaugeBalance = swerveGauge.balanceOf(address(this));
            if (withdrawAmount > gaugeBalance) {
                withdrawAmount = gaugeBalance;
            }
            if (withdrawAmount > 0) {
                swerveGauge.withdraw(withdrawAmount);
            }
            return availableAmount + withdrawAmount;
        }
        return neededAmount;
    }

    function _removeLiquidityFromSwerve(uint256 swusdAmount) internal {
        // unstake in gauge
        swusdAmount = ensureEnoughTokensAreAvailable(swusdAmount);

        // remove currency token from swerve
        swusdToken.safeApprove(address(swervePool), 0);
        swusdToken.safeApprove(address(swervePool), swusdAmount);
        uint256 minCurrencyAmount = swusdAmount * swervePool.curve().get_virtual_price();
        minCurrencyAmount *= (MAX_BPS - swerveSlippage);
        minCurrencyAmount /= (precisionMultiplier * 1e18 * MAX_BPS);
        swervePool.remove_liquidity_one_coin(swusdAmount, int128(int256(tokenIndex)), minCurrencyAmount);
    }

    function removeLiquidityFromSwerve(uint256 amountToWithdraw) internal {
        // get rough estimate of how much swUSD we should sell
        uint256 roughSwerveTokenAmount = calcTokenAmount(amountToWithdraw, false) * 1005 / 1000;
        _removeLiquidityFromSwerve(roughSwerveTokenAmount);
    }

    /**
     * @dev Join the pool by depositing currency tokens
     * @param amount amount of currency token to deposit
     */
    function deposit(uint256 amount) external joiningNotPaused {
        require((poolValue() + amount) <= depositLimit, "Swift: Pool value cannot exceed depositLimit");
        
        mint(amount, _msgSender());

        latestJoinBlock[tx.origin] = block.number;
        token.safeTransferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @dev Exit pool only with liquid tokens
     * This function will withdraw underlying tokens
     * @param shares amount of pool tokens to redeem for underlying tokens
     */
    function withdraw(uint256 shares) external {
        require(block.number != latestJoinBlock[tx.origin], "Swift: Cannot deposit and withdraw in same block");

        uint256 amountToWithdraw = poolValue() * shares / totalSupply();

        // burn tokens
        _burn(_msgSender(), shares);

        uint256 beforeBalance = currencyBalance();
        if (amountToWithdraw > beforeBalance) {
            removeLiquidityFromSwerve(amountToWithdraw - beforeBalance);
        }
        uint256 afterBalance = currencyBalance();
        if (amountToWithdraw > afterBalance) {
            amountToWithdraw = afterBalance;
        }

        token.safeTransfer(_msgSender(), amountToWithdraw);
    }

    /**
     * @dev Amount of tokens in Vault swerve has access to as a credit line
     * This will check the debt limit, as well as the tokens
     * available in the Vault, and determine the maximum amount of tokens
     * (if any) swerve may draw on
     * @return The quantity of tokens available for swerve to draw on
     */
    function creditAvailable() public view returns (uint256) {
        uint256 balance = currencyBalance();
        uint256 reserved = (MAX_BPS - debtRatio) * poolValue() / MAX_BPS;
        if (balance > reserved) {
            return balance - reserved;
        }
        return 0;
    }

    /**
     * @dev Deposit funds into Swerve.fi pool and stake in gauge
     * Called by owner to help manage funds in pool and save on gas for deposits
     */
    function earn() public onlyOwner {
        uint256 currencyAmount = creditAvailable();
        if (currencyAmount > 0) {
            uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
            amounts[tokenIndex] = currencyAmount;

            // add to swerve
            uint256 minMintAmount = calcTokenAmount(currencyAmount, true);
            minMintAmount *= (MAX_BPS - swerveSlippage);
            minMintAmount /= MAX_BPS;
            token.safeApprove(address(swervePool), 0);
            token.safeApprove(address(swervePool), currencyAmount);
            swervePool.add_liquidity(amounts, minMintAmount);

            // stake swusd tokens in gauge
            uint256 swusdBalance = swusdToken.balanceOf(address(this));
            swusdToken.safeApprove(address(swerveGauge), 0);
            swusdToken.safeApprove(address(swerveGauge), swusdBalance);
            swerveGauge.deposit(swusdBalance);
        }
    }

    function harvest() public onlyOwner {
        swerveMinter.mint(address(swerveGauge));
        uint256 beforeBalance = currencyBalance();
        // claiming rewards and liquidating them
        uint256 swrvBalance = swrvToken.balanceOf(address(this));
        if (swrvBalance > 0) {
            swrvToken.safeApprove(address(uniRouter), 0);
            swrvToken.safeApprove(address(uniRouter), swrvBalance);
            uniRouter.swapExactTokensForTokens(
                swrvBalance,
                0,
                uniSWRV2TokenPath,
                address(this),
                block.timestamp + 1 hours);
        }
        uint256 afterBalance = currencyBalance();
        if (afterBalance > beforeBalance) {
            uint256 gain = afterBalance - beforeBalance;
            uint256 debtValue = swusdTokenValue();
            uint256 managementFee = debtValue * (block.timestamp - lastHarvest) * managementFeeRatio;
            managementFee /= (SECS_PER_YEAR * MAX_BPS);
            uint256 performanceFee = gain * performanceFeeRatio / MAX_BPS;
            uint256 totalFee = managementFee + performanceFee;
            if (totalFee > gain) {
                totalFee = gain;
            }
            if (rewards != address(0)) {
                mint(totalFee, rewards);
            }
        }
        lastHarvest = block.timestamp;
    }

    function harvestAndEarn() external onlyOwner {
        harvest();
        earn();
    }

    /**
     * @dev Collect SWRV tokens minted by staking at gauge
     */
    function collectSWRV() external onlyOwner {
        swerveMinter.mint(address(swerveGauge));
        uint256 swrvBalance = swrvToken.balanceOf(address(this));
        swrvToken.safeTransfer(_msgSender(), swrvBalance);
        lastHarvest = block.timestamp;
    }

    /**
     * @dev Remove liquidity from swerve
     * @param swusdAmount amount of swerve pool tokens
     */
    function pull(uint256 swusdAmount) external onlyOwner {
        _removeLiquidityFromSwerve(swusdAmount);
    }

    /**
     * @dev Removes tokens from this Vault that are not the type of token managed
     * by this Vault. This may be used in case of accidentally sending the
     * wrong kind of token to this Vault.
     *
     * Tokens will be sent to `governance`.
     *
     * This will fail if an attempt is made to sweep the tokens that this Vault manages.
     *
     * This may only be called by governance.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyOwner {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), balance);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
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
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISwerveMinter} from "./ISwerveMinter.sol";

interface ISwerveGauge {
    function balanceOf(address depositor) external view returns (uint256);

    function minter() external view returns (ISwerveMinter);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwerveMinter {
    function mint(address gauge) external;

    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISwerve} from "./ISwerve.sol";

interface ISwervePool {
    /**
     * @dev Wrap underlying coins and deposit them in the pool
     * @param uamounts List of amounts of underlying coins to deposit
     * @param min_mint_amount Minimum amount of LP token to mint from the deposit
     */
    function add_liquidity(
        uint256[4] calldata uamounts,
        uint256 min_mint_amount
    ) external;

    /**
     * @dev Withdraw and unwrap a single coin from the pool
     * @param _token_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @param min_uamount Minimum amount of underlying coin to receive
     */
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    /**
     * @dev Calculate the amount received when withdrawing a single underlying coin
     * @param _token_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @return the amount of coin i received
     */
    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    /**
     * @dev LP token of the associated pool
     */
    function token() external view returns (address);

    function curve() external view returns (ISwerve);

    /**
     * @dev Underlying coins within the associated pool
     */
    function underlying_coins(int128 id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwerve {
    /**
     * @dev Estimate the amount of LP tokens minted or burned based on a deposit or withdrawal
     * It should be used as a basis for determining expected amounts when calling
     * add_liquidity or remove_liquidity_imbalance, but should not be considered to be precise
     * @param amounts Amount of each coin being deposited. Amounts correspond to the tokens
     * at the same index locations within coins
     * @param deposit set True for deposits, False for withdrawals
     * @return the expected amount of LP tokens minted or burned
     */
    function calc_token_amount(
        uint256[4] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    /**
     * @dev The current price of the pool LP token relative to the underlying pool assets
     * Given as an integer with 1e18 precision
     */
    function get_virtual_price() external view returns (uint256);
}

