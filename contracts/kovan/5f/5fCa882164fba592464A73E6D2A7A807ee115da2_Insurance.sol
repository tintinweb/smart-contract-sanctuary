// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint8 public constant DEFAULT_DECIMALS = 18; // GToken and Controller use this decimals
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR = uint256(10)**CURVE_RATIO_DECIMALS;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/vaults/yearnv2/v032/IYearnV2Vault.sol";
import "../common/Controllable.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IController.sol";
import "../common/Constants.sol";
import "../interfaces/IERC20Detailed.sol";
import "../common/Whitelist.sol";

/// @notice Base contract for gro protocol vault adaptors - Vault adaptors act as a
///     layer between the protocol and any yield aggregator vault. They provides additional
///     functionality needed by the protocol, and allow the protocol to be agnostic
///     to the type of underlying vault it interacts with.
///
///     ###############################################
///     Base Vault Adaptor specifications
///     ###############################################
///
///     Any deposit/withdrawal into the system will always attempt to interact with the
///     appropriate vault adaptor (depending on token).
///     - Deposit: A deposit will move assets into the vault adaptor, which will be
///         available for investment into the underlying vault once a large enough amount
///         of assets has amassed in the vault adaptor.
///     - Withdrawal: A withdrawal will always attempt to pull from the vaultAdaptor if possible,
///         if the assets in the adaptor fail to cover the withdrawal, the adaptor will
///         attempt to withdraw assets from the underlying vaults strategies. The latter will
///         also depend on whether pwrd or gvt is being withdrawn, as strategy assets affect
///         system exposure levels.
///     - Invest: Once a significant amount of assets have amassed in the vault adaptor, the
///         invest trigger will signal that the adaptor is ready to invest assets. The adaptor
///         always aims to hold a percent of total assets as univested assets (vaultReserve).
///         This allows for smaller withdrawals to be cheaper as they dont have to interact with
///         the underlying strategies.
///     - Debt ratios: Ratio in %BP of assets to invest in the underlying strategies of a vault
abstract contract BaseVaultAdaptor is Controllable, Constants, Whitelist, IVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant MAX_STRATS = 20;

    // Underlying token
    address public immutable override token;
    uint256 public immutable decimals;
    // Underlying vault
    address public immutable override vault;
    // Number of strategies
    uint256 public strategiesLength;
    // Used to determine if its OK to invest assets to underlying vault
    uint256 public investThreshold;
    // Used to establish if the strategy debt ratios need to be updated
    uint256 public strategyRatioBuffer;
    // How much of total assets should be held in the vault adaptor (%BP)
    uint256 public vaultReserve;

    event LogAdaptorToken(address token);
    event LogAdaptorVault(address vault);
    event LogAdaptorReserve(uint256 reserve);
    event LogAdaptorStrategies(uint256 length);
    event LogNewAdaptorInvestThreshold(uint256 threshold);
    event LogNewAdaptorStrategyBuffer(uint256 buffer);
    event LogNewDebtRatios(uint256[] strategyRetios);
    event LogMigrate(address parent, address child, uint256 amount);

    /// @notice Only the underlying vault is allowed to call
    modifier onlyVault() {
        require(msg.sender == vault);
        _;
    }

    constructor(address _vault, address _token) public {
        vault = _vault;
        token = _token;
        decimals = IERC20Detailed(_token).decimals();
        IERC20(_token).safeApprove(address(_vault), 0);
        IERC20(_token).safeApprove(address(_vault), type(uint256).max);
    }

    function setVaultReserve(uint256 reserve) external onlyOwner {
        require(reserve <= PERCENTAGE_DECIMAL_FACTOR);
        vaultReserve = reserve;
        emit LogAdaptorReserve(reserve);
    }

    function setStrategiesLength(uint256 _strategiesLength) external onlyOwner {
        strategiesLength = _strategiesLength;
        emit LogAdaptorStrategies(_strategiesLength);
    }

    function setInvestThreshold(uint256 _investThreshold) external onlyOwner {
        investThreshold = _investThreshold;
        emit LogNewAdaptorInvestThreshold(_investThreshold);
    }

    function setStrategyRatioBuffer(uint256 _strategyRatioBuffer) external onlyOwner {
        strategyRatioBuffer = _strategyRatioBuffer;
        emit LogNewAdaptorStrategyBuffer(_strategyRatioBuffer);
    }

    /// @notice Determine if assets should be moved from the vault adaptors into the underlying vault
    function investTrigger() external view override returns (bool) {
        uint256 vaultHold = _totalAssets().mul(vaultReserve).div(PERCENTAGE_DECIMAL_FACTOR);
        uint256 _investThreshold = investThreshold.mul(uint256(10)**decimals);
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance < _investThreshold) {
            return false;
        } else if (balance.sub(_investThreshold) > vaultHold) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice Move assets from vault adaptor into the underlying vault
    function invest() external override onlyWhitelist {
        uint256 vaultHold = _totalAssets().mul(vaultReserve).div(PERCENTAGE_DECIMAL_FACTOR);
        uint256 _investThreshold = investThreshold.mul(uint256(10)**decimals);
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance <= vaultHold) return;

        if (balance.sub(vaultHold) > _investThreshold) {
            depositToUnderlyingVault(balance.sub(vaultHold));
        }

        // Check and update strategies debt ratio
        if (strategiesLength > 1) {
            // Only for stablecoin vaults
            uint256[] memory targetRatios = _controller().getStrategiesTargetRatio();
            uint256[] memory currentRatios = getStrategiesDebtRatio();
            bool update;
            for (uint256 i; i < strategiesLength; i++) {
                if (currentRatios[i] < targetRatios[i] && targetRatios[i].sub(currentRatios[i]) > strategyRatioBuffer) {
                    update = true;
                    break;
                }

                if (currentRatios[i] > targetRatios[i] && currentRatios[i].sub(targetRatios[i]) > strategyRatioBuffer) {
                    update = true;
                    break;
                }
            }
            if (update) {
                updateStrategiesDebtRatio(targetRatios);
            }
        }
    }

    /// @notice Calculate system total assets
    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    /// @notice Get number of strategies in underlying vault
    function getStrategiesLength() external view override returns (uint256) {
        return strategiesLength;
    }

    /// @notice Withdraw assets from underlying vault
    /// @param amount Amount to withdraw
    /// @dev Sends assets to msg.sender
    function withdraw(uint256 amount) external override {
        require(msg.sender == _controller().lifeGuard(), "withdraw: !lifeguard");
        if (!_withdrawFromAdapter(amount, msg.sender)) {
            amount = _withdraw(calculateShare(amount), msg.sender);
        }
    }

    /// @notice Withdraw assets from underlying vault
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    /// @dev Will try to pull assets from adaptor before moving on to pull
    ///     assets from unerlying vault/strategies
    function withdraw(uint256 amount, address recipient) external override {
        require(msg.sender == _controller().insurance(), "withdraw: !insurance");
        if (!_withdrawFromAdapter(amount, recipient)) {
            amount = _withdraw(calculateShare(amount), recipient);
        }
    }

    /// @notice Withdraw assets from vault to vault adaptor
    /// @param amount Amount to withdraw
    function withdrawToAdapter(uint256 amount) external onlyOwner {
        amount = _withdraw(calculateShare(amount), address(this));
    }

    /// @notice Withdraw assets from underlying vault, but do so in a specific strategy order
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    /// @param reversed reverse strategy order
    /// @dev This is an addaptation for yearn v2 vaults - these vaults have a defined withdraw
    ///     order. Gro protocol needs to respect prtocol exposure, and thus might have to withdraw
    ///     from different strategies depending on if pwrd or gvts are withdrawn.
    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external override {
        IController ctrl = _controller();
        require(
            msg.sender == ctrl.withdrawHandler() ||
                msg.sender == ctrl.insurance() ||
                msg.sender == ctrl.emergencyHandler(),
            "withdraw: !withdrawHandler/insurance"
        );
        if (!_withdrawFromAdapter(amount, recipient)) {
            amount = _withdrawByStrategyOrder(calculateShare(amount), recipient, reversed);
        }
    }

    /// @notice Withdraw assets from underlying vault, but do so from a specific strategy
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    /// @param strategyIndex Index of target strategy
    /// @dev Same as for withdrawByStrategyOrder, but now we withdraw from a specific strategy.
    ///     This functionality exists to be able to move assets from overExposed strategies.
    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external override {
        require(msg.sender == _controller().insurance(), "withdraw: !withdrawHandler/insurance");
        if (!_withdrawFromAdapter(amount, recipient)) {
            amount = _withdrawByStrategyIndex(calculateShare(amount), recipient, strategyIndex);
        }
    }

    /// @notice Withdraw assets from the vault adaptor itself
    /// @param amount Amount to withdraw
    /// @param recipient Target recipient
    function _withdrawFromAdapter(uint256 amount, address recipient) private returns (bool _success) {
        uint256 adapterAmount = IERC20(token).balanceOf(address(this));
        if (adapterAmount >= amount) {
            IERC20(token).safeTransfer(recipient, amount);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Get total amount invested in strategy
    /// @param index Index of strategy
    function getStrategyAssets(uint256 index) external view override returns (uint256 amount) {
        return getStrategyTotalAssets(index);
    }

    /// @notice Deposit assets into the vault adaptor
    /// @param amount Deposit amount
    function deposit(uint256 amount) external override {
        require(msg.sender == _controller().lifeGuard(), "withdraw: !lifeguard");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Set new strategy debt ratios
    /// @param strategyRatios Array of new debt ratios
    function updateStrategyRatio(uint256[] calldata strategyRatios) external override {
        require(
            msg.sender == _controller().insurance() || msg.sender == owner(),
            "!updateStrategyRatio: !owner/insurance"
        );
        updateStrategiesDebtRatio(strategyRatios);
        emit LogNewDebtRatios(strategyRatios);
    }

    /// @notice Check if underlying strategy needs to be harvested
    /// @param index Index of stratey
    /// @param callCost Cost of harvest
    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view override returns (bool harvested) {
        require(index < strategiesLength, "invalid index");
        return _strategyHarvestTrigger(index, callCost);
    }

    /// @notice Harvest underlying strategy
    /// @param index Index of strategy
    function strategyHarvest(uint256 index) external override onlyWhitelist returns (bool harvested) {
        require(index < strategiesLength, "invalid index");
        uint256 beforeAssets = vaultTotalAssets();
        _strategyHarvest(index);
        uint256 afterAssets = vaultTotalAssets();
        if (afterAssets > beforeAssets) {
            _controller().distributeStrategyGainLoss(afterAssets.sub(beforeAssets), 0);
        } else if (afterAssets < beforeAssets) {
            _controller().distributeStrategyGainLoss(0, beforeAssets.sub(afterAssets));
        }
        harvested = true;
    }

    /// @notice Migrate assets to new vault
    /// @param child target for migration
    function migrate(address child) external onlyOwner {
        require(child != address(0), "migrate: child == 0x");
        IERC20 _token = IERC20(token);
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(child, balance);
        emit LogMigrate(address(this), child, balance);
    }

    // Virtual functions
    function _strategyHarvest(uint256 index) internal virtual;

    function updateStrategiesDebtRatio(uint256[] memory ratios) internal virtual;

    function getStrategiesDebtRatio() internal view virtual returns (uint256[] memory);

    /// @notice Deposit from vault adaptors to underlying vaults
    function depositToUnderlyingVault(uint256 amount) internal virtual;

    function _withdraw(uint256 share, address recipient) internal virtual returns (uint256);

    function _withdrawByStrategyOrder(
        uint256 share,
        address recipient,
        bool reversed
    ) internal virtual returns (uint256);

    function _withdrawByStrategyIndex(
        uint256 share,
        address recipient,
        uint256 index
    ) internal virtual returns (uint256);

    function _strategyHarvestTrigger(uint256 index, uint256 callCost) internal view virtual returns (bool);

    function getStrategyEstimatedTotalAssets(uint256 index) internal view virtual returns (uint256);

    function getStrategyTotalAssets(uint256 index) internal view virtual returns (uint256);

    function vaultTotalAssets() internal view virtual returns (uint256);

    function _totalAssets() internal view returns (uint256) {
        uint256 total = IERC20(token).balanceOf(address(this)).add(vaultTotalAssets());
        return total;
    }

    function calculateShare(uint256 amount) private view returns (uint256 share) {
        uint256 sharePrice = _getVaultSharePrice();
        share = amount.mul(uint256(10)**decimals).div(sharePrice);
        uint256 balance = IERC20(vault).balanceOf(address(this));
        share = share < balance ? share : balance;
    }

    /// @notice Calculate system total assets including estimated profits
    function totalEstimatedAssets() external view returns (uint256) {
        uint256 total = IERC20(token).balanceOf(address(this)).add(IERC20(token).balanceOf(address(vault)));
        for (uint256 i = 0; i < strategiesLength; i++) {
            total = total.add(getStrategyEstimatedTotalAssets(i));
        }
        return total;
    }

    function _getVaultSharePrice() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
     * - `to` cannot be the zero address.
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IYearnV2Vault {
    function strategies(address _strategy) external view returns (StrategyParams memory);

    function totalAssets() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256 _amount, address _recipient) external;

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function withdrawByStrategy(
        address[20] calldata _strategies,
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function depositLimit() external view returns (uint256);

    function debtOutstanding(address strategy) external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function updateStrategyDebtRatio(address strategy, uint256 ratio) external;

    function withdrawalQueue(uint256 index) external view returns (address);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IController.sol";
import "../interfaces/IPausable.sol";

contract Controllable is Ownable {
    address public controller;

    event ChangeController(address indexed oldController, address indexed newController);

    /// Modifier to make a function callable only when the contract is not paused.
    /// Requirements:
    /// - The contract must not be paused.
    modifier whenNotPaused() {
        require(!_pausable().paused(), "Pausable: paused");
        _;
    }

    /// Modifier to make a function callable only when the contract is paused
    /// Requirements:
    /// - The contract must be paused
    modifier whenPaused() {
        require(_pausable().paused(), "Pausable: not paused");
        _;
    }

    /// @notice Returns true if the contract is paused, and false otherwise
    function ctrlPaused() public view returns (bool) {
        return _pausable().paused();
    }

    function setController(address newController) external onlyOwner {
        require(newController != address(0), "setController: !0x");
        address oldController = controller;
        controller = newController;
        emit ChangeController(oldController, newController);
    }

    function _controller() internal view returns (IController) {
        require(controller != address(0), "Controller not set");
        return IController(controller);
    }

    function _pausable() internal view returns (IPausable) {
        require(controller != address(0), "Controller not set");
        return IPausable(controller);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IVault {
    function withdraw(uint256 amount) external;

    function withdraw(uint256 amount, address recipient) external;

    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external;

    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external;

    function deposit(uint256 amount) external;

    function updateStrategyRatio(uint256[] calldata strategyRetios) external;

    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);

    function vault() external view returns (address);

    function investTrigger() external view returns (bool);

    function invest() external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IController {
    function stablecoins() external view returns (address[3] memory);

    function vaults() external view returns (address[3] memory);

    function underlyingVaults(uint256 i) external view returns (address vault);

    function curveVault() external view returns (address);

    function pnl() external view returns (address);

    function insurance() external view returns (address);

    function lifeGuard() external view returns (address);

    function buoy() external view returns (address);

    function reward() external view returns (address);

    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function emergencyHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);

    function emergencyState() external view returns (bool);

    function deadCoin() external view returns (uint256);

    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external;

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external;

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external;

    function getUserAssets(bool pwrd, address account) external view returns (uint256 deductUsd);

    function referrals(address account) external view returns (address);

    function addReferral(address account, address referral) external;

    function getStrategiesTargetRatio() external view returns (uint256[] memory);

    function withdrawalFee(bool pwrd) external view returns (uint256);

    function validGTokenDecrease(uint256 amount) external view returns (bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event LogAddToWhitelist(address indexed user);
    event LogRemoveFromWhitelist(address indexed user);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "only whitelist");
        _;
    }

    function addToWhitelist(address user) external onlyOwner {
        require(user != address(0), "WhiteList: 0x");
        whitelist[user] = true;
        emit LogAddToWhitelist(user);
    }

    function removeFromWhitelist(address user) external onlyOwner {
        require(user != address(0), "WhiteList: 0x");
        whitelist[user] = false;
        emit LogRemoveFromWhitelist(user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IPausable {
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./IYearnV2Strategy.sol";
import "../../BaseVaultAdaptor.sol";

/// @notice YearnV2Vault adaptor - Implementation of the gro protocol vault adaptor used to
///     interact with Yearn v2 vaults. Gro protocol uses a modified version of the yearnV2Vault
///     to accomodate for additional functionality (see Vault.vy):
///         - Adaptor modifier:
///             Withdraw/Deposit methods can only be accessed by the vaultAdaptor
///         - Withdraw by StrategyOrder/Index:
///             In order to be able to ensure that protocol exposures are within given thresholds
///             inside the vault, the vault can now withdraw from the vault (underlying strategies)
///             by a specific strategy or order of strategies. The orginal yearnV2Vault has a set
///             withdrawalQueue.
///         - The vault adaptor now acts as the first withdraw layer. This means that the adaptor,
///             will always try to maintain a set amount of loose assets to make withdrawals cheaper.
///             The underlying yearn vault on the other hand will always have a total debt ratio of
///             100%, meaning that it will atempt to always have all its assets invested in the
///             underlying strategies.
///         - Asset availability:
///             - VaultAdaptor:
///                 - vaultReserve (%BP - see BaseVaultAdaptor)
///             - Vault:
///                 - target debt ratio => 100% (10000)
///                 - loose assets cannot be guranteed
///                     - after a vaultAdaptor invest action assets will be available
///                     - after each strategy has called harvest no assets should be available
contract VaultAdaptorYearnV2_032 is BaseVaultAdaptor {
    constructor(address _vault, address _token) public BaseVaultAdaptor(_vault, _token) {}

    /// @notice Withdraw from vault adaptor, if withdrawal amount exceeds adaptors
    ///     total available assets, withdraw from underlying vault, using a specific
    ///     strategy order for withdrawal -> the withdrawal order dictates which strategy
    ///     to withdraw from first, if this strategies assets are exhausted before the
    ///     withdraw amount has been covered, the ramainder will be withdrawn from the next
    ///     strategy in the list.
    /// @param share Number of shares to withdraw (yVault shares)
    /// @param recipient Recipient of withdrawal
    /// @param pwrd Pwrd or gvt
    function _withdrawByStrategyOrder(
        uint256 share,
        address recipient,
        bool pwrd
    ) internal override returns (uint256) {
        if (pwrd) {
            address[MAX_STRATS] memory _strategies;
            for (uint256 i = strategiesLength; i > 0; i--) {
                _strategies[i - 1] = IYearnV2Vault(vault).withdrawalQueue((strategiesLength - i));
            }
            return IYearnV2Vault(vault).withdrawByStrategy(_strategies, share, recipient, 1);
        } else {
            return _withdraw(share, recipient);
        }
    }

    /// @notice Withdraw from vault adaptor, if withdrawal amount exceeds adaptors,
    ///     withdraw from a specific strategy
    /// @param share Number of shares to withdraw (yVault shares)
    /// @param recipient Recipient of withdrawal
    /// @param index Index of strategy
    function _withdrawByStrategyIndex(
        uint256 share,
        address recipient,
        uint256 index
    ) internal override returns (uint256) {
        if (index != 0) {
            address[MAX_STRATS] memory _strategies;
            uint256 strategyIndex = 0;
            _strategies[strategyIndex] = IYearnV2Vault(vault).withdrawalQueue(index);
            for (uint256 i = 0; i < strategiesLength; i++) {
                if (i == index) {
                    continue;
                }
                strategyIndex++;
                _strategies[strategyIndex] = IYearnV2Vault(vault).withdrawalQueue(i);
            }
            return IYearnV2Vault(vault).withdrawByStrategy(_strategies, share, recipient, 0);
        } else {
            return _withdraw(share, recipient);
        }
    }

    /// @notice Deposit from vault adaptors to underlying vaults
    /// @param _amount Amount to deposit
    function depositToUnderlyingVault(uint256 _amount) internal override {
        if (_amount > 0) {
            IYearnV2Vault(vault).deposit(_amount, address(this));
        }
    }

    function _strategyHarvest(uint256 index) internal override {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        IYearnV2Strategy(yearnVault.withdrawalQueue(index)).harvest();
    }

    /// @notice Set debt ratio of underlying strategies to 0
    function resetStrategyDeltaRatio() private {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        for (uint256 i = 0; i < strategiesLength; i++) {
            yearnVault.updateStrategyDebtRatio(yearnVault.withdrawalQueue(i), 0);
        }
    }

    function updateStrategiesDebtRatio(uint256[] memory ratios) internal override {
        uint256 ratioTotal = 0;
        for (uint256 i = 0; i < ratios.length; i++) {
            ratioTotal = ratioTotal.add(ratios[i]);
        }
        require(ratioTotal <= 10**4, "The total of ratios is more than 10000");

        resetStrategyDeltaRatio();

        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        for (uint256 i = 0; i < ratios.length; i++) {
            yearnVault.updateStrategyDebtRatio(yearnVault.withdrawalQueue(i), ratios[i]);
        }
    }

    /// @notice Return debt ratio of underlying strategies
    function getStrategiesDebtRatio() internal view override returns (uint256[] memory ratios) {
        ratios = new uint256[](strategiesLength);
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        StrategyParams memory strategyParam;
        for (uint256 i; i < strategiesLength; i++) {
            strategyParam = yearnVault.strategies(yearnVault.withdrawalQueue(i));
            ratios[i] = strategyParam.debtRatio;
        }
    }

    function _strategyHarvestTrigger(uint256 index, uint256 callCost) internal view override returns (bool) {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        return IYearnV2Strategy(yearnVault.withdrawalQueue(index)).harvestTrigger(callCost);
    }

    function getStrategyEstimatedTotalAssets(uint256 index) internal view override returns (uint256) {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        return IYearnV2Strategy(yearnVault.withdrawalQueue(index)).estimatedTotalAssets();
    }

    function getStrategyTotalAssets(uint256 index) internal view override returns (uint256) {
        IYearnV2Vault yearnVault = IYearnV2Vault(vault);
        StrategyParams memory strategyParam = yearnVault.strategies(yearnVault.withdrawalQueue(index));
        return strategyParam.totalDebt;
    }

    function _withdraw(uint256 share, address recipient) internal override returns (uint256 withdrawalAmount) {
        (, , withdrawalAmount, ) = IYearnV2Vault(vault).withdraw(share, recipient, 1);
    }

    function vaultTotalAssets() internal view override returns (uint256) {
        return IYearnV2Vault(vault).totalAssets();
    }

    function _getVaultSharePrice() internal view override returns (uint256) {
        return IYearnV2Vault(vault).pricePerShare();
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IYearnV2Strategy {
    function vault() external view returns (address);

    function setVault(address _vault) external;

    function keeper() external view returns (address);

    function setKeeper(address _keeper) external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function withdraw(uint256 _amount) external;

    function estimatedTotalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../vaults/yearnv2/v032/IYearnV2Vault.sol";
import "../vaults/yearnv2/v032/IYearnV2Strategy.sol";
import "../interfaces/IERC20Detailed.sol";

contract MockYearnV2Vault is ERC20, IYearnV2Vault {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public override depositLimit;
    uint256 public override totalDebt;

    uint256 public total;
    uint256 public airlock;
    mapping(address => uint256) public strategiesDebtLimit;
    mapping(address => uint256) public strategiesTotalDebt;
    mapping(address => uint256) public strategiesDebtRatio;

    address public depositRecipient;
    address public withdrawRecipient;
    address[] public override withdrawalQueue;

    uint256 public amount;

    uint256[] public debtRatios;

    constructor(address _token) public ERC20("Vault", "Vault") {
        _setupDecimals(18);
        token = IERC20(_token);
    }

    function approveStrategies(address[] calldata strategyArray) external {
        for (uint256 i = 0; i < strategyArray.length; i++) {
            token.approve(strategyArray[i], type(uint256).max);
        }
    }

    function setStrategies(address[] calldata _strategies) external {
        for (uint256 i = 0; i < _strategies.length; i++) {
            require(_strategies[i] != address(0), "Invalid strategy address.");
        }
        withdrawalQueue = _strategies;
    }

    function setStrategyDebtRatio(address strategy, uint256 debtRatio) external {
        strategiesDebtRatio[strategy] = debtRatio;
    }

    function getStrategiesDebtRatio() external view returns (uint256[] memory ratios) {
        ratios = new uint256[](withdrawalQueue.length);
        for (uint256 i = 0; i < withdrawalQueue.length; i++) {
            ratios[i] = strategiesDebtRatio[withdrawalQueue[i]];
        }
    }

    function strategies(address _strategy) external view override returns (StrategyParams memory result) {
        result.debtRatio = strategiesDebtRatio[_strategy];
    }

    function setTotalAssets(uint256 _total) external {
        total = _total;
    }

    function totalAssets() public view override returns (uint256) {
        uint256 val = token.balanceOf(address(this));
        for (uint256 i = 0; i < withdrawalQueue.length; i++) {
            val = val.add(token.balanceOf(withdrawalQueue[i]));
        }
        return val;
    }

    function setAirlock(uint256 _airlock) external {
        airlock = _airlock;
    }

    function setTotalDebt(uint256 _totalDebt) public {
        totalDebt = _totalDebt;
    }

    function deposit(uint256 _amount, address _recipient) external override {
        totalDebt = totalDebt.add(_amount);
        total = total.add(_amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        // uint256 available = _amount;
        // if (airlock < _amount) {
        //      available = airlock;
        // }
        // airlock = airlock.sub(available);
        // total = total.add(available);
        depositRecipient = _recipient;
    }

    function withdrawByStrategy(
        address[20] calldata _strategies,
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external override returns (uint256) {}

    function withdraw(
        uint256 maxShares,
        address _recipient,
        uint256 maxLoss
    )
        external
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        maxLoss;
        uint256 _total = token.balanceOf(address(this));
        uint256 _amount = maxShares;
        if (_total < _amount) {
            //     available = total;
            for (uint256 i = 0; i < withdrawalQueue.length; i++) {
                address strategy = withdrawalQueue[i];
                uint256 stratDebt = strategiesDebtLimit[strategy];
                if (stratDebt > 0) {
                    strategiesDebtLimit[strategy] = 0;
                    IYearnV2Strategy(strategy).withdraw(stratDebt);
                    totalDebt = totalDebt.sub(stratDebt);
                }
            }
        }
        token.safeTransfer(_recipient, _amount);
        withdrawRecipient = _recipient;
    }

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external override returns (uint256) {
        _gain;
        _loss;
        _debtPayment;
        address strategy = msg.sender;
        uint256 sBalance = token.balanceOf(strategy);
        if (sBalance > strategiesDebtLimit[strategy]) {
            uint256 outAmount = sBalance.sub(strategiesDebtLimit[strategy]);
            token.safeTransferFrom(strategy, address(this), outAmount);
        } else {
            uint256 inAmount = strategiesDebtLimit[strategy].sub(sBalance);
            token.safeTransfer(
                strategy,
                inAmount > token.balanceOf(address(this)) ? token.balanceOf(address(this)) : inAmount
            );
        }
    }

    function updateStrategyDebtRatio(address strategy, uint256 debtRatio) external override {
        strategiesDebtRatio[strategy] = debtRatio;
    }

    function debtOutstanding(address) external view override returns (uint256) {
        return 0;
    }

    function setStrategyTotalDebt(address _strategy, uint256 _totalDebt) external {
        strategiesTotalDebt[_strategy] = _totalDebt;
    }

    function pricePerShare() external view override returns (uint256) {
        if (this.totalAssets() == 0) {
            return uint256(10)**IERC20Detailed(address(token)).decimals();
        } else {
            return this.totalAssets().mul(IERC20Detailed(address(token)).decimals()).div(this.totalSupply());
        }
    }

    function getStrategyDebtLimit(address strategy) external view returns (uint256) {
        return strategiesDebtLimit[strategy];
    }

    function getStrategyTotalDebt(address strategy) external view returns (uint256) {
        return strategiesTotalDebt[strategy];
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "contracts/interfaces/IVault.sol";
import "contracts/common/Whitelist.sol";
import {ICurveMetaPool} from "contracts/interfaces/ICurve.sol";
import "contracts/interfaces/IERC20Detailed.sol";
import "../BaseStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @notice Yearn V2 vault interface
interface V2YVault {
    function deposit(uint256 _amount) external;

    function deposit() external;

    function withdraw(uint256 maxShares) external;

    function withdraw() external;

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function pricePerShare() external view returns (uint256);

    function token() external view returns (address);
}

library Math {
    /// @notice Returns the largest of two numbers
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /// @notice Returns the smallest of two numbers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Returns the average of two numbers. The result is rounded towards zero.
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

/// @notice Yearn curve Metapool strategy
///     Deposit stablecoins into Curve metapool - deposit received metapool tokens
///     to Yearn vault. Harvest only repays debts and pull available credit from vault.
///     This strategy can migrate between metapools and yearn vaults, and requires that
///     a new metapool and yearn vault get set and tend run. Theres a 0.5% withdrawal fee on this strategy,
///     this means that there should be a 0.5% buffer on assets before migrating in order,
///     for this strategy not to generate any loss.
///     ########################################
///     Strategy breakdown
///     ########################################
///
///     Want: 3Crv
///     Additional tokens: MetaPoolLP token (Curve), YMetaPoolVault token (yearn)
///     Exposures:
///         Protocol: Curve, Yearn, +1 stablecoin from metapool
///         stablecoins: DAI, USDC, USDT +1 stablecoin from metapool
///     Debt ratio set to 100% - should be only strategy in curveVault
///
///     Strategy logic:
///         Vault => Loan out 3Crv into strategy
///             strategy => invest 3Crv into target Curve meta pool
///                      <= get metapool tokens (MLP) in return
///             strategy => invest MLP into yearn YMetaPoolVault
///                      <= get Yshares in return
///
///         Harvest: Report back gains/losses to vault:
///                     - do not withdraw any assets from Yearn/metapool
///                     - do pull and invest any new 3crv available in vault
///
///         Migrate metapool: Move assets from one metapool to another:
///                     - Set new target metapool/Yearn vault
///                     - Ensure that current gains cover withdrawal fee (Yearn)
///                     - Strategy withdraw assetse down to 3Crv tokens and
///                         redeploys into new metapool/yearn vault
///
///         Tend: Withdraw available assets from yearn without getting hit by a fee
///                 Used to redistribute 3Crv tokens into stablecoins
///                 - see lifeguards, distributeCurveVault function
contract StableYearnXPool is BaseStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lpToken; // Meta lp token (MLP)
    // Default Curve metapool
    address public curve = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // Default yearn vault
    V2YVault public yVault = V2YVault(address(0x84E13785B5a27879921D6F685f041421C7F482dA));
    // Index of 3crv token in metapool
    int128 wantIndex = 1;
    // Number of tokens in metapool (+1 Stablecoin, 3Crv)
    uint256 constant metaPool = 2;
    uint256 public decimals = 18;
    uint256 difference;

    // Curve meta pool to migrate to
    address public prepCurve;
    // Yearn vault to migrate to
    address public prepYVault;
    bool public tendLock;

    event LogNewMigration(address indexed yVault, address indexed curve, address lpToken);
    event LogNewMigrationPreperation(address indexed yVault, address indexed curve);
    event LogForceMigration(bool status);
    event LogMigrationCost(int256 cost);

    constructor(address _vault) public BaseStrategy(_vault) {
        profitFactor = 1000;
        debtThreshold = 1_000_000 * 1e18;
        tendLock = true;
        require(
            keccak256(bytes(apiVersion())) == keccak256(bytes(VaultAPI(_vault).apiVersion())),
            "WRONG VERSION"
        );
    }

    /// @notice Set migration targets
    /// @param _yVault Target Yearn vault
    /// @param _curve Target Curve meta pool
    function setMetaPool(address _yVault, address _curve) external onlyOwner {
        prepYVault = _yVault;
        prepCurve = _curve;
        emit LogNewMigrationPreperation(_yVault, _curve);
    }

    function name() external view override returns (string memory) {
        return "StrategyCurveXPool";
    }

    /// @notice Force the pool to migrate, allows to trigger tend no matter the circumstances
    ///     - Warning this will very likely result in a loss of assets as yearn v1 vaults have
    ///         a 50 BP withdrawal fee on anything above the assets available in the vault
    function forceTend() external onlyOwner {
        tendLock = true;
        emit LogForceMigration(true);
    }

    function resetDifference() external onlyOwner {
        difference = 0;
    }

    /// @notice Get the total assets of this strategy.
    ///     This method is only used to pull out debt if debt ratio has changed.
    /// @return Total assets in want this strategy has invested into underlying vault
    function estimatedTotalAssets() public view override returns (uint256) {
        return _estimatedTotalAssets(true);
    }

    /// @notice Expected returns from strategy (gains from pool swaps)
    function expectedReturn() public view returns (uint256) {
        return _expectedReturn();
    }

    function _expectedReturn() private view returns (uint256) {
        uint256 estimateAssets = _estimatedTotalAssets(true);
        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets - debt;
        }
    }

    /// @notice This strategy doesn't realize profit outside of APY from the vault.
    ///     This method is only used to pull out debt if debt ratio has changed.
    /// @param _debtOutstanding Debt to pay back
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _debtPayment = _debtOutstanding;
        uint256 lentAssets =
            convertToUnderlying(yVault.balanceOf(address(this)), decimals, wantIndex);
        uint256 looseAssets = want.balanceOf(address(this));
        uint256 total = looseAssets.add(lentAssets);

        if (lentAssets == 0) {
            // No position to harvest or profit to report
            if (_debtPayment > looseAssets) {
                // We can only return looseAssets
                _debtPayment = looseAssets;
            }

            return (_profit, _loss, _debtPayment);
        }

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if (total > debt) {
            _profit = total - debt;
            uint256 amountToFree = _profit.add(_debtPayment);
            if (amountToFree > 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));

                // If we don't have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _profit, _debtPayment);
                    }
                }
            }
        } else {
            // Serious issue - A loss should never happen but if it does lets record it accurately
            _loss = debt - total;
            uint256 amountToFree = _debtPayment;

            if (amountToFree > 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw

                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));

                if (newLoose < amountToFree) {
                    _debtPayment = newLoose;
                }
            }
        }
    }

    /// @notice Withdraw amount from yVault/pool
    /// @param _amount Expected amount to withdraw
    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 amountInYtokens = convertFromUnderlying(_amount, decimals, wantIndex);
        uint256 yBalance = yVault.balanceOf(address(this));

        uint256 balanceBefore = want.balanceOf(address(this));

        if (amountInYtokens == 0) {
            return 0;
        }

        if (amountInYtokens > yBalance) {
            // Can't withdraw more than we own
            amountInYtokens = yBalance;
        }

        ICurveMetaPool _curve = ICurveMetaPool(curve);

        uint256 lpBalance = amountInYtokens.mul(yVault.pricePerShare()).div(uint256(10)**decimals);
        uint256 tokenAmonut = _curve.calc_withdraw_one_coin(lpBalance, wantIndex);
        uint256 minAmount = tokenAmonut.sub(tokenAmonut.mul(9995).div(10000));

        yVault.withdraw(amountInYtokens);
        _curve.remove_liquidity_one_coin(
            amountInYtokens,
            wantIndex,
            minAmount
        );
        uint256 newBalance = want.balanceOf(address(this));

        return newBalance.sub(balanceBefore);
    }

    /// @notice Used when emergency stop has been called to empty out strategy
    /// @param _amountNeeded Expected amount to withdraw
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        _loss; // We should not be able to make a loss here

        uint256 looseAssets = want.balanceOf(address(this));

        if (looseAssets < _amountNeeded) {
            _withdrawSome(_amountNeeded - looseAssets);
        }

        _liquidatedAmount = Math.min(_amountNeeded, want.balanceOf(address(this)));
    }

    /// @notice Used to invest any assets sent from the vault during report
    /// @param _debtOutstanding Should always be 0 at this point
    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (tendLock) {
            tendLock = false;
            migrate();
        }
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal > 0) {
            ICurveMetaPool _curve = ICurveMetaPool(curve);
            uint256[metaPool] memory tokenAmounts;
            tokenAmounts[uint256(wantIndex)] = _wantBal;

            uint256 minAmount = _curve.calc_token_amount(tokenAmounts, true);
            minAmount = minAmount.sub(minAmount.mul(9995).div(10000));

            _curve.add_liquidity(tokenAmounts, minAmount);
            uint256 lpBalance = lpToken.balanceOf(address(this));
            yVault.deposit(lpBalance);
        }
        uint256 debt = vault.strategies(address(this)).totalDebt;
        uint256 _estimate = _estimatedTotalAssets(false);
        if (debt > _estimate) {
            uint256 difference = debt.sub(_estimate);
        } else {
            uint256 difference = 0;
        }
    }

    function hardMigration() external onlyOwner() {
        prepareMigration(address(vault));
    }

    /// @notice Prepare for migration by transfering tokens
    function prepareMigration(address _newStrategy) internal override {
        yVault.withdraw();
        ICurveMetaPool _curve = ICurveMetaPool(curve); 

        uint256 lpBalance = lpToken.balanceOf(address(this));
        uint256 tokenAmonut = _curve.calc_withdraw_one_coin(lpBalance, wantIndex);
        uint256 minAmount = tokenAmonut.sub(tokenAmonut.mul(9995).div(10000));
        _curve.remove_liquidity_one_coin(
            lpToken.balanceOf(address(this)),
            wantIndex,
            minAmount
        );
        uint looseAssets = want.balanceOf(address(this));
        want.safeTransfer(_newStrategy, looseAssets);

    }

    /// @notice Tokens protected by strategy - want tokens are protected by default
    function protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](1);
        protected[1] = address(yVault);
        protected[2] = address(lpToken);
        return protected;
    }

    /// @notice Migrate to new metapool
    function migrate() private {
        uint256 initialBalance = _estimatedTotalAssets(false);
        if (yVault.balanceOf(address(this)) > 0) {
            migrateWant();
        }
        migrateYearn(prepYVault, prepCurve);
        uint256 finalBalance = _estimatedTotalAssets(false);
        emit LogNewMigration(prepYVault, prepCurve, address(lpToken));
        emit LogMigrationCost(int256(initialBalance - finalBalance));
        emit LogForceMigration(tendLock);
        prepCurve = address(0);
        prepYVault = address(0);
    }

    /// @notice Migrate Yearn vault
    /// @param _prepYVault Target Yvault
    /// @param _prepCurve Target Curve meta pool
    function migrateYearn(address _prepYVault, address _prepCurve) private {
        yVault = V2YVault(_prepYVault); // Set the yearn vault for this strategy
        curve = _prepCurve;
        lpToken = IERC20(yVault.token());
        if (lpToken.allowance(address(this), _prepYVault) == 0) {
            lpToken.safeApprove(_prepYVault, uint256(-1));
        }
        if (want.allowance(address(this), _prepCurve) == 0) {
            want.safeApprove(_prepCurve, uint256(-1));
        }
    }

    /// @notice Pull out any invested funds before migration
    function migrateWant() private returns (bool) {
        yVault.withdraw();
        ICurveMetaPool _curve = ICurveMetaPool(curve); 

        uint256 lpBalance = lpToken.balanceOf(address(this));
        uint256 tokenAmonut = _curve.calc_withdraw_one_coin(lpBalance, wantIndex);
        uint256 minAmount = tokenAmonut.sub(tokenAmonut.mul(9995).div(10000));

        _curve.remove_liquidity_one_coin(
            lpToken.balanceOf(address(this)),
            wantIndex,
            minAmount
        );
        return true;
    }

    /// @notice Estimated total assets of strategy
    /// @param diff Calc token amounts (curve) underreports total amount, to counteract this
    ///     we add initial difference from last harvest to estimated total assets,
    function _estimatedTotalAssets(bool diff) private view returns (uint256) {
        uint256 amount =
            yVault.balanceOf(address(this)).mul(yVault.pricePerShare()).div(uint256(10)**decimals);
        uint256 estimated;
        if (amount > 0) {
            estimated = ICurveMetaPool(curve).calc_withdraw_one_coin(amount, wantIndex);
        } else {
            estimated = want.balanceOf(address(this));
        }
        if (diff) {
            return estimated.add(difference);
        } else {
            return estimated;
        }
    }

    /// @notice Convert ytokens to want
    /// @param amountOfTokens Amount to convert
    function convertToUnderlying(
        uint256 amountOfTokens,
        uint256 _decimals,
        int128 index
    ) private view returns (uint256 balance) {
        if (amountOfTokens == 0) {
            balance = 0;
        } else {
            uint256 lpAmount =
                amountOfTokens.mul(yVault.pricePerShare()).div(uint256(10)**_decimals);
            balance = ICurveMetaPool(curve).calc_withdraw_one_coin(lpAmount, index);
        }
    }

    /// @notice Convert want to ytokens
    /// @param amountOfUnderlying Amount to convert
    function convertFromUnderlying(
        uint256 amountOfUnderlying,
        uint256 _decimals,
        int128 index
    ) private view returns (uint256 balance) {
        if (amountOfUnderlying == 0) {
            balance = 0;
        } else {
            uint256 lpAmount = wantToLp(amountOfUnderlying, index);
            balance = lpAmount.mul(uint256(10)**_decimals).div(yVault.pricePerShare());
        }
    }

    /// @notice Convert want token to LP meta pool token
    /// @param amount Amount to convert
    function wantToLp(uint256 amount, int128 index) private view returns (uint256) {
        uint256[metaPool] memory tokenAmounts;
        tokenAmounts[uint256(index)] = amount;

        return ICurveMetaPool(curve).calc_token_amount(tokenAmounts, true);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface ICurve3Pool {
    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata inAmounts, bool deposit) external view returns (uint256);

    function balances(int128 i) external view returns (uint256);
}

interface ICurve3Deposit {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function add_liquidity(uint256[3] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 amount, uint256[3] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface ICurveMetaPool {
    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] calldata inAmounts, bool deposit) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function add_liquidity(uint256[2] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;
}

interface ICurveZap {
    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 amount, uint256[4] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[4] calldata inAmounts, bool deposit) external view returns (uint256);

    function pool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */
abstract contract BaseStrategy is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public metadataURI;

    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy's version must match the Vault's `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.3.2";
    }

    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards Yearn's TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
     *  Locked (TVL) calculation across it's ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;
    uint256 public gasReward;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // The minimum multiple that `callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == governance(), "!authorized");
        _;
    }

    modifier onlyKeepers() {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }

    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, uint256(-1)); // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;

        vault.approve(rewards, uint256(-1)); // Allow rewards to be pulled
    }

    function setGasRewards(uint256 _gasReward) external onlyOwner {
        require(_gasReward < 5000 && _gasReward > 0, "setGasRewards: !gasReward");
        gasReward = _gasReward;
    }

    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyStrategist {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, uint256(-1));
        emit UpdatedRewards(_rewards);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCost` must be priced in terms of `want`.
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCost The keeper's estimated cast cost to call `tend()`.
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCost) public view virtual returns (bool) {
        // We usually don't need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        return false;
    }

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCost` must be priced in terms of `want`.
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/master/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCost The keeper's estimated cast cost to call `harvest()`.
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCost) public view virtual returns (bool) {
        StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if Strategy is not activated
        if (params.activation == 0) return false;

        // Should not trigger if we haven't waited long enough since previous harvest
        if (block.timestamp.sub(params.lastReport) < minReportDelay) return false;

        // Should trigger if hasn't been called in a while
        if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external nonReentrant {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 totalAssets = estimatedTotalAssets();
            // NOTE: use the larger of total assets or debt outstanding to book losses properly
            (debtPayment, loss) = liquidatePosition(
                totalAssets > debtOutstanding ? totalAssets : debtOutstanding
            );
            // NOTE: take up any remainder here as profit
            if (debtPayment > debtOutstanding) {
                profit = debtPayment.sub(debtOutstanding);
                debtPayment = debtOutstanding;
            }
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
            // If profits - gasReward is greater than losses, pass on the gasReward to the user
            // who called the harvest
            uint256 _gasReward = profit.mul(gasReward).div(10000);
            if (_gasReward > 0 && profit.sub(_gasReward) > loss) {
                profit = profit.sub(_gasReward);
                want.safeTransfer(msg.sender, _gasReward);
            }
        }

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by governance or the Vault.
     * @dev
     *  The new Strategy's Vault must be the same as this Strategy's Vault.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault) || msg.sender == governance());
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     *
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyOwner {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++)
            require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}

abstract contract BaseStrategyInitializable is BaseStrategy {
    event Cloned(address indexed clone);

    constructor(address _vault) public BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function clone(address _vault) external returns (address) {
        return this.clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external returns (address newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

        emit Cloned(newStrategy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {FixedStablecoins, FixedVaults} from "./common/FixedContracts.sol";
import "./common/Controllable.sol";

import "./interfaces/IBuoy.sol";
import "./interfaces/IEmergencyHandler.sol";
import "./interfaces/IInsurance.sol";
import "./interfaces/ILifeGuard.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IWithdrawHandler.sol";

/// @notice Entry point for withdrawal call to Gro Protocol - User withdrawals come as
///     either single asset or balanced withdrawals, which match the underling lifeguard Curve pool or our
///     Vault allocations. Like deposits, withdrawals come in three different sizes:
///         1) sardine - the smallest type of withdrawals, deemed to not affect the system exposure, and is
///            withdrawn directly from the vaults - Curve vault is used to price the withdrawal (buoy)
///         2) tuna - mid sized withdrawals, will withdraw from the most overexposed vault and exchange into
///            the desired asset (lifeguard). If the most overexposed asset is withdrawn, no exchange takes
///            place, this minimizes slippage as it doesn't need to perform any exchanges in the Curve pool
///         3) whale - the largest withdrawal - Withdraws from all stablecoin vaults in target deltas,
///            calculated as the difference between target allocations and vaults exposure (insurance). Uses
///            Curve pool to exchange withdrawns assets to desired assets.
contract WithdrawHandler is Controllable, FixedStablecoins, FixedVaults, IWithdrawHandler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IController public ctrl;
    ILifeGuard public lg;
    IBuoy public buoy;
    IInsurance public insurance;
    IEmergencyHandler public emergencyHandler;

    event LogNewDependencies(
        address controller,
        address lifeguard,
        address buoy,
        address insurance,
        address emergencyHandler
    );
    event LogNewWithdrawal(
        address indexed user,
        address indexed referral,
        bool pwrd,
        bool balanced,
        bool all,
        uint256 deductUsd,
        uint256 returnUsd,
        uint256 lpAmount,
        uint256[N_COINS] tokenAmounts
    );

    // Data structure to hold data for withdrawals
    struct WithdrawParameter {
        address account;
        bool pwrd;
        bool balanced;
        bool all;
        uint256 index;
        uint256[N_COINS] minAmounts;
        uint256 lpAmount;
    }

    constructor(
        address[N_COINS] memory _vaults,
        address[N_COINS] memory _tokens,
        uint256[N_COINS] memory _decimals
    ) public FixedStablecoins(_tokens, _decimals) FixedVaults(_vaults) {}

    /// @notice Update protocol dependencies
    function setDependencies() external onlyOwner {
        ctrl = _controller();
        lg = ILifeGuard(ctrl.lifeGuard());
        buoy = IBuoy(lg.getBuoy());
        insurance = IInsurance(ctrl.insurance());
        emergencyHandler = IEmergencyHandler(ctrl.emergencyHandler());
        emit LogNewDependencies(
            address(ctrl),
            address(lg),
            address(buoy),
            address(insurance),
            address(emergencyHandler)
        );
    }

    /// @notice Withdrawing by LP tokens will attempt to do a balanced
    ///     withdrawal from the lifeguard - Balanced meaning that the withdrawal
    ///     tries to match the token balances of the underlying Curve pool.
    ///     This is calculated by dividing the individual token balances of
    ///     the pool by the total amount. This should give minimal slippage.
    /// @param pwrd Pwrd or Gvt (pwrd/gvt)
    /// @param lpAmount Amount of LP tokens to burn
    /// @param minAmounts Minimum accepted amount of tokens to get back
    function withdrawByLPToken(
        bool pwrd,
        uint256 lpAmount,
        uint256[N_COINS] calldata minAmounts
    ) external override {
        require(!ctrl.emergencyState(), "withdrawByLPToken: emergencyState");
        require(lpAmount > 0, "!minAmount");
        WithdrawParameter memory parameters = WithdrawParameter(
            msg.sender,
            pwrd,
            true,
            false,
            N_COINS,
            minAmounts,
            lpAmount
        );
        _withdraw(parameters);
    }

    /// @notice Withdraws by one token from protocol.
    /// @param pwrd Pwrd or Gvt (pwrd/gvt)
    /// @param index Protocol index of stablecoin
    /// @param lpAmount LP token amount to burn
    /// @param minAmount Minimum amount of tokens to get back
    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) external override {
        if (ctrl.emergencyState()) {
            emergencyHandler.emergencyWithdrawal(msg.sender, pwrd, lpAmount, minAmount);
        } else {
            require(index < N_COINS, "!withdrawByStablecoin: invalid index");
            require(lpAmount > 0, "!minAmount");
            uint256[N_COINS] memory minAmounts;
            minAmounts[index] = minAmount;
            WithdrawParameter memory parameters = WithdrawParameter(
                msg.sender,
                pwrd,
                false,
                false,
                index,
                minAmounts,
                lpAmount
            );
            _withdraw(parameters);
        }
    }

    /// @notice Withdraw all pwrd/gvt for a specifc stablecoin
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param index Protocol index of stablecoin
    /// @param minAmount Minimum amount of returned assets
    function withdrawAllSingle(
        bool pwrd,
        uint256 index,
        uint256 minAmount
    ) external override {
        if (ctrl.emergencyState()) {
            emergencyHandler.emergencyWithdrawAll(msg.sender, pwrd, minAmount);
        } else {
            _withdrawAllSingleFromAccount(msg.sender, pwrd, index, minAmount);
        }
    }

    /// @notice Burn a pwrd/gvt for a balanced amount of stablecoin assets
    /// @param pwrd Pwrd or Gvt (pwrd/gvt)
    /// @param minAmounts Minimum amount of returned assets
    function withdrawAllBalanced(bool pwrd, uint256[N_COINS] calldata minAmounts) external override {
        require(!ctrl.emergencyState(), "withdrawByLPToken: emergencyState");
        WithdrawParameter memory parameters = WithdrawParameter(msg.sender, pwrd, true, true, N_COINS, minAmounts, 0);
        _withdraw(parameters);
    }

    /// @notice Function to get deltas for balanced withdrawals
    /// @param amount Amount to withdraw (denoted in LP tokens)
    /// @dev This function should be used to determine input values
    ///     when atempting a balanced withdrawal
    function getVaultDeltas(uint256 amount) external view returns (uint256[N_COINS] memory tokenAmounts) {
        uint256[N_COINS] memory delta = insurance.getDelta(buoy.lpToUsd(amount));
        for (uint256 i; i < N_COINS; i++) {
            uint256 withdraw = amount.mul(delta[i]).div(PERCENTAGE_DECIMAL_FACTOR);
            if (withdraw > 0) tokenAmounts[i] = buoy.singleStableFromLp(withdraw, int128(i));
        }
    }

    function withdrawalFee(bool pwrd) public view returns (uint256) {
        return _controller().withdrawalFee(pwrd);
    }

    /// @notice Prepare for a single sided withdraw all action
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param index Index of token
    /// @param minAmount Minimum amount accepted in return
    function _withdrawAllSingleFromAccount(
        address account,
        bool pwrd,
        uint256 index,
        uint256 minAmount
    ) private {
        require(index < N_COINS, "!withdrawAllSingleFromAccount: invalid index");
        uint256[N_COINS] memory minAmounts;
        minAmounts[index] = minAmount;
        WithdrawParameter memory parameters = WithdrawParameter(account, pwrd, false, true, index, minAmounts, 0);
        _withdraw(parameters);
    }

    /// @notice Main withdraw logic
    /// @param parameters Struct holding withdraw info
    /// @dev Paramater struct here to avoid triggering stack to deep...
    function _withdraw(WithdrawParameter memory parameters) private {
        ctrl.eoaOnly(msg.sender);
        require(buoy.safetyCheck(), "!safetyCheck");

        uint256 deductUsd;
        uint256 returnUsd;
        uint256 lpAmountFee;
        uint256[N_COINS] memory tokenAmounts;
        // If it's a "withdraw all" action
        uint256 virtualPrice = buoy.getVirtualPrice();
        if (parameters.all) {
            deductUsd = ctrl.getUserAssets(parameters.pwrd, parameters.account);
            returnUsd = deductUsd.sub(deductUsd.mul(withdrawalFee(parameters.pwrd)).div(PERCENTAGE_DECIMAL_FACTOR));
            lpAmountFee = returnUsd.mul(DEFAULT_DECIMALS_FACTOR).div(virtualPrice);
            // If it's a normal withdrawal
        } else {
            uint256 userAssets = ctrl.getUserAssets(parameters.pwrd, parameters.account);
            uint256 lpAmount = parameters.lpAmount;
            uint256 fee = lpAmount.mul(withdrawalFee(parameters.pwrd)).div(PERCENTAGE_DECIMAL_FACTOR);
            lpAmountFee = lpAmount.sub(fee);
            returnUsd = lpAmountFee.mul(virtualPrice).div(DEFAULT_DECIMALS_FACTOR);
            deductUsd = lpAmount.mul(virtualPrice).div(DEFAULT_DECIMALS_FACTOR);
            require(deductUsd <= userAssets, "!withdraw: not enough balance");
        }
        uint256 hodlerBonus = deductUsd.sub(returnUsd);

        bool whale = ctrl.isValidBigFish(parameters.pwrd, false, returnUsd);

        // If it's a balanced withdrawal
        if (parameters.balanced) {
            (returnUsd, tokenAmounts) = _withdrawBalanced(
                parameters.account,
                parameters.pwrd,
                lpAmountFee,
                parameters.minAmounts,
                returnUsd
            );
            // If it's a single asset withdrawal
        } else {
            (returnUsd, tokenAmounts[parameters.index]) = _withdrawSingle(
                parameters.account,
                parameters.pwrd,
                lpAmountFee,
                parameters.minAmounts[parameters.index],
                parameters.index,
                returnUsd,
                whale
            );
        }

        ctrl.burnGToken(parameters.pwrd, parameters.all, parameters.account, deductUsd, hodlerBonus);

        emit LogNewWithdrawal(
            parameters.account,
            ctrl.referrals(parameters.account),
            parameters.pwrd,
            parameters.balanced,
            parameters.all,
            deductUsd,
            returnUsd,
            lpAmountFee,
            tokenAmounts
        );
    }

    /// @notice Withdrawal logic of single asset withdrawals
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param lpAmount LP token value of withdrawal
    /// @param minAmount Minimum amount accepted in return
    /// @param index Index of token
    /// @param withdrawUsd USD value of withdrawals
    /// @param whale Whale withdrawal
    function _withdrawSingle(
        address account,
        bool pwrd,
        uint256 lpAmount,
        uint256 minAmount,
        uint256 index,
        uint256 withdrawUsd,
        bool whale
    ) private returns (uint256 dollarAmount, uint256 tokenAmount) {
        dollarAmount = withdrawUsd;
        // Is the withdrawal large...
        if (whale) {
            (dollarAmount, tokenAmount) = _prepareForWithdrawalSingle(account, pwrd, index, minAmount, withdrawUsd);
        } else {
            // ... or small
            IVault adapter = IVault(getVault(index));
            tokenAmount = buoy.singleStableFromLp(lpAmount, int128(index));
            adapter.withdrawByStrategyOrder(tokenAmount, account, pwrd);
        }
        require(tokenAmount >= minAmount, "!withdrawSingle: !minAmount");
    }

    /// @notice Withdrawal logic of balanced withdrawals - Balanced withdrawals
    ///     pull out assets from vault by delta difference between target allocations
    ///     and actual vault amounts ( insurane getDelta ). These withdrawals should
    ///     have minimal impact on user funds as they dont interact with curve (no slippage),
    ///     but are only possible as long as there are assets available to cover the withdrawal
    ///     in the stablecoin vaults - as no swapping or realancing will take place.
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param lpAmount LP token value of withdrawal
    /// @param minAmounts Minimum amounts accepted in return
    /// @param withdrawUsd USD value of withdrawals
    function _withdrawBalanced(
        address account,
        bool pwrd,
        uint256 lpAmount,
        uint256[N_COINS] memory minAmounts,
        uint256 withdrawUsd
    ) private returns (uint256 dollarAmount, uint256[N_COINS] memory tokenAmounts) {
        uint256 coins = N_COINS;
        uint256[N_COINS] memory delta = insurance.getDelta(withdrawUsd);
        address[N_COINS] memory _vaults = vaults();
        for (uint256 i; i < coins; i++) {
            uint256 withdraw = lpAmount.mul(delta[i]).div(PERCENTAGE_DECIMAL_FACTOR);
            if (withdraw > 0) {
                tokenAmounts[i] = buoy.singleStableFromLp(withdraw, int128(i));
                require(tokenAmounts[i] >= minAmounts[i], "!withdrawBalanced: !minAmount");
                IVault adapter = IVault(_vaults[i]);
                require(tokenAmounts[i] <= adapter.totalAssets(), "_withdrawBalanced: !adapterBalance");
                adapter.withdrawByStrategyOrder(tokenAmounts[i], account, pwrd);
            }
        }
        dollarAmount = buoy.stableToUsd(tokenAmounts, false);
    }

    /// @notice Withdrawal logic for large single asset withdrawals.
    ///     Large withdrawals are routed through the insurance layer to
    ///     ensure that withdrawal dont affect protocol exposure.
    /// @param account User account
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param minAmount Minimum amount accepted in return
    /// @param index Index of token
    /// @param withdrawUsd USD value of withdrawals
    function _prepareForWithdrawalSingle(
        address account,
        bool pwrd,
        uint256 index,
        uint256 minAmount,
        uint256 withdrawUsd
    ) private returns (uint256 dollarAmount, uint256 amount) {
        bool curve = insurance.rebalanceForWithdraw(withdrawUsd, pwrd);
        if (curve) {
            lg.depositStable(false);
            (dollarAmount, amount) = lg.withdrawSingleByLiquidity(index, minAmount, account);
        } else {
            (dollarAmount, amount) = lg.withdrawSingleByExchange(index, minAmount, account);
        }
        require(minAmount <= amount, "!prepareForWithdrawalSingle: !minAmount");
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./Constants.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IVault.sol";

contract FixedStablecoins is Constants {
    address public immutable DAI; // = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public immutable USDC; // = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable USDT; // = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint256 public immutable DAI_DECIMALS; // = 1E18;
    uint256 public immutable USDC_DECIMALS; // = 1E6;
    uint256 public immutable USDT_DECIMALS; // = 1E6;

    constructor(address[N_COINS] memory _tokens, uint256[N_COINS] memory _decimals) public {
        DAI = _tokens[0];
        USDC = _tokens[1];
        USDT = _tokens[2];
        DAI_DECIMALS = _decimals[0];
        USDC_DECIMALS = _decimals[1];
        USDT_DECIMALS = _decimals[2];
    }

    function underlyingTokens() internal view returns (address[N_COINS] memory tokens) {
        tokens[0] = DAI;
        tokens[1] = USDC;
        tokens[2] = USDT;
    }

    function getToken(uint256 index) internal view returns (address) {
        if (index == 0) {
            return DAI;
        } else if (index == 1) {
            return USDC;
        } else {
            return USDT;
        }
    }

    function decimals() internal view returns (uint256[N_COINS] memory _decimals) {
        _decimals[0] = DAI_DECIMALS;
        _decimals[1] = USDC_DECIMALS;
        _decimals[2] = USDT_DECIMALS;
    }

    function getDecimal(uint256 index) internal view returns (uint256) {
        if (index == 0) {
            return DAI_DECIMALS;
        } else if (index == 1) {
            return USDC_DECIMALS;
        } else {
            return USDT_DECIMALS;
        }
    }
}

contract FixedGTokens {
    IToken public immutable pwrd;
    IToken public immutable gvt;

    constructor(address _pwrd, address _gvt) public {
        pwrd = IToken(_pwrd);
        gvt = IToken(_gvt);
    }

    function gTokens(bool _pwrd) internal view returns (IToken) {
        if (_pwrd) {
            return pwrd;
        } else {
            return gvt;
        }
    }
}

contract FixedVaults is Constants {
    address public immutable DAI_VAULT;
    address public immutable USDC_VAULT;
    address public immutable USDT_VAULT;

    constructor(address[N_COINS] memory _vaults) public {
        DAI_VAULT = _vaults[0];
        USDC_VAULT = _vaults[1];
        USDT_VAULT = _vaults[2];
    }

    function getVault(uint256 index) internal view returns (address) {
        if (index == 0) {
            return DAI_VAULT;
        } else if (index == 1) {
            return USDC_VAULT;
        } else {
            return USDT_VAULT;
        }
    }

    function vaults() internal view returns (address[N_COINS] memory _vaults) {
        _vaults[0] = DAI_VAULT;
        _vaults[1] = USDC_VAULT;
        _vaults[2] = USDT_VAULT;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import {ICurve3Pool} from "./ICurve.sol";
import "./IChainPrice.sol";

interface IBuoy {
    function safetyCheck() external view returns (bool);

    function updateRatios() external returns (bool);

    function updateRatiosWithTolerance(uint256 tolerance) external returns (bool);

    function lpToUsd(uint256 inAmount) external view returns (uint256);

    function usdToLp(uint256 inAmount) external view returns (uint256);

    function stableToUsd(uint256[3] calldata inAmount, bool deposit) external view returns (uint256);

    function stableToLp(uint256[3] calldata inAmount, bool deposit) external view returns (uint256);

    function singleStableFromLp(uint256 inAmount, int128 i) external view returns (uint256);

    function curvePool() external view returns (ICurve3Pool);

    function getVirtualPrice() external view returns (uint256);

    function singleStableFromUsd(uint256 inAmount, int128 i) external view returns (uint256);

    function singleStableToUsd(uint256 inAmount, uint256 i) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IEmergencyHandler {
    function emergencyWithdrawal(
        address user,
        bool pwrd,
        uint256 inAmount,
        uint256 minAmounts
    ) external;

    function emergencyWithdrawAll(
        address user,
        bool pwrd,
        uint256 minAmounts
    ) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IInsurance {
    function calculateDepositDeltasOnAllVaults() external view returns (uint256[3] memory);

    function rebalanceTrigger() external view returns (bool sysNeedRebalance);

    function rebalance() external;

    function calcSkim() external view returns (uint256);

    function rebalanceForWithdraw(uint256 withdrawUsd, bool pwrd) external returns (bool);

    function getDelta(uint256 withdrawUsd) external view returns (uint256[3] memory delta);

    function getVaultDeltaForDeposit(uint256 amount)
        external
        view
        returns (
            uint256[3] memory,
            uint256[3] memory,
            uint256
        );

    function sortVaultsByDelta(bool bigFirst) external view returns (uint256[3] memory vaultIndexes);

    function getStrategiesTargetRatio(uint256 utilRatio) external view returns (uint256[] memory);

    function setUnderlyingTokenPercent(uint256 coinIndex, uint256 percent) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

// LP -> Liquidity pool token
interface ILifeGuard {
    function assets(uint256 i) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function getAssets() external view returns (uint256[3] memory);

    function totalAssetsUsd() external view returns (uint256);

    function availableUsd() external view returns (uint256 dollar);

    function availableLP() external view returns (uint256);

    function depositStable(bool rebalance) external returns (uint256);

    function investToCurveVault() external;

    function distributeCurveVault(uint256 amount, uint256[3] memory delta) external returns (uint256[3] memory);

    function deposit() external returns (uint256 usdAmount);

    function withdrawSingleByLiquidity(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external returns (uint256 usdAmount, uint256 amount);

    function withdrawSingleByExchange(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external returns (uint256 usdAmount, uint256 amount);

    function invest(uint256 whaleDepositAmount, uint256[3] calldata delta) external returns (uint256 dollarAmount);

    function getBuoy() external view returns (address);

    function investSingle(
        uint256[3] calldata inAmounts,
        uint256 i,
        uint256 j
    ) external returns (uint256 dollarAmount);

    function investToCurveVaultTrigger() external view returns (bool _invest);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IWithdrawHandler {
    function withdrawByLPToken(
        bool pwrd,
        uint256 lpAmount,
        uint256[3] calldata minAmounts
    ) external;

    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) external;

    function withdrawAllSingle(
        bool pwrd,
        uint256 index,
        uint256 minAmount
    ) external;

    function withdrawAllBalanced(bool pwrd, uint256[3] calldata minAmounts) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IToken {
    function factor() external view returns (uint256);

    function factor(uint256 totalAssets) external view returns (uint256);

    function mint(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burn(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burnAll(address account) external;

    function totalAssets() external view returns (uint256);

    function getPricePerShare() external view returns (uint256);

    function getShareAssets(uint256 shares) external view returns (uint256);

    function getAssets(address account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IChainPrice {
    function getPriceFeed(uint256 i) external view returns (uint256 _price);
}

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "../common/Constants.sol";
import "../interfaces/IBuoy.sol";
import "../interfaces/IController.sol";
import "../interfaces/IDepositHandler.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/ILifeGuard.sol";
import "../interfaces/IPnL.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IWithdrawHandler.sol";
import "./MockERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract MockController is Constants, Pausable, Ownable, IController, IWithdrawHandler, IDepositHandler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 pricePerShare = CHAINLINK_PRICE_DECIMAL_FACTOR;
    uint256 _gTokenTotalAssets;
    uint256 utilisationRatioLimit;
    address[3] underlyingTokens;
    uint256[3] delta;
    mapping(uint256 => address) public override underlyingVaults;
    address public override curveVault;
    uint256 public override deadCoin;
    bool public override emergencyState;

    mapping(address => bool) whiteListedPools;
    mapping(address => address) public override referrals;
    address public override insurance;
    address public override reward;

    address public override pnl;
    address public override lifeGuard;
    address public override buoy;
    address public gvt;
    address public pwrd;
    //tmp fix for pwrd override in withdraw
    address public _pwrd;
    uint256 public override totalAssets;
    uint256 skimPercent;

    bool public whale;
    uint256[] public vaultOrder;

    // Added for testing purposes - cant get events from function called
    // within a function in truffle test (not available in rawLogs)
    event LogNewDeposit(address indexed user, uint256 usdAmount, uint256[3] tokens);
    event LogNewWithdrawal(address indexed user, uint256 usdAmount, uint256[3] tokenAmounts);
    event LogNewSingleCoinWithdrawal(address indexed user, uint256 usdAmount, uint256 token, uint256 lpTokens);

    function setUnderlyingTokens(address[3] calldata tokens) external onlyOwner {
        underlyingTokens = tokens;
    }

    // Mocks insurance module delta calculation
    function setDelta(uint256[3] calldata newDelta) external {
        delta = newDelta;
    }

    function setGvt(address _gvt) external {
        gvt = _gvt;
    }

    function setPwrd(address newPwrd) external {
        pwrd = newPwrd;
        _pwrd = newPwrd;
    }

    function setVaultOrder(uint256[] calldata newOrder) external {
        vaultOrder = newOrder;
    }

    // Mocks insurance vaults
    function setVault(uint256 index, address vault) external {
        underlyingVaults[index] = vault;
    }

    function setCurveVault(address _curveVault) external onlyOwner {
        curveVault = _curveVault;
    }

    function stablecoins() external view override returns (address[3] memory) {
        return underlyingTokens;
    }

    function deposit(
        address gTokenAddress,
        uint256[3] calldata inAmounts,
        uint256 minAmount,
        address pool,
        address _referral
    ) external {
        require(minAmount > 0, "minAmount should be greater than 0.");
        ILifeGuard lg = ILifeGuard(pool);

        for (uint256 i = 0; i < N_COINS; i++) {
            address token = underlyingTokens[i];
            IERC20(token).safeTransferFrom(msg.sender, pool, inAmounts[i]);
        }
        uint256 dollarAmount;
        bool invest = false;

        dollarAmount = lg.deposit();

        if (invest) {
            dollarAmount = lg.invest(dollarAmount, delta);
        }

        _mintGToken(gTokenAddress, dollarAmount);
        emit LogNewDeposit(msg.sender, dollarAmount, inAmounts);
    }

    function depositGvt(
        uint256[3] calldata inAmounts,
        uint256 minAmount,
        address _referral
    ) external override {
        require(minAmount > 0, "minAmount should be greater than 0.");
        ILifeGuard lg = ILifeGuard(lifeGuard);

        for (uint256 i = 0; i < N_COINS; i++) {
            address token = underlyingTokens[i];
            IERC20(token).safeTransferFrom(msg.sender, lifeGuard, inAmounts[i]);
        }
        uint256 dollarAmount;
        bool invest = false;
        if (whale) {
            uint256 outAmount = lg.deposit();
            dollarAmount = lg.invest(outAmount, delta);
        } else {
            dollarAmount = lg.investSingle(inAmounts, vaultOrder[0], vaultOrder[1]);
        }
        _mintGToken(gvt, dollarAmount);
        emit LogNewDeposit(msg.sender, dollarAmount, inAmounts);
    }

    function depositPwrd(
        uint256[3] calldata inAmounts,
        uint256 minAmount,
        address _referral
    ) external override {
        require(minAmount > 0, "minAmount should be greater than 0.");
        ILifeGuard lg = ILifeGuard(lifeGuard);

        for (uint256 i = 0; i < N_COINS; i++) {
            address token = underlyingTokens[i];
            IERC20(token).safeTransferFrom(msg.sender, lifeGuard, inAmounts[i]);
        }
        uint256 dollarAmount;
        bool invest = false;
        if (whale) {
            uint256 outAmount = lg.deposit();
            dollarAmount = lg.invest(outAmount, delta);
        } else {
            dollarAmount = lg.investSingle(inAmounts, vaultOrder[0], vaultOrder[1]);
        }
        _mintGToken(pwrd, dollarAmount);
        emit LogNewDeposit(msg.sender, dollarAmount, inAmounts);
    }

    function withdrawAllSingle(
        address gTokenAddress,
        uint256 index,
        uint256 minAmount,
        address pool
    ) public {}

    function withdrawAllBalanced(
        address gTokenAddress,
        uint256[] calldata minAmounts,
        address pool
    ) public {}

    function withdrawalFee(bool pwrd_) external view override returns (uint256) {}

    function withdrawByLPToken(
        bool pwrd_,
        uint256 lpAmount,
        uint256[3] calldata minAmounts
    ) external override {
        _withdrawLp(pwrd_, lpAmount, minAmounts);
    }

    function _withdrawLp(
        bool pwrd_,
        uint256 lpAmount,
        uint256[3] memory minAmount
    ) internal {
        ILifeGuard lg = ILifeGuard(lifeGuard);
        IBuoy buoy = IBuoy(lg.getBuoy());
        uint256 dollarAmount;
        uint256[3] memory _amounts;
        if (whale) {
            for (uint256 i = 0; i < 3; i++) {
                uint256 lpPart = lpAmount.mul(delta[i]).div(10000);
                uint256 amount = buoy.singleStableFromLp(lpPart, int128(i));
                IVault vault = IVault(underlyingVaults[i]);
                vault.withdrawByStrategyOrder(amount, msg.sender, pwrd_);
                _amounts[i] = amount;
            }
        } else {
            uint256 i = vaultOrder[0];
            IVault vault = IVault(underlyingVaults[i]);
            uint256 amount = buoy.singleStableFromLp(lpAmount, int128(i));
            vault.withdrawByStrategyOrder(amount, msg.sender, pwrd_);
            _amounts[i] = amount;
        }
        dollarAmount = buoy.stableToUsd(_amounts, false);
        IToken dt;
        if (pwrd_) {
            dt = IToken(_pwrd);
        } else {
            dt = IToken(gvt);
        }
        dt.burn(msg.sender, dt.factor(), dollarAmount);
    }

    function withdrawByStablecoin(
        bool pwrd_,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) external override {
        _withdrawSingle(pwrd_, index, lpAmount, minAmount);
    }

    function withdrawAllSingle(
        bool pwrd_,
        uint256 index,
        uint256 minAmount
    ) external override {}

    function _withdrawSingle(
        bool pwrd_,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) internal {
        ILifeGuard lg = ILifeGuard(lifeGuard);
        IBuoy buoy = IBuoy(lg.getBuoy());
        uint256 dollarAmount;
        if (whale) {
            for (uint256 i = 0; i < 3; i++) {
                uint256 lpPart = lpAmount.mul(delta[i]).div(10000);
                uint256 amount = buoy.singleStableFromLp(lpPart, int128(i));
                IVault vault = IVault(underlyingVaults[i]);
                vault.withdrawByStrategyOrder(amount, lifeGuard, pwrd_);
                (dollarAmount, ) = lg.withdrawSingleByExchange(index, 1, msg.sender);
            }
        } else {
            IVault vault = IVault(underlyingVaults[vaultOrder[0]]);
            uint256 amount = buoy.singleStableFromLp(lpAmount, int128(vaultOrder[0]));
            vault.withdrawByStrategyOrder(amount, lifeGuard, pwrd_);
            (dollarAmount, ) = lg.withdrawSingleByExchange(index, 1, msg.sender);
        }
        IToken dt;
        if (pwrd_) {
            dt = IToken(_pwrd);
        } else {
            dt = IToken(gvt);
        }
        dt.burn(msg.sender, dt.factor(), dollarAmount);
    }

    function withdrawAllBalanced(bool pwrd_, uint256[3] calldata minAmounts) external override {}

    function addPool(address pool, address[] calldata tokens) external onlyOwner {
        tokens;
        whiteListedPools[pool] = true;
    }

    function _deposit(uint256 dollarAmount) private {
        _gTokenTotalAssets = _gTokenTotalAssets.add(dollarAmount);
    }

    function _withdraw(uint256 dollarAmount) private {
        _gTokenTotalAssets = _gTokenTotalAssets.sub(dollarAmount);
    }

    function _mintGToken(address gToken, uint256 amount) private {
        IToken dt = IToken(gToken);
        dt.mint(msg.sender, dt.factor(), amount);
        _deposit(amount);
    }

    function _burnGToken(
        address gToken,
        uint256 amount,
        uint256 bonus
    ) private {
        IToken dt = IToken(gToken);
        dt.burn(msg.sender, dt.factor(), amount);
        _withdraw(amount);
    }

    function gTokenTotalAssets() public view override returns (uint256) {
        return _gTokenTotalAssets;
    }

    function setGTokenTotalAssets(uint256 totalAssets) external {
        _gTokenTotalAssets = totalAssets;
    }

    function increaseGTokenTotalAssets(uint256 totalAssets) external {
        _gTokenTotalAssets = _gTokenTotalAssets.add(totalAssets);
    }

    function decreaseGTokenTotalAssets(uint256 totalAssets) external {
        _gTokenTotalAssets = _gTokenTotalAssets.sub(totalAssets);
    }

    function mintGTokens(address gToken, uint256 amount) external {
        _mintGToken(gToken, amount);
    }

    function burnGTokens(address gToken, uint256 amount) external {
        _burnGToken(gToken, amount, 0);
    }

    function vaults() external view override returns (address[N_COINS] memory) {
        uint256 length = underlyingTokens.length;
        address[N_COINS] memory result;
        for (uint256 i = 0; i < length; i++) {
            result[i] = underlyingVaults[i];
        }
        return result;
    }

    function setPnL(address _pnl) external {
        pnl = _pnl;
    }

    function setLifeGuard(address _lifeGuard) external {
        lifeGuard = _lifeGuard;
    }

    function setInsurance(address _insurance) external {
        insurance = _insurance;
    }

    function setUtilisationRatioLimitForDeposit(uint256 _utilisationRatioLimit) external {
        utilisationRatioLimit = _utilisationRatioLimit;
    }

    function increaseGTokenLastAmount(address gTokenAddress, uint256 dollarAmount) external {
        if (gTokenAddress == pwrd) {
            IPnL(pnl).increaseGTokenLastAmount(true, dollarAmount);
        } else {
            IPnL(pnl).increaseGTokenLastAmount(false, dollarAmount);
        }
    }

    function decreaseGTokenLastAmount(
        address gTokenAddress,
        uint256 dollarAmount,
        uint256 bonus
    ) external {
        if (gTokenAddress == pwrd) {
            IPnL(pnl).decreaseGTokenLastAmount(true, dollarAmount, bonus);
        } else {
            IPnL(pnl).decreaseGTokenLastAmount(false, dollarAmount, bonus);
        }
    }

    function setGVT(address token) external {
        gvt = token;
    }

    function setPWRD(address token) external {
        pwrd = token;
    }

    function setTotalAssets(uint256 _totalAssets) external {
        totalAssets = _totalAssets;
    }

    function eoaOnly(address sender) external override {
        sender;
    }

    function withdrawHandler() external view override returns (address) {
        return address(this);
    }

    function depositHandler() external view override returns (address) {
        return address(this);
    }

    function emergencyHandler() external view override returns (address) {
        return address(this);
    }

    function setWhale(bool _whale) external {
        whale = _whale;
    }

    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view override returns (bool) {
        return whale;
    }

    function gToken(bool isPWRD) external view override returns (address) {}

    function setSkimPercent(uint256 _percent) external {
        skimPercent = _percent;
    }

    function getSkimPercent() external view override returns (uint256) {
        return skimPercent;
    }

    function emergency(uint256 coin) external {}

    function restart(uint256[] calldata allocations) external {}

    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external override {
        IPnL(pnl).distributeStrategyGainLoss(gain, loss, reward);
    }

    function distributePriceChange() external {
        IPnL(pnl).distributePriceChange(totalAssets);
    }

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external override {
        IPnL(pnl).decreaseGTokenLastAmount(pwrd, amount, bonus);
        if (pwrd) {
            _burnGToken(_pwrd, amount, bonus);
        } else {
            _burnGToken(gvt, amount, bonus);
        }
    }

    function depositPool() external {
        ILifeGuard(lifeGuard).deposit();
    }

    function depositStablePool(bool rebalance) external {
        ILifeGuard(lifeGuard).depositStable(rebalance);
    }

    function investPool(uint256 amount, uint256[3] memory delta) external {
        ILifeGuard(lifeGuard).invest(amount, delta);
    }

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external override {}

    function getUserAssets(bool pwrd, address account) external view override returns (uint256 deductUsd) {}

    function distributeCurveAssets(uint256 amount, uint256[N_COINS] memory delta) external {
        uint256[N_COINS] memory amounts = ILifeGuard(lifeGuard).distributeCurveVault(amount, delta);
    }

    function addReferral(address account, address referral) external override {}

    function getStrategiesTargetRatio() external view override returns (uint256[] memory result) {
        result = new uint256[](2);
        result[0] = 5000;
        result[1] = 5000;
    }

    function validGTokenDecrease(uint256 amount) external view override returns (bool) {}
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IDepositHandler {
    function depositGvt(
        uint256[3] calldata inAmounts,
        uint256 minAmount,
        address _referral
    ) external;

    function depositPwrd(
        uint256[3] calldata inAmounts,
        uint256 minAmount,
        address _referral
    ) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IPnL {
    function calcPnL() external view returns (uint256, uint256);

    function increaseGTokenLastAmount(bool pwrd, uint256 dollarAmount) external;

    function decreaseGTokenLastAmount(
        bool pwrd,
        uint256 dollarAmount,
        uint256 bonus
    ) external;

    function lastGvtAssets() external view returns (uint256);

    function lastPwrdAssets() external view returns (uint256);

    function utilisationRatio() external view returns (uint256);

    function emergencyPnL() external;

    function recover() external;

    function distributeStrategyGainLoss(
        uint256 gain,
        uint256 loss,
        address reward
    ) external;

    function distributePriceChange(uint256 currentTotalAssets) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MockERC20 is ERC20, Ownable {
    function mint(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Account is empty.");
        require(amount > 0, "amount is less than zero.");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Account is empty.");
        require(amount > 0, "amount is less than zero.");
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";

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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
 *
 * ################### GERC20 additions to IERC20 ###################
 *      _burn: Added paramater - burnAmount added to take rebased amount into account,
 *          affects the Transfer event
 *      _mint: Added paramater - mintAmount added to take rebased amount into account,
 *          affects the Transfer event
 *      _transfer: Added paramater - transferAmount added to take rebased amount into account,
 *          affects the Transfer event
 *      _decreaseApproved: Added function - internal function to allowed override of transferFrom
 *
 */
abstract contract GERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupplyBase() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOfBase(address account) public view returns (uint256) {
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
        _transfer(_msgSender(), recipient, amount, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
        _transfer(sender, recipient, amount, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *      GERC20 addition - transferAmount added to take rebased amount into account
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
        uint256 transferAmount,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, transferAmount);

        _balances[sender] = _balances[sender].sub(transferAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(transferAmount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *      GERC20 addition - mintAmount added to take rebased amount into account
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 mintAmount,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, mintAmount);

        _totalSupply = _totalSupply.add(mintAmount);
        _balances[account] = _balances[account].add(mintAmount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *      GERC20 addition - burnAmount added to take rebased amount into account
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 burnAmount,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), burnAmount);

        _balances[account] = _balances[account].sub(burnAmount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(burnAmount);
        emit Transfer(account, address(0), amount);
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

    function _decreaseApproved(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = _allowances[owner][spender].sub(amount);
        emit Approval(owner, spender, _allowances[owner][spender]);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./GERC20.sol";
import "../common/Constants.sol";
import "../common/Whitelist.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IController.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/IToken.sol";

/// @notice Base contract for gro protocol tokens - The Gro token specifies some additional functionality
///     shared by both tokens (Rebasing, NonRebasing).
///     - Factor:
///         The GToken factor. The two tokens are associated with a factor that controls their price (NonRebasing),
///         or their amount (Rebasing). The factor is defined by the totalSupply / total assets lock in token.
///     - Base:
///         The base amount of minted tokens, this affects the Rebasing token as the totalSupply is defined by:
///         BASE amount / factor
///     - Total assets:
///         Total assets is the dollarvalue of the underlying assets used to mint Gtokens. The Gtoken
///         depends on an external contract (Controller.sol) to get this value (retrieved from PnL calculations)
abstract contract GToken is GERC20, Constants, Whitelist, IToken {
    uint256 public constant BASE = DEFAULT_DECIMALS_FACTOR;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IController public ctrl;

    constructor(string memory name, string memory symbol) public GERC20(name, symbol, DEFAULT_DECIMALS) {}

    function setController(address controller) external onlyOwner {
        ctrl = IController(controller);
    }

    function factor() public view override returns (uint256) {
        return factor(totalAssets());
    }

    function applyFactor(
        uint256 a,
        uint256 b,
        bool base
    ) internal pure returns (uint256 resultant) {
        uint256 _BASE = BASE;
        uint256 diff;
        if (base) {
            diff = a.mul(b) % _BASE;
            resultant = a.mul(b).div(_BASE);
        } else {
            diff = a.mul(_BASE) % b;
            resultant = a.mul(_BASE).div(b);
        }
        if (diff >= 5E17) {
            resultant = resultant.add(1);
        }
    }

    function factor(uint256 totalAssets) public view override returns (uint256) {
        if (totalSupplyBase() == 0) {
            return getInitialBase();
        }

        if (totalAssets > 0) {
            return totalSupplyBase().mul(BASE).div(totalAssets);
        }

        // This case is totalSupply > 0 && totalAssets == 0, and only occurs on system loss
        return 0;
    }

    function totalAssets() public view override returns (uint256) {
        return ctrl.gTokenTotalAssets();
    }

    function getInitialBase() internal pure virtual returns (uint256) {
        return BASE;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./GToken.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @notice Rebasing token implementation of the GToken.
///     This contract defines the PWRD Stablecoin (pwrd) - A yield bearing stable coin used in
///     Gro protocol. The Rebasing token does not rebase in discrete events by minting new tokens,
///     but rather relies on the GToken factor to establish the amount of tokens in circulation,
///     in a continuous manner. The token supply is defined as:
///         BASE (10**18) / factor (total supply / total assets)
///     where the total supply is the number of minted tokens, and the total assets
///     is the USD value of the underlying assets used to mint the token.
///     For simplicity the underlying amount of tokens will be refered to as base, while
///     the rebased amount (base/factor) will be refered to as rebase.
contract RebasingGToken is GToken {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event LogTransfer(address indexed sender, address indexed recipient, uint256 indexed amount);

    constructor(string memory name, string memory symbol) public GToken(name, symbol) {}

    /// @notice TotalSupply override - the totalsupply of the Rebasing token is
    ///     calculated by dividing the totalSupplyBase (standard ERC20 totalSupply)
    ///     by the factor. This result is the rebased amount
    function totalSupply() public view override returns (uint256) {
        uint256 f = factor();
        return f > 0 ? applyFactor(totalSupplyBase(), f, false) : 0;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 f = factor();
        return f > 0 ? applyFactor(balanceOfBase(account), f, false) : 0;
    }

    /// @notice Transfer override - Overrides the transfer method to transfer
    ///     the correct underlying base amount of tokens, but emit the rebased amount
    /// @param recipient Recipient of transfer
    /// @param amount Base amount to transfer
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 transferAmount = applyFactor(amount, factor(), true);
        // amount.mul(factor()).div(BASE);
        super._transfer(msg.sender, recipient, transferAmount, amount);
        emit LogTransfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Price should always be 1E18
    function getPricePerShare() external view override returns (uint256) {
        return BASE;
    }

    function getShareAssets(uint256 shares) external view override returns (uint256) {
        return shares;
    }

    function getAssets(address account) external view override returns (uint256) {
        return balanceOf(account);
    }

    /// @notice Mint RebasingGTokens
    /// @param account Target account
    /// @param _factor Factor to use for mint
    /// @param amount Mint amount in USD
    function mint(
        address account,
        uint256 _factor,
        uint256 amount
    ) external override onlyWhitelist {
        require(account != address(0), "mint: 0x");
        require(amount > 0, "Amount is zero.");
        // Apply factor to amount to get rebase amount
        uint256 mintAmount = applyFactor(amount, _factor, true);
        // uint256 mintAmount = amount.mul(_factor).div(BASE);
        _mint(account, mintAmount, amount);
    }

    /// @notice Burn RebasingGTokens
    /// @param account Target account
    /// @param _factor Factor to use for mint
    /// @param amount Burn amount in USD
    function burn(
        address account,
        uint256 _factor,
        uint256 amount
    ) external override onlyWhitelist {
        require(account != address(0), "burn: 0x");
        require(amount > 0, "Amount is zero.");
        // Apply factor to amount to get rebase amount
        uint256 burnAmount = applyFactor(amount, _factor, true);
        // uint256 burnAmount = amount.mul(_factor).div(BASE);
        _burn(account, burnAmount, amount);
    }

    /// @notice Burn all pwrds for account - used by withdraw all methods
    /// @param account Target account
    function burnAll(address account) external override onlyWhitelist {
        require(account != address(0), "burnAll: 0x");
        uint256 burnAmount = balanceOfBase(account);
        uint256 amount = applyFactor(burnAmount, factor(), false);
        // uint256 amount = burnAmount.mul(BASE).div(factor());
        // Apply factor to amount to get rebase amount
        _burn(account, burnAmount, amount);
    }

    /// @notice transferFrom override - Overrides the transferFrom method
    ///     to transfer the correct amount of underlying tokens (Base amount)
    ///     but emit the rebased amount
    /// @param sender Sender of transfer
    /// @param recipient Reciepient of transfer
    /// @param amount Mint amount in USD
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        super._decreaseApproved(sender, msg.sender, amount);
        uint256 transferAmount = applyFactor(amount, factor(), true);
        // amount.mul(factor()).div(BASE)
        super._transfer(sender, recipient, transferAmount, amount);
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Global Enums and Structs
import "../BaseStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// Part: IIdleTokenV3_1

interface IIdleTokenV3_1 {
    // view
    /**
     * IdleToken price calculation not considering fees, in underlying
     *
     * @return price : price in underlying token
     */
    function tokenPrice() external view returns (uint256 price);

    // view
    /**
     * Map which saves avg idleToken minting price per user
     * Used in calculating redeem price
     *
     * @return price : price in underlying token
     */
    function userAvgPrices(address user) external view returns (uint256 price);


    // view
    /**
     * Current fee on interest gained
     *
     * @return fee : fee on interest gained
     */
    function fee() external view returns (uint256 fee);

    /**
     * @return underlying : underlying token address
     */
    function token() external view returns (address underlying);

    /**
     * Get APR of every ILendingProtocol
     *
     * @return addresses : array of token addresses
     * @return aprs : array of aprs (ordered in respect to the `addresses` array)
     */
    function getAPRs() external view returns (address[] memory addresses, uint256[] memory aprs);

    // external
    // We should save the amount one has deposited to calc interests

    /**
     * Used to mint IdleTokens, given an underlying amount (eg. DAI).
     * This method triggers a rebalance of the pools if needed
     * NOTE: User should 'approve' _amount of tokens before calling mintIdleToken
     * NOTE 2: this method can be paused
     *
     * @param _amount : amount of underlying token to be lended
     * @param _skipRebalance : flag for skipping rebalance for lower gas price
     * @param _referral : referral address
     * @return mintedTokens : amount of IdleTokens minted
     */
    function mintIdleToken(uint256 _amount, bool _skipRebalance, address _referral) external returns (uint256 mintedTokens);

    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * This method triggers a rebalance of the pools if needed
     * NOTE: If the contract is paused or iToken price has decreased one can still redeem but no rebalance happens.
     * NOTE 2: If iToken price has decresed one should not redeem (but can do it) otherwise he would capitalize the loss.
     *         Ideally one should wait until the black swan event is terminated
     *
     * @param _amount : amount of IdleTokens to be burned
     * @return redeemedTokens : amount of underlying tokens redeemed
     */
    function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens);
    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * and send interest-bearing tokens (eg. cDAI/iDAI) directly to the user.
     * Underlying (eg. DAI) is not redeemed here.
     *
     * @param _amount : amount of IdleTokens to be burned
     */
    function redeemInterestBearingTokens(uint256 _amount) external;

    /**
     * @return : whether has rebalanced or not
     */
    function rebalance() external returns (bool);


    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);
}

// Part: IUniswapRouter

interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

// Part: IdleReservoir

interface IdleReservoir {
  function drip() external returns (uint256);
}

// File: StrategyIdle.sol

contract StrategyIdle is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 constant public MAX_GOV_TOKENS_LENGTH = 5;

    uint256 constant public FULL_ALLOC = 100000;

    address public uniswapRouterV2;
    address public weth;
    address public idleReservoir;
    address public idleYieldToken;
    address public referral;

    bool public checkVirtualPrice;
    uint256 public lastVirtualPrice;

    bool public checkRedeemedAmount;

    bool public alreadyRedeemed;

    address[] public govTokens;
    mapping(address => address[]) public paths;

    uint256 public redeemThreshold;

    modifier updateVirtualPrice() {
        uint256 currentTokenPrice = _getTokenPrice();
        if (checkVirtualPrice) {
            require(lastVirtualPrice <= currentTokenPrice, "Virtual price is decreasing from the last time, potential losses");
        }
        lastVirtualPrice = currentTokenPrice;
        _;
    }

    constructor(
        address _vault,
        address[] memory _govTokens,
        address _weth,
        address _idleReservoir,
        address _idleYieldToken,
        address _referral,
        address _uniswapRouterV2
    ) public BaseStrategy(_vault) {
        _init(
			_vault,
			_govTokens,
			_weth,
			_idleReservoir,
			_idleYieldToken,
			_referral,
			_uniswapRouterV2
		);
    }

    function _init(
        address _vault,
        address[] memory _govTokens,
        address _weth,
        address _idleReservoir,
        address _idleYieldToken,
        address _referral,
        address _uniswapRouterV2
    ) internal {

        require(address(want) == IIdleTokenV3_1(_idleYieldToken).token(), "Vault want is different from Idle token underlying");

        weth = _weth;
        idleReservoir = _idleReservoir;
        idleYieldToken = _idleYieldToken;
        referral = _referral;

        uniswapRouterV2 = _uniswapRouterV2;
        _setGovTokens(_govTokens);

        checkVirtualPrice = true;
        lastVirtualPrice = IIdleTokenV3_1(_idleYieldToken).tokenPrice();

        alreadyRedeemed = false;

        checkRedeemedAmount = true;

        redeemThreshold = 1;

        want.safeApprove(_idleYieldToken, type(uint256).max);
    }

    function setCheckVirtualPrice(bool _checkVirtualPrice) external onlyOwner {
        checkVirtualPrice = _checkVirtualPrice;
    }

    function setCheckRedeemedAmount(bool _checkRedeemedAmount) external onlyOwner {
        checkRedeemedAmount = _checkRedeemedAmount;
    }

    function enableAllChecks() external onlyOwner {
        checkVirtualPrice = true;
        checkRedeemedAmount = true;
    }

    function disableAllChecks() external onlyOwner {
        checkVirtualPrice = false;
        checkRedeemedAmount = false;
    }

    function setGovTokens(address[] memory _govTokens) external onlyOwner {
        _setGovTokens(_govTokens);
    }

    function setRedeemThreshold(uint256 _redeemThreshold) external onlyOwner {
        redeemThreshold = _redeemThreshold;
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external override view returns (string memory) {
        return string(abi.encodePacked("StrategyIdle", IIdleTokenV3_1(idleYieldToken).symbol()));
    }

    function estimatedTotalAssets() public override view returns (uint256) {
        // TODO: Build a more accurate estimate using the value of all positions in terms of `want`
        return want.balanceOf(address(this))
                   .add(balanceOnIdle()) //TODO: estimate gov tokens value
        ;
    }

    /*
     * Perform any strategy unwinding or other calls necessary to capture the "free return"
     * this strategy has generated since the last time it's core position(s) were adjusted.
     * Examples include unwrapping extra rewards. This call is only used during "normal operation"
     * of a Strategy, and should be optimized to minimize losses as much as possible. This method
     * returns any realized profits and/or realized losses incurred, and should return the total
     * amounts of profits/losses/debt payments (in `want` tokens) for the Vault's accounting
     * (e.g. `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`. It is okay for it
     *       to be less than `_debtOutstanding`, as that should only used as a guide for how much
     *       is left to pay back. Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // Reset, it could have been set during a withdrawal
        if(alreadyRedeemed) {
            alreadyRedeemed = false;
        }

        // Assure IdleController has IDLE tokens during redeem
        IdleReservoir(idleReservoir).drip();

        // Get debt, currentValue (want+idle), only want
        uint256 debt = vault.strategies(address(this)).totalDebt;
        uint256 currentValue = estimatedTotalAssets();
        uint256 wantBalance = balanceOfWant();

        // Calculate total profit w/o farming
        if (debt < currentValue){
            _profit = currentValue.sub(debt);
        } else {
            _loss = debt.sub(currentValue);
        }

        // To withdraw = profit from lending + _debtOutstanding
        uint256 toFree = _debtOutstanding.add(_profit);

        // In the case want is not enough, divest from idle
        if (toFree > wantBalance) {
            // Divest only the missing part = toFree-wantBalance
            toFree = toFree.sub(wantBalance);
            uint256 freedAmount = freeAmount(toFree);

            // loss in the case freedAmount less to be freed
            uint256 withdrawalLoss = freedAmount < toFree ? toFree.sub(freedAmount) : 0;

            // profit recalc
            if (withdrawalLoss < _profit) {
                _profit = _profit.sub(withdrawalLoss);
            } else {
                _loss = _loss.add(withdrawalLoss.sub(_profit));
                _profit = 0;
            }
        }

        // Claim only if not done in the previous liquidate step during redeem
        if (!alreadyRedeemed) {
            IIdleTokenV3_1(idleYieldToken).redeemIdleToken(0);
        } else {
            alreadyRedeemed = false;
        }

        // If we have govTokens, let's convert them!
        // This is done in a separate step since there might have been
        // a migration or an exitPosition
        uint256 liquidated = _liquidateGovTokens();

        // Increase profit by liquidated amount
        _profit = _profit.add(liquidated);

        // Recalculate profit
        wantBalance = want.balanceOf(address(this));

        if (wantBalance < _profit) {
            _profit = wantBalance;
            _debtPayment = 0;
        } else if (wantBalance < _debtPayment.add(_profit)){
            _debtPayment = wantBalance.sub(_profit);
        } else {
            _debtPayment = _debtOutstanding;
        }
    }

    /*
     * Perform any adjustments to the core position(s) of this strategy given
     * what change the Vault made in the "investable capital" available to the
     * strategy. Note that all "free capital" in the strategy after the report
     * was made is available for reinvestment. Also note that this number could
     * be 0, and you should handle that scenario accordingly.
     */
    function adjustPosition(uint256 _debtOutstanding) internal override updateVirtualPrice {
        // TODO: Do something to invest excess `want` tokens (from the Vault) into your positions
        // NOTE: Try to adjust positions so that `_debtOutstanding` can be freed up on *next* harvest (not immediately)

        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        uint256 balanceOfWant = balanceOfWant();
        if (balanceOfWant > _debtOutstanding) {
            IIdleTokenV3_1(idleYieldToken).mintIdleToken(balanceOfWant.sub(_debtOutstanding), true, referral);
        }
    }

    /*
    * Safely free an amount from Idle protocol
    */
    function freeAmount(uint256 _amount)
        internal
        updateVirtualPrice
        returns (uint256 freedAmount)
    {
        uint256 valueToRedeemApprox = _amount.mul(1e18).div(lastVirtualPrice) + 1;
        uint256 valueToRedeem = Math.min(
            valueToRedeemApprox,
            IERC20(idleYieldToken).balanceOf(address(this))
        );

        alreadyRedeemed = true;
        
        uint256 preBalanceOfWant = balanceOfWant();
        IIdleTokenV3_1(idleYieldToken).redeemIdleToken(valueToRedeem);
        freedAmount = balanceOfWant().sub(preBalanceOfWant);

        if (checkRedeemedAmount) {
            // Note: could be equal, prefer >= in case of rounding
            // We just need that is at least the amountToRedeem, not below
            require(
                freedAmount.add(redeemThreshold) >= _amount,
                'Redeemed amount must be >= amountToRedeem');
        }


        return freedAmount;
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amountNeeded`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        updateVirtualPrice
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // TODO: Do stuff here to free up to `_amountNeeded` from all positions back into `want`

        if (balanceOfWant() < _amountNeeded) {
            // Note: potential drift by 1 wei, reduce to max balance in the case approx is rounded up
            uint256 amountToRedeem = _amountNeeded.sub(balanceOfWant());
            freeAmount(amountToRedeem);
        }

        // _liquidatedAmount min(_amountNeeded, balanceOfWant), otw vault accounting breaks
        uint256 balanceOfWant = balanceOfWant();

        if (balanceOfWant >= _amountNeeded) {
            _liquidatedAmount = _amountNeeded;
        } else {
            _liquidatedAmount = balanceOfWant;
            _loss = _amountNeeded.sub(balanceOfWant);
        }
    }

    // NOTE: Can override `tendTrigger` and `harvestTrigger` if necessary

    function harvestTrigger(uint256 callCost) public view override returns (bool) {
        return super.harvestTrigger(ethToWant(callCost));
    }

    function prepareMigration(address _newStrategy) internal override {
        // TODO: Transfer any non-`want` tokens to the new strategy
        // NOTE: `migrate` will automatically forward all `want` in this strategy to the new one

        // this automatically claims the gov tokens in addition to want
        IIdleTokenV3_1(idleYieldToken).redeemIdleToken(IERC20(idleYieldToken).balanceOf(address(this)));

        // Transfer gov tokens to new strategy
        for (uint256 i = 0; i < govTokens.length; i++) {
            IERC20 govToken = IERC20(govTokens[i]);
            govToken.safeTransfer(_newStrategy, govToken.balanceOf(address(this)));
        }
    }

    function protectedTokens()
        internal
        override
        view
        returns (address[] memory)
    {
        address[] memory protected = new address[](1+govTokens.length);

        for (uint256 i = 0; i < govTokens.length; i++) {
            protected[i] = govTokens[i];
        }
        protected[govTokens.length] = idleYieldToken;

        return protected;
    }

    function balanceOnIdle() public view returns (uint256) {
        uint256 idleTokenBalance = IERC20(idleYieldToken).balanceOf(address(this));

        // Always approximate by excess
        return idleTokenBalance > 0 ?
            idleTokenBalance.mul(_getTokenPrice()).div(1e18).add(1) : 0
        ;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function ethToWant(uint256 _amount) public view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(want);
        uint256[] memory amounts = IUniswapRouter(uniswapRouterV2).getAmountsOut(_amount, path);

        return amounts[amounts.length - 1];
    }

    function getTokenPrice() view public returns (uint256) {
        return _getTokenPrice();
    }

    function _liquidateGovTokens() internal returns (uint256 liquidated) {
        for (uint256 i = 0; i < govTokens.length; i++) {
            address govTokenAddress = govTokens[i];
            uint256 balance = IERC20(govTokenAddress).balanceOf(address(this));
            if (balance > 0) {
                address[] memory path = paths[govTokenAddress];
                uint[] memory amounts = IUniswapRouter(uniswapRouterV2).swapExactTokensForTokens(
                    balance, 1, path, address(this), now.add(1800)
                );

                // leverage uniswap returns want amount
                liquidated = liquidated.add(amounts[path.length-1]);
            }
        }
    }

    function _setGovTokens(address[] memory _govTokens) internal {
        require(_govTokens.length <= MAX_GOV_TOKENS_LENGTH , 'GovTokens too long');

        // Disallow uniswap on old tokens
        for (uint256 i = 0; i < govTokens.length; i++) {
            address govTokenAddress = govTokens[i];
            IERC20(govTokenAddress).safeTransfer(uniswapRouterV2, 0);
            delete paths[govTokenAddress];
        }

        // Set new gov tokens
        govTokens = _govTokens;

        // Allow uniswap on new tokens
        for (uint256 i = 0; i < _govTokens.length; i++) {
            address govTokenAddress = _govTokens[i];
            IERC20(govTokenAddress).safeApprove(uniswapRouterV2, type(uint256).max);

            address[] memory _path = new address[](3);
            _path[0] = address(govTokenAddress);
            _path[1] = weth;
            _path[2] = address(want);

            paths[_govTokens[i]] = _path;
        }
    }

    function _getTokenPrice() view internal returns (uint256) {
        /*
         *  As per https://github.com/Idle-Labs/idle-contracts/blob/ad0f18fef670ea6a4030fe600f64ece3d3ac2202/contracts/IdleTokenGovernance.sol#L878-L900
         *
         *  Price on minting is currentPrice
         *  Price on redeem must consider the fee
         *
         *  Below the implementation of the following redeemPrice formula
         *
         *  redeemPrice := underlyingAmount/idleTokenAmount
         *
         *  redeemPrice = currentPrice * (1 - scaledFee * ΔP%)
         *
         *  where:
         *  - scaledFee   := fee/FULL_ALLOC
         *  - ΔP% := 0 when currentPrice < userAvgPrice (no gain) and (currentPrice-userAvgPrice)/currentPrice
         *
         *  n.b: gain := idleTokenAmount * ΔP% * currentPrice
         */

        IIdleTokenV3_1 iyt = IIdleTokenV3_1(idleYieldToken);

        uint256 userAvgPrice = iyt.userAvgPrices(address(this));
        uint256 currentPrice = iyt.tokenPrice();

        uint256 tokenPrice;

        // When no deposits userAvgPrice is 0 equiv currentPrice
        // and in the case of issues
        if (userAvgPrice == 0 || currentPrice < userAvgPrice) {
            tokenPrice = currentPrice;
        } else {
            uint256 fee = iyt.fee();

            tokenPrice = ((currentPrice.mul(FULL_ALLOC))
                .sub(
                    fee.mul(
                         currentPrice.sub(userAvgPrice)
                    )
                )).div(FULL_ALLOC);
        }

        return tokenPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {BaseStrategy} from "../BaseStrategy.sol";

import "contracts/interfaces/GenericLender/IGenericLender.sol";
import "contracts/interfaces/WantToEthOracle/IWantToEth.sol";

interface IUni {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

/********************
 *
 *   A lender optimisation strategy for any erc20 asset
 *   https://github.com/Grandthrax/yearnV2-generic-lender-strat
 *   v0.3.1
 *
 *   This strategy works by taking plugins designed for standard lending platforms
 *   It automatically chooses the best yield generating platform and adjusts accordingly
 *   The adjustment is sub optimal so there is an additional option to manually set position
 *
 ********************* */
contract YearnGenericLender is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public withdrawalThreshold = 1e16;
    uint256 public constant SECONDSPERYEAR = 31556952;

    IGenericLender[] public lenders;
    bool public externalOracle = false;
    address public wantToEthOracle;

    event Cloned(address indexed clone);

    constructor(address _vault) public BaseStrategy(_vault) {
        debtThreshold = 100 * 1e18;
    }

    function clone(address _vault) external returns (address newStrategy) {
        newStrategy = this.clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external returns (address newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        YearnGenericLender(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

        emit Cloned(newStrategy);
    }

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function setWithdrawalThreshold(uint256 _threshold) external onlyAuthorized {
        withdrawalThreshold = _threshold;
    }

    function setPriceOracle(address _oracle) external onlyAuthorized {
        wantToEthOracle = _oracle;
    }

    function name() external view override returns (string memory) {
        return "StrategyLenderYieldOptimiser";
    }

    //management functions
    //add lenders for the strategy to choose between
    // only governance to stop strategist adding dodgy lender
    function addLender(address a) public onlyOwner {
        IGenericLender n = IGenericLender(a);
        require(n.strategy() == address(this), "Undocked Lender");

        for (uint256 i = 0; i < lenders.length; i++) {
            require(a != address(lenders[i]), "Already Added");
        }
        lenders.push(n);
    }

    //but strategist can remove for safety
    function safeRemoveLender(address a) public onlyAuthorized {
        _removeLender(a, false);
    }

    function forceRemoveLender(address a) public onlyAuthorized {
        _removeLender(a, true);
    }

    //force removes the lender even if it still has a balance
    function _removeLender(address a, bool force) internal {
        for (uint256 i = 0; i < lenders.length; i++) {
            if (a == address(lenders[i])) {
                bool allWithdrawn = lenders[i].withdrawAll();

                if (!force) {
                    require(allWithdrawn, "WITHDRAW FAILED");
                }

                //put the last index here
                //remove last index
                if (i != lenders.length - 1) {
                    lenders[i] = lenders[lenders.length - 1];
                }

                //pop shortens array by 1 thereby deleting the last index
                lenders.pop();

                //if balance to spend we might as well put it into the best lender
                if (want.balanceOf(address(this)) > 0) {
                    adjustPosition(0);
                }
                return;
            }
        }
        require(false, "NOT LENDER");
    }

    //we could make this more gas efficient but it is only used by a view function
    struct lendStatus {
        string name;
        uint256 assets;
        uint256 rate;
        address add;
    }

    //Returns the status of all lenders attached the strategy
    function lendStatuses() public view returns (lendStatus[] memory) {
        lendStatus[] memory statuses = new lendStatus[](lenders.length);
        for (uint256 i = 0; i < lenders.length; i++) {
            lendStatus memory s;
            s.name = lenders[i].lenderName();
            s.add = address(lenders[i]);
            s.assets = lenders[i].nav();
            s.rate = lenders[i].apr();
            statuses[i] = s;
        }

        return statuses;
    }

    // lent assets plus loose assets
    function estimatedTotalAssets() public view override returns (uint256) {
        uint256 nav = lentTotalAssets();
        nav = nav.add(want.balanceOf(address(this)));

        return nav;
    }

    function numLenders() public view returns (uint256) {
        return lenders.length;
    }

    //the weighted apr of all lenders. sum(nav * apr)/totalNav
    function estimatedAPR() public view returns (uint256) {
        uint256 bal = estimatedTotalAssets();
        if (bal == 0) {
            return 0;
        }

        uint256 weightedAPR = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            weightedAPR = weightedAPR.add(lenders[i].weightedApr());
        }

        return weightedAPR.div(bal);
    }

    //Estimates the impact on APR if we add more money. It does not take into account adjusting position
    function _estimateDebtLimitIncrease(uint256 change) internal view returns (uint256) {
        uint256 highestAPR = 0;
        uint256 aprChoice = 0;
        uint256 assets = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if (apr > highestAPR) {
                aprChoice = i;
                highestAPR = apr;
                assets = lenders[i].nav();
            }
        }

        uint256 weightedAPR = highestAPR.mul(assets.add(change));

        for (uint256 i = 0; i < lenders.length; i++) {
            if (i != aprChoice) {
                weightedAPR = weightedAPR.add(lenders[i].weightedApr());
            }
        }

        uint256 bal = estimatedTotalAssets().add(change);

        return weightedAPR.div(bal);
    }

    //Estimates debt limit decrease. It is not accurate and should only be used for very broad decision making
    function _estimateDebtLimitDecrease(uint256 change) internal view returns (uint256) {
        uint256 lowestApr = uint256(-1);
        uint256 aprChoice = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if (apr < lowestApr) {
                aprChoice = i;
                lowestApr = apr;
            }
        }

        uint256 weightedAPR = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            if (i != aprChoice) {
                weightedAPR = weightedAPR.add(lenders[i].weightedApr());
            } else {
                uint256 asset = lenders[i].nav();
                if (asset < change) {
                    //simplistic. not accurate
                    change = asset;
                }
                weightedAPR = weightedAPR.add(lowestApr.mul(change));
            }
        }
        uint256 bal = estimatedTotalAssets().add(change);
        return weightedAPR.div(bal);
    }

    //estimates highest and lowest apr lenders. Public for debugging purposes but not much use to general public
    function estimateAdjustPosition()
        public
        view
        returns (
            uint256 _lowest,
            uint256 _lowestApr,
            uint256 _highest,
            uint256 _potential
        )
    {
        //all loose assets are to be invested
        uint256 looseAssets = want.balanceOf(address(this));

        // our simple algo
        // get the lowest apr strat
        // cycle through and see who could take its funds plus want for the highest apr
        _lowestApr = uint256(-1);
        _lowest = 0;
        uint256 lowestNav = 0;
        for (uint256 i = 0; i < lenders.length; i++) {
            if (lenders[i].hasAssets()) {
                uint256 apr = lenders[i].apr();
                if (apr < _lowestApr) {
                    _lowestApr = apr;
                    _lowest = i;
                    lowestNav = lenders[i].nav();
                }
            }
        }

        uint256 toAdd = lowestNav.add(looseAssets);

        uint256 highestApr = 0;
        _highest = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr;
            apr = lenders[i].aprAfterDeposit(looseAssets);

            if (apr > highestApr) {
                highestApr = apr;
                _highest = i;
            }
        }

        //if we can improve apr by withdrawing we do so
        _potential = lenders[_highest].aprAfterDeposit(toAdd);
    }

    //gives estiomate of future APR with a change of debt limit. Useful for governance to decide debt limits
    function estimatedFutureAPR(uint256 newDebtLimit) public view returns (uint256) {
        uint256 oldDebtLimit = vault.strategies(address(this)).totalDebt;
        uint256 change;
        if (oldDebtLimit < newDebtLimit) {
            change = newDebtLimit - oldDebtLimit;
            return _estimateDebtLimitIncrease(change);
        } else {
            change = oldDebtLimit - newDebtLimit;
            return _estimateDebtLimitDecrease(change);
        }
    }

    //cycle all lenders and collect balances
    function lentTotalAssets() public view returns (uint256) {
        uint256 nav = 0;
        for (uint256 i = 0; i < lenders.length; i++) {
            nav = nav.add(lenders[i].nav());
        }
        return nav;
    }

    // we need to free up profit plus _debtOutstanding.
    // If _debtOutstanding is more than we can free we get as much as possible
    // should be no way for there to be a loss. we hope...
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _profit = 0;
        _loss = 0; //for clarity
        _debtPayment = _debtOutstanding;

        uint256 lentAssets = lentTotalAssets();

        uint256 looseAssets = want.balanceOf(address(this));

        uint256 total = looseAssets.add(lentAssets);

        if (lentAssets == 0) {
            //no position to harvest or profit to report
            if (_debtPayment > looseAssets) {
                //we can only return looseAssets
                _debtPayment = looseAssets;
            }

            return (_profit, _loss, _debtPayment);
        }

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if (total > debt) {
            _profit = total - debt;

            uint256 amountToFree = _profit.add(_debtPayment);
            //we need to add outstanding to our profit
            //dont need to do logic if there is nothiing to free
            if (amountToFree > 0 && looseAssets < amountToFree) {
                //withdraw what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));

                //if we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _profit, _debtPayment);
                    }
                }
            }
        } else {
            //serious loss should never happen but if it does lets record it accurately
            _loss = debt - total;
            uint256 amountToFree = _loss.add(_debtPayment);

            if (amountToFree > 0 && looseAssets < amountToFree) {
                //withdraw what we can withdraw

                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));

                //if we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_loss > newLoose) {
                        _loss = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _loss, _debtPayment);
                    }
                }
            }
        }
    }

    /*
     * Key logic.
     *   The algorithm moves assets from lowest return to highest
     *   like a very slow idiots bubble sort
     *   we ignore debt outstanding for an easy life
     */
    function adjustPosition(uint256 _debtOutstanding) internal override {
        _debtOutstanding; //ignored. we handle it in prepare return
        //emergency exit is dealt with at beginning of harvest
        if (emergencyExit) {
            return;
        }

        //we just keep all money in want if we dont have any lenders
        if (lenders.length == 0) {
            return;
        }

        (uint256 lowest, uint256 lowestApr, uint256 highest, uint256 potential) = estimateAdjustPosition();

        if (potential > lowestApr) {
            //apr should go down after deposit so wont be withdrawing from self
            lenders[lowest].withdrawAll();
        }

        uint256 bal = want.balanceOf(address(this));
        if (bal > 0) {
            want.safeTransfer(address(lenders[highest]), bal);
            lenders[highest].deposit();
        }
    }

    struct lenderRatio {
        address lender;
        //share x 1000
        uint16 share;
    }

    //share must add up to 1000. 500 means 50% etc
    function manualAllocation(lenderRatio[] memory _newPositions) public onlyAuthorized {
        uint256 share = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            lenders[i].withdrawAll();
        }

        uint256 assets = want.balanceOf(address(this));

        for (uint256 i = 0; i < _newPositions.length; i++) {
            bool found = false;

            //might be annoying and expensive to do this second loop but worth it for safety
            for (uint256 j = 0; j < lenders.length; j++) {
                if (address(lenders[j]) == _newPositions[i].lender) {
                    found = true;
                }
            }
            require(found, "NOT LENDER");

            share = share.add(_newPositions[i].share);
            uint256 toSend = assets.mul(_newPositions[i].share).div(1000);
            want.safeTransfer(_newPositions[i].lender, toSend);
            IGenericLender(_newPositions[i].lender).deposit();
        }

        require(share == 1000, "SHARE!=1000");
    }

    //cycle through withdrawing from worst rate first
    function _withdrawSome(uint256 _amount) internal returns (uint256 amountWithdrawn) {
        if (lenders.length == 0) {
            return 0;
        }

        //dont withdraw dust
        if (_amount < withdrawalThreshold) {
            return 0;
        }

        amountWithdrawn = 0;
        //most situations this will only run once. Only big withdrawals will be a gas guzzler
        uint256 j = 0;
        while (amountWithdrawn < _amount) {
            uint256 lowestApr = uint256(-1);
            uint256 lowest = 0;
            for (uint256 i = 0; i < lenders.length; i++) {
                if (lenders[i].hasAssets()) {
                    uint256 apr = lenders[i].apr();
                    if (apr < lowestApr) {
                        lowestApr = apr;
                        lowest = i;
                    }
                }
            }
            if (!lenders[lowest].hasAssets()) {
                return amountWithdrawn;
            }
            amountWithdrawn = amountWithdrawn.add(lenders[lowest].withdraw(_amount - amountWithdrawn));
            j++;
            //dont want infinite loop
            if (j >= 6) {
                return amountWithdrawn;
            }
        }
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amountNeeded`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed, uint256 _loss) {
        uint256 _balance = want.balanceOf(address(this));

        if (_balance >= _amountNeeded) {
            //if we don't set reserve here withdrawer will be sent our full balance
            return (_amountNeeded, 0);
        } else {
            uint256 received = _withdrawSome(_amountNeeded - _balance).add(_balance);
            if (received >= _amountNeeded) {
                return (_amountNeeded, 0);
            } else {
                return (received, 0);
            }
        }
    }

    function harvestTrigger(uint256 callCost) public view override returns (bool) {
        uint256 wantCallCost = _callCostToWant(callCost);
        return super.harvestTrigger(wantCallCost);
    }

    function ethToWant(uint256 _amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(want);

        uint256[] memory amounts = IUni(uniswapRouter).getAmountsOut(_amount, path);

        return amounts[amounts.length - 1];
    }

    function _callCostToWant(uint256 callCost) internal view returns (uint256) {
        uint256 wantCallCost;

        //three situations
        //1 currency is eth so no change.
        //2 we use uniswap swap price
        //3 we use external oracle
        if (address(want) == weth) {
            wantCallCost = callCost;
        } else if (wantToEthOracle == address(0)) {
            wantCallCost = ethToWant(callCost);
        } else {
            wantCallCost = IWantToEth(wantToEthOracle).ethToWant(callCost);
        }

        return wantCallCost;
    }

    function tendTrigger(uint256 callCost) public view override returns (bool) {
        // make sure to call tendtrigger with same callcost as harvestTrigger
        if (harvestTrigger(callCost)) {
            return false;
        }

        //now let's check if there is better apr somewhere else.
        //If there is and profit potential is worth changing then lets do it
        (uint256 lowest, uint256 lowestApr, , uint256 potential) = estimateAdjustPosition();

        //if protential > lowestApr it means we are changing horses
        if (potential > lowestApr) {
            uint256 nav = lenders[lowest].nav();

            //To calculate our potential profit increase we work out how much extra
            //we would make in a typical harvest interlude. That is maxReportingDelay
            //then we see if the extra profit is worth more than the gas cost * profitFactor

            //safe math not needed here
            //apr is scaled by 1e18 so we downscale here
            uint256 profitIncrease = (nav.mul(potential) - nav.mul(lowestApr)).div(1e18).mul(maxReportDelay).div(SECONDSPERYEAR);

            uint256 wantCallCost = _callCostToWant(callCost);

            return (wantCallCost.mul(profitFactor) < profitIncrease);
        }
    }

    /*
     * revert if we can't withdraw full balance
     */
    function prepareMigration(address _newStrategy) internal override {
        uint256 outstanding = vault.strategies(address(this)).totalDebt;
        (, uint256 loss, uint256 wantBalance) = prepareReturn(outstanding);
    }

    function protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](1);
        protected[0] = address(want);
        return protected;
    }
    //predicts our profit at next report
    function expectedReturn() public view returns (uint256) {
        uint256 estimateAssets = estimatedTotalAssets();

        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets - debt;
        }
    }
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IGenericLender {
    function lenderName() external view returns (string memory);

    function nav() external view returns (uint256);

    function strategy() external view returns (address);

    function apr() external view returns (uint256);

    function weightedApr() external view returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);

    function emergencyWithdraw(uint256 amount) external;

    function deposit() external;

    function withdrawAll() external returns (bool);

    function hasAssets() external view returns (bool);

    function aprAfterDeposit(uint256 amount) external view returns (uint256);

    function setDust(uint256 _dust) external;

    function sweep(address _token) external;
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWantToEth {
    function wantToEth(uint256 input) external view returns (uint256);

    function ethToWant(uint256 input) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import {VaultAPI} from "../../BaseStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "contracts/interfaces/GenericLender/IGenericLender.sol";

interface IBaseStrategy {
    function apiVersion() external pure returns (string memory);

    function name() external pure returns (string memory);

    function vault() external view returns (address);

    function keeper() external view returns (address);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function strategist() external view returns (address);
}

abstract contract GenericLenderBase is IGenericLender {
    using SafeERC20 for IERC20;
    VaultAPI public vault;
    address public override strategy;
    IERC20 public want;
    string public override lenderName;
    uint256 public dust;

    event Cloned(address indexed clone);

    constructor(address _strategy, string memory _name) public {
        _initialize(_strategy, _name);
    }

    function _initialize(address _strategy, string memory _name) internal {
        require(address(strategy) == address(0), "Lender already initialized");

        strategy = _strategy;
        vault = VaultAPI(IBaseStrategy(strategy).vault());
        want = IERC20(vault.token());
        lenderName = _name;
        dust = 10000;

        want.safeApprove(_strategy, uint256(-1));
    }

    function initialize(address _strategy, string memory _name) external virtual {
        _initialize(_strategy, _name);
    }

    function _clone(address _strategy, string memory _name) internal returns (address newLender) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newLender := create(0, clone_code, 0x37)
        }

        GenericLenderBase(newLender).initialize(_strategy, _name);
        emit Cloned(newLender);
    }

    function setDust(uint256 _dust) external virtual override management {
        dust = _dust;
    }

    function sweep(address _token) external virtual override management {
        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(vault.governance(), IERC20(_token).balanceOf(address(this)));
    }

    function protectedTokens() internal view virtual returns (address[] memory);

    //make sure to use
    modifier management() {
        require(
            msg.sender == address(strategy) || msg.sender == vault.governance() || msg.sender == IBaseStrategy(strategy).strategist(),
            "!management"
        );
        _;
    }
}

// SPDX-License-Identifier: AGPLv3

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../BaseStrategy.sol";

import "../../../../interfaces/UniSwap/IUni.sol";
import "../../../../interfaces/IHarvest.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

/// @notice Harvest finance stablecoin strategy
///     Deposits and stakes stablecoins into Harvest finance - this strategy
///     generates yield through the underlying protocol + the selling of farm tokens
///     ########################################
///     Strategy breakdown
///     ########################################
///
///     Want: stablecoin 
///     Additional tokens: fToken, Farm
///     Exposures: 
///         Protocol: Harvest Finance, Compound, Idle finance
///         stablecoins: want
///
///     Strategy logic:
///         Vault => Loans out stablecoin to strategy
///             strategy => invest stablecoin into harvset finance fVault
///                      <= get fToken in return
///             strategy => stakes fToken in fToken staking contract
///                      <= get fToken stake shares in return
///                      <= get Farm tokens in return for staking
///
///         Harvest: Report back gains/losses to vault, sells Farm tokens:
contract StrategyHarvestStable is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address[] public farmPath;
    IHarvest public harvestStrat;
    IStake public harvestStake;
    IERC20 public farm =IERC20(address(0xa0246c9032bC3A600820415aE600c6388619A14D));
    IERC20 public weth = IERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
   
    constructor(address _vault, address _harvestStake) public BaseStrategy(_vault) {
        profitFactor = 1000;
        debtThreshold = 1_000_000 *1e18;
        harvestStake = IStake(_harvestStake);
        address _harvestStrat = harvestStake.lpToken();
        harvestStrat = IHarvest(_harvestStrat);
        require(address(want) == harvestStrat.underlying(), "Wrong farm");
        farmPath = new address[](3);
        farmPath[0] = address(farm);
        farmPath[1] = address(weth);
        farmPath[2] = address(want);

        want.safeApprove(_harvestStrat, type(uint256).max);
        IERC20(address(harvestStrat)).safeApprove(_harvestStake, type(uint256).max);
        farm.safeApprove(uniswapRouter, uint(-1));
    }

    function name() external override view returns (string memory) {
        return string(abi.encodePacked("StrategyHarvest", harvestStrat.symbol()));
    }

    /// @notice Get the total assets of this strategy
    /// @return Total assets in want this strategy has invested
    function estimatedTotalAssets() public override view returns (uint256) {
        return want.balanceOf(address(this))
            .add(convertToUnderlying(harvestStake.balanceOf(address(this))));
    }

    /// @notice Convert fTokens to want
    /// @param amountOfTokens Amount to convert
    function convertToUnderlying(uint256 amountOfTokens) public view returns (uint256) {
        return amountOfTokens > 0 ? amountOfTokens
            .mul(harvestStrat.getPricePerFullShare())
            .div(10**harvestStrat.decimals()) : 0;
    }

    /// @notice Check if it's worth harvesting the strategy
    /// @param callCost The keeper's estimated cast cost to call `harvest()`
    /// @return true True if gains outweigh cost of calling harvest
    function harvestTrigger(uint256 callCost) public override view returns (bool) {
        uint256 wantCallCost = ethToWant(callCost);
        uint estimatedFarm = harvestStake.earned(address(this));
        if (estimatedFarm > 0) {
            wantCallCost = wantCallCost.sub(farmToWant(estimatedFarm));
        }
        return super.harvestTrigger(wantCallCost);
    }

    /// @notice Convert want to fTokens
    /// @param amountOfUnderlying Amount to convert
    function convertFromUnderlying(uint256 amountOfUnderlying) public view returns (uint256 balance){
        if (amountOfUnderlying == 0) {
            balance = 0;
        } else {
            balance = amountOfUnderlying
                .mul(10**harvestStrat.decimals())
                .div(harvestStrat.getPricePerFullShare());
        }
    }

    /// @notice Expected returns from strategy (gains from protocols and tokens)
    function expectedReturn() public view returns (uint256)
    {
        uint256 estimateAssets = estimatedTotalAssets();
        uint estimatedFarm = harvestStake.earned(address(this));
        if (estimatedFarm > 0) {
            estimateAssets = estimateAssets.add(farmToWant(estimatedFarm));
        }
        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets - debt;
        }
    }

    /// @notice Claim any available Farm rewards
    function claimFarm() internal {
        harvestStake.getReward();

        IUni(uniswapRouter).swapExactTokensForTokens(
            farm.balanceOf(address(this)),
            uint256(0),
            farmPath,
            address(this),
            now
        );
    }

    /// @notice This strategy doesnt realise profit outside of APY from the vault.
    ///     This method is only used to pull out debt if debt ratio has changed 
    /// @param _debtOutstanding debt to pay back.
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _debtPayment = _debtOutstanding;
        uint256 lentAssets = convertToUnderlying(harvestStake.balanceOf(address(this)));
        if (harvestStake.earned(address(this)) > 0 ) {
            claimFarm();
        }
        uint256 looseAssets = want.balanceOf(address(this));
        uint256 total = looseAssets.add(lentAssets);
        if (lentAssets == 0) {
            // No position to harvest or profit to report
            if (_debtPayment > looseAssets) {
                // We can only return looseAssets
                _debtPayment = looseAssets;
            }
            return (_profit, _loss, _debtPayment);
        }
        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (total > debt) {
            _profit = total - debt;
            uint256 amountToFree = _profit.add(_debtPayment);
            if (amountToFree > 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));
                // If we dont have enough money adjust _debtOutstanding and only change profit if needed
                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _profit, _debtPayment);
                    }
                }
            }
        } else {
            // Serious - A loss should never happen but if it does lets record it accurately
            _loss = debt - total;
            uint256 amountToFree = _debtPayment;
            if (amountToFree > 0 && looseAssets < amountToFree) {
                // Withdraw what we can withdraw
                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));
                if (newLoose < amountToFree) {
                    _debtPayment = newLoose;
                }
            }
        }
    }

    /// @notice Used to invest any assets sent from the vault during report
    /// @param _debtOutstanding Should always be 0 at this point
    function adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 _toInvest = want.balanceOf(address(this));
        if (_toInvest > 0 ) {
            harvestStrat.deposit(_toInvest);
            harvestStake.stake(harvestStrat.balanceOf(address(this)));
        }
    }

    /// @notice Withdraw amount of want from fStake/fToken 
    /// @param _amount Expected amount to withdraw
    function _withdrawSome(uint256 _amount) internal returns (uint256) {

        uint256 amountInFtokens = convertFromUnderlying(_amount);
        uint256 stakeBalance = harvestStake.balanceOf(address(this));

        uint256 balanceBefore = want.balanceOf(address(this));

        if(amountInFtokens < 2){
            return 0;
        }
        if (amountInFtokens > stakeBalance) {
            // Can't withdraw more than we own
            amountInFtokens = stakeBalance;
        }
        // Not state changing but OK because of previous call
        uint256 liquidityInFTokens = harvestStrat.balanceOf(address(harvestStake));

        if (liquidityInFTokens > 2) {
            if (amountInFtokens <= liquidityInFTokens) {
                // We can take all
                harvestStake.withdraw(amountInFtokens);
                harvestStrat.withdraw(amountInFtokens);
            } else {
                // Take all we can
                harvestStake.withdraw(liquidityInFTokens);
                harvestStrat.withdraw(liquidityInFTokens);
            }
        }
        uint256 newBalance = want.balanceOf(address(this));
        return newBalance.sub(balanceBefore);
    }

    /// @notice Used when emergency stop has been called to empty out strategy
    /// @param _amountNeeded Expected amount to withdraw
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        _loss; // Should not be able to make a loss here
        uint256 looseAssets = want.balanceOf(address(this));
        if(looseAssets < _amountNeeded){
            _withdrawSome(_amountNeeded - looseAssets);
        }
        _liquidatedAmount = Math.min(_amountNeeded, want.balanceOf(address(this)));
    }

    /// @notice Convert farm tokens to want
    /// @param amount Amount to convert
    function farmToWant(uint256 amount) internal view returns (uint256) {
        uint256[] memory amounts = IUni(uniswapRouter).getAmountsOut(amount, farmPath);
        return amounts[amounts.length - 1];
    }

    /// @notice Convert ETH to want, used for harvest trigger
    /// @param amount Amount to convert
    function ethToWant(uint256 amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(want);

        uint256[] memory amounts = IUni(uniswapRouter).getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }

    function prepareMigration(address _newStrategy) internal override {
        uint256 remFarm = harvestStake.earned(address(this));
        if (remFarm > 0) {
            claimFarm();
        }

        harvestStake.exit();
        IERC20(address(harvestStrat)).safeTransfer(_newStrategy, harvestStrat.balanceOf(address(this)));
    }

    function protectedTokens()
        internal
        override
        view
        returns (address[] memory)
    {
        address[] memory protected = new address[](1);
          protected[0] = address(harvestStrat);
          protected[1] = address(harvestStake);
          return protected;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.6.12;

interface IUni{
    function getAmountsOut(
        uint256 amountIn, 
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

interface IHarvest {
    function deposit(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function withdraw(uint256 numberOfShares) external;

    function withdrawAll() external;

    function approve(address spender, uint256 amount) external;

    function underlying() external view returns (address);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

interface IStake {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function lpToken() external view returns (address);

    function stake(uint256 amount) external;

    function getReward() external;

    function withdraw(uint256 amount) external;

    function exit() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../BaseStrategy.sol";

import "contracts/interfaces/DyDx/DydxFlashLoanBase.sol";
import "contracts/interfaces/DyDx/ICallee.sol";
import "contracts/interfaces/Aave/ILendingPoolAddressesProvider.sol";
import "contracts/interfaces/Aave/ILendingPool.sol";
import "contracts/interfaces/Compound/CErc20I.sol";
import "contracts/interfaces/Compound/ComptrollerI.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


interface IUni{
    function getAmountsOut(
        uint256 amountIn, 
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/********************
 *
 *   A lender optimisation strategy for any erc20 asset
 *   https://github.com/Grandthrax/yearnV2-generic-lender-strat
 *   v0.2.2
 *
 ********************* */

contract GenericLevComp is BaseStrategy, DydxFlashloanBase, ICallee {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // @notice emitted when trying to do Flash Loan. flashLoan address is 0x00 when no flash loan used
    event Leverage(uint256 amountRequested, uint256 amountGiven, bool deficit, address flashLoan);

    //Flash Loan Providers
    address private constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address private constant AAVE_LENDING = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    ILendingPoolAddressesProvider public addressesProvider;

    // Comptroller address for compound.finance
    ComptrollerI public constant compound = ComptrollerI(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    //Only three tokens we use
    address public constant comp = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    CErc20I public cToken;
    //address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    //Operating variables
    uint256 public collateralTarget = 0.73 ether; // 73%
    uint256 public blocksToLiquidationDangerZone = 46500; // 7 days =  60*60*24*7/13

    uint256 public minWant = 0; //Only lend if we have enough want to be worth it. Can be set to non-zero
    uint256 public minCompToSell = 0.1 ether; //used both as the threshold to sell but also as a trigger for harvest

    //To deactivate flash loan provider if needed
    bool public DyDxActive = true;
    bool public AaveActive = false;

    uint256 public dyDxMarketId;

    constructor(address _vault, address _cToken) public BaseStrategy(_vault) {
        cToken = CErc20I(address(_cToken));

        //pre-set approvals
        IERC20(comp).safeApprove(uniswapRouter, uint256(-1));
        want.safeApprove(address(cToken), uint256(-1));
        want.safeApprove(SOLO, uint256(-1));

        // You can set these parameters on deployment to whatever you want
        maxReportDelay = 86400; // once per 24 hours
        profitFactor = 100; // multiple before triggering harvest

        _setMarketIdFromTokenAddress();

        addressesProvider = ILendingPoolAddressesProvider(AAVE_LENDING);

        //we do this horrible thing because you can't compare strings in solidity
        require(keccak256(bytes(apiVersion())) == keccak256(bytes(VaultAPI(_vault).apiVersion())), "WRONG VERSION");
    }

    function name() external override view returns (string memory){
        return "StrategyGenericLevCompFarm";
    }

    /*
     * Control Functions
     */
    function setDyDx(bool _dydx) external management {
        DyDxActive = _dydx;
    }

    function setAave(bool _ave) external management {
        AaveActive = _ave;
    }

    function setMinCompToSell(uint256 _minCompToSell) external management {
        minCompToSell = _minCompToSell;
    }

    function setMinWant(uint256 _minWant) external management {
        minWant = _minWant;
    }

    function updateMarketId() external management {
        _setMarketIdFromTokenAddress();
    }

    function setCollateralTarget(uint256 _collateralTarget) external management {
        (, uint256 collateralFactorMantissa, ) = compound.markets(address(cToken));
        require(collateralFactorMantissa > _collateralTarget, "!dangerous collateral");
        collateralTarget = _collateralTarget;
    }

    /*
     * Base External Facing Functions
     */
    /*
     * An accurate estimate for the total amount of assets (principle + return)
     * that this strategy is currently managing, denominated in terms of want tokens.
     */
    function estimatedTotalAssets() public override view returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();

        uint256 _claimableComp = predictCompAccrued();
        uint256 currentComp = IERC20(comp).balanceOf(address(this));

        // Use touch price. it doesnt matter if we are wrong as this is not used for decision making
        uint256 estimatedWant =  priceCheck(comp, address(want),_claimableComp.add(currentComp));
        uint256 conservativeWant = estimatedWant.mul(9).div(10); //10% pessimist

        return want.balanceOf(address(this)).add(deposits).add(conservativeWant).sub(borrows);
    }

    //predicts our profit at next report
    function expectedReturn() public view returns (uint256) {
        uint256 estimateAssets = estimatedTotalAssets();

        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets - debt;
        }
    }

    /*
     * Provide a signal to the keeper that `tend()` should be called.
     * (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `harvestTrigger` should never return `true` at the same time.
     * tendTrigger should be called with same gasCost as harvestTrigger
     */
    function tendTrigger(uint256 gasCost) public override view returns (bool) {
        if (harvestTrigger(gasCost)) {
            //harvest takes priority
            return false;
        }

        if (getblocksUntilLiquidation() <= blocksToLiquidationDangerZone) {
            return true;
        }
    }

    /*
     * Provide a signal to the keeper that `harvest()` should be called.
     * gasCost is expected_gas_use * gas_price
     * (keepers are always reimbursed by yEarn)
     *
     * NOTE: this call and `tendTrigger` should never return `true` at the same time.
     */
    function harvestTrigger(uint256 gasCost) public override view returns (bool) {
        
        StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if strategy is not activated
        if (params.activation == 0) return false;


        uint256 wantGasCost = priceCheck(weth, address(want), gasCost);
        uint256 compGasCost = priceCheck(weth, comp, gasCost);

        // after enough comp has accrued we want the bot to run
        uint256 _claimableComp = predictCompAccrued();

        if (_claimableComp > minCompToSell) {
            // check value of COMP in wei
            if ( _claimableComp.add(IERC20(comp).balanceOf(address(this))) > compGasCost.mul(profitFactor)) {
                return true;
            }
        }


        // Should trigger if hadn't been called in a while
        if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

        //check if vault wants lots of money back
        // dont return dust
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > profitFactor.mul(wantGasCost)) return true;

        // Check for profits and losses
        uint256 total = estimatedTotalAssets();

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

        uint256 credit = vault.creditAvailable().add(profit);
        return (profitFactor.mul(wantGasCost) < credit);
    }

    //WARNING. manipulatable and simple routing. Only use for safe functions
    function priceCheck(address start, address end, uint256 _amount) public view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        address[] memory path;
        if(start == weth){
            path = new address[](2);
            path[0] = weth;
            path[1] = end;
        }else{
            path = new address[](3);
            path[0] = start; 
            path[1] = weth; 
            path[2] = end;
        }
 
        uint256[] memory amounts = IUni(uniswapRouter).getAmountsOut(_amount, path);

        return amounts[amounts.length - 1];
    }

    /*****************
     * Public non-base function
     ******************/

    //Calculate how many blocks until we are in liquidation based on current interest rates
    //WARNING does not include compounding so the estimate becomes more innacurate the further ahead we look
    //equation. Compound doesn't include compounding for most blocks
    //((deposits*colateralThreshold - borrows) / (borrows*borrowrate - deposits*colateralThreshold*interestrate));
    function getblocksUntilLiquidation() public view returns (uint256) {
        (, uint256 collateralFactorMantissa, ) = compound.markets(address(cToken));

        (uint256 deposits, uint256 borrows) = getCurrentPosition();

        uint256 borrrowRate = cToken.borrowRatePerBlock();

        uint256 supplyRate = cToken.supplyRatePerBlock();

        uint256 collateralisedDeposit1 = deposits.mul(collateralFactorMantissa).div(1e18);
        uint256 collateralisedDeposit = collateralisedDeposit1;

        uint256 denom1 = borrows.mul(borrrowRate);
        uint256 denom2 = collateralisedDeposit.mul(supplyRate);

        if (denom2 >= denom1) {
            return uint256(-1);
        } else {
            uint256 numer = collateralisedDeposit.sub(borrows);
            uint256 denom = denom1 - denom2;
            //minus 1 for this block
            return numer.mul(1e18).div(denom);
        }
    }

    // This function makes a prediction on how much comp is accrued
    // It is not 100% accurate as it uses current balances in Compound to predict into the past
    function predictCompAccrued() public view returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        if (deposits == 0) {
            return 0; // should be impossible to have 0 balance and positive comp accrued
        }

        //comp speed is amount to borrow or deposit (so half the total distribution for want)
        uint256 distributionPerBlock = compound.compSpeeds(address(cToken));

        uint256 totalBorrow = cToken.totalBorrows();

        //total supply needs to be echanged to underlying using exchange rate
        uint256 totalSupplyCtoken = cToken.totalSupply();
        uint256 totalSupply = totalSupplyCtoken.mul(cToken.exchangeRateStored()).div(1e18);

        uint256 blockShareSupply = 0;
        if(totalSupply > 0){
            blockShareSupply = deposits.mul(distributionPerBlock).div(totalSupply);
        }
        
        uint256 blockShareBorrow = 0;
        if(totalBorrow > 0){
            blockShareBorrow = borrows.mul(distributionPerBlock).div(totalBorrow);
        }
        
        //how much we expect to earn per block
        uint256 blockShare = blockShareSupply.add(blockShareBorrow);

        //last time we ran harvest
        uint256 lastReport = vault.strategies(address(this)).lastReport;
        uint256 blocksSinceLast= (block.timestamp.sub(lastReport)).div(13); //roughly 13 seconds per block

        return blocksSinceLast.mul(blockShare);
    }

    //Returns the current position
    //WARNING - this returns just the balance at last time someone touched the cToken token. Does not accrue interst in between
    //cToken is very active so not normally an issue.
    function getCurrentPosition() public view returns (uint256 deposits, uint256 borrows) {
        (, uint256 ctokenBalance, uint256 borrowBalance, uint256 exchangeRate) = cToken.getAccountSnapshot(address(this));
        borrows = borrowBalance;

        deposits = ctokenBalance.mul(exchangeRate).div(1e18);
    }

    //statechanging version
    function getLivePosition() public returns (uint256 deposits, uint256 borrows) {
        deposits = cToken.balanceOfUnderlying(address(this));

        //we can use non state changing now because we updated state with balanceOfUnderlying call
        borrows = cToken.borrowBalanceStored(address(this));
    }

    //Same warning as above
    function netBalanceLent() public view returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPosition();
        return deposits.sub(borrows);
    }

    /***********
     * internal core logic
     *********** */
    /*
     * A core method.
     * Called at beggining of harvest before providing report to owner
     * 1 - claim accrued comp
     * 2 - if enough to be worth it we sell
     * 3 - because we lose money on our loans we need to offset profit from comp.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        ) {
        _profit = 0;
        _loss = 0; //for clarity. also reduces bytesize

        if (cToken.balanceOf(address(this)) == 0) {
            uint256 wantBalance = want.balanceOf(address(this));
            //no position to harvest
            //but we may have some debt to return
            //it is too expensive to free more debt in this method so we do it in adjust position
            _debtPayment = Math.min(wantBalance, _debtOutstanding); 
            return (_profit, _loss, _debtPayment);
        }
        (uint256 deposits, uint256 borrows) = getLivePosition();

        //claim comp accrued
        _claimComp();
        //sell comp
        _disposeOfComp();

        uint256 wantBalance = want.balanceOf(address(this));

        uint256 investedBalance = deposits.sub(borrows);
        uint256 balance = investedBalance.add(wantBalance);

        uint256 debt = vault.strategies(address(this)).totalDebt;

        //Balance - Total Debt is profit
        if (balance > debt) {
            _profit = balance - debt;

            if (wantBalance < _profit) {
                //all reserve is profit                
                _profit = wantBalance;
            } else if (wantBalance > _profit.add(_debtOutstanding)){
                _debtPayment = _debtOutstanding;
            }else{
                _debtPayment = wantBalance - _profit;
            }
        } else {
            //we will lose money until we claim comp then we will make money
            //this has an unintended side effect of slowly lowering our total debt allowed
            _loss = debt - balance;
            _debtPayment = Math.min(wantBalance, _debtOutstanding);
        }
    }

    /*
     * Second core function. Happens after report call.
     *
     * Similar to deposit function from V1 strategy
     */

    function adjustPosition(uint256 _debtOutstanding) internal override {
        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        //we are spending all our cash unless we have debt outstanding
        uint256 _wantBal = want.balanceOf(address(this));
        if(_wantBal < _debtOutstanding){
            //this is graceful withdrawal. dont use backup
            //we use more than 1 because withdrawunderlying causes problems with 1 token due to different decimals
            if(cToken.balanceOf(address(this)) > 1){ 
                _withdrawSome(_debtOutstanding - _wantBal, false);
            }

            return;
        }
        
        (uint256 position, bool deficit) = _calculateDesiredPosition(_wantBal - _debtOutstanding, true);
        
        //if we are below minimun want change it is not worth doing
        //need to be careful in case this pushes to liquidation
        if (position > minWant) {
            //if dydx is not active we just try our best with basic leverage
            if (!DyDxActive) {
                uint i = 0;
                while(position > 0){
                    position = position.sub(_noFlashLoan(position, deficit));
                    if(i >= 6){
                        break;
                    }
                    i++;
                }
            } else {
                //if there is huge position to improve we want to do normal leverage. it is quicker
                if (position > want.balanceOf(SOLO)) {
                    position = position.sub(_noFlashLoan(position, deficit));
                }

                //flash loan to position
                if(position > 0){
                    doDyDxFlashLoan(deficit, position);
                }

            }
        }
    }

    /*************
     * Very important function
     * Input: amount we want to withdraw and whether we are happy to pay extra for Aave.
     *       cannot be more than we have
     * Returns amount we were able to withdraw. notall if user has some balance left
     *
     * Deleverage position -> redeem our cTokens
     ******************** */
    function _withdrawSome(uint256 _amount, bool _useBackup) internal returns (bool notAll) {
        (uint256 position, bool deficit) = _calculateDesiredPosition(_amount, false);

        //If there is no deficit we dont need to adjust position
        if (deficit) {
            //we do a flash loan to give us a big gap. from here on out it is cheaper to use normal deleverage. Use Aave for extremely large loans
            if (DyDxActive) {
                position = position.sub(doDyDxFlashLoan(deficit, position));
            }

            // Will decrease number of interactions using aave as backup
            // because of fee we only use in emergency
            if (position > 0 && AaveActive && _useBackup) {
                position = position.sub(doAaveFlashLoan(deficit, position));
            }

            uint8 i = 0;
            //position will equal 0 unless we haven't been able to deleverage enough with flash loan
            //if we are not in deficit we dont need to do flash loan
            while (position > 0) {
                position = position.sub(_noFlashLoan(position, true));
                i++;

                //A limit set so we don't run out of gas
                if (i >= 5) {
                    notAll = true;
                    break;
                }
            }
        }

        //now withdraw
        //if we want too much we just take max

        //This part makes sure our withdrawal does not force us into liquidation
        (uint256 depositBalance, uint256 borrowBalance) = getCurrentPosition();

        uint256 AmountNeeded = 0;
        if(collateralTarget > 0){
            AmountNeeded = borrowBalance.mul(1e18).div(collateralTarget);
        }
        uint256 redeemable = depositBalance.sub(AmountNeeded);

        if (redeemable < _amount) {
            cToken.redeemUnderlying(redeemable);
        } else {
            cToken.redeemUnderlying(_amount);
        }

        //let's sell some comp if we have more than needed
        //flash loan would have sent us comp if we had some accrued so we don't need to call claim comp
        _disposeOfComp();
    }

    /***********
     *  This is the main logic for calculating how to change our lends and borrows
     *  Input: balance. The net amount we are going to deposit/withdraw.
     *  Input: dep. Is it a deposit or withdrawal
     *  Output: position. The amount we want to change our current borrow position.
     *  Output: deficit. True if we are reducing position size
     *
     *  For instance deficit =false, position 100 means increase borrowed balance by 100
     ****** */
    function _calculateDesiredPosition(uint256 balance, bool dep) internal returns (uint256 position, bool deficit) {
        //we want to use statechanging for safety
        (uint256 deposits, uint256 borrows) = getLivePosition();

        //When we unwind we end up with the difference between borrow and supply
        uint256 unwoundDeposit = deposits.sub(borrows);

        //we want to see how close to collateral target we are.
        //So we take our unwound deposits and add or remove the balance we are are adding/removing.
        //This gives us our desired future undwoundDeposit (desired supply)

        uint256 desiredSupply = 0;
        if (dep) {
            desiredSupply = unwoundDeposit.add(balance);
        } else { 
            if(balance > unwoundDeposit) balance = unwoundDeposit;
            desiredSupply = unwoundDeposit.sub(balance);
        }

        //(ds *c)/(1-c)
        uint256 num = desiredSupply.mul(collateralTarget);
        uint256 den = uint256(1e18).sub(collateralTarget);

        uint256 desiredBorrow = num.div(den);
        if (desiredBorrow > 1e5) {
            //stop us going right up to the wire
            desiredBorrow = desiredBorrow - 1e5;
        }

        //now we see if we want to add or remove balance
        // if the desired borrow is less than our current borrow we are in deficit. so we want to reduce position
        if (desiredBorrow < borrows) {
            deficit = true;
            position = borrows - desiredBorrow; //safemath check done in if statement
        } else {
            //otherwise we want to increase position
            deficit = false;
            position = desiredBorrow - borrows;
        }
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amount`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed, uint256 _loss) {
        uint256 _balance = want.balanceOf(address(this));
        uint256 assets = netBalanceLent().add(_balance);

        uint256 debtOutstanding = vault.debtOutstanding();

        if(debtOutstanding > assets){
            _loss = debtOutstanding - assets;
        }

        if (assets < _amountNeeded) {

            //if we cant afford to withdraw we take all we can
            //withdraw all we can
            (uint256 deposits, uint256 borrows) = getLivePosition();

            //1 token causes rounding error with withdrawUnderlying
            if(cToken.balanceOf(address(this)) > 1){ 
                _withdrawSome(deposits.sub(borrows), true);
            }

            _amountFreed = Math.min(_amountNeeded, want.balanceOf(address(this)));
           
        } else {
            if (_balance < _amountNeeded) {
                _withdrawSome(_amountNeeded.sub(_balance), true);

                //overflow error if we return more than asked for
                _amountFreed = Math.min(_amountNeeded, want.balanceOf(address(this)));
            }else{
                _amountFreed = _amountNeeded;
            }
        }
    }

    function _claimComp() internal {
        CTokenI[] memory tokens = new CTokenI[](1);
        tokens[0] = cToken;

        compound.claimComp(address(this), tokens);
    }

    //sell comp function
    function _disposeOfComp() internal {
        uint256 _comp = IERC20(comp).balanceOf(address(this));

        if (_comp > minCompToSell) {
            address[] memory path = new address[](3);
            path[0] = comp;
            path[1] = weth;
            path[2] = address(want);

            IUni(uniswapRouter).swapExactTokensForTokens(_comp, uint256(0), path, address(this), now);
        }
    }

    //lets leave
    //if we can't deleverage in one go set collateralFactor to 0 and call harvest multiple times until delevered
    function prepareMigration(address _newStrategy) internal override {
        (uint256 deposits, uint256 borrows) = getLivePosition();
        _withdrawSome(deposits.sub(borrows), false);

        (, , uint256 borrowBalance, ) = cToken.getAccountSnapshot(address(this));

        require(borrowBalance == 0, "DELEVERAGE_FIRST");

        IERC20 _comp = IERC20(comp);
        uint _compB = _comp.balanceOf(address(this));
        if(_compB > 0){
            _comp.safeTransfer(_newStrategy, _compB);
        }
    }

    //Three functions covering normal leverage and deleverage situations
    // max is the max amount we want to increase our borrowed balance
    // returns the amount we actually did
    function _noFlashLoan(uint256 max, bool deficit) internal returns (uint256 amount) {
        //we can use non-state changing because this function is always called after _calculateDesiredPosition
        (uint256 lent, uint256 borrowed) = getCurrentPosition();

        //if we have nothing borrowed then we can't deleverage any more
        if (borrowed == 0 && deficit) {
            return 0;
        }

        (, uint256 collateralFactorMantissa, ) = compound.markets(address(cToken));

        if (deficit) {
            amount = _normalDeleverage(max, lent, borrowed, collateralFactorMantissa);
        } else {
            amount = _normalLeverage(max, lent, borrowed, collateralFactorMantissa);
        }

        emit Leverage(max, amount, deficit, address(0));
    }

    //maxDeleverage is how much we want to reduce by
    function _normalDeleverage(
        uint256 maxDeleverage,
        uint256 lent,
        uint256 borrowed,
        uint256 collatRatio
    ) internal returns (uint256 deleveragedAmount) {
        uint256 theoreticalLent = 0;

        //collat ration should never be 0. if it is something is very wrong... but just incase
        if(collatRatio != 0){
            theoreticalLent = borrowed.mul(1e18).div(collatRatio);
        }

        deleveragedAmount = lent.sub(theoreticalLent);

        if (deleveragedAmount >= borrowed) {
            deleveragedAmount = borrowed;
        }
        if (deleveragedAmount >= maxDeleverage) {
            deleveragedAmount = maxDeleverage;
        }

        cToken.redeemUnderlying(deleveragedAmount);

        //our borrow has been increased by no more than maxDeleverage
        cToken.repayBorrow(deleveragedAmount);
    }

    //maxDeleverage is how much we want to increase by
    function _normalLeverage(
        uint256 maxLeverage,
        uint256 lent,
        uint256 borrowed,
        uint256 collatRatio
    ) internal returns (uint256 leveragedAmount) {
        uint256 theoreticalBorrow = lent.mul(collatRatio).div(1e18);

        leveragedAmount = theoreticalBorrow.sub(borrowed);

        if (leveragedAmount >= maxLeverage) {
            leveragedAmount = maxLeverage;
        }

        cToken.borrow(leveragedAmount);
        cToken.mint(want.balanceOf(address(this)));
    }

    //called by flash loan
    function _loanLogic(
        bool deficit,
        uint256 amount,
        uint256 repayAmount
    ) internal {
        uint256 bal = want.balanceOf(address(this));
        require(bal >= amount, "FLASH_FAILED"); // to stop malicious calls

        //if in deficit we repay amount and then withdraw
        if (deficit) {
            cToken.repayBorrow(amount);

            //if we are withdrawing we take more to cover fee
            cToken.redeemUnderlying(repayAmount);
        } else {
            //check if this failed incase we borrow into liquidation
            require(cToken.mint(bal) == 0, "mint error");
            //borrow more to cover fee
            // fee is so low for dydx that it does not effect our liquidation risk.
            //DONT USE FOR AAVE
            cToken.borrow(repayAmount);
        }
    }

    function protectedTokens() internal override view returns (address[] memory) {

        //want is protected automatically
        address[] memory protected = new address[](2);
        protected[0] = comp;
        protected[1] = address(cToken);
        return protected;
    }

    /******************
     * Flash loan stuff
     ****************/

    // Flash loan DXDY
    // amount desired is how much we are willing for position to change
    function doDyDxFlashLoan(bool deficit, uint256 amountDesired) internal returns (uint256) {
        uint256 amount = amountDesired;
        ISoloMargin solo = ISoloMargin(SOLO);
        
        // Not enough want in DyDx. So we take all we can
        uint256 amountInSolo = want.balanceOf(SOLO);

        if (amountInSolo < amount) {
            amount = amountInSolo;
        }

        uint256 repayAmount = amount.add(2); // we need to overcollateralise on way back

        bytes memory data = abi.encode(deficit, amount, repayAmount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(dyDxMarketId, amount);
        operations[1] = _getCallAction(
            // Encode custom data for callFunction
            data
        );
        operations[2] = _getDepositAction(dyDxMarketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);

        emit Leverage(amountDesired, amount, deficit, SOLO);

        return amount;
    }

    //returns our current collateralisation ratio. Should be compared with collateralTarget
    function storedCollateralisation() public view returns (uint256 collat) {
        (uint256 lend, uint256 borrow) = getCurrentPosition();
        if (lend == 0) {
            return 0;
        }
        collat = uint256(1e18).mul(borrow).div(lend);
    }

    //DyDx calls this function after doing flash loan
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        (bool deficit, uint256 amount, uint256 repayAmount) = abi.decode(data, (bool, uint256, uint256));
        require(msg.sender == SOLO, "NOT_SOLO");

        _loanLogic(deficit, amount, repayAmount);
       
    }

    bool internal awaitingFlash = false;

    function doAaveFlashLoan(bool deficit, uint256 _flashBackUpAmount) internal returns (uint256 amount) {
        //we do not want to do aave flash loans for leveraging up. Fee could put us into liquidation
        if (!deficit) {
            return _flashBackUpAmount;
        }

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());

        uint256 availableLiquidity = want.balanceOf(address(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3));

        if (availableLiquidity < _flashBackUpAmount) {
            amount = availableLiquidity;
        } else {
            amount = _flashBackUpAmount;
        }

        bytes memory data = abi.encode(deficit, amount);

        //anyone can call aave flash loan to us. (for some reason. grrr)
        awaitingFlash = true;

        lendingPool.flashLoan(address(this), address(want), amount, data);

        awaitingFlash = false;

        emit Leverage(_flashBackUpAmount, amount, deficit, AAVE_LENDING);
    }

    //Aave calls this function after doing flash loan
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external {
        (bool deficit, uint256 amount) = abi.decode(_params, (bool, uint256));
        require(msg.sender == addressesProvider.getLendingPool(), "NOT_AAVE");
        require(awaitingFlash, "Malicious");

        _loanLogic(deficit, amount, amount.add(_fee));

        // return the flash loan plus Aave's flash loan fee back to the lending pool
        uint256 totalDebt = _amount.add(_fee);

        address core = addressesProvider.getLendingPoolCore();
        IERC20(_reserve).safeTransfer(core, totalDebt);
    }

        // -- Internal Helper functions -- //

    function _setMarketIdFromTokenAddress() internal {
        ISoloMargin solo = ISoloMargin(SOLO);

        uint256 numMarkets = solo.getNumMarkets();

        address curToken;
        for (uint256 i = 0; i < numMarkets; i++) {
            curToken = solo.getMarketTokenAddress(i);

            if (curToken == address(want)) {
                dyDxMarketId = i;
                return;
            }
        }

        revert("No marketId found for provided token");
    }

    modifier management(){
        require(msg.sender == governance() || msg.sender == strategist, "!management");
        _;
    }
}

pragma solidity 0.6.12;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ISoloMargin.sol";

contract DydxFlashloanBase {
    using SafeMath for uint256;


    function _getAccountInfo() internal view returns (Account.Info memory) {
        return Account.Info({owner: address(this), number: 1});
    }

    function _getWithdrawAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Withdraw,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }

    function _getCallAction(bytes memory data) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({sign: false, denomination: Types.AssetDenomination.Wei, ref: Types.AssetReference.Delta, value: 0}),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: data
            });
    }

    function _getDepositAction(uint256 marketId, uint256 amount) internal view returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.Deposit,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: true,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: amount
                }),
                primaryMarketId: marketId,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: ""
            });
    }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Account} from "./ISoloMargin.sol";

/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for Solo must implement in order to ingest data.
 */
interface ICallee {
    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to Solo
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) external;
}

pragma solidity 0.6.12;

/**
    @title ILendingPoolAddressesProvider interface
    @notice provides the interface to fetch the LendingPoolCore address
 */

interface ILendingPoolAddressesProvider {
    function getLendingPoolCore() external view returns (address payable);

    function getLendingPool() external view returns (address);
}

pragma solidity 0.6.12;

interface ILendingPool {
    function addressesProvider() external view returns (address);

    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;

    function redeemUnderlying(
        address _reserve,
        address _user,
        uint256 _amount
    ) external;

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external;

    function repay(
        address _reserve,
        uint256 _amount,
        address _onBehalfOf
    ) external payable;

    function swapBorrowRateMode(address _reserve) external;

    function rebalanceFixedBorrowRate(address _reserve, address _user) external;

    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;

    function liquidationCall(
        address _collateral,
        address _reserve,
        address _user,
        uint256 _purchaseAmount,
        bool _receiveAToken
    ) external payable;

    function flashLoan(
        address _receiver,
        address _reserve,
        uint256 _amount,
        bytes calldata _params
    ) external;

    function getReserveConfigurationData(address _reserve)
        external
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationDiscount,
            address interestRateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool fixedBorrowRateEnabled,
            bool isActive
        );

    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsFixed,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 fixedBorrowRate,
            uint256 averageFixedBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );

    function getUserAccountData(address _user)
        external
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address _reserve, address _user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentUnderlyingBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance,
            uint256 borrowRateMode,
            uint256 borrowRate,
            uint256 liquidityRate,
            uint256 originationFee,
            uint256 variableBorrowIndex,
            uint256 lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );

    function getReserves() external view;
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./CTokenI.sol";

interface CErc20I is CTokenI {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        CTokenI cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./CTokenI.sol";

interface ComptrollerI {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /***  Comp claims ****/
    function claimComp(address holder) external;

    function claimComp(address holder, CTokenI[] memory cTokens) external;

    function markets(address ctoken)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function compSpeeds(address ctoken) external view returns (uint256);
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library Account {
    enum Status {Normal, Liquid, Vapor}
    struct Info {
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
    struct Storage {
        mapping(uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
    }
}

library Actions {
    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (publicly)
        Sell, // sell an amount of some token (publicly)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
    }

    enum AccountLayout {OnePrimary, TwoPrimary, PrimaryAndSecondary}

    enum MarketLayout {ZeroMarkets, OneMarket, TwoMarkets}

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }
}

library Decimal {
    struct D256 {
        uint256 value;
    }
}

library Interest {
    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }
}

library Monetary {
    struct Price {
        uint256 value;
    }
    struct Value {
        uint256 value;
    }
}

library Storage {
    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;
        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;
        // Interest index of the market
        Interest.Index index;
        // Contract address of the price oracle for this market
        address priceOracle;
        // Contract address of the interest setter for this market
        address interestSetter;
        // Multiplier on the marginRatio for this market
        Decimal.D256 marginPremium;
        // Multiplier on the liquidationSpread for this market
        Decimal.D256 spreadPremium;
        // Whether additional borrows are allowed for this market
        bool isClosing;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of Solo
    struct State {
        // number of markets
        uint256 numMarkets;
        // marketId => Market
        mapping(uint256 => Market) markets;
        // owner => account number => Account
        mapping(address => mapping(uint256 => Account.Storage)) accounts;
        // Addresses that can control other users accounts
        mapping(address => mapping(address => bool)) operators;
        // Addresses that can control all users accounts
        mapping(address => bool) globalOperators;
        // mutable risk parameters of the system
        RiskParams riskParams;
        // immutable risk limits of the system
        RiskLimits riskLimits;
    }
}

library Types {
    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

interface ISoloMargin {
    struct OperatorArg {
        address operator1;
        bool trusted;
    }

    function ownerSetSpreadPremium(uint256 marketId, Decimal.D256 memory spreadPremium) external;

    function getIsGlobalOperator(address operator1) external view returns (bool);

    function getMarketTokenAddress(uint256 marketId) external view returns (address);

    function ownerSetInterestSetter(uint256 marketId, address interestSetter) external;

    function getAccountValues(Account.Info memory account) external view returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketPriceOracle(uint256 marketId) external view returns (address);

    function getMarketInterestSetter(uint256 marketId) external view returns (address);

    function getMarketSpreadPremium(uint256 marketId) external view returns (Decimal.D256 memory);

    function getNumMarkets() external view returns (uint256);

    function ownerWithdrawUnsupportedTokens(address token, address recipient) external returns (uint256);

    function ownerSetMinBorrowedValue(Monetary.Value memory minBorrowedValue) external;

    function ownerSetLiquidationSpread(Decimal.D256 memory spread) external;

    function ownerSetEarningsRate(Decimal.D256 memory earningsRate) external;

    function getIsLocalOperator(address owner, address operator1) external view returns (bool);

    function getAccountPar(Account.Info memory account, uint256 marketId) external view returns (Types.Par memory);

    function ownerSetMarginPremium(uint256 marketId, Decimal.D256 memory marginPremium) external;

    function getMarginRatio() external view returns (Decimal.D256 memory);

    function getMarketCurrentIndex(uint256 marketId) external view returns (Interest.Index memory);

    function getMarketIsClosing(uint256 marketId) external view returns (bool);

    function getRiskParams() external view returns (Storage.RiskParams memory);

    function getAccountBalances(Account.Info memory account)
        external
        view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        );

    function renounceOwnership() external;

    function getMinBorrowedValue() external view returns (Monetary.Value memory);

    function setOperators(OperatorArg[] memory args) external;

    function getMarketPrice(uint256 marketId) external view returns (address);

    function owner() external view returns (address);

    function isOwner() external view returns (bool);

    function ownerWithdrawExcessTokens(uint256 marketId, address recipient) external returns (uint256);

    function ownerAddMarket(
        address token,
        address priceOracle,
        address interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium
    ) external;

    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;

    function getMarketWithInfo(uint256 marketId)
        external
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        );

    function ownerSetMarginRatio(Decimal.D256 memory ratio) external;

    function getLiquidationSpread() external view returns (Decimal.D256 memory);

    function getAccountWei(Account.Info memory account, uint256 marketId) external view returns (Types.Wei memory);

    function getMarketTotalPar(uint256 marketId) external view returns (Types.TotalPar memory);

    function getLiquidationSpreadForPair(uint256 heldMarketId, uint256 owedMarketId) external view returns (Decimal.D256 memory);

    function getNumExcessTokens(uint256 marketId) external view returns (Types.Wei memory);

    function getMarketCachedIndex(uint256 marketId) external view returns (Interest.Index memory);

    function getAccountStatus(Account.Info memory account) external view returns (uint8);

    function getEarningsRate() external view returns (Decimal.D256 memory);

    function ownerSetPriceOracle(uint256 marketId, address priceOracle) external;

    function getRiskLimits() external view returns (Storage.RiskLimits memory);

    function getMarket(uint256 marketId) external view returns (Storage.Market memory);

    function ownerSetIsClosing(uint256 marketId, bool isClosing) external;

    function ownerSetGlobalOperator(address operator1, bool approved) external;

    function transferOwnership(address newOwner) external;

    function getAdjustedAccountValues(Account.Info memory account) external view returns (Monetary.Value memory, Monetary.Value memory);

    function getMarketMarginPremium(uint256 marketId) external view returns (Decimal.D256 memory);

    function getMarketInterestRate(uint256 marketId) external view returns (Interest.Rate memory);
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./InterestRateModel.sol";

interface CTokenI {
    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral, uint256 seizeTokens);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function interestRateModel() external view returns (InterestRateModel);

    function totalReserves() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface InterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256, uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./CTokenI.sol";

interface CEtherI is CTokenI {
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function liquidateBorrow(address borrower, CTokenI cTokenCollateral) external payable;

    function mint() external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "contracts/interfaces/Compound/CErc20I.sol";
import "contracts/interfaces/Compound/InterestRateModel.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./GenericLenderBase.sol";

/********************
 *   A lender plugin for LenderYieldOptimiser for any erc20 asset on Cream (not eth)
 *   Made by SamPriestley.com
 *   https://github.com/Grandthrax/yearnv2/blob/master/contracts/GenericLender/GenericCream.sol
 *
 ********************* */

contract GenericCream is GenericLenderBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 private constant blocksPerYear = 2_300_000;

    CErc20I public cToken;

    constructor(
        address _strategy,
        string memory name,
        address _cToken
    ) public GenericLenderBase(_strategy, name) {
        _initialize(_cToken);
    }

    function initialize(address _cToken) external {
        _initialize(_cToken);
    }

    function _initialize(address _cToken) internal {
        require(address(cToken) == address(0), "GenericCream already initialized");
        cToken = CErc20I(_cToken);
        require(cToken.underlying() == address(want), "WRONG CTOKEN");
        want.safeApprove(_cToken, uint256(-1));
    }

    function cloneCreamLender(
        address _strategy,
        string memory _name,
        address _cToken
    ) external returns (address newLender) {
        newLender = _clone(_strategy, _name);
        GenericCream(newLender).initialize(_cToken);
    }

    function nav() external view override returns (uint256) {
        return _nav();
    }

    function _nav() internal view returns (uint256) {
        return want.balanceOf(address(this)).add(underlyingBalanceStored());
    }

    function underlyingBalanceStored() public view returns (uint256 balance) {
        uint256 currentCr = cToken.balanceOf(address(this));
        if (currentCr == 0) {
            balance = 0;
        } else {
            //The current exchange rate as an unsigned integer, scaled by 1e18.
            balance = currentCr.mul(cToken.exchangeRateStored()).div(1e18);
        }
    }

    function apr() external view override returns (uint256) {
        return _apr();
    }

    function _apr() internal view returns (uint256) {
        return cToken.supplyRatePerBlock().mul(blocksPerYear);
    }

    function weightedApr() external view override returns (uint256) {
        uint256 a = _apr();
        return a.mul(_nav());
    }

    function withdraw(uint256 amount) external override management returns (uint256) {
        return _withdraw(amount);
    }

    //emergency withdraw. sends balance plus amount to governance
    function emergencyWithdraw(uint256 amount) external override management {
        //dont care about error here
        cToken.redeemUnderlying(amount);

        want.safeTransfer(vault.governance(), want.balanceOf(address(this)));
    }

    //withdraw an amount including any want balance
    function _withdraw(uint256 amount) internal returns (uint256) {
        uint256 balanceUnderlying = cToken.balanceOfUnderlying(address(this));
        uint256 looseBalance = want.balanceOf(address(this));
        uint256 total = balanceUnderlying.add(looseBalance);

        if (amount > total) {
            //cant withdraw more than we own
            amount = total;
        }
        if (looseBalance >= amount) {
            want.safeTransfer(address(strategy), amount);
            return amount;
        }

        //not state changing but OK because of previous call
        uint256 liquidity = want.balanceOf(address(cToken));

        if (liquidity > 1) {
            uint256 toWithdraw = amount.sub(looseBalance);

            if (toWithdraw <= liquidity) {
                //we can take all
                require(cToken.redeemUnderlying(toWithdraw) == 0, "ctoken: redeemUnderlying fail");
            } else {
                //take all we can
                require(cToken.redeemUnderlying(liquidity) == 0, "ctoken: redeemUnderlying fail");
            }
        }
        looseBalance = want.balanceOf(address(this));
        want.safeTransfer(address(strategy), looseBalance);
        return looseBalance;
    }

    function deposit() external override management {
        uint256 balance = want.balanceOf(address(this));
        require(cToken.mint(balance) == 0, "ctoken: mint fail");
    }

    function withdrawAll() external override management returns (bool) {
        uint256 invested = _nav();
        uint256 returned = _withdraw(invested);
        return returned >= invested;
    }

    function hasAssets() external view override returns (bool) {
        return cToken.balanceOf(address(this)) > 0;
    }

    function aprAfterDeposit(uint256 amount) external view override returns (uint256) {
        uint256 cashPrior = want.balanceOf(address(cToken));

        uint256 borrows = cToken.totalBorrows();
        uint256 reserves = cToken.totalReserves();

        uint256 reserverFactor = cToken.reserveFactorMantissa();
        InterestRateModel model = cToken.interestRateModel();

        //the supply rate is derived from the borrow rate, reserve factor and the amount of total borrows.
        uint256 supplyRate = model.getSupplyRate(cashPrior.add(amount), borrows, reserves, reserverFactor);

        return supplyRate.mul(blocksPerYear);
    }

    function protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(cToken);
        return protected;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IFlashLoanReceiver.sol";
import "./ILendingPoolAddressesProvider.sol";
import "../utils/Withdrawable.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver, Withdrawable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    ILendingPoolAddressesProvider public addressesProvider;

    constructor(address _addressProvider) public {
        addressesProvider = ILendingPoolAddressesProvider(_addressProvider);
    }

    receive() external payable {}

    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
        address payable core = addressesProvider.getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(
        address payable _destination,
        address _reserve,
        uint256 _amount
    ) internal {
        if (_reserve == ethAddress) {
            (bool success, ) = _destination.call{value: _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_reserve).safeTransfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve) internal view returns (uint256) {
        if (_reserve == ethAddress) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }
}

pragma solidity 0.6.12;

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external;
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
    Ensures that any contract that inherits from this contract is able to
    withdraw funds that are accidentally received or stuck.
 */

contract Withdrawable is Ownable {
    using SafeERC20 for ERC20;
    address constant ETHER = address(0);

    event LogWithdraw(address indexed _from, address indexed _assetAddress, uint256 amount);

    /**
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdraw(address _assetAddress) public onlyOwner {
        uint256 assetBalance;
        if (_assetAddress == ETHER) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = ERC20(_assetAddress).balanceOf(address(this));
            ERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
        emit LogWithdraw(msg.sender, _assetAddress, assetBalance);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IToken.sol";

abstract contract MockGToken is ERC20, Ownable, IToken {
    function mint(
        address account,
        uint256 factor,
        uint256 amount
    ) external override {
        factor;
        require(account != address(0), "Account is empty.");
        require(amount > 0, "amount is less than zero.");
        _mint(account, amount);
    }

    function burn(
        address account,
        uint256 factor,
        uint256 amount
    ) external override {
        factor;
        require(account != address(0), "Account is empty.");
        require(amount > 0, "amount is less than zero.");
        _burn(account, amount);
    }

    function factor() external view override returns (uint256) {}

    function factor(uint256 totalAssets) external view override returns (uint256) {
        totalAssets;
    }

    function burnAll(address account) external override {
        _burn(account, balanceOf(account));
    }

    function totalAssets() external view override returns (uint256) {
        return totalSupply();
    }

    function getPricePerShare() external view override returns (uint256) {}

    function getShareAssets(uint256 shares) external view override returns (uint256) {
        return shares;
    }

    function getAssets(address account) external view override returns (uint256) {
        return balanceOf(account);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./MockGToken.sol";
import "../common/Constants.sol";

contract MockPWRDToken is MockGToken, Constants {
    constructor() public ERC20("pwrd", "pwrd") {
        _setupDecimals(DEFAULT_DECIMALS);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./MockGToken.sol";
import "../common/Constants.sol";

contract MockGvtToken is MockGToken, Constants {
    constructor() public ERC20("gvt", "gvt") {
        _setupDecimals(DEFAULT_DECIMALS);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./common/FixedContracts.sol";
import "./common/Controllable.sol";

import "./interfaces/IChainPrice.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IEmergencyHandler.sol";
import "./interfaces/IInsurance.sol";
import "./interfaces/IPausable.sol";
import "./interfaces/IPnL.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IVault.sol";

/// @notice Alternate route for withdrawals during protocol emergency states:
///     EmergencyHanlder is not called directly, rather calls to the withdrawHandler
///     are rerouted to the emergencyHandler if the system enters a emergency state.
///     All deposits are blocked in a emegency state, and withdrawals are priced against
///     Chainlink rather than curve.
///     An emergency state assumes that something has gone wrong with curve, which means that
///     pricing and swapping no longer works correctly. In this state the system will give back
///     any assets it has in excess to the user withdrawing [excluding any broken asset].
contract EmergencyHandler is Controllable, FixedStablecoins, FixedGTokens, FixedVaults, IEmergencyHandler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IChainPrice public immutable chain;
    IInsurance public insurance;
    IController public ctrl;
    IPnL public pnl;

    event LogEmergencyWithdrawal();
    event LogNewDependencies();

    constructor(
        address pwrd,
        address gvt,
        address _chain,
        address[N_COINS] memory _vaults,
        address[N_COINS] memory _tokens,
        uint256[N_COINS] memory _decimals
    ) public FixedStablecoins(_tokens, _decimals) FixedGTokens(pwrd, gvt) FixedVaults(_vaults) {
        chain = IChainPrice(_chain);
    }

    /// @notice Update protocol dependencies
    function setDependencies() external onlyOwner {
        ctrl = _controller();
        insurance = IInsurance(ctrl.insurance());
        pnl = IPnL(ctrl.pnl());
        emit LogNewDependencies();
    }

    /// @notice Withdraw all
    /// @param user User address
    /// @param pwrd pwrd/gvt token
    /// @param minAmount min amount of token to withdraw
    function emergencyWithdrawAll(
        address user,
        bool pwrd,
        uint256 minAmount
    ) external override {
        // Only withdrawHandler can call this method
        require(msg.sender == ctrl.withdrawHandler(), "EmergencyHandler: !WithdrawHandler");
        IToken gt = IToken(gTokens(pwrd));
        uint256 userAssets = gt.getAssets(user);

        _withdraw(user, pwrd, true, userAssets, minAmount);
    }

    /// @notice Withdraw partial
    /// @param user User address
    /// @param pwrd pwrd/gvt token
    /// @param inAmount usd to witdraw
    /// @param minAmount min amount of token to withdraw
    function emergencyWithdrawal(
        address user,
        bool pwrd,
        uint256 inAmount,
        uint256 minAmount
    ) external override {
        // Only withdrawHandler can call this method
        require(msg.sender == ctrl.withdrawHandler(), "EmergencyHandler: !WithdrawHandler");
        IToken gt = IToken(gTokens(pwrd));
        uint256 userAssets = gt.getAssets(user);
        // User must have a positive amount of gTokens
        require(userAssets >= inAmount, "EmergencyHandler: !userGTokens");

        _withdraw(user, pwrd, false, inAmount, minAmount);
    }

    /// @notice emergency withdraw
    /// @param user user address
    /// @param pwrd pwrd/gvt token
    /// @param all withdraw all
    /// @param deductUsd usd to witdraw
    /// @param minAmount min amount of token to withdraw
    function _withdraw(
        address user,
        bool pwrd,
        bool all,
        uint256 deductUsd,
        uint256 minAmount
    ) private {
        uint256 withdrawalFee = deductUsd.mul(ctrl.withdrawalFee(pwrd)).div(PERCENTAGE_DECIMAL_FACTOR);
        uint256 reductUsd = deductUsd.sub(withdrawalFee);

        /// Gvt can still be block if there are enough pwrd in the system
        if (!pwrd) {
            require(ctrl.validGTokenDecrease(reductUsd), "exceeds utilisation limit");
        }

        uint256[N_COINS] memory vaultIndexes = insurance.sortVaultsByDelta(false);
        uint256 tokenAmount = reductUsd.mul(CHAINLINK_PRICE_DECIMAL_FACTOR).div(chain.getPriceFeed(vaultIndexes[2]));
        tokenAmount = tokenAmount.mul(getDecimal(vaultIndexes[2])).div(DEFAULT_DECIMALS_FACTOR);

        IVault vault = IVault(getVault(vaultIndexes[2]));
        uint256 vaultAssets = vault.totalAssets();
        if (vaultAssets < tokenAmount) {
            if (vaultAssets > minAmount) {
                tokenAmount = vaultAssets;
            } else {
                revert("EmergencyHandler: !totalAssets");
            }
        }

        address account = user;

        vault.withdrawByStrategyOrder(tokenAmount, address(this), pwrd);
        IERC20 token = IERC20(getToken(vaultIndexes[2]));
        uint256 outAmount = token.balanceOf(address(this));
        require(outAmount >= minAmount, "EmergencyHandler: !minAmount");

        ctrl.burnGToken(pwrd, all, account, deductUsd, withdrawalFee);
        token.safeTransfer(account, outAmount);
        emit LogEmergencyWithdrawal();
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedStablecoins, FixedVaults} from "../common/FixedContracts.sol";
import "../common/Controllable.sol";
import "../common/Whitelist.sol";

import "../interfaces/IBuoy.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/ILifeGuard.sol";
import "../interfaces/IVault.sol";
import {ICurve3Deposit} from "../interfaces/ICurve.sol";

/// @notice Contract for interactions with curve3pool
///     Handles asset swapping and investment into underlying vaults for larger deposits.
///         The lifeguard also handles interaction with any Curve pool token vaults (currently 3Crv),
///         This vault is treated specially as it causes exposures against all three stablecoins:
///             1) Large deposits that go through the lifeguard on their way into the vault adapters
///                 may have a set percentage of their assets left in the lifeguard for later deposit into
///                 the Curve vault - This is a binary action determined by the current Curve exposure.
///             2) Withdrawals will only happen from the Curve vault in edge cases - when withdrawal is
///                 greater than total amount of assets in stablecoin vaults.
///             3) The lifeguard can pull out assets from the Curve vault and redistribute it to the
///                 underlying stablecoin vaults to avoid overexposure.
///
///     In addition the lifeguard allows the system to toggle additional price checks on
///     each deposit/withdrawal (see buoy for more details)
contract LifeGuard3Pool is ILifeGuard, Controllable, Whitelist, FixedStablecoins {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ICurve3Deposit public immutable crv3pool; // curve pool
    IERC20 public immutable lpToken; // Pool token
    IBuoy public immutable buoy; // Oracle

    address public insurance;
    address public depositHandler;
    address public withdrawHandler;

    uint256 public investToCurveThreshold;
    /// Mapping of asset amounts in lifeguard (DAI, USDC, USDT)
    mapping(uint256 => uint256) public override assets;

    event LogHealhCheckUpdate(bool status);
    event LogNewCurveThreshold(uint256 threshold);
    event LogNewEmergencyWithdrawal(uint256 indexed token1, uint256 indexed token2, uint256 ratio, uint256 decimals);
    event LogNewInvest(
        uint256 depositAmount,
        uint256[N_COINS] delta,
        uint256[N_COINS] amounts,
        uint256 dollarAmount,
        bool needSkim
    );
    event LogNewStableDeposit(uint256[N_COINS] inAmounts, uint256 lpToken, bool rebalance);

    constructor(
        address _crv3pool,
        address poolToken,
        address _buoy,
        address[N_COINS] memory _tokens,
        uint256[N_COINS] memory _decimals
    ) public FixedStablecoins(_tokens, _decimals) {
        crv3pool = ICurve3Deposit(_crv3pool);
        buoy = IBuoy(_buoy);
        lpToken = IERC20(poolToken);
        for (uint256 i = 0; i < N_COINS; i++) {
            IERC20(_tokens[i]).safeApprove(_crv3pool, type(uint256).max);
        }
    }

    /// @notice Approve the wihtdrawHandler to pull from lifeguard
    function setDependencies() external onlyOwner {
        IController ctrl = _controller();
        if (withdrawHandler != address(0)) {
            for (uint256 i = 0; i < N_COINS; i++) {
                address coin = getToken(i);
                IERC20(coin).safeApprove(withdrawHandler, uint256(0));
            }
        }
        withdrawHandler = ctrl.withdrawHandler();
        for (uint256 i = 0; i < N_COINS; i++) {
            address coin = getToken(i);
            IERC20(coin).safeApprove(withdrawHandler, uint256(0));
            IERC20(coin).safeApprove(withdrawHandler, type(uint256).max);
        }
        depositHandler = ctrl.depositHandler();
        insurance = ctrl.insurance();
    }

    function getAssets() external view override returns (uint256[N_COINS] memory _assets) {
        for (uint256 i; i < N_COINS; i++) {
            _assets[i] = assets[i];
        }
    }

    /// @notice Approve vault adaptor to pull from lifeguard
    /// @param index Index of vaultAdaptors underlying asset
    function approveVaults(uint256 index) external onlyOwner {
        IVault vault;
        if (index < N_COINS) {
            vault = IVault(_controller().underlyingVaults(index));
        } else {
            vault = IVault(_controller().curveVault());
        }
        address coin = vault.token();
        IERC20(coin).safeApprove(address(vault), uint256(0));
        IERC20(coin).safeApprove(address(vault), type(uint256).max);
    }

    /// @notice Set the upper limit to the amount of assets the lifeguard will
    ///     hold on to before signaling that an invest to Curve action is necessary.
    /// @param _investToCurveThreshold New invest threshold
    function setInvestToCurveThreshold(uint256 _investToCurveThreshold) external onlyOwner {
        investToCurveThreshold = _investToCurveThreshold;
        emit LogNewCurveThreshold(_investToCurveThreshold);
    }

    /// @notice Invest assets into Curve vault
    function investToCurveVault() external override onlyWhitelist {
        uint256[N_COINS] memory _inAmounts;
        for (uint256 i = 0; i < N_COINS; i++) {
            _inAmounts[i] = assets[i];
            assets[i] = 0;
        }
        crv3pool.add_liquidity(_inAmounts, 0);
        _investToVault(N_COINS, false);
    }

    /// @notice Check if lifeguard is ready to invest into the Curve vault
    function investToCurveVaultTrigger() external view override returns (bool invest) {
        uint256 totalAssetsLP = _totalAssets();
        return totalAssetsLP > investToCurveThreshold.mul(uint256(10)**IERC20Detailed(address(lpToken)).decimals());
    }

    /// @notice Pull out and redistribute Curve vault assets (3Crv) to underlying stable vaults
    /// @param amount Amount to pull out
    /// @param delta Distribution of assets to vaults (%BP)
    function distributeCurveVault(uint256 amount, uint256[N_COINS] memory delta)
        external
        override
        returns (uint256[N_COINS] memory)
    {
        require(msg.sender == controller, "distributeCurveVault: !controller");
        IVault vault = IVault(_controller().curveVault());

        vault.withdraw(amount);
        _withdrawUnbalanced(amount, delta);
        uint256[N_COINS] memory amounts;
        for (uint256 i = 0; i < N_COINS; i++) {
            amounts[i] = _investToVault(i, false);
        }
        return amounts;
    }

    /// @notice Deposit lifeguards stablecoins into Curve pool
    /// @param rebalance Is the deposit for a rebalance Y/N
    function depositStable(bool rebalance) external override returns (uint256) {
        require(msg.sender == withdrawHandler || msg.sender == insurance, "depositStable: !depositHandler");
        uint256[N_COINS] memory _inAmounts;
        uint256 countOfStableHasAssets = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 balance = IERC20(getToken(i)).balanceOf(address(this));
            if (balance != 0) {
                countOfStableHasAssets++;
            }
            if (!rebalance) {
                balance = balance.sub(assets[i]);
            } else {
                assets[i] = 0;
            }
            _inAmounts[i] = balance;
        }
        if (countOfStableHasAssets == 0) return 0;
        crv3pool.add_liquidity(_inAmounts, 0);
        uint256 lpAmount = lpToken.balanceOf(address(this));
        emit LogNewStableDeposit(_inAmounts, lpAmount, rebalance);
        return lpAmount;
    }

    /// @notice Leave part of user deposits assets in lifeguard for depositing into alternative vault
    /// @param amount Amount of token deposited
    /// @param index Index of token
    /// @dev Updates internal assets mapping so lifeguard can keep track of how much
    ///     extra assets it is holding
    function skim(uint256 amount, uint256 index) internal returns (uint256 balance) {
        uint256 skimPercent = _controller().getSkimPercent();
        uint256 skimmed = amount.mul(skimPercent).div(PERCENTAGE_DECIMAL_FACTOR);
        balance = amount.sub(skimmed);
        assets[index] = assets[index].add(skimmed);
    }

    /// @notice Deposit assets into Curve pool
    function deposit() external override returns (uint256 newAssets) {
        require(msg.sender == depositHandler, "depositStable: !depositHandler");
        uint256[N_COINS] memory _inAmounts;
        for (uint256 i = 0; i < N_COINS; i++) {
            IERC20 coin = IERC20(getToken(i));
            _inAmounts[i] = coin.balanceOf(address(this)).sub(assets[i]);
        }
        uint256 previousAssets = lpToken.balanceOf(address(this));
        crv3pool.add_liquidity(_inAmounts, 0);
        newAssets = lpToken.balanceOf(address(this)).sub(previousAssets);
    }

    /// @notice Withdraw single asset from Curve pool
    /// @param i Token index
    /// @param minAmount Acceptable minimum amount of token to recieve
    /// @param recipient Recipient of assets
    /// @dev withdrawSingle Swaps available assets in the lifeguard into target assets
    ///        using the Curve exhange function. This asset is then sent to target recipient
    function withdrawSingleByLiquidity(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external override returns (uint256, uint256) {
        require(msg.sender == withdrawHandler, "withdrawSingleByLiquidity: !withdrawHandler");
        IERC20 coin = IERC20(getToken(i));
        crv3pool.remove_liquidity_one_coin(lpToken.balanceOf(address(this)), int128(i), 0);
        uint256 balance = coin.balanceOf(address(this)).sub(assets[i]);
        require(balance > minAmount, "withdrawSingle: !minAmount");
        coin.safeTransfer(recipient, balance);
        return (buoy.singleStableToUsd(balance, i), balance);
    }

    /// @notice Exchange underlying assets into one token
    /// @param i Index of token to exchange to
    /// @param minAmount Acceptable minimum amount of token to recieve
    /// @param recipient Recipient of assets
    /// @dev withdrawSingle Swaps available assets in the lifeguard into target assets
    ///        using the Curve exhange function. This asset is then sent to target recipient
    function withdrawSingleByExchange(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external override returns (uint256 usdAmount, uint256 balance) {
        require(msg.sender == withdrawHandler, "withdrawSingleByExchange: !withdrawHandler");
        IERC20 coin = IERC20(getToken(i));
        balance = coin.balanceOf(address(this)).sub(assets[i]);
        // Are available assets - locked assets for LP vault more than required
        // minAmount. Then estimate USD value and transfer...
        if (minAmount <= balance) {
            uint256[N_COINS] memory inAmounts;
            inAmounts[i] = balance;
            usdAmount = buoy.stableToUsd(inAmounts, false);
            // ...if not, swap other loose assets into target assets before
            // estimating USD value and transfering.
        } else {
            for (uint256 j; j < N_COINS; j++) {
                if (j == i) continue;
                IERC20 inCoin = IERC20(getToken(j));
                uint256 inBalance = inCoin.balanceOf(address(this)).sub(assets[j]);
                if (inBalance > 0) {
                    _exchange(inBalance, int128(j), int128(i));
                    if (coin.balanceOf(address(this)).sub(assets[i]) >= minAmount) {
                        break;
                    }
                }
            }
            balance = coin.balanceOf(address(this)).sub(assets[i]);
            uint256[N_COINS] memory inAmounts;
            inAmounts[i] = balance;
            usdAmount = buoy.stableToUsd(inAmounts, false);
        }
        require(balance >= minAmount);
        coin.safeTransfer(recipient, balance);
    }

    /// @notice Return underlying buoy
    function getBuoy() external view override returns (address) {
        return address(buoy);
    }

    /// @notice Deposit into underlying vaults
    /// @param depositAmount LP amount to invest
    /// @param delta Target distribution of investment (%BP)
    function invest(uint256 depositAmount, uint256[N_COINS] calldata delta)
        external
        override
        returns (uint256 dollarAmount)
    {
        require(msg.sender == insurance || msg.sender == depositHandler, "depositStable: !depositHandler");
        bool needSkim = true;
        if (depositAmount == 0) {
            depositAmount = lpToken.balanceOf(address(this));
            needSkim = false;
        }
        uint256[N_COINS] memory amounts;
        _withdrawUnbalanced(depositAmount, delta);
        for (uint256 i = 0; i < N_COINS; i++) {
            amounts[i] = _investToVault(i, needSkim);
        }
        dollarAmount = buoy.stableToUsd(amounts, true);
        emit LogNewInvest(depositAmount, delta, amounts, dollarAmount, needSkim);
    }

    /// @notice Invest target stablecoins into specified vaults. The two
    ///     specified vaults, i and j should represent the least and second least
    ///     exposed vaults. This function will exchanges any unwanted stablecoins
    ///     (most exposed) to the least exposed vaults underlying asset (i).
    /// @param inAmounts Stable coin amounts
    /// @param i Index of target stablecoin/vault
    /// @param j Index of target stablecoin/vault
    /// @dev i and j represent the two least exposed vaults, any invested assets
    ///     targeting the most exposed vault will be exchanged for i, the least
    ///     exposed asset.
    function investSingle(
        uint256[N_COINS] calldata inAmounts,
        uint256 i,
        uint256 j
    ) external override returns (uint256 dollarAmount) {
        require(msg.sender == depositHandler, "!investSingle: !depositHandler");
        // Swap any additional stablecoins to target
        for (uint256 k; k < N_COINS; k++) {
            if (k == i || k == j) continue;
            uint256 inBalance = inAmounts[k];
            if (inBalance > 0) {
                _exchange(inBalance, int128(k), int128(i));
            }
        }
        uint256[N_COINS] memory amounts;

        uint256 k = N_COINS - (i + j);
        if (inAmounts[i] > 0 || inAmounts[k] > 0) {
            amounts[i] = _investToVault(i, true);
        }
        if (inAmounts[j] > 0) {
            amounts[j] = _investToVault(j, true);
        }
        // Assess USD value of new stablecoin amount
        dollarAmount = buoy.stableToUsd(amounts, true);
    }

    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    /// @notice Total available (not reserved for Curve vault) assets held by contract (denoted in LP tokens)
    function availableLP() external view override returns (uint256) {
        uint256[N_COINS] memory _assets;
        for (uint256 i; i < N_COINS; i++) {
            IERC20 coin = IERC20(getToken(i));
            _assets[i] = coin.balanceOf(address(this)).sub(assets[i]);
        }
        return buoy.stableToLp(_assets, true);
    }

    function totalAssetsUsd() external view override returns (uint256) {
        return buoy.lpToUsd(_totalAssets());
    }

    // @notice Total available (not reserved for Curve vault) assets held by contract (denoted in USD)
    function availableUsd() external view override returns (uint256) {
        uint256 lpAmount = lpToken.balanceOf(address(this));
        uint256 skimPercent = _controller().getSkimPercent();
        lpAmount = lpAmount.sub(lpAmount.mul(skimPercent).div(PERCENTAGE_DECIMAL_FACTOR));
        return buoy.lpToUsd(lpAmount);
    }

    // Private functions

    /// @notice Exchange one stable coin to another
    /// @param amount Amount of in token
    /// @param _in Index of in token
    /// @param out Index of out token
    function _exchange(
        uint256 amount,
        int128 _in,
        int128 out
    ) private returns (uint256) {
        crv3pool.exchange(_in, out, amount, 0);
    }

    /// @notice Withdraw from pool in specific coin targets
    /// @param inAmount Total amount of withdraw (in LP tokens)
    /// @param delta Distribution of underlying assets to withdraw (%BP)
    function _withdrawUnbalanced(uint256 inAmount, uint256[N_COINS] memory delta) private {
        uint256 leftAmount = inAmount;
        for (uint256 i; i < N_COINS - 1; i++) {
            if (delta[i] > 0) {
                uint256 amount = inAmount.mul(delta[i]).div(PERCENTAGE_DECIMAL_FACTOR);
                leftAmount = leftAmount.sub(amount);
                crv3pool.remove_liquidity_one_coin(amount, int128(i), 0);
            }
        }
        if (leftAmount > 0) {
            crv3pool.remove_liquidity_one_coin(leftAmount, int128(N_COINS - 1), 0);
        }
    }

    function _totalAssets() private view returns (uint256) {
        uint256[N_COINS] memory _assets;
        for (uint256 i; i < N_COINS; i++) {
            _assets[i] = assets[i];
        }
        return buoy.stableToLp(_assets, true);
    }

    /// @notice Deposit all target stablecoins to vault
    /// @param i Target vault
    /// @param needSkim Leave assets in lifeguard for deposit into Curve vault (Y/N)
    function _investToVault(uint256 i, bool needSkim) private returns (uint256 balance) {
        IVault vault;
        IERC20 coin;
        if (i < N_COINS) {
            vault = IVault(_controller().underlyingVaults(i));
            coin = IERC20(getToken(i));
        } else {
            vault = IVault(_controller().curveVault());
            coin = lpToken;
        }
        balance = coin.balanceOf(address(this)).sub(assets[i]);
        if (balance > 0) {
            if (i == N_COINS) {
                IVault(vault).deposit(balance);
                IVault(vault).invest();
            } else {
                uint256 investBalance = needSkim ? skim(balance, i) : balance;
                IVault(vault).deposit(investBalance);
            }
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {FixedStablecoins} from "contracts/common/FixedContracts.sol";
import {ICurve3Pool} from "contracts/interfaces/ICurve.sol";

import "contracts/common/Controllable.sol";

import "contracts/interfaces/IBuoy.sol";
import "contracts/interfaces/IChainPrice.sol";
import "contracts/interfaces/IChainlinkAggregator.sol";
import "contracts/interfaces/IERC20Detailed.sol";

/// @notice Contract for calculating prices of underlying assets and LP tokens in Curve pool. Also
///     used to sanity check pool against external oracle, to ensure that pools underlying coin ratios
///     are within a specific range (measued in BP) of the external oracles coin price ratios.
///     Sanity check:
///         The Buoy checks previously recorded (cached) curve coin dy, which it compares against current curve dy,
///         blocking any interaction that is outside a certain tolerance (BASIS_POINTS). When updting the cached
///         value, the buoy uses chainlink to ensure that curves prices arent off peg.
contract Buoy3Pool is FixedStablecoins, Controllable, IBuoy, IChainPrice {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 TIME_LIMIT = 3000;
    uint256 public BASIS_POINTS = 20;
    uint256 constant CHAIN_FACTOR = 100;

    ICurve3Pool public immutable override curvePool;
    IERC20 public immutable lpToken;

    mapping(uint256 => uint256) lastRatio;

    // Chianlink price feed
    address public immutable daiUsdAgg;
    address public immutable usdcUsdAgg;
    address public immutable usdtUsdAgg;

    mapping(address => mapping(address => uint256)) public tokenRatios;

    event LogNewBasisPointLimit(uint256 oldLimit, uint256 newLimit);

    constructor(
        address _crv3pool,
        address poolToken,
        address[N_COINS] memory _tokens,
        uint256[N_COINS] memory _decimals,
        address[N_COINS] memory aggregators
    ) public FixedStablecoins(_tokens, _decimals) {
        curvePool = ICurve3Pool(_crv3pool);
        lpToken = IERC20(poolToken);
        daiUsdAgg = aggregators[0];
        usdcUsdAgg = aggregators[1];
        usdtUsdAgg = aggregators[2];
    }

    /// @notice Set limit for how much Curve pool and external oracle is allowed
    ///     to deviate before failing transactions
    /// @param newLimit New limit in BP
    function setBasisPointsLmit(uint256 newLimit) external onlyOwner {
        uint256 oldLimit = BASIS_POINTS;
        BASIS_POINTS = newLimit;
        emit LogNewBasisPointLimit(oldLimit, newLimit);
    }

    /// @notice Check the health of the Curve pool:
    ///     Ratios are checked by the following heuristic:
    ///     Orcale A - Curve
    ///     Oracle B - External oracle
    ///     Both oracles establish ratios for a set of stable coins
    ///         (a, b, c)
    ///     and product the following set of ratios:
    ///         (a/a, a/b, a/c), (b/b, b/a, b/c), (c/c, c/a, c/b)
    ///     It's simply to reduce the number of comparisons to be made
    ///     in order to have complete coverage of the system ratios:
    ///         1) ratios between a stable coin and itself can be discarded
    ///         2) inverted ratios, a/b bs b/a, while producing different results
    ///             should both reflect the same change in any one of the two
    ///             underlying assets, but in opposite directions
    ///     This mean that the following set should provide the necessary coverage checks
    ///     to establish that the coins pricing is healthy:
    ///         (a/b, a/c)
    function safetyCheck() external view override returns (bool) {
        for (uint256 i = 1; i < N_COINS; i++) {
            uint256 _ratio = curvePool.get_dy(int128(0), int128(i), getDecimal(0));
            _ratio = abs(int256(_ratio - lastRatio[i]));
            if (_ratio.mul(PERCENTAGE_DECIMAL_FACTOR).div(CURVE_RATIO_DECIMALS_FACTOR) > BASIS_POINTS) {
                return false;
            }
        }
        return true;
    }

    /// @notice Updated cached curve value with a custom tolerance towards chainlink
    /// @param tolerance How much difference between curve and chainlink can be tolerated
    function updateRatiosWithTolerance(uint256 tolerance) external override returns (bool) {
        require(msg.sender == controller || msg.sender == owner(), "updateRatiosWithTolerance: !authorized");
        return _updateRatios(tolerance);
    }

    /// @notice Updated cached curve values
    function updateRatios() external override returns (bool) {
        require(msg.sender == controller || msg.sender == owner(), "updateRatios: !authorized");
        return _updateRatios(BASIS_POINTS);
    }

    /// @notice Get USD value for a specific input amount of tokens, slippage included
    function stableToUsd(uint256[N_COINS] calldata inAmounts, bool deposit) external view override returns (uint256) {
        return _stableToUsd(inAmounts, deposit);
    }

    /// @notice Get estimate USD price of a stablecoin amount
    /// @param inAmount Token amount
    /// @param i Index of token
    function singleStableToUsd(uint256 inAmount, uint256 i) external view override returns (uint256) {
        uint256[N_COINS] memory inAmounts;
        inAmounts[i] = inAmount;
        return _stableToUsd(inAmounts, true);
    }

    /// @notice Get LP token value of input amount of tokens
    function stableToLp(uint256[N_COINS] calldata tokenAmounts, bool deposit) external view override returns (uint256) {
        return _stableToLp(tokenAmounts, deposit);
    }

    /// @notice Get LP token value of input amount of single token
    function singleStableFromUsd(uint256 inAmount, int128 i) external view override returns (uint256) {
        return _singleStableFromLp(_usdToLp(inAmount), i);
    }

    /// @notice Get LP token value of input amount of single token
    function singleStableFromLp(uint256 inAmount, int128 i) external view override returns (uint256) {
        return _singleStableFromLp(inAmount, i);
    }

    /// @notice Get USD price of LP tokens you receive for a specific input amount of tokens, slippage included
    function lpToUsd(uint256 inAmount) external view override returns (uint256) {
        return _lpToUsd(inAmount);
    }

    /// @notice Convert USD amount to LP tokens
    function usdToLp(uint256 inAmount) external view override returns (uint256) {
        return _usdToLp(inAmount);
    }

    /// @notice Split LP token amount to balance of pool tokens
    /// @param inAmount Amount of LP tokens
    /// @param totalBalance Total balance of pool
    function poolBalances(uint256 inAmount, uint256 totalBalance)
        internal
        view
        returns (uint256[N_COINS] memory balances)
    {
        uint256[N_COINS] memory _balances;
        for (uint256 i = 0; i < N_COINS; i++) {
            _balances[i] = (IERC20(getToken(i)).balanceOf(address(curvePool)).mul(inAmount)).div(totalBalance);
        }
        balances = _balances;
    }

    function getVirtualPrice() external view override returns (uint256) {
        return curvePool.get_virtual_price();
    }

    // Internal functions
    function _lpToUsd(uint256 inAmount) internal view returns (uint256) {
        return inAmount.mul(curvePool.get_virtual_price()).div(DEFAULT_DECIMALS_FACTOR);
    }

    function _stableToUsd(uint256[N_COINS] memory tokenAmounts, bool deposit) internal view returns (uint256) {
        require(tokenAmounts.length == N_COINS, "deposit: !length");
        uint256[N_COINS] memory _tokenAmounts;
        for (uint256 i = 0; i < N_COINS; i++) {
            _tokenAmounts[i] = tokenAmounts[i];
        }
        uint256 lpAmount = curvePool.calc_token_amount(_tokenAmounts, deposit);
        return _lpToUsd(lpAmount);
    }

    function _stableToLp(uint256[N_COINS] memory tokenAmounts, bool deposit) internal view returns (uint256) {
        require(tokenAmounts.length == N_COINS, "deposit: !length");
        uint256[N_COINS] memory _tokenAmounts;
        for (uint256 i = 0; i < N_COINS; i++) {
            _tokenAmounts[i] = tokenAmounts[i];
        }
        return curvePool.calc_token_amount(_tokenAmounts, deposit);
    }

    function _singleStableFromLp(uint256 inAmount, int128 i) internal view returns (uint256) {
        uint256 result = curvePool.calc_withdraw_one_coin(inAmount, i);
        return result;
    }

    /// @notice Convert USD amount to LP tokens
    function _usdToLp(uint256 inAmount) internal view returns (uint256) {
        return inAmount.mul(DEFAULT_DECIMALS_FACTOR).div(curvePool.get_virtual_price());
    }

    /// @notice Calculate price ratios for stablecoins
    ///     Get USD price data for stablecoin
    /// @param i Stablecoin to get USD price for
    function getPriceFeed(uint256 i) external view override returns (uint256 _price) {
        _price = uint256(IChainlinkAggregator(getAggregator(i)).latestAnswer());
    }

    /// @notice Fetch chainlink token ratios
    /// @param i Token in
    function getTokenRatios(uint256 i) private view returns (uint256[3] memory _ratios) {
        uint256[3] memory _prices;
        _prices[0] = uint256(IChainlinkAggregator(getAggregator(0)).latestAnswer());
        _prices[1] = uint256(IChainlinkAggregator(getAggregator(1)).latestAnswer());
        _prices[2] = uint256(IChainlinkAggregator(getAggregator(2)).latestAnswer());
        for (uint256 j = 0; j < 3; j++) {
            if (i == j) {
                _ratios[i] = CHAINLINK_PRICE_DECIMAL_FACTOR;
            } else {
                _ratios[j] = _prices[i].mul(CHAINLINK_PRICE_DECIMAL_FACTOR).div(_prices[j]);
            }
        }
        return _ratios;
    }

    function getAggregator(uint256 index) private view returns (address) {
        if (index == 0) {
            return daiUsdAgg;
        } else if (index == 1) {
            return usdcUsdAgg;
        } else {
            return usdtUsdAgg;
        }
    }

    /// @notice Get absolute value
    function abs(int256 x) private pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    function _updateRatios(uint256 tolerance) private returns (bool) {
        uint256[N_COINS] memory chainRatios = getTokenRatios(0);
        uint256[N_COINS] memory newRatios;
        for (uint256 i = 1; i < N_COINS; i++) {
            uint256 _ratio = curvePool.get_dy(int128(0), int128(i), getDecimal(0));
            uint256 check = abs(int256(_ratio) - int256(chainRatios[i].div(CHAIN_FACTOR)));
            if (check.mul(PERCENTAGE_DECIMAL_FACTOR).div(CURVE_RATIO_DECIMALS_FACTOR) > tolerance) {
                return false;
            } else {
                newRatios[i] = _ratio;
            }
        }
        for (uint256 i = 1; i < N_COINS; i++) {
            lastRatio[i] = newRatios[i];
        }
        return true;
    }
}

pragma solidity >=0.6.0 <0.7.0;

interface IChainlinkAggregator {
    function latestAnswer() external view returns (int256);

    function latestRound() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "contracts/interfaces/IChainlinkAggregator.sol";

contract MockAggregator is IChainlinkAggregator {
    uint80 public roundId_;
    int256 public answer_;
    uint256 public startedAt_;
    uint256 public updatedAt_;
    uint80 public answeredInRound_;

    constructor(int256 latestPrice) public {
        roundId_ = 1;
        answer_ = latestPrice;
        startedAt_ = block.timestamp;
        updatedAt_ = block.timestamp;
        answeredInRound_ = 1;
    }

    function setPrice(int256 newPrice) external {
        answer_ = newPrice;
        updatedAt_ = block.timestamp;
        answeredInRound_ = answeredInRound_ + 1;
        roundId_ = roundId_ + 1;
    }

    function latestRound() external view override returns (uint256) {
        return uint256(roundId_);
    }

    function latestAnswer() external view override returns (int256) {
        return answer_;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ILifeGuard.sol";
import "../interfaces/IController.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IBuoy.sol";
import "../common/Constants.sol";
import "../common/Controllable.sol";

// LP -> Liquidity pool token
contract MockLifeGuard is Constants, Controllable, ILifeGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address[] public stablecoins;
    address public buoy;

    uint256 constant vp = 1005330723799997871;
    uint256[] public decimals = [18, 6, 6];
    uint256[] vpSingle = [996343755718242128, 994191500557422927, 993764724471177721];
    uint256[] public balanced = [30, 30, 40];
    uint256[] public inAmounts;

    uint256 private _totalAssets;
    uint256 private _totalAssetsUsd;
    uint256 private _depositStableAmount;

    mapping(uint256 => uint256) public override assets;

    function setDepositStableAmount(uint256 depositStableAmount) external {
        _depositStableAmount = depositStableAmount;
    }

    function setStablecoins(address[] calldata _stablecoins) external {
        stablecoins = _stablecoins;
    }

    function setBuoy(address _buoy) external {
        buoy = _buoy;
    }

    function totalAssets() external view override returns (uint256) {
        return usdToLp(_totalAssetsUsd);
    }

    function _stableToUsd(uint256[] memory inAmounts, bool _deposit) private view returns (uint256) {
        uint256 lp = _stableToLp(inAmounts, _deposit);
        return _lpToUsd(lp);
    }

    function stableToLp(uint256[] calldata inAmounts, bool _deposit) external view returns (uint256) {
        return _stableToLp(inAmounts, _deposit);
    }

    function _stableToLp(uint256[] memory inAmounts, bool _deposit) private view returns (uint256) {
        uint256 totalAmount;
        for (uint256 i = 0; i < vpSingle.length; i++) {
            totalAmount = totalAmount.add(inAmounts[i].mul(vpSingle[i]).div(10**decimals[i]));
        }
        return totalAmount;
    }

    function singleStableFromLp(uint256 inAmount, uint256 i) external view returns (uint256) {
        return _singleStableFromLp(inAmount, i);
    }

    function _singleStableFromLp(uint256 inAmount, uint256 i) private view returns (uint256) {
        return inAmount.mul(10**decimals[i]).div(vpSingle[i]);
    }

    function underlyingCoins(uint256 index) external view returns (address coin) {
        return stablecoins[index];
    }

    function depositStable(bool curve) external override returns (uint256) {
        return _depositStableAmount;
    }

    function setInAmounts(uint256[] memory _inAmounts) external {
        inAmounts = _inAmounts;
    }

    function deposit() external override returns (uint256 usdAmount) {
        usdAmount = _stableToUsd(inAmounts, true);
        _totalAssetsUsd += usdAmount;
    }

    function withdraw(uint256 inAmount, address recipient)
        external
        returns (uint256 usdAmount, uint256[] memory amounts)
    {
        usdAmount = _lpToUsd(inAmount);
        if (_totalAssetsUsd > usdAmount) _totalAssetsUsd -= usdAmount;
        else _totalAssetsUsd = 0;
        amounts = new uint256[](3);
        address[N_COINS] memory vaults = _controller().vaults();
        for (uint256 i = 0; i < 3; i++) {
            uint256 lpAmount = inAmount.mul(balanced[i]).div(100);
            amounts[i] = _singleStableFromLp(lpAmount, i);
            IERC20 token = IERC20(IVault(vaults[i]).token());
            if (token.balanceOf(vaults[i]) > amounts[i]) token.transferFrom(vaults[i], recipient, amounts[i]);
        }
    }

    function withdrawSingleByLiquidity(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external override returns (uint256 usdAmount, uint256 amount) {
        usdAmount = _lpToUsd(inAmounts[0]);
        amount = _singleStableFromLp(inAmounts[0], i);
        address[N_COINS] memory vaults = _controller().vaults();
        IERC20 token = IERC20(IVault(vaults[i]).token());
        if (token.balanceOf(vaults[i]) > amount) token.transferFrom(vaults[i], recipient, amount);
    }

    function withdrawSingleByExchange(
        uint256 i,
        uint256 minAmount,
        address recipient
    ) external override returns (uint256 usdAmount, uint256 amount) {
        usdAmount = _lpToUsd(inAmounts[0]);
        amount = _singleStableFromLp(inAmounts[0], i);
        address[N_COINS] memory vaults = _controller().vaults();
        IERC20 token = IERC20(IVault(vaults[i]).token());
        if (token.balanceOf(vaults[i]) > amount) token.transferFrom(vaults[i], recipient, amount);
    }

    function invest(uint256 whaleDepositAmount, uint256[3] calldata delta) external override returns (uint256) {
        address[N_COINS] memory vaults = _controller().vaults();
        for (uint256 i; i < vaults.length; i++) {
            IERC20 token = IERC20(IVault(vaults[i]).token());
            token.transfer(vaults[i], token.balanceOf(address(this)));
        }
        _totalAssetsUsd -= whaleDepositAmount;
        return whaleDepositAmount;
    }

    function getEmergencyPrice(uint256 token) external view returns (uint256, uint256) {
        uint256 ratios = uint256(10)**decimals[token];
        uint256 decimals = uint256(10)**decimals[token];
        return (ratios, decimals);
    }

    function singleStableToUsd(uint256 inAmount, uint256 i) external view returns (uint256) {
        uint256[] memory inAmounts = new uint256[](stablecoins.length);
        inAmounts[i] = inAmount;
        return _stableToUsd(inAmounts, true);
    }

    function singleStableFromUsd(uint256 inAmount, uint256 i) public view returns (uint256) {
        return _singleStableFromLp(_lpToUsd(inAmount), i);
    }

    function _lpToUsd(uint256 inAmount) private pure returns (uint256) {
        return inAmount.mul(vp).div(DEFAULT_DECIMALS_FACTOR);
    }

    function usdToLp(uint256 inAmount) private view returns (uint256) {
        return inAmount.mul(DEFAULT_DECIMALS_FACTOR).div(vp);
    }

    function getBuoy() external view override returns (address) {
        return buoy;
    }

    address public exchanger;

    function setExchanger(address _exchanger) external {
        exchanger = _exchanger;
    }

    function investSingle(
        uint256[3] calldata inAmounts,
        uint256 i,
        uint256 j
    ) external override returns (uint256 dollarAmount) {
        dollarAmount = IBuoy(buoy).stableToUsd(inAmounts, true);
        for (uint256 k; k < 3; k++) {
            if (k == i || k == j) continue;
            uint256 inBalance = inAmounts[k];
            if (inBalance > 0) {
                _exchange(inBalance, k, i);
            }
        }
        if (inAmounts[i] > 0) {
            address vault = _controller().vaults()[i];
            IERC20 token = IERC20(IVault(vault).token());
            token.transfer(vault, token.balanceOf(address(this)));
        }
        if (inAmounts[j] > 0) {
            address vault = _controller().vaults()[j];
            IERC20 token = IERC20(IVault(vault).token());
            token.transfer(vault, token.balanceOf(address(this)));
        }
    }

    function _exchange(
        uint256 amount,
        uint256 src,
        uint256 dest
    ) private returns (uint256) {
        IERC20(stablecoins[src]).transfer(exchanger, amount);
        uint256 descAmount = amount.mul(10**decimals[dest]).div(10**decimals[src]);
        IERC20(stablecoins[dest]).transferFrom(exchanger, address(this), descAmount);
        return descAmount;
    }

    function availableLP() external view override returns (uint256) {}

    function availableUsd() external view override returns (uint256 dollar) {}

    function investToCurveVault() external override {}

    function distributeCurveVault(uint256 amount, uint256[3] memory delta)
        external
        override
        returns (uint256[3] memory)
    {}

    function totalAssetsUsd() external view override returns (uint256) {
        return _totalAssetsUsd;
    }

    function investToCurveVaultTrigger() external view override returns (bool) {}

    function getAssets() external view override returns (uint256[3] memory) {}
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IPnL.sol";
import "../common/Controllable.sol";
import "../interfaces/IPnL.sol";
import "../common/Constants.sol";
import {FixedGTokens} from "../common/FixedContracts.sol";

/// @notice Contract for calculating protocol profit and loss. The PnL contract stores snapshots
///     of total assets in pwrd and gvt, which are used to calculate utilisation ratio and establish
///     changes in underling pwrd and gvt factors. The protocol will allow these values to drift as long
///     as they stay within a certain threshold of protocol actuals, or large amounts of assets are being
///     deposited or withdrawn from the protocol. The PnL contract ensures that any profits are distributed
///     between pwrd and gvt based on the utilisation ratio - as this ratio movese towards 1, a larger
///     amount of the pwrd profit is shifted to gvt. Protocol losses are on the other hand soaked up
///     by gvt, ensuring that pwrd never lose value.
///
///     ###############################################
///     PnL variables and calculations
///     ###############################################
///
///     yield - system gains and losses from assets invested into strategies are realised once
///         a harvest is run. Yield is ditributed to pwrd and gvt based on the utilisation ratio of the
///         two tokens (see _calcProfit).
///
///     PerformanceFee - The performance fee is deducted from any yield profits, and is used to
///         buy back and distribute governance tokens to users.
///
///     hodler Fee - Withdrawals experience a hodler fee that is socialized to all other holders.
///         Like other gains, this isn't realised on withdrawal, but rather when a critical amount
///         has amassed in the system (totalAssetsPercentThreshold).
///
///     ###############################################
///     PnL Actions
///     ###############################################
///
///     Pnl has two trigger mechanisms:
///         - Harvest:
///             - It will realize any loss/profit from the strategy
///             - It will atempt to update lastest cached curve stable coin dy
///                 - if successfull, it will try to realize any price changes (pre tvl vs current)
///         - Withdrawals
///             - Any user withdrawals are distributing the holder fee to the other users
contract PnL is Controllable, Constants, FixedGTokens, IPnL {
    using SafeMath for uint256;

    uint256 public override lastGvtAssets;
    uint256 public override lastPwrdAssets;
    bool public rebase = true;

    uint256 public performanceFee; // Amount of gains to use to buy back and distribute gov tokens

    event LogRebaseSwitch(bool status);
    event LogNewPerfromanceFee(uint256 fee);
    event LogNewGtokenChange(bool pwrd, int256 change);
    event LogPnLExecution(
        uint256 deductedAssets,
        int256 totalPnL,
        int256 investPnL,
        int256 pricePnL,
        uint256 withdrawalBonus,
        uint256 performanceBonus,
        uint256 beforeGvtAssets,
        uint256 beforePwrdAssets,
        uint256 afterGvtAssets,
        uint256 afterPwrdAssets
    );

    constructor(
        address pwrd,
        address gvt,
        uint256 pwrdAssets,
        uint256 gvtAssets
    ) public FixedGTokens(pwrd, gvt) {
        lastPwrdAssets = pwrdAssets;
        lastGvtAssets = gvtAssets;
    }

    /// @notice Turn pwrd rebasing on/off - This stops yield/ hodler bonuses to be distributed to the pwrd
    ///     token, which effectively stops it from rebasing any further.
    function setRebase(bool _rebase) external onlyOwner {
        rebase = _rebase;
        emit LogRebaseSwitch(_rebase);
    }

    /// @notice Fee taken from gains to be redistributed to users who stake their tokens
    /// @param _performanceFee Amount to remove from gains (%BP)
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        performanceFee = _performanceFee;
        emit LogNewPerfromanceFee(_performanceFee);
    }

    /// @notice Increase previously recorded GToken assets by specific amount
    /// @param pwrd pwrd/gvt
    /// @param dollarAmount Amount to increase by
    function increaseGTokenLastAmount(bool pwrd, uint256 dollarAmount) external override {
        require(msg.sender == controller, "increaseGTokenLastAmount: !controller");
        if (!pwrd) {
            lastGvtAssets = lastGvtAssets.add(dollarAmount);
        } else {
            lastPwrdAssets = lastPwrdAssets.add(dollarAmount);
        }
        emit LogNewGtokenChange(pwrd, int256(dollarAmount));
    }

    /// @notice Decrease previously recorded GToken assets by specific amount
    /// @param pwrd pwrd/gvt
    /// @param dollarAmount Amount to decrease by
    /// @param bonus hodler bonus
    function decreaseGTokenLastAmount(
        bool pwrd,
        uint256 dollarAmount,
        uint256 bonus
    ) external override {
        require(msg.sender == controller, "decreaseGTokenLastAmount: !controller");
        uint256 lastGA = lastGvtAssets;
        uint256 lastPA = lastPwrdAssets;
        if (!pwrd) {
            lastGA = dollarAmount > lastGA ? 0 : lastGA.sub(dollarAmount);
        } else {
            lastPA = dollarAmount > lastPA ? 0 : lastPA.sub(dollarAmount);
        }
        if (bonus > 0) {
            uint256 preGABeforeBonus = lastGA;
            uint256 prePABeforeBonus = lastPA;
            uint256 preTABeforeBonus = preGABeforeBonus.add(prePABeforeBonus);
            if (rebase) {
                lastGA = preGABeforeBonus.add(bonus.mul(preGABeforeBonus).div(preTABeforeBonus));
                lastPA = prePABeforeBonus.add(bonus.mul(prePABeforeBonus).div(preTABeforeBonus));
            } else {
                lastGA = preGABeforeBonus.add(bonus);
            }
            emit LogPnLExecution(0, int256(bonus), 0, 0, bonus, 0, preGABeforeBonus, prePABeforeBonus, lastGA, lastPA);
        }

        lastGvtAssets = lastGA;
        lastPwrdAssets = lastPA;
        emit LogNewGtokenChange(pwrd, int256(-dollarAmount));
    }

    /// @notice Return latest system asset states
    function calcPnL() external view override returns (uint256, uint256) {
        return (lastGvtAssets, lastPwrdAssets);
    }

    /// @notice Calculate utilisation ratio between gvt and pwrd
    function utilisationRatio() external view override returns (uint256) {
        return lastGvtAssets != 0 ? lastPwrdAssets.mul(PERCENTAGE_DECIMAL_FACTOR).div(lastGvtAssets) : 0;
    }

    /// @notice Update assets after entering emergency state
    function emergencyPnL() external override {
        require(msg.sender == controller, "emergencyPnL: !controller");
        forceDistribute();
    }

    /// @notice Recover system from emergency state
    function recover() external override {
        require(msg.sender == controller, "recover: !controller");
        forceDistribute();
    }

    /// @notice Distribute yield based on utilisation ratio
    /// @param gvtAssets Total gvt assets
    /// @param pwrdAssets Total pwrd assets
    /// @param profit Amount of profit to distribute
    /// @param reward Rewards contract
    function handleInvestGain(
        uint256 gvtAssets,
        uint256 pwrdAssets,
        uint256 profit,
        address reward
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 performanceBonus;
        if (performanceFee > 0 && reward != address(0)) {
            performanceBonus = profit.mul(performanceFee).div(PERCENTAGE_DECIMAL_FACTOR);
            profit = profit.sub(performanceBonus);
        }
        if (rebase) {
            uint256 totalAssets = gvtAssets.add(pwrdAssets);
            uint256 gvtProfit = profit.mul(gvtAssets).div(totalAssets);
            uint256 pwrdProfit = profit.mul(pwrdAssets).div(totalAssets);

            uint256 factor = pwrdAssets.mul(10000).div(gvtAssets);
            if (factor > 10000) factor = 10000;
            if (factor < 8000) {
                factor = factor.mul(3).div(8).add(3000);
            } else {
                factor = factor.sub(8000).mul(2).add(6000);
            }

            uint256 portionFromPwrdProfit = pwrdProfit.mul(factor).div(10000);
            gvtAssets = gvtAssets.add(gvtProfit.add(portionFromPwrdProfit));
            pwrdAssets = pwrdAssets.add(pwrdProfit.sub(portionFromPwrdProfit));
        } else {
            gvtAssets = gvtAssets.add(profit);
        }
        return (gvtAssets, pwrdAssets, performanceBonus);
    }

    /// @notice Distribute losses
    /// @param gvtAssets Total gvt assets
    /// @param pwrdAssets Total pwrd assets
    /// @param loss Amount of loss to distribute
    function handleLoss(
        uint256 gvtAssets,
        uint256 pwrdAssets,
        uint256 loss
    ) private pure returns (uint256, uint256) {
        uint256 maxGvtLoss = gvtAssets.sub(DEFAULT_DECIMALS_FACTOR);
        if (loss > maxGvtLoss) {
            gvtAssets = DEFAULT_DECIMALS_FACTOR;
            pwrdAssets = pwrdAssets.sub(loss.sub(maxGvtLoss));
        } else {
            gvtAssets = gvtAssets - loss;
        }
        return (gvtAssets, pwrdAssets);
    }

    function forceDistribute() private {
        uint256 total = _controller().totalAssets();

        if (total > lastPwrdAssets.add(DEFAULT_DECIMALS_FACTOR)) {
            lastGvtAssets = total - lastPwrdAssets;
        } else {
            lastGvtAssets = DEFAULT_DECIMALS_FACTOR;
            lastPwrdAssets = total.sub(DEFAULT_DECIMALS_FACTOR);
        }
    }

    function distributeStrategyGainLoss(
        uint256 gain,
        uint256 loss,
        address reward
    ) external override {
        require(msg.sender == controller, "!Controller");
        uint256 lastGA = lastGvtAssets;
        uint256 lastPA = lastPwrdAssets;
        uint256 performanceBonus;
        uint256 gvtAssets;
        uint256 pwrdAssets;
        int256 investPnL;
        if (gain > 0) {
            (gvtAssets, pwrdAssets, performanceBonus) = handleInvestGain(lastGA, lastPA, gain, reward);
            if (performanceBonus > 0) {
                gvt.mint(reward, gvt.factor(gvtAssets), performanceBonus);
                gvtAssets = gvtAssets.add(performanceBonus);
            }

            lastGvtAssets = gvtAssets;
            lastPwrdAssets = pwrdAssets;
            investPnL = int256(gain);
        } else if (loss > 0) {
            (lastGvtAssets, lastPwrdAssets) = handleLoss(lastGA, lastPA, loss);
            investPnL = -int256(loss);
        }

        emit LogPnLExecution(
            0,
            investPnL,
            investPnL,
            0,
            0,
            performanceBonus,
            lastGA,
            lastPA,
            lastGvtAssets,
            lastPwrdAssets
        );
    }

    function distributePriceChange(uint256 currentTotalAssets) external override {
        require(msg.sender == controller, "!Controller");
        uint256 gvtAssets = lastGvtAssets;
        uint256 pwrdAssets = lastPwrdAssets;
        uint256 totalAssets = gvtAssets.add(pwrdAssets);

        if (currentTotalAssets > totalAssets) {
            lastGvtAssets = gvtAssets.add(currentTotalAssets.sub(totalAssets));
        } else if (currentTotalAssets < totalAssets) {
            (lastGvtAssets, lastPwrdAssets) = handleLoss(gvtAssets, pwrdAssets, totalAssets.sub(currentTotalAssets));
        }
        int256 priceChange = int256(currentTotalAssets) - int256(totalAssets);

        emit LogPnLExecution(
            0,
            priceChange,
            0,
            priceChange,
            0,
            0,
            gvtAssets,
            pwrdAssets,
            lastGvtAssets,
            lastPwrdAssets
        );
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {FixedStablecoins, FixedVaults} from "./common/FixedContracts.sol";
import "./common/Controllable.sol";

import "./interfaces/IBuoy.sol";
import "./interfaces/IDepositHandler.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IInsurance.sol";
import "./interfaces/ILifeGuard.sol";

/// @notice Entry point for deposits into Gro protocol - User deposits can be done with one or
///     multiple assets, being more expensive gas wise for each additional asset that is deposited.
///     The deposits are treated differently depending on size:
///         1) sardine - the smallest type of deposit, deemed to not affect the system exposure, and
///            is deposited directly into the system - Curve vault is used to price the deposit (buoy)
///         2) tuna - mid sized deposits, will be swapped to least exposed vault asset using Curve's
///            exchange function (lifeguard). Targeting the desired asset (single sided deposit
///            against the least exposed stablecoin) minimizes slippage as it doesn't need to perform
///            any exchanges in the Curve pool
///         3) whale - the largest deposits - deposit will be distributed across all stablecoin vaults
///
///     Tuna and Whale deposits will go through the lifeguard, which in turn will perform all
///     necessary asset swaps.
contract DepositHandler is Controllable, FixedStablecoins, FixedVaults, IDepositHandler {
    IController public ctrl;
    ILifeGuard public lg;
    IBuoy public buoy;
    IInsurance public insurance;

    mapping(uint256 => bool) public feeToken; // (USDT might have a fee)

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event LogNewFeeToken(address indexed token, uint256 index);
    event LogNewDependencies(address controller, address lifeguard, address buoy, address insurance);
    event LogNewDeposit(
        address indexed user,
        address indexed referral,
        bool pwrd,
        uint256 usdAmount,
        uint256[N_COINS] tokens
    );

    constructor(
        uint256 _feeToken,
        address[N_COINS] memory _vaults,
        address[N_COINS] memory _tokens,
        uint256[N_COINS] memory _decimals
    ) public FixedStablecoins(_tokens, _decimals) FixedVaults(_vaults) {
        feeToken[_feeToken] = true;
    }

    /// @notice Update protocol dependencies
    function setDependencies() external onlyOwner {
        ctrl = _controller();
        lg = ILifeGuard(ctrl.lifeGuard());
        buoy = IBuoy(lg.getBuoy());
        insurance = IInsurance(ctrl.insurance());
        emit LogNewDependencies(address(ctrl), address(lg), address(buoy), address(insurance));
    }

    /// @notice Some tokens might have fees associated with them (e.g. USDT)
    /// @param index Index (of system tokens) that could have fees
    function setFeeToken(uint256 index) external onlyOwner {
        address token = ctrl.stablecoins()[index];
        require(token != address(0), "setFeeToken: !invalid token");
        feeToken[index] = true;
        emit LogNewFeeToken(token, index);
    }

    /// @notice Entry when depositing for pwrd
    /// @param inAmounts Amount of each stablecoin deposited
    /// @param minAmount Minimum ammount to expect in return for deposit
    /// @param _referral Referral address (only useful for first deposit)
    function depositPwrd(
        uint256[N_COINS] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external override whenNotPaused {
        depositGToken(inAmounts, minAmount, _referral, true);
    }

    /// @notice Entry when depositing for gvt
    /// @param inAmounts Amount of each stablecoin deposited
    /// @param minAmount Minimum ammount to expect in return for deposit
    /// @param _referral Referral address (only useful for first deposit)
    function depositGvt(
        uint256[N_COINS] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external override whenNotPaused {
        depositGToken(inAmounts, minAmount, _referral, false);
    }

    /// @notice Deposit logic
    /// @param inAmounts Amount of each stablecoin deposited
    /// @param minAmount Minimum amount to expect in return for deposit
    /// @param _referral Referral address (only useful for first deposit)
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    function depositGToken(
        uint256[N_COINS] memory inAmounts,
        uint256 minAmount,
        address _referral,
        bool pwrd
    ) private {
        ctrl.eoaOnly(msg.sender);
        require(minAmount > 0, "minAmount is 0");
        require(buoy.safetyCheck(), "!safetyCheck");
        ctrl.addReferral(msg.sender, _referral);

        uint256 roughUsd = roughUsd(inAmounts);
        uint256 dollarAmount = _deposit(pwrd, roughUsd, minAmount, inAmounts);
        ctrl.mintGToken(pwrd, msg.sender, dollarAmount);
        // Update underlying assets held in pwrd/gvt
        emit LogNewDeposit(msg.sender, ctrl.referrals(msg.sender), pwrd, dollarAmount, inAmounts);
    }

    /// @notice Determine the size of the deposit, and route it accordingly:
    ///     sardine (small) - gets sent directly to the vault adapter
    ///     tuna (middle) - tokens get routed through lifeguard and exchanged to
    ///             target token (based on current vault exposure)
    ///     whale (large) - tokens get deposited into lifeguard Curve pool, withdraw
    ///             into target amounts and deposited across all vaults
    /// @param roughUsd Estimated USD value of deposit, used to determine size
    /// @param minAmount Minimum amount to return (in Curve LP tokens)
    /// @param inAmounts Input token amounts
    function _deposit(
        bool pwrd,
        uint256 roughUsd,
        uint256 minAmount,
        uint256[N_COINS] memory inAmounts
    ) private returns (uint256 dollarAmount) {
        // If a large fish, transfer assets to lifeguard before determening what to do with them
        if (ctrl.isValidBigFish(pwrd, true, roughUsd)) {
            for (uint256 i = 0; i < N_COINS; i++) {
                // Transfer token to target (lifeguard)
                if (inAmounts[i] > 0) {
                    IERC20 token = IERC20(getToken(i));
                    if (feeToken[i]) {
                        // Separate logic for USDT
                        uint256 current = token.balanceOf(address(lg));
                        token.safeTransferFrom(msg.sender, address(lg), inAmounts[i]);
                        inAmounts[i] = token.balanceOf(address(lg)).sub(current);
                    } else {
                        token.safeTransferFrom(msg.sender, address(lg), inAmounts[i]);
                    }
                }
            }
            dollarAmount = _invest(inAmounts, roughUsd);
        } else {
            // If sardine, send the assets directly to the vault adapter
            for (uint256 i = 0; i < N_COINS; i++) {
                if (inAmounts[i] > 0) {
                    // Transfer token to vaultadaptor
                    IERC20 token = IERC20(getToken(i));
                    address _vault = getVault(i);
                    if (feeToken[i]) {
                        // Seperate logic for USDT
                        uint256 current = token.balanceOf(_vault);
                        token.safeTransferFrom(msg.sender, _vault, inAmounts[i]);
                        inAmounts[i] = token.balanceOf(_vault).sub(current);
                    } else {
                        token.safeTransferFrom(msg.sender, _vault, inAmounts[i]);
                    }
                }
            }
            // Establish USD vault of deposit
            dollarAmount = buoy.stableToUsd(inAmounts, true);
        }
        require(dollarAmount >= buoy.lpToUsd(minAmount), "!minAmount");
    }

    /// @notice Determine how to handle the deposit - get stored vault deltas and indexes,
    ///     and determine if the deposit will be a tuna (deposits into least exposed vaults)
    ///        or a whale (spread across all three vaults)
    ///     Tuna - Deposit swaps all overexposed assets into least exposed asset before investing,
    ///         deposited assets into the two least exposed vaults
    ///     Whale - Deposits all assets into the lifeguard Curve pool, and withdraws
    ///         them in target allocation (insurance underlyingTokensPercents) amounts before
    ///        investing them into all vaults
    /// @param _inAmounts Input token amounts
    /// @param roughUsd Estimated rough USD value of deposit
    function _invest(uint256[N_COINS] memory _inAmounts, uint256 roughUsd) internal returns (uint256 dollarAmount) {
        // Calculate asset distribution - for large deposits, we will want to spread the
        // assets across all stablecoin vaults to avoid overexposure, otherwise we only
        // ensure that the deposit doesn't target the most overexposed vault
        (, uint256[N_COINS] memory vaultIndexes, uint256 _vaults) = insurance.getVaultDeltaForDeposit(roughUsd);
        if (_vaults < N_COINS) {
            dollarAmount = lg.investSingle(_inAmounts, vaultIndexes[0], vaultIndexes[1]);
        } else {
            uint256 outAmount = lg.deposit();
            uint256[N_COINS] memory delta = insurance.calculateDepositDeltasOnAllVaults();
            dollarAmount = lg.invest(outAmount, delta);
        }
    }

    /// @notice Give a USD estimate of the deposit - this is purely used to determine deposit size
    ///     and does not impact amount of tokens minted
    /// @param inAmounts Amount of tokens deposited
    function roughUsd(uint256[N_COINS] memory inAmounts) private view returns (uint256 usdAmount) {
        for (uint256 i; i < N_COINS; i++) {
            if (inAmounts[i] > 0) {
                usdAmount = usdAmount.add(inAmounts[i].mul(10**18).div(getDecimal(i)));
            }
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IController.sol";
import "../../interfaces/ILifeGuard.sol";
import "../../interfaces/IBuoy.sol";
import "../../interfaces/IWithdrawHandler.sol";

contract MockFlashLoanAttack {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private lifeguard;
    address private controller;

    function setController(address _controller) external {
        controller = _controller;
    }

    function setLifeGuard(address _lifeguard) external {
        lifeguard = _lifeguard;
    }

    function withdraw(bool pwrd, uint256 lpAmount) public {
        IController c = IController(controller);

        uint256[3] memory minAmounts;
        IWithdrawHandler(c.withdrawHandler()).withdrawByLPToken(pwrd, lpAmount, minAmounts);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import {FixedStablecoins, FixedGTokens} from "./common/FixedContracts.sol";
import "./common/Whitelist.sol";

import "./interfaces/IBuoy.sol";
import "./interfaces/IChainPrice.sol";
import "./interfaces/IController.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IInsurance.sol";
import "./interfaces/ILifeGuard.sol";
import "./interfaces/IPnL.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IVault.sol";

/// @notice The main hub for Gro protocol - The controller links up the other contracts,
///     and acts a route for the other contracts to call one another. It holds global states
///     such as paused and emergency. Contracts that depend on the controller implement
///     Controllable.
///
///     *****************************************************************************
///     System tokens - GTokens:
///     gvt - high yield, uninsured
///     pwrd - insured by gvt, pays part of its yield to gvt (depending on utilisation)
///
///     Tokens order is DAI, USDC, USDT.
///     Index 0 - DAI, 1 - USDC, 2 - USDT
///
///     System vaults:
///     Stablecoin vaults: One per stablecoin
///     Curve vault: Vault for LP (liquidity pool) token
contract Controller is Pausable, Ownable, Whitelist, FixedStablecoins, FixedGTokens, IController {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public override curveVault; // LP token vault

    bool public preventSmartContracts = false;

    address public override insurance; // Insurance logic
    address public override pnl; // Profit and loss calculations
    address public override lifeGuard; // Asset swapping
    address public override buoy; // Oracle
    address public override depositHandler;
    address public override withdrawHandler;
    address public override emergencyHandler;

    uint256 public override deadCoin = 99;
    bool public override emergencyState;
    // Lower bound for how many gvt can be burned before getting to close to the utilisation ratio
    uint256 public utilisationRatioLimitGvt;
    uint256 public utilisationRatioLimitPwrd;

    /// Limits for what deposits/withdrawals that are considered 'large', and thus will be handled with
    ///     a different logic - limits are checked against total assets locked in etiher of the two tokens (pwrd, gvt)
    uint256 public bigFishThreshold = 100; // %Basis Points limit
    uint256 public bigFishAbsoluteThreshold = 0; // Absolute limit
    address public override reward;

    mapping(address => bool) public safeAddresses; // Some integrations need to be exempt from flashloan checks
    mapping(uint256 => address) public override underlyingVaults; // Protocol stablecoin vaults
    mapping(address => uint256) public vaultIndexes;

    mapping(address => address) public override referrals;

    // Pwrd (true) and gvt (false) mapped to respective withdrawal fee
    mapping(bool => uint256) public override withdrawalFee;

    event LogNewWithdrawHandler(address tokens);
    event LogNewDepositHandler(address tokens);
    event LogNewVault(uint256 index, address vault);
    event LogNewCurveVault(address curveVault);
    event LogNewLifeguard(address lifeguard);
    event LogNewInsurance(address insurance);
    event LogNewPnl(address pnl);
    event LogNewBigFishThreshold(uint256 percent, uint256 absolute);
    event LogFlashSwitchUpdated(bool status);
    event LogNewSafeAddress(address account);
    event LogNewRewardsContract(address reward);
    event LogNewUtilLimit(bool indexed pwrd, uint256 limit);
    event LogNewCurveToStableDistribution(uint256 amount, uint256[N_COINS] amounts, uint256[N_COINS] delta);
    event LogNewWithdrawalFee(address user, bool pwrd, uint256 newFee);

    constructor(
        address pwrd,
        address gvt,
        address[N_COINS] memory _tokens,
        uint256[N_COINS] memory _decimals
    ) public FixedStablecoins(_tokens, _decimals) FixedGTokens(pwrd, gvt) {}

    function pause() external onlyWhitelist {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setWithdrawHandler(address _withdrawHandler, address _emergencyHandler) external onlyOwner {
        require(_withdrawHandler != address(0), "setWithdrawHandler: 0x");
        withdrawHandler = _withdrawHandler;
        emergencyHandler = _emergencyHandler;
        emit LogNewWithdrawHandler(_withdrawHandler);
    }

    function setDepositHandler(address _depositHandler) external onlyOwner {
        require(_depositHandler != address(0), "setDepositHandler: 0x");
        depositHandler = _depositHandler;
        emit LogNewDepositHandler(_depositHandler);
    }

    function stablecoins() external view override returns (address[N_COINS] memory) {
        return underlyingTokens();
    }

    /// @notice Returns amount to skim of larger deposits for alternative vault (Curve)
    function getSkimPercent() external view override returns (uint256) {
        return IInsurance(insurance).calcSkim();
    }

    /// @notice Returns list of all the underling protocol vaults
    function vaults() external view override returns (address[N_COINS] memory) {
        address[N_COINS] memory result;
        for (uint256 i = 0; i < N_COINS; i++) {
            result[i] = underlyingVaults[i];
        }
        return result;
    }

    /// @notice Set system vaults, vault index should match its underlying token
    function setVault(uint256 index, address vault) external onlyOwner {
        require(vault != address(0), "setVault: 0x");
        require(index < N_COINS, "setVault: !index");
        underlyingVaults[index] = vault;
        vaultIndexes[vault] = index + 1;
        emit LogNewVault(index, vault);
    }

    function setCurveVault(address _curveVault) external onlyOwner {
        require(_curveVault != address(0), "setCurveVault: 0x");
        curveVault = _curveVault;
        vaultIndexes[_curveVault] = N_COINS + 1;
        emit LogNewCurveVault(_curveVault);
    }

    function setLifeGuard(address _lifeGuard) external onlyOwner {
        require(_lifeGuard != address(0), "setLifeGuard: 0x");
        lifeGuard = _lifeGuard;
        buoy = ILifeGuard(_lifeGuard).getBuoy();
        emit LogNewLifeguard(_lifeGuard);
    }

    function setInsurance(address _insurance) external onlyOwner {
        require(_insurance != address(0), "setInsurance: 0x");
        insurance = _insurance;
        emit LogNewInsurance(_insurance);
    }

    function setPnL(address _pnl) external onlyOwner {
        require(_pnl != address(0), "setPnl: 0x");
        pnl = _pnl;
        emit LogNewPnl(_pnl);
    }

    function addSafeAddress(address account) external onlyOwner {
        safeAddresses[account] = true;
        emit LogNewSafeAddress(account);
    }

    function switchEoaOnly(bool check) external onlyOwner {
        preventSmartContracts = check;
    }

    /// @notice Set limit for when a deposit will be rerouted for alternative logic
    /// @param _percent %BP limit
    /// @param _absolute Absolute limit
    /// @dev The two limits should be used as an upper and lower bound - the % limit
    ///     considers the current TVL in the token interacted with (gvt or pwrd) and will
    ///     act as the upper bound when the TVL is low. The absolute value will be the lower bound,
    ///     ensuring that small deposits won't suffer higher gas costs.
    function setBigFishThreshold(uint256 _percent, uint256 _absolute) external onlyOwner {
        require(_percent > 0, "_whaleLimit is 0");
        bigFishThreshold = _percent;
        bigFishAbsoluteThreshold = _absolute;
        emit LogNewBigFishThreshold(_percent, _absolute);
    }

    function setReward(address _reward) external onlyOwner {
        require(_reward != address(0), "setReward: 0x");
        reward = _reward;
        emit LogNewRewardsContract(_reward);
    }

    function addReferral(address account, address referral) external override {
        require(msg.sender == depositHandler, "!depositHandler");
        if (account != address(0) && referral != address(0) && referrals[account] == address(0)) {
            referrals[account] = referral;
        }
    }

    /// @notice Set withdrawal fee for token
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param newFee New token fee
    function setWithdrawalFee(bool pwrd, uint256 newFee) external onlyOwner {
        withdrawalFee[pwrd] = newFee;
        emit LogNewWithdrawalFee(msg.sender, pwrd, newFee);
    }

    /// @notice Calculate system total assets
    function totalAssets() external view override returns (uint256) {
        return emergencyState ? _totalAssetsEmergency() : _totalAssets();
    }

    /// @notice Calculate pwrd/gro vault total assets
    function gTokenTotalAssets() public view override returns (uint256) {
        (uint256 gvtAssets, uint256 pwrdAssets) = IPnL(pnl).calcPnL();
        if (msg.sender == address(gvt)) {
            return gvtAssets;
        }
        if (msg.sender == address(pwrd)) {
            return pwrdAssets;
        }
        return 0;
    }

    function gToken(bool isPWRD) external view override returns (address) {
        return isPWRD ? address(pwrd) : address(gvt);
    }

    /// @notice Check if the deposit/withdrawal needs to go through alternate logic
    /// @param amount USD amount of deposit/withdrawal
    /// @dev Larger deposits are handled differently than small deposits in order
    ///     to guarantee that the system isn't overexposed to any one stablecoin
    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view override returns (bool) {
        if (deposit && pwrd) {
            require(validGTokenIncrease(amount), "isBigFish: !validGTokenIncrease");
        } else if (!pwrd && !deposit) {
            require(validGTokenDecrease(amount), "isBigFish: !validGTokenDecrease");
        }
        (uint256 gvtAssets, uint256 pwrdAssets) = IPnL(pnl).calcPnL();
        uint256 assets = pwrdAssets.add(gvtAssets);
        if (amount < bigFishAbsoluteThreshold) {
            return false;
        } else if (amount > assets) {
            return true;
        } else {
            return amount > assets.mul(bigFishThreshold).div(PERCENTAGE_DECIMAL_FACTOR);
        }
    }

    function distributeCurveAssets(uint256 amount, uint256[N_COINS] memory delta) external onlyWhitelist {
        uint256[N_COINS] memory amounts = ILifeGuard(lifeGuard).distributeCurveVault(amount, delta);
        emit LogNewCurveToStableDistribution(amount, amounts, delta);
    }

    /// @notice Block if not an EOA or whitelisted
    /// @param sender Address of contract to check
    function eoaOnly(address sender) public override {
        if (preventSmartContracts && !safeAddresses[tx.origin]) {
            require(sender == tx.origin, "EOA only");
        }
    }

    /// @notice TotalAssets = lifeguard + stablecoin vaults + LP vault
    function _totalAssets() private view returns (uint256) {
        require(IBuoy(buoy).safetyCheck(), "!buoy.safetyCheck");
        uint256[N_COINS] memory lgAssets = ILifeGuard(lifeGuard).getAssets();
        uint256[N_COINS] memory vaultAssets;
        for (uint256 i = 0; i < N_COINS; i++) {
            vaultAssets[i] = lgAssets[i].add(IVault(underlyingVaults[i]).totalAssets());
        }
        uint256 totalLp = IVault(curveVault).totalAssets();
        totalLp = totalLp.add(IBuoy(buoy).stableToLp(vaultAssets, true));
        uint256 vp = IBuoy(buoy).getVirtualPrice();

        return totalLp.mul(vp).div(DEFAULT_DECIMALS_FACTOR);
    }

    /// @notice Same as _totalAssets function, but excluding curve vault + 1 stablecoin
    ///             and uses chianlink as a price oracle
    function _totalAssetsEmergency() private view returns (uint256) {
        IChainPrice chainPrice = IChainPrice(buoy);
        uint256 total;
        for (uint256 i = 0; i < N_COINS; i++) {
            if (i != deadCoin) {
                address tokenAddress = getToken(i);
                uint256 decimals = getDecimal(i);
                IERC20 token = IERC20(tokenAddress);
                uint256 price = chainPrice.getPriceFeed(i);
                uint256 assets = IVault(underlyingVaults[i]).totalAssets().add(token.balanceOf(lifeGuard));
                assets = assets.mul(price).div(CHAINLINK_PRICE_DECIMAL_FACTOR);
                assets = assets.mul(DEFAULT_DECIMALS_FACTOR).div(decimals);
                total = total.add(assets);
            }
        }
        return total;
    }

    /// @notice Set protocol into emergency mode, disabling the use of a give stablecoin.
    ///             This state assumes:
    ///                 - Stablecoin of excessively of peg
    ///                 - Curve3Pool has failed
    ///             Swapping wil be disabled and the allocation target will be set to
    ///             100 % for the disabled stablecoin, effectively stopping the system from
    ///             returning any to the user. Deposit are disable in this mode.
    /// @param coin Stable coin to disable
    function emergency(uint256 coin) external onlyWhitelist {
        require(coin < N_COINS, "invalid coin");
        if (!paused()) {
            _pause();
        }
        deadCoin = coin;
        emergencyState = true;

        uint256 percent;
        for (uint256 i; i < N_COINS; i++) {
            if (i == coin) {
                percent = 10000;
            } else {
                percent = 0;
            }
            IInsurance(insurance).setUnderlyingTokenPercent(i, percent);
        }
        IPnL(pnl).emergencyPnL();
    }

    /// @notice Recover the system after emergency mode -
    /// @param allocations New system target allocations
    /// @dev Will recalculate system assets and atempt to give back any
    ///     recovered assets to the GVT side
    function restart(uint256[] calldata allocations) external onlyOwner whenPaused {
        _unpause();
        deadCoin = 99;
        emergencyState = false;

        for (uint256 i; i < N_COINS; i++) {
            IInsurance(insurance).setUnderlyingTokenPercent(i, allocations[i]);
        }
        IPnL(pnl).recover();
    }

    /// @notice Distribute any gains or losses generated from a harvest
    /// @param gain harvset gains
    /// @param loss harvest losses
    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external override {
        uint256 index = vaultIndexes[msg.sender];
        require(index > 0 || index <= N_COINS + 1, "!VaultAdaptor");
        IPnL ipnl = IPnL(pnl);
        IBuoy ibuoy = IBuoy(buoy);
        uint256 gainUsd;
        uint256 lossUsd;
        index = index - 1;
        if (index < N_COINS) {
            if (gain > 0) {
                gainUsd = ibuoy.singleStableToUsd(gain, index);
            } else if (loss > 0) {
                lossUsd = ibuoy.singleStableToUsd(loss, index);
            }
        } else {
            if (gain > 0) {
                gainUsd = ibuoy.lpToUsd(gain);
            } else if (loss > 0) {
                lossUsd = ibuoy.lpToUsd(loss);
            }
        }
        ipnl.distributeStrategyGainLoss(gainUsd, lossUsd, reward);
        // Check if curve spot price within tollerance, if so update them
        if (ibuoy.updateRatios()) {
            // If the curve ratios were successfully updated, realize system price changes
            ipnl.distributePriceChange(_totalAssets());
        }
    }

    function realizePriceChange(uint256 tolerance) external onlyOwner {
        IPnL ipnl = IPnL(pnl);
        IBuoy ibuoy = IBuoy(buoy);
        if (emergencyState) {
            ipnl.distributePriceChange(_totalAssetsEmergency());
        } else {
            // Check if curve spot price within tollerance, if so update them
            if (ibuoy.updateRatiosWithTolerance(tolerance)) {
                // If the curve ratios were successfully updated, realize system price changes
                ipnl.distributePriceChange(_totalAssets());
            }
        }
    }

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external override {
        require(msg.sender == withdrawHandler || msg.sender == emergencyHandler, "burnGToken: !withdrawHandler");
        IToken gt = gTokens(pwrd);
        if (!all) {
            gt.burn(account, gt.factor(), amount);
        } else {
            gt.burnAll(account);
        }
        // Update underlying assets held in pwrd/gvt
        IPnL(pnl).decreaseGTokenLastAmount(pwrd, amount, bonus);
    }

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external override {
        require(msg.sender == depositHandler, "burnGToken: !depositHandler");
        IToken gt = gTokens(pwrd);
        gt.mint(account, gt.factor(), amount);
        IPnL(pnl).increaseGTokenLastAmount(pwrd, amount);
    }

    /// @notice Calcualte withdrawal value when withdrawing all
    /// @param pwrd Pwrd or gvt (pwrd/gvt)
    /// @param account User account
    function getUserAssets(bool pwrd, address account) external view override returns (uint256 deductUsd) {
        IToken gt = gTokens(pwrd);
        deductUsd = gt.getAssets(account);
        require(deductUsd > 0, "!minAmount");
    }

    /// @notice Check if it's OK to mint the specified amount of tokens, this affects
    ///     pwrds, as they have an upper bound set by the amount of gvt
    /// @param amount Amount of token to mint
    function validGTokenIncrease(uint256 amount) private view returns (bool) {
        return
            gTokens(false).totalAssets().mul(utilisationRatioLimitPwrd).div(PERCENTAGE_DECIMAL_FACTOR) >=
            amount.add(gTokens(true).totalAssets());
    }

    /// @notice Check if it's OK to burn the specified amount of tokens, this affects
    ///     gvt, as they have a lower bound set by the amount of pwrds
    /// @param amount Amount of token to burn
    function validGTokenDecrease(uint256 amount) public view override returns (bool) {
        return
            gTokens(false).totalAssets().sub(amount).mul(utilisationRatioLimitGvt).div(PERCENTAGE_DECIMAL_FACTOR) >=
            gTokens(true).totalAssets();
    }

    /// @notice Set the lower bound for when to stop accepting deposits for pwrd - this allows for a bit of legroom
    ///     for gvt to be sold (if this limit is reached, this contract only accepts deposits for gvt)
    /// @param _utilisationRatioLimitPwrd Lower limit for pwrd (%BP)
    function setUtilisationRatioLimitPwrd(uint256 _utilisationRatioLimitPwrd) external onlyOwner {
        utilisationRatioLimitPwrd = _utilisationRatioLimitPwrd;
        emit LogNewUtilLimit(true, _utilisationRatioLimitPwrd);
    }

    /// @notice Set the lower bound for when to stop accepting gvt withdrawals
    /// @param _utilisationRatioLimitGvt Lower limit for pwrd (%BP)
    function setUtilisationRatioLimitGvt(uint256 _utilisationRatioLimitGvt) external onlyOwner {
        utilisationRatioLimitGvt = _utilisationRatioLimitGvt;
        emit LogNewUtilLimit(false, _utilisationRatioLimitGvt);
    }

    function getStrategiesTargetRatio() external view override returns (uint256[] memory) {
        uint256 utilRatio = IPnL(pnl).utilisationRatio();
        return IInsurance(insurance).getStrategiesTargetRatio(utilRatio);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../Controller.sol";
import "../../interfaces/ILifeGuard.sol";
import "../../interfaces/IBuoy.sol";
import "../../interfaces/IWithdrawHandler.sol";
import "../../interfaces/IDepositHandler.sol";
import "./MockFlashLoanAttack.sol";

contract MockFlashLoan {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private flNext;
    address private lifeguard;
    address private controller;

    constructor(address _flNext) public {
        flNext = _flNext;
    }

    function setController(address _controller) external {
        controller = _controller;
    }

    function setLifeGuard(address _lifeguard) external {
        lifeguard = _lifeguard;
    }

    function callNextChain(address gTokenAddress, uint256[3] calldata amounts) external {
        ILifeGuard lg = ILifeGuard(lifeguard);
        IBuoy buoy = IBuoy(lg.getBuoy());
        Controller c = Controller(controller);

        require(
            gTokenAddress == address(c.gvt()) || gTokenAddress == address(c.pwrd()),
            "invalid gTokenAddress"
        );

        address[3] memory tokens = c.stablecoins();
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(c.depositHandler(), amounts[i]);
        }
        uint256 lp = buoy.stableToLp(amounts, true);
        uint256 lpWithSlippage = lp.sub(lp.div(1000));
        bool pwrd = gTokenAddress == address(c.pwrd());
        if (pwrd) {
            IDepositHandler(c.depositHandler()).depositPwrd(amounts, lpWithSlippage, address(0));
        } else {
            IDepositHandler(c.depositHandler()).depositGvt(amounts, lpWithSlippage, address(0));
        }

        IERC20(gTokenAddress).transfer(flNext, IERC20(gTokenAddress).balanceOf(address(this)));
        MockFlashLoanAttack(flNext).withdraw(pwrd, lpWithSlippage);
    }

    function withdrawDeposit(bool pwrd, uint256[3] calldata amounts) external {
        ILifeGuard lg = ILifeGuard(lifeguard);
        IBuoy buoy = IBuoy(lg.getBuoy());
        Controller c = Controller(controller);

        uint256 lp = buoy.stableToLp(amounts, false);
        uint256 lpWithSlippage = lp.add(lp.div(1000));
        uint256[3] memory minAmounts;
        IWithdrawHandler(c.withdrawHandler()).withdrawByLPToken(pwrd, lpWithSlippage, minAmounts);

        address[3] memory tokens = c.stablecoins();
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(c.depositHandler(), amounts[i]);
        }
        lp = buoy.stableToLp(amounts, true);
        lpWithSlippage = lp.sub(lp.div(1000));
        if (pwrd) {
            IDepositHandler(c.depositHandler()).depositPwrd(amounts, lpWithSlippage, address(0));
        } else {
            IDepositHandler(c.depositHandler()).depositGvt(amounts, lpWithSlippage, address(0));
        }
    }

    function depositWithdraw(bool pwrd, uint256[3] calldata amounts) external {
        ILifeGuard lg = ILifeGuard(lifeguard);
        IBuoy buoy = IBuoy(lg.getBuoy());
        Controller c = Controller(controller);

        address[3] memory tokens = c.stablecoins();
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(c.depositHandler(), amounts[i]);
        }
        uint256 lp = buoy.stableToLp(amounts, true);
        uint256 lpWithSlippage = lp.sub(lp.div(1000));
        if (pwrd) {
            IDepositHandler(c.depositHandler()).depositPwrd(amounts, lpWithSlippage, address(0));
        } else {
            IDepositHandler(c.depositHandler()).depositGvt(amounts, lpWithSlippage, address(0));
        }

        lp = buoy.stableToLp(amounts, false);
        lpWithSlippage = lp.add(lp.div(1000));
        uint256[3] memory minAmounts;
        IWithdrawHandler(c.withdrawHandler()).withdrawByLPToken(pwrd, lpWithSlippage, minAmounts);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IVault.sol";
import "../vaults/yearnv2/v032/IYearnV2Strategy.sol";
import "../vaults/yearnv2/v032/IYearnV2Vault.sol";
import "./MockYearnV2Vault.sol";

contract MockYearnV2Strategy is ERC20, IYearnV2Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public harvestAmount;
    uint256 public estimatedAmount;
    bool public worthHarvest;

    address public override vault;
    address public override keeper;
    address public pool;

    constructor(address _token) public ERC20("Strategy", "Strategy") {
        _setupDecimals(18);
        token = IERC20(_token);
    }

    function withdraw(uint256 _amount) external override {
        token.transfer(vault, _amount);
    }

    function harvest() external override {
        // MockYearnV2Vault valt = MockYearnV2Vault(vault);
        // uint256 debtLimit = valt.getStrategyDebtLimit(address(this));
        // uint256 lastTotalDebt = valt.getStrategyTotalDebt(address(this));
        // uint256 balance = token.balanceOf(address(this));
        uint256 gain = 0;
        uint256 loss = 0;
        uint256 delt = 0;
        // if(balance > lastTotalDebt){
        //     gain = balance.sub(lastTotalDebt);
        // } else {
        //     loss = lastTotalDebt.sub(balance);
        // }
        // if(debtLimit >= balance) {
        //     delt = debtLimit.sub(balance);
        // }else {
        //     uint256 overflow = balance.sub(debtLimit);
        //     token.safeTransfer(vault, overflow);
        // }
        IYearnV2Vault(vault).report(gain, loss, delt);
    }

    function setHarvestAmount(uint256 _amount) external {
        harvestAmount = _amount;
    }

    function setVault(address _vault) external override {
        vault = _vault;
        token.safeApprove(_vault, type(uint256).max);
    }

    function setKeeper(address _keeper) external override {
        keeper = _keeper;
    }

    function setPool(address _pool) external {
        pool = _pool;
    }

    function setWorthHarvest(bool _worthHarvest) external {
        worthHarvest = _worthHarvest;
    }

    function harvestTrigger(uint256 callCost) public view override returns (bool) {
        callCost;
        return worthHarvest;
    }

    function estimatedTotalAssets() public view override returns (uint256) {
        // return estimatedAmount;
        return token.balanceOf(address(this));
    }

    function setEstimatedAmount(uint256 _estimatedAmount) external {
        estimatedAmount = _estimatedAmount;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IVault.sol";
import "../common/Constants.sol";

contract MockVaultAdaptor is IVault, Constants {
    using SafeMath for uint256;

    IERC20 public underlyingToken;
    uint256 public total = 0;
    uint256 public totalEstimated = 0;
    uint256 public amountAvailable;
    uint256 public countOfStrategies;
    address public override vault;
    address[] harvestQueue;
    uint256[] expectedDebtLimits;
    mapping(uint256 => uint256) strategyEstimatedAssets;

    address controller;
    uint256 amountToController;

    uint256 public gain;
    uint256 public loss;
    uint256 public startBlock;
    uint256 public swapInterestIncrement = 0;
    uint256 public strategiesLength;
    uint256 public investThreshold;
    uint256 public strategyRatioBuffer;

    constructor() public {}

    function setToken(address _token) external {}

    function setStrategiesLength(uint256 _strategiesLength) external {
        strategiesLength = _strategiesLength;
    }

    function setInvestThreshold(uint256 _investThreshold) external {
        investThreshold = _investThreshold;
    }

    function setStrategyRatioBuffer(uint256 _strategyRatioBuffer) external {
        strategyRatioBuffer = _strategyRatioBuffer;
    }

    function setUnderlyingToken(address _token) external {
        underlyingToken = IERC20(_token);
    }

    function setTotal(uint256 _total) external {
        total = _total;
    }

    function setController(address _controller) external {
        controller = _controller;
    }

    function setAmountToController(uint256 _amountToController) external {
        amountToController = _amountToController;
    }

    function setTotalEstimated(uint256 _totalEstimated) external {
        totalEstimated = _totalEstimated;
    }

    function setStrategyAssets(uint256 _index, uint256 _totalEstimated) external {
        strategyEstimatedAssets[_index] = _totalEstimated;
    }

    function setCountOfStrategies(uint32 _countOfStrategies) external {
        countOfStrategies = _countOfStrategies;
    }

    function setVault(address _vault) external {
        vault = _vault;
    }

    function setHarvestQueueAndLimits(address[] calldata _queue, uint256[] calldata _debtLimits) external {
        harvestQueue = _queue;
        expectedDebtLimits = _debtLimits;
    }

    function approve(address account, uint256 amount) external {
        underlyingToken.approve(account, amount);
    }

    function getHarvestQueueAndLimits() external view returns (address[] memory, uint256[] memory) {
        return (harvestQueue, expectedDebtLimits);
    }

    function strategyHarvest(uint256 _index) external override returns (bool) {}

    function strategyHarvestTrigger(uint256 _index, uint256 _callCost) external view override returns (bool) {}

    function deposit(uint256 _amount) external override {
        underlyingToken.transferFrom(msg.sender, address(this), _amount);
        // token.transfer(vault, _amount);
    }

    function withdraw(uint256 _amount) external override {
        underlyingToken.transfer(msg.sender, _amount);
    }

    function withdraw(uint256 _amount, address recipient) external override {
        recipient;
        underlyingToken.transfer(msg.sender, _amount);
    }

    function withdrawByStrategyOrder(
        uint256 _amount,
        address _recipient,
        bool pwrd
    ) external override {
        pwrd;
        underlyingToken.transfer(_recipient, _amount);
    }

    function depositAmountAvailable(uint256 _amount) external view returns (uint256) {
        _amount;
        return amountAvailable;
    }

    function setDepositAmountAvailable(uint256 _amountAvailable) external returns (uint256) {
        amountAvailable = _amountAvailable;
    }

    function addTotalAssets(uint256 addAsset) public {
        total += addAsset;
    }

    function startSwap(uint256 rate) external {
        startBlock = block.number;
        swapInterestIncrement = rate;
    }

    function getStartBlock() external view returns (uint256) {
        return startBlock;
    }

    function totalAssets() external view override returns (uint256) {
        uint256 interest = 0;
        if (startBlock != 0) {
            uint256 blockAdvancement = block.number.sub(startBlock);
            interest = blockAdvancement.mul(swapInterestIncrement);
        }
        return underlyingToken.balanceOf(address(this)).add(interest).add(total);
    }

    function updateStrategyRatio(uint256[] calldata debtratios) external override {}

    function getStrategiesLength() external view override returns (uint256) {
        return countOfStrategies;
    }

    function setGain(uint256 _gain) external {
        gain = _gain;
    }

    function setLoss(uint256 _loss) external {
        loss = _loss;
    }

    function getStrategyAssets(uint256 index) external view override returns (uint256) {
        return strategyEstimatedAssets[index];
    }

    function token() external view override returns (address) {
        return address(underlyingToken);
    }

    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external override {}

    function investTrigger() external view override returns (bool) {}

    function invest() external override {}

    function withdrawToAdapter(uint256 amount) external {}
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./MockERC20.sol";

contract MockUSDT is MockERC20 {
    constructor() public ERC20("USDT", "USDT") {
        _setupDecimals(6);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./MockERC20.sol";

contract MockUSDC is MockERC20 {
    constructor() public ERC20("USDC", "USDC") {
        _setupDecimals(6);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./MockERC20.sol";

contract MockDAI is MockERC20 {
    constructor() public ERC20("DAI", "DAI") {
        _setupDecimals(18);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "./MockERC20.sol";

contract MockLPToken is MockERC20 {
    constructor() public ERC20("LPT", "LPT") {
        _setupDecimals(18);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/ICurve.sol";
import "./MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./MockLPToken.sol";

// Mock curve 3pool for deposit/withdrawal
contract MockCurveDeposit is ICurve3Deposit {
    using SafeERC20 for IERC20;

    address[] public coins;
    uint256 N_COINS = 3;
    uint256[] public PRECISION_MUL = [1, 1000000000000, 1000000000000];
    uint256[] public decimals = [18, 6, 6];
    uint256[] public rates = [1001835600000000000, 999482, 999069];
    uint256 constant vp = 1005530723799997871;
    uint256[] vpSingle = [996343755718242128, 994191500557422927, 993764724471177721];
    uint256[] desired_ratio = [250501710687927000, 386958750403203000, 362539538908870000];
    uint256[] poolratio = [20, 40, 40];
    uint256 Fee = 4000;
    MockLPToken PoolToken;

    constructor(address[] memory _tokens, address _PoolToken) public {
        coins = _tokens;
        PoolToken = MockLPToken(_PoolToken);
    }

    function setTokens(
        address[] calldata _tokens,
        uint256[] calldata _precisions,
        uint256[] calldata _rates
    ) external {
        coins = _tokens;
        N_COINS = _tokens.length;
        PRECISION_MUL = _precisions;
        rates = _rates;
    }

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external override {
        i;
        j;
        dx;
        min_dy;
    }

    function add_liquidity(uint256[3] calldata uamounts, uint256 min_mint_amount) external override {
        uint256 amount;
        for (uint256 i; i < N_COINS; i++) {
            IERC20 token = IERC20(coins[i]);
            token.safeTransferFrom(msg.sender, address(this), uamounts[i]);
            amount = ((uamounts[i] * (10**(18 - decimals[i]))) * vpSingle[i]) / (10**18);
        }
        PoolToken.mint(msg.sender, min_mint_amount);
    }

    function remove_liquidity(uint256 amount, uint256[3] calldata min_uamounts) external override {
        require(PoolToken.balanceOf(msg.sender) > amount, "remove_liquidity: !balance");
        PoolToken.burn(msg.sender, amount);
        for (uint256 i; i < N_COINS; i++) {
            IERC20 token = IERC20(coins[i]);
            token.transfer(msg.sender, min_uamounts[i]);
        }
    }

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external override {
        require(PoolToken.balanceOf(msg.sender) > max_burn_amount, "remove_liquidity: !balance");
        PoolToken.burn(msg.sender, max_burn_amount);
        for (uint256 i; i < N_COINS; i++) {
            IERC20 token = IERC20(coins[i]);
            if (amounts[i] > 0) {
                token.safeTransfer(msg.sender, amounts[i]);
            }
        }
    }

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external override {
        min_amount;
        require(PoolToken.balanceOf(msg.sender) > _token_amount, "remove_liquidity: !balance");
        uint256 outAmount = ((_token_amount * (10**18)) / vpSingle[uint256(i)]) / PRECISION_MUL[uint256(i)];
        PoolToken.burn(msg.sender, _token_amount);
        IERC20 token = IERC20(coins[uint256(i)]);
        token.safeTransfer(msg.sender, outAmount);
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        uint256 x = rates[uint256(i)] * dx * PRECISION_MUL[uint256(i)];
        uint256 y = rates[uint256(j)] * PRECISION_MUL[uint256(j)];
        return x / y;
    }

    function calc_token_amount(uint256[3] calldata inAmounts, bool deposit) external view returns (uint256) {
        deposit;
        uint256 totalAmount;
        for (uint256 i = 0; i < vpSingle.length; i++) {
            totalAmount += (inAmounts[i] * vpSingle[i]) / (10**decimals[i]);
        }
        return totalAmount;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IBuoy.sol";
import "../interfaces/IERC20Detailed.sol";
import {ICurve3Pool} from "../interfaces/ICurve.sol";
import "../common/Whitelist.sol";
import "../common/Constants.sol";

/// @notice Contract for calculating prices of underlying
///     assets and LP tokens in curvepool. Also used to
///     Sanity check pool against external oracle to ensure
///     that pool is healthy by checking pool underlying coin
///     ratios against oracle coin price ratios
contract MockBuoy is IBuoy, IChainPrice, Whitelist, Constants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address[] public stablecoins;
    ICurve3Pool public override curvePool;

    uint256 constant vp = 1005330723799997871;
    uint256[] public decimals = [18, 6, 6];
    uint256[] vpSingle = [996343755718242128, 994191500557422927, 993764724471177721];
    uint256[] chainPrices = [10001024, 100000300, 99998869];
    uint256[] public balanced = [30, 30, 40];

    function setStablecoins(address[] calldata _stablecoins) external {
        stablecoins = _stablecoins;
    }

    function lpToUsd(uint256 inAmount) external view override returns (uint256) {
        return _lpToUsd(inAmount);
    }

    function _lpToUsd(uint256 inAmount) private view returns (uint256) {
        return inAmount.mul(vp).div(DEFAULT_DECIMALS_FACTOR);
    }

    function usdToLp(uint256 inAmount) public view override returns (uint256) {
        return inAmount.mul(DEFAULT_DECIMALS_FACTOR).div(vp);
    }

    function stableToUsd(uint256[3] calldata inAmounts, bool _deposit) external view override returns (uint256) {
        return _stableToUsd(inAmounts, _deposit);
    }

    function _stableToUsd(uint256[3] memory inAmounts, bool _deposit) private view returns (uint256) {
        uint256 lp = _stableToLp(inAmounts, _deposit);
        return _lpToUsd(lp);
    }

    function stableToLp(uint256[3] calldata inAmounts, bool _deposit) external view override returns (uint256) {
        return _stableToLp(inAmounts, _deposit);
    }

    function _stableToLp(uint256[3] memory inAmounts, bool deposit) private view returns (uint256) {
        deposit;
        uint256 totalAmount;
        for (uint256 i = 0; i < vpSingle.length; i++) {
            totalAmount = totalAmount.add(inAmounts[i].mul(vpSingle[i]).div(10**decimals[i]));
        }
        return totalAmount;
    }

    function singleStableFromLp(uint256 inAmount, int128 i) external view override returns (uint256) {
        return _singleStableFromLp(inAmount, uint256(i));
    }

    function _singleStableFromLp(uint256 inAmount, uint256 i) private view returns (uint256) {
        return inAmount.mul(10**18).div(vpSingle[i]).div(10**(18 - decimals[i]));
    }

    function singleStableToUsd(uint256 inAmount, uint256 i) external view override returns (uint256) {
        uint256[3] memory inAmounts;
        inAmounts[i] = inAmount;
        return _stableToUsd(inAmounts, true);
    }

    function singleStableFromUsd(uint256 inAmount, int128 i) external view override returns (uint256) {
        return _singleStableFromLp(usdToLp(inAmount), uint256(i));
    }

    function getRatio(uint256 token0, uint256 token1) external view returns (uint256, uint256) {}

    function safetyCheck() external view override returns (bool) {
        return true;
    }

    function getVirtualPrice() external view override returns (uint256) {
        return vp;
    }

    function updateRatios() external override returns (bool) {}

    function updateRatiosWithTolerance(uint256 tolerance) external override returns (bool) {}

    function getPriceFeed(uint256 i) external view override returns (uint256 _price) {
        return chainPrices[i];
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../common/StructDefinitions.sol";
import "../common/Constants.sol";
import "../common/Controllable.sol";
import "../common/Whitelist.sol";
import "../interfaces/IAllocation.sol";
import "../interfaces/IInsurance.sol";
import "../interfaces/IExposure.sol";

import "../interfaces/IERC20Detailed.sol";
import "../interfaces/ILifeGuard.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IBuoy.sol";
import "../interfaces/IPnL.sol";

/// @notice Contract for supporting protocol insurance logic - used for calculating large deposits,
///     withdrawals, rebalancing vaults and strategies and calculating risk exposure.
///     The gro protocol needs to ensure that all assets are kept within certain bounds,
///     defined on both a stablecoin and a protocol level. The stablecoin exposure is defined as
///     a system parameter (by governance), protocol exposure is calculated based on utilisation
///     ratio of gvt versus pwrd.
///
///     *****************************************************************************
///     Dependencies - insurance strategies
///     *****************************************************************************
///     Allocation.sol
///      - Protocol Allocation calculations
///     Exposure.sol
///      - Protocol Exposure calculations
///
///     Current system vaults : strategies:
///      - DAI vault : Harvest finance, Yearn generic lender
///      - USDC vaults : Harvest finance, Yearn generic lender
///      - USDT vault : Harvest finance, Yearn generic lender
///      - Curve vault : CurveXpool (Curve meta pool + yearn strategy)
///
///     Risk exposures:
///      - Stable coin - DAI, USDC, USDT
///      - LP tokens - 3Crv, Metapool tokens
contract Insurance is Constants, Controllable, Whitelist, IInsurance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IAllocation public allocation;
    IExposure public exposure;

    mapping(uint256 => uint256) public underlyingTokensPercents;
    uint256 public curveVaultPercent;

    // Buffer used to ensure that exposures don't get to close to the limit
    // (defined as 100% - (utilisation ratio / 2), will ensure that
    // rebalance will trigger before any overexposures have occured
    uint256 public exposureBufferRebalance;
    // How much can be withdrawn from a single vault before triggering a whale withdrawal
    //  - Whale withdrawal will withdraw from multiple vaults based on the vaults
    //      current exposure delta (difference between current assets vs target assets).
    //      The assets will be swapped into the request asset/s (via Curve)
    uint256 public maxPercentForWithdraw;
    // How much can be deposited into a single vault before triggering a whale deposit
    //  - Whale deposit will deposit into multiple vaults based on stablecoin allocation targets.
    //      The deposited asset/s will be swapped into the desired asset amounts (via Curve)
    uint256 public maxPercentForDeposit;

    event LogNewAllocation(address allocation);
    event LogNewExposure(address exposure);
    event LogNewTargetAllocation(uint256 indexed index, uint256 percent);
    event LogNewCurveAllocation(uint256 percent);
    event LogNewExposureBuffer(uint256 buffer);
    event LogNewVaultMax(bool deposit, uint256 percent);

    modifier onlyValidIndex(uint256 index) {
        require(index >= 0 && index < N_COINS, "Invalid index value.");
        _;
    }

    /// @notice Set strategy allocation contract
    /// @param _allocation Address of allocation logic strategy
    function setAllocation(address _allocation) external onlyOwner {
        require(_allocation != address(0), "Zero address provided");
        allocation = IAllocation(_allocation);
        emit LogNewAllocation(_allocation);
    }

    /// @notice Set exposure contract
    /// @param _exposure Address of exposure logic strategy
    function setExposure(address _exposure) external onlyOwner {
        require(_exposure != address(0), "Zero address provided");
        exposure = IExposure(_exposure);
        emit LogNewExposure(_exposure);
    }

    /// @notice Set allocation target for stablecoins
    /// @param coinIndex Protocol index of stablecoin
    /// @param percent Target allocation percent
    function setUnderlyingTokenPercent(uint256 coinIndex, uint256 percent) external override onlyValidIndex(coinIndex) {
        require(msg.sender == controller || msg.sender == owner(), "setUnderlyingTokenPercent: !authorized");
        underlyingTokensPercents[coinIndex] = percent;
        emit LogNewTargetAllocation(coinIndex, percent);
    }

    function setCurveVaultPercent(uint256 _curveVaultPercent) external onlyOwner {
        curveVaultPercent = _curveVaultPercent;
        emit LogNewCurveAllocation(_curveVaultPercent);
    }

    /// @notice Set target for exposure buffer, this is used by the system to determine when to rebalance
    /// @param rebalanceBuffer Buffer percentage
    function setExposureBufferRebalance(uint256 rebalanceBuffer) external onlyOwner {
        exposureBufferRebalance = rebalanceBuffer;
        emit LogNewExposureBuffer(rebalanceBuffer);
    }

    /// @notice Set max percent of the vault assets for whale withdrawal,
    ///     if the withdrawal amount <= max percent * the total assets of target vault,
    ///     withdraw target assets from single vault
    /// @param _maxPercentForWithdraw Target max pecent in %BP
    function setWhaleThresholdWithdraw(uint256 _maxPercentForWithdraw) external onlyOwner {
        maxPercentForWithdraw = _maxPercentForWithdraw;
        emit LogNewVaultMax(false, _maxPercentForWithdraw);
    }

    /// @notice Set max percent of the vault assets for whale deposits,
    ///     if the deposit amount >= max percent * the total assets of target vault,
    ///     deposit into single vault
    /// @param _maxPercentForDeposit Target max pecent in %BP
    function setWhaleThresholdDeposit(uint256 _maxPercentForDeposit) external onlyOwner {
        maxPercentForDeposit = _maxPercentForDeposit;
        emit LogNewVaultMax(true, _maxPercentForDeposit);
    }

    /// @notice Deposit deltas => stablecoin allocation targets. Large deposits will thus
    ///     always push the system towards a steady state
    function calculateDepositDeltasOnAllVaults() public view override returns (uint256[N_COINS] memory) {
        return getStablePercents();
    }

    /// @notice Get the vaults order by their current exposure
    /// @param amount Amount deposited
    function getVaultDeltaForDeposit(uint256 amount)
        external
        view
        override
        returns (
            uint256[N_COINS] memory,
            uint256[N_COINS] memory,
            uint256
        )
    {
        uint256[N_COINS] memory investDelta;
        uint256[N_COINS] memory vaultIndexes;
        (uint256 totalAssets, uint256[N_COINS] memory vaultAssets) = exposure.getUnifiedAssets(_controller().vaults());
        // If deposited amount is less than the deposit limit for a the system, the
        // deposited is treated as a tuna deposit (single vault target)...
        if (amount < totalAssets.mul(maxPercentForDeposit).div(PERCENTAGE_DECIMAL_FACTOR)) {
            uint256[N_COINS] memory _vaultIndexes = exposure.sortVaultsByDelta(
                false,
                totalAssets,
                vaultAssets,
                getStablePercents()
            );
            investDelta[vaultIndexes[0]] = 10000;
            vaultIndexes[0] = _vaultIndexes[0];
            vaultIndexes[1] = _vaultIndexes[1];
            vaultIndexes[2] = _vaultIndexes[2];

            return (investDelta, vaultIndexes, 1);
            // ...Else its a whale deposit, and the deposit will be spread across all vaults,
            // based on allocation targets
        } else {
            return (investDelta, vaultIndexes, N_COINS);
        }
    }

    /// @notice Sort vaults by the delta of target asset - current asset,
    ///     only support 3 vaults now
    /// @param bigFirst Return array order most exposed -> least exposed
    function sortVaultsByDelta(bool bigFirst) external view override returns (uint256[N_COINS] memory vaultIndexes) {
        (uint256 totalAssets, uint256[N_COINS] memory vaultAssets) = exposure.getUnifiedAssets(_controller().vaults());
        return exposure.sortVaultsByDelta(bigFirst, totalAssets, vaultAssets, getStablePercents());
    }

    /// @notice Prepares system for rebalance by comparing current system risk exposure to target exposure
    function rebalanceTrigger() external view override returns (bool sysNeedRebalance) {
        SystemState memory sysState = prepareCalculation();
        sysState.utilisationRatio = IPnL(_controller().pnl()).utilisationRatio();
        sysState.rebalanceThreshold = PERCENTAGE_DECIMAL_FACTOR.sub(sysState.utilisationRatio.div(2)).sub(
            exposureBufferRebalance
        );
        ExposureState memory expState = exposure.calcRiskExposure(sysState);
        sysNeedRebalance = expState.stablecoinExposed || expState.protocolExposed;
    }

    /// @notice Rebalance will check the exposure and calculate the delta of overexposed assets/protocols.
    ///     Rebalance will attempt to withdraw assets from overexposed strategies to minimize protocol exposure.
    ///     After which it will pull assets out from overexposed vaults and invest the freed up assets
    ///     to the other stablecoin vaults.
    function rebalance() external override onlyWhitelist {
        SystemState memory sysState = prepareCalculation();
        sysState.utilisationRatio = IPnL(_controller().pnl()).utilisationRatio();
        sysState.rebalanceThreshold = PERCENTAGE_DECIMAL_FACTOR.sub(sysState.utilisationRatio.div(2)).sub(
            exposureBufferRebalance
        );
        ExposureState memory expState = exposure.calcRiskExposure(sysState);
        /// If the system is in an OK state, do nothing...
        if (!expState.stablecoinExposed && !expState.protocolExposed) return;
        /// ...Else, trigger a rebalance
        sysState.targetBuffer = exposureBufferRebalance;
        AllocationState memory allState = allocation.calcSystemTargetDelta(sysState, expState);
        _rebalance(allState);
    }

    /// @notice Rebalancing for large withdrawals, calculates changes in utilisation ratio based
    ///     on the amount withdrawn, and rebalances to get additional assets for withdrawal
    /// @param withdrawUsd Target USD amount to withdraw
    /// @param pwrd Pwrd or gvt
    function rebalanceForWithdraw(uint256 withdrawUsd, bool pwrd) external override returns (bool) {
        require(msg.sender == _controller().withdrawHandler(), "rebalanceForWithdraw: !withdrawHandler");
        return withdraw(withdrawUsd, pwrd);
    }

    /// @notice Determine if part of a deposit should be routed to the LP vault - This only applies
    ///     to Tuna and Whale deposits
    /// @dev If the current Curve exposure > target curve exposure, no more assets should be invested
    ///     to the LP vault
    function calcSkim() external view override returns (uint256) {
        IPnL pnl = IPnL(_controller().pnl());
        (uint256 gvt, uint256 pwrd) = pnl.calcPnL();
        uint256 totalAssets = gvt.add(pwrd);
        uint256 curveAssets = IVault(_controller().curveVault()).totalAssets();
        if (totalAssets != 0 && curveAssets.mul(PERCENTAGE_DECIMAL_FACTOR).div(totalAssets) >= curveVaultPercent) {
            return 0;
        }
        return curveVaultPercent;
    }

    /// @notice Calculate assets distribution for strategies
    function getStrategiesTargetRatio(uint256 utilRatio) external view override returns (uint256[] memory) {
        return allocation.calcStrategyPercent(utilRatio);
    }

    /// @notice Get protocol and vault total assets
    function prepareCalculation() public view returns (SystemState memory systemState) {
        ILifeGuard lg = getLifeGuard();
        IBuoy buoy = IBuoy(lg.getBuoy());
        require(buoy.safetyCheck());
        IVault curve = IVault(_controller().curveVault());
        systemState.lifeguardCurrentAssetsUsd = lg.totalAssetsUsd();
        systemState.curveCurrentAssetsUsd = buoy.lpToUsd(curve.totalAssets());
        systemState.totalCurrentAssetsUsd = systemState.lifeguardCurrentAssetsUsd.add(
            systemState.curveCurrentAssetsUsd
        );
        systemState.curvePercent = curveVaultPercent;
        address[N_COINS] memory vaults = _controller().vaults();
        // Stablecoin total assets
        for (uint256 i = 0; i < N_COINS; i++) {
            IVault vault = IVault(vaults[i]);
            uint256 vaultAssets = vault.totalAssets();
            uint256 vaultAssetsUsd = buoy.singleStableToUsd(vaultAssets, i);
            systemState.totalCurrentAssetsUsd = systemState.totalCurrentAssetsUsd.add(vaultAssetsUsd);
            systemState.vaultCurrentAssets[i] = vaultAssets;
            systemState.vaultCurrentAssetsUsd[i] = vaultAssetsUsd;
        }
        systemState.stablePercents = getStablePercents();
    }

    /// @notice Logic for large withdrawals - We attempt to optimize large withdrawals on both
    ///     vault and strategy level - depending on the quantity being withdrawn, we try to limit
    ///     gas costs by reducing the number of vaults and strategies to interact with
    /// @param amount Amount to withdraw in USD
    /// @param pwrd Is pwrd or vault being burned - affects withdrawal queue
    function withdraw(uint256 amount, bool pwrd) private returns (bool curve) {
        address[N_COINS] memory vaults = _controller().vaults();

        // Determine if it's possible to withdraw from one or two vaults without breaking exposure
        (uint256 withdrawType, uint256[N_COINS] memory withdrawalAmounts) = calculateWithdrawalAmountsOnPartVaults(
            amount,
            vaults
        );

        // If it's not possible to withdraw from a subset of the vaults, calculate how much
        // to withdraw from each based on current amounts in vaults vs allocation targets

        // Withdraw from more than one vault
        if (withdrawType > 1) {
            // Withdraw from all stablecoin vaults
            if (withdrawType == 2)
                withdrawalAmounts = calculateWithdrawalAmountsOnAllVaults(amount, vaults);
                // Withdraw from all stable coin vaults + LP vault
            else {
                // withdrawType == 3
                for (uint256 i; i < N_COINS; i++) {
                    withdrawalAmounts[i] = IVault(vaults[i]).totalAssets();
                }
            }
        }
        ILifeGuard lg = getLifeGuard();
        for (uint256 i = 0; i < N_COINS; i++) {
            // Withdraw assets from vault adaptor - if assets are available they will be pulled
            // direcly from the adaptor, otherwise assets will have to be pulled from the underlying
            // strategies, which will costs additional gas
            if (withdrawalAmounts[i] > 0) {
                IVault(vaults[i]).withdrawByStrategyOrder(withdrawalAmounts[i], address(lg), pwrd);
            }
        }

        if (withdrawType == 3) {
            // If more assets are needed than are available in the stablecoin vaults,
            // assets will be withdrawn from the LP Vault. This possibly involves additional
            // fees, which will be deducted from the users withdrawal amount.
            IBuoy buoy = IBuoy(lg.getBuoy());
            uint256[N_COINS] memory _withdrawalAmounts;
            _withdrawalAmounts[0] = withdrawalAmounts[0];
            _withdrawalAmounts[1] = withdrawalAmounts[1];
            _withdrawalAmounts[2] = withdrawalAmounts[2];
            uint256 leftUsd = amount.sub(buoy.stableToUsd(_withdrawalAmounts, false));
            IVault curveVault = IVault(_controller().curveVault());
            uint256 curveVaultUsd = buoy.lpToUsd(curveVault.totalAssets());
            require(curveVaultUsd > leftUsd, "no enough system assets");
            curveVault.withdraw(buoy.usdToLp(leftUsd), address(lg));
            curve = true;
        }
    }

    /// @notice Calculate withdrawal amounts based on part vaults, if the sum of part vaults'
    ///     maxWithdrawal can meet required amount, return true and valid array,
    ///     otherwise return false and invalid array
    /// @return withdrawType
    ///     1 - withdraw from part stablecoin vaults
    ///     2 - withdraw from all stablecoin vaults
    ///     3 - withdraw from all stablecoin vaults and Curve vault/lifeguard
    function calculateWithdrawalAmountsOnPartVaults(uint256 amount, address[N_COINS] memory vaults)
        private
        view
        returns (uint256 withdrawType, uint256[N_COINS] memory withdrawalAmounts)
    {
        uint256 maxWithdrawal;
        uint256 leftAmount = amount;
        uint256 vaultIndex;
        (uint256 totalAssets, uint256[N_COINS] memory vaultAssets) = exposure.getUnifiedAssets(vaults);
        if (amount > totalAssets) {
            withdrawType = 3;
        } else {
            withdrawType = 2;
            // Get list of vaults order by most exposed => least exposed
            uint256[N_COINS] memory vaultIndexes = exposure.sortVaultsByDelta(
                true,
                totalAssets,
                vaultAssets,
                getStablePercents()
            );

            IBuoy buoy = IBuoy(getLifeGuard().getBuoy());
            // Establish how much needs to be withdrawn from each vault
            for (uint256 i; i < N_COINS - 1; i++) {
                vaultIndex = vaultIndexes[i];
                // Limit of how much can be withdrawn from this vault
                maxWithdrawal = vaultAssets[vaultIndex].mul(maxPercentForWithdraw).div(PERCENTAGE_DECIMAL_FACTOR);
                // If withdraw amount exceeds withdraw capacity, withdraw remainder
                // from next vault in list...
                if (leftAmount > maxWithdrawal) {
                    withdrawalAmounts[vaultIndex] = buoy.singleStableFromUsd(maxWithdrawal, int128(vaultIndex));
                    leftAmount = leftAmount.sub(maxWithdrawal);
                    // ...Else, stop. Withdrawal covered by one vault.
                } else {
                    withdrawType = 1;
                    withdrawalAmounts[vaultIndex] = buoy.singleStableFromUsd(leftAmount, int128(vaultIndex));
                    break;
                }
            }
        }
    }

    /// @notice Calcualte difference between vault current assets and target assets
    /// @param withdrawUsd USD value of withdrawals
    function getDelta(uint256 withdrawUsd) external view override returns (uint256[N_COINS] memory delta) {
        address[N_COINS] memory vaults = _controller().vaults();
        delta = exposure.calcRoughDelta(getStablePercents(), vaults, withdrawUsd);
    }

    /// @notice Calculate withdrawal amounts based on target percents of all vaults,
    ///     if one withdrawal amount > one vault's total asset, use rebalance calculation
    function calculateWithdrawalAmountsOnAllVaults(uint256 amount, address[N_COINS] memory vaults)
        private
        view
        returns (uint256[N_COINS] memory withdrawalAmounts)
    {
        // Simple == true - withdraw from all vaults based on target percents
        bool simple = true;
        // First pass uses rough usd calculations to asses the distribution of withdrawals
        // from the vaults...
        uint256[N_COINS] memory delta = exposure.calcRoughDelta(getStablePercents(), vaults, amount);
        for (uint256 i = 0; i < N_COINS; i++) {
            IVault vault = IVault(vaults[i]);
            withdrawalAmounts[i] = amount
            .mul(delta[i])
            .mul(uint256(10)**IERC20Detailed(vault.token()).decimals())
            .div(PERCENTAGE_DECIMAL_FACTOR)
            .div(DEFAULT_DECIMALS_FACTOR);
            if (withdrawalAmounts[i] > vault.totalAssets()) {
                simple = false;
                break;
            }
        }
        // ...If this doesn't work, we do a more complex calculation to establish
        // how much we need to withdraw
        if (!simple) {
            (withdrawalAmounts, ) = calculateVaultSwapData(amount);
        }
    }

    /// @notice calculateVaultsSwapData will compare the current asset excluding withdraw
    ///     amount with target for each vault
    ///     swapInAmounts Stores the coin need to be withdraw above the target in vault
    ///     swapOutPercent Stores the required percent for vault below target
    /// @param withdrawAmount The whale withdraw amount
    function calculateVaultSwapData(uint256 withdrawAmount)
        private
        view
        returns (uint256[N_COINS] memory swapInAmounts, uint256[N_COINS] memory swapOutPercents)
    {
        // Calculate total assets and total number of strategies
        SystemState memory state = prepareCalculation();

        require(withdrawAmount < state.totalCurrentAssetsUsd, "Withdrawal exceeds system assets");
        state.totalCurrentAssetsUsd = state.totalCurrentAssetsUsd.sub(withdrawAmount);

        StablecoinAllocationState memory stableState = allocation.calcVaultTargetDelta(state, false);
        swapInAmounts = stableState.swapInAmounts;
        swapOutPercents = stableState.swapOutPercents;
    }

    function getLifeGuard() private view returns (ILifeGuard) {
        return ILifeGuard(_controller().lifeGuard());
    }

    /// @notice Rebalance will pull assets out from the overexposed vaults
    ///     and transfer to the other vaults
    function _rebalance(AllocationState memory allState) private {
        address[N_COINS] memory vaults = _controller().vaults();
        ILifeGuard lg = getLifeGuard();
        IBuoy buoy = IBuoy(lg.getBuoy());
        // Withdraw from strategies that are overexposed
        if (allState.needProtocolWithdrawal) {
            for (uint256 i = 0; i < N_COINS; i++) {
                if (allState.protocolWithdrawalUsd[i] > 0) {
                    uint256 amount = buoy.singleStableFromUsd(allState.protocolWithdrawalUsd[i], int128(i));
                    IVault(vaults[i]).withdrawByStrategyIndex(
                        amount,
                        IVault(vaults[i]).vault(),
                        allState.protocolExposedIndex
                    );
                }
            }
        }

        bool hasWithdrawal = moveAssetsFromVaultsToLifeguard(
            vaults,
            allState.stableState.swapInAmounts,
            lg,
            allState.needProtocolWithdrawal ? 0 : allState.protocolExposedIndex,
            allState.strategyTargetRatio // Only adjust strategy ratio here
        );

        // Withdraw from Curve vault
        uint256 curveDeltaUsd = allState.stableState.curveTargetDeltaUsd;
        if (curveDeltaUsd > 0) {
            uint256 usdAmount = lg.totalAssetsUsd();
            // This step moves all lifeguard assets into swap out stablecoin vaults, it might cause
            // protocol over exposure in some edge cases after invest/harvest. But it won't have a
            // large impact on the system, as investToCurve should be run periodically by external actors,
            // minimising the total amount of assets in the lifeguard.
            //   - Its recommended to check the total assets in the lifeguard and run the invest to curve
            //   trigger() to determine if investToCurve needs to be run manually before rebalance
            lg.depositStable(true);
            if (usdAmount < curveDeltaUsd) {
                IVault(_controller().curveVault()).withdraw(buoy.usdToLp(curveDeltaUsd.sub(usdAmount)), address(lg));
            }
        }

        if (curveDeltaUsd == 0 && hasWithdrawal) lg.depositStable(false);

        // Keep buffer asset in lifeguard and convert the rest of the assets to target stablecoin.
        // If swapOutPercent all are zero, don't run prepareInvestment
        for (uint256 i = 0; i < N_COINS; i++) {
            if (allState.stableState.swapOutPercents[i] > 0) {
                uint256[N_COINS] memory _swapOutPercents;
                _swapOutPercents[0] = allState.stableState.swapOutPercents[0];
                _swapOutPercents[1] = allState.stableState.swapOutPercents[1];
                _swapOutPercents[2] = allState.stableState.swapOutPercents[2];
                lg.invest(0, _swapOutPercents);
                break;
            }
        }
    }

    /// @notice Move assets from Strategies to lifeguard in preparation to have them
    ///     swapped and redistributed to other stablecoin vaults
    /// @param vaults Underlying vaults
    /// @param swapInAmounts Amount to remove from vault
    /// @param lg Lifeguard
    /// @param strategyIndex Index of strategy to withdraw from
    /// @param strategyTargetRatio Targets debt ratios of strategies
    function moveAssetsFromVaultsToLifeguard(
        address[N_COINS] memory vaults,
        uint256[N_COINS] memory swapInAmounts,
        ILifeGuard lg,
        uint256 strategyIndex,
        uint256[] memory strategyTargetRatio
    ) private returns (bool) {
        bool moved = false;

        for (uint256 i = 0; i < N_COINS; i++) {
            IVault vault = IVault(vaults[i]);
            if (swapInAmounts[i] > 0) {
                moved = true;
                vault.withdrawByStrategyIndex(swapInAmounts[i], address(lg), strategyIndex);
            }
            vault.updateStrategyRatio(strategyTargetRatio);
        }

        return moved;
    }

    function getStablePercents() private view returns (uint256[N_COINS] memory stablePercents) {
        for (uint256 i = 0; i < N_COINS; i++) {
            stablePercents[i] = underlyingTokensPercents[i];
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

struct SystemState {
    uint256 totalCurrentAssetsUsd;
    uint256 curveCurrentAssetsUsd;
    uint256 lifeguardCurrentAssetsUsd;
    uint256[3] vaultCurrentAssets;
    uint256[3] vaultCurrentAssetsUsd;
    uint256 rebalanceThreshold;
    uint256 utilisationRatio;
    uint256 targetBuffer;
    uint256[3] stablePercents;
    uint256 curvePercent;
}

struct ExposureState {
    uint256[3] stablecoinExposure;
    uint256[] protocolExposure;
    uint256 curveExposure;
    bool stablecoinExposed;
    bool protocolExposed;
}

struct AllocationState {
    uint256[] strategyTargetRatio;
    bool needProtocolWithdrawal;
    uint256 protocolExposedIndex;
    uint256[3] protocolWithdrawalUsd;
    StablecoinAllocationState stableState;
}

struct StablecoinAllocationState {
    uint256 swapInTotalAmountUsd;
    uint256[3] swapInAmounts;
    uint256[3] swapInAmountsUsd;
    uint256[3] swapOutPercents;
    uint256[3] vaultsTargetUsd;
    uint256 curveTargetUsd;
    uint256 curveTargetDeltaUsd;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../common/StructDefinitions.sol";

interface IAllocation {
    function calcSystemTargetDelta(SystemState calldata sysState, ExposureState calldata expState)
        external
        view
        returns (AllocationState memory allState);

    function calcVaultTargetDelta(SystemState calldata sysState, bool onlySwapOut)
        external
        view
        returns (StablecoinAllocationState memory stableState);

    function calcStrategyPercent(uint256 utilisationRatio) external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../common/StructDefinitions.sol";

interface IExposure {
    function calcRiskExposure(SystemState calldata sysState) external view returns (ExposureState memory expState);

    function getExactRiskExposure(SystemState calldata sysState) external view returns (ExposureState memory expState);

    function getUnifiedAssets(address[3] calldata vaults)
        external
        view
        returns (uint256 unifiedTotalAssets, uint256[3] memory unifiedAssets);

    function sortVaultsByDelta(
        bool bigFirst,
        uint256 unifiedTotalAssets,
        uint256[3] calldata unifiedAssets,
        uint256[3] calldata targetPercents
    ) external pure returns (uint256[3] memory vaultIndexes);

    function calcRoughDelta(
        uint256[3] calldata targets,
        address[3] calldata vaults,
        uint256 withdrawUsd
    ) external view returns (uint256[3] memory);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IPnL.sol";
import "../common/Constants.sol";

contract MockPnL is Constants, IPnL {
    using SafeMath for uint256;

    uint256 public override lastGvtAssets;
    uint256 public override lastPwrdAssets;
    uint256 public totalProfit;

    function calcPnL() external view override returns (uint256, uint256) {
        return (lastGvtAssets, lastPwrdAssets);
    }

    function setLastGvtAssets(uint256 _lastGvtAssets) public {
        lastGvtAssets = _lastGvtAssets;
    }

    function setLastPwrdAssets(uint256 _lastPwrdAssets) public {
        lastPwrdAssets = _lastPwrdAssets;
    }

    function setTotalProfit(uint256 _totalProfit) public {
        totalProfit = _totalProfit;
    }

    function increaseGTokenLastAmount(bool pwrd, uint256 dollarAmount) external override {}

    function decreaseGTokenLastAmount(
        bool pwrd,
        uint256 dollarAmount,
        uint256 bonus
    ) external override {}

    function utilisationRatio() external view override returns (uint256) {
        return lastGvtAssets != 0 ? lastPwrdAssets.mul(PERCENTAGE_DECIMAL_FACTOR).div(lastGvtAssets) : 0;
    }

    function emergencyPnL() external override {}

    function recover() external override {}

    function distributeStrategyGainLoss(
        uint256 gain,
        uint256 loss,
        address reward
    ) external override {}

    function distributePriceChange(uint256 currentTotalAssets) external override {}
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../common/StructDefinitions.sol";
import "../common/Constants.sol";
import "../common/Controllable.sol";
import "../common/Whitelist.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/ILifeGuard.sol";
import "../interfaces/IExposure.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IBuoy.sol";

/// @notice Contract for calculating current protocol exposures on a stablecoin and
///     protocol level. This contract can be upgraded if the systems underlying protocols
///     or tokens have changed. Protocol exposure are calculated at a high level, as any
///     additional exposures from underlying protocol exposures should at most be equal to
///     the high level exposure.
///     For example: harvest finance stablecoin vaults (fTokens)
///         - High level exposure
///             - Harvest finance
///         - Low level exposures (from fToken investments):
///             - Compound
///             - Idle finance
///     Neither of these two low level exposures should matter as long as there arent
///     additional exposure to these protocol elsewhere. So by desing, the protocols
///     are given indexes based on the strategies in the stablecoin vaults, which need
///     to be symetrical for this to work - e.g. all vaults needs to have the same exposure
///     profile, and non of these exposure profiles can overlap. In the case where the
///     additional exposure needs to be taken into account (maker has USDC collateral,
///     Curve adds exposure to all stablecoins in a liquidity pool), they will be calculated
///     and added ontop of the base exposure from vaults and strategies.
///
///     --------------------------------------------------------
///     Current protocol setup:
///     --------------------------------------------------------
///     Stablecoins: DAI, USDC, USDT
///     LP tokens: 3Crv
///     Vaults: DAIVault, USDCVault, USDTVault, 3Crv vault
///     Strategy (exposures):
///         - Compound
///         - Idle finance
///         - Yearn Generic Lender:
///             - Cream
///         - CurveXpool:
///             - Curve3Pool
///             - CurveMetaPool
///             - Yearn
contract Exposure is Constants, Controllable, Whitelist, IExposure {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public protocolCount;
    uint256 public makerUSDCExposure;

    event LogNewProtocolCount(uint256 count);
    event LogNewMakerExposure(uint256 exposure);

    /// @notice Add protocol for the exposure calculations
    /// @dev Currently set to:
    ///     1 - Harvest finance
    ///     2 - Cream
    ///     Curve exposure is calculated separately as it has wider system impact
    function setProtocolCount(uint256 _protocolCount) external onlyOwner {
        protocolCount = _protocolCount;
        emit LogNewProtocolCount(_protocolCount);
    }

    /// @notice Specify additional USDC exposure to Maker
    /// @param _makerUSDCExposure Exposure amount to Maker
    function setMakerUSDCExposure(uint256 _makerUSDCExposure) external onlyOwner {
        makerUSDCExposure = _makerUSDCExposure;
        emit LogNewMakerExposure(_makerUSDCExposure);
    }

    function getExactRiskExposure(SystemState calldata sysState)
        external
        view
        override
        returns (ExposureState memory expState)
    {
        expState = _calcRiskExposure(sysState, false);
        ILifeGuard lifeguard = ILifeGuard(_controller().lifeGuard());
        IBuoy buoy = IBuoy(_controller().buoy());
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 assets = lifeguard.assets(i);
            uint256 assetsUsd = buoy.singleStableToUsd(assets, i);
            expState.stablecoinExposure[i] = expState.stablecoinExposure[i].add(
                assetsUsd.mul(PERCENTAGE_DECIMAL_FACTOR).div(sysState.totalCurrentAssetsUsd)
            );
        }
    }

    /// @notice Calculate stablecoin and protocol level risk exposure
    /// @param sysState Struct holding info about systems current state
    /// @dev This loops through all the vaults, checks the amount of assets in them
    ///     and their underlying strategies to understand stablecoin exposure
    ///     - Any assets invested in Curve or similar AMM will have additional stablecoin exposure.
    ///     The protocol exposure is calculated by assessing the amount of assets each
    ///     vault has invested in a strategy.
    function calcRiskExposure(SystemState calldata sysState)
        external
        view
        override
        returns (ExposureState memory expState)
    {
        expState = _calcRiskExposure(sysState, true);

        // Establish if any stablecoin/protocol is over exposed
        (expState.stablecoinExposed, expState.protocolExposed) = isExposed(
            sysState.rebalanceThreshold,
            expState.stablecoinExposure,
            expState.protocolExposure,
            expState.curveExposure
        );
    }

    /// @notice Do a rough USD dollar calculation by treating every stablecoin as
    ///     worth 1 USD and set all Decimals to 18
    function getUnifiedAssets(address[N_COINS] calldata vaults)
        public
        view
        override
        returns (uint256 unifiedTotalAssets, uint256[N_COINS] memory unifiedAssets)
    {
        // unify all assets to 18 decimals, treat each stablecoin as being worth 1 USD
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 assets = IVault(vaults[i]).totalAssets();
            unifiedAssets[i] = assets.mul(DEFAULT_DECIMALS_FACTOR).div(
                uint256(10)**IERC20Detailed(IVault(vaults[i]).token()).decimals()
            );
            unifiedTotalAssets = unifiedTotalAssets.add(unifiedAssets[i]);
        }
    }

    /// @notice Rough delta calculation - assumes each stablecoin is priced at 1 USD,
    ///     and looks at differences between current allocations and target allocations
    /// @param targets Stable coin allocation targest
    /// @param vaults Stablecoin vaults
    /// @param withdrawUsd USD value of withdrawals
    function calcRoughDelta(
        uint256[N_COINS] calldata targets,
        address[N_COINS] calldata vaults,
        uint256 withdrawUsd
    ) external view override returns (uint256[N_COINS] memory delta) {
        (uint256 totalAssets, uint256[N_COINS] memory vaultTotalAssets) = getUnifiedAssets(vaults);

        require(totalAssets > withdrawUsd, "totalAssets < withdrawalUsd");
        totalAssets = totalAssets.sub(withdrawUsd);
        uint256 totalDelta;
        for (uint256 i; i < N_COINS; i++) {
            uint256 target = totalAssets.mul(targets[i]).div(PERCENTAGE_DECIMAL_FACTOR);
            if (vaultTotalAssets[i] > target) {
                delta[i] = vaultTotalAssets[i].sub(target);
                totalDelta = totalDelta.add(delta[i]);
            }
        }
        uint256 percent = PERCENTAGE_DECIMAL_FACTOR;
        for (uint256 i; i < N_COINS - 1; i++) {
            if (delta[i] > 0) {
                delta[i] = delta[i].mul(PERCENTAGE_DECIMAL_FACTOR).div(totalDelta);
                percent = percent.sub(delta[i]);
            }
        }
        delta[N_COINS - 1] = percent;
        return delta;
    }

    /// @notice Sort vaults by the delta of target asset - current asset,
    ///     only support 3 vaults now
    /// @param bigFirst Return array order most exposed -> least exposed
    /// @param unifiedTotalAssets Estimated system USD assets
    /// @param unifiedAssets Estimated vault USD assets
    /// @param targetPercents Vault target percent array
    function sortVaultsByDelta(
        bool bigFirst,
        uint256 unifiedTotalAssets,
        uint256[N_COINS] calldata unifiedAssets,
        uint256[N_COINS] calldata targetPercents
    ) external pure override returns (uint256[N_COINS] memory vaultIndexes) {
        uint256 maxIndex;
        uint256 minIndex;
        int256 maxDelta;
        int256 minDelta;
        for (uint256 i = 0; i < N_COINS; i++) {
            // Get difference between vault current assets and vault target
            int256 delta = int256(
                unifiedAssets[i] - unifiedTotalAssets.mul(targetPercents[i]).div(PERCENTAGE_DECIMAL_FACTOR)
            );
            // Establish order
            if (delta > maxDelta) {
                maxDelta = delta;
                maxIndex = i;
            } else if (delta < minDelta) {
                minDelta = delta;
                minIndex = i;
            }
        }
        if (bigFirst) {
            vaultIndexes[0] = maxIndex;
            vaultIndexes[2] = minIndex;
        } else {
            vaultIndexes[0] = minIndex;
            vaultIndexes[2] = maxIndex;
        }
        vaultIndexes[1] = N_COINS - maxIndex - minIndex;
    }

    /// @notice Calculate what percentage of system total assets the assets in a strategy make up
    /// @param vault Address of target vault that holds the strategy
    /// @param index Index of strategy
    /// @param vaultAssetsPercent Percentage of system assets
    /// @param vaultAssets Total assets in vaults
    function calculatePercentOfSystem(
        address vault,
        uint256 index,
        uint256 vaultAssetsPercent,
        uint256 vaultAssets
    ) private view returns (uint256 percentOfSystem) {
        if (vaultAssets == 0) return 0;
        uint256 strategyAssetsPercent = IVault(vault).getStrategyAssets(index).mul(PERCENTAGE_DECIMAL_FACTOR).div(
            vaultAssets
        );

        percentOfSystem = vaultAssetsPercent.mul(strategyAssetsPercent).div(PERCENTAGE_DECIMAL_FACTOR);
    }

    /// @notice Calculate the net stablecoin exposure
    /// @param directlyExposure Amount of stablecoin in vault+strategies
    /// @param curveExposure Percent of assets in Curve
    function calculateStableCoinExposure(uint256[N_COINS] memory directlyExposure, uint256 curveExposure)
        private
        view
        returns (uint256[N_COINS] memory stableCoinExposure)
    {
        uint256 maker = directlyExposure[0].mul(makerUSDCExposure).div(PERCENTAGE_DECIMAL_FACTOR);
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 indirectExposure = curveExposure;
            if (i == 1) {
                indirectExposure = indirectExposure.add(maker);
            }
            stableCoinExposure[i] = directlyExposure[i].add(indirectExposure);
        }
    }

    /// @notice Determine if an assets or protocol is overexposed
    /// @param rebalanceThreshold Threshold for triggering a rebalance due to overexposure
    /// @param stableCoinExposure Current stable coin exposures
    /// @param protocolExposure Current prtocol exposures
    /// @param curveExposure Current Curve exposure
    function isExposed(
        uint256 rebalanceThreshold,
        uint256[N_COINS] memory stableCoinExposure,
        uint256[] memory protocolExposure,
        uint256 curveExposure
    ) private pure returns (bool stablecoinExposed, bool protocolExposed) {
        for (uint256 i = 0; i < N_COINS; i++) {
            if (stableCoinExposure[i] > rebalanceThreshold) {
                stablecoinExposed = true;
                break;
            }
        }
        for (uint256 i = 0; i < protocolExposure.length; i++) {
            if (protocolExposure[i] > rebalanceThreshold) {
                protocolExposed = true;
                break;
            }
        }
        if (!protocolExposed && curveExposure > rebalanceThreshold) protocolExposed = true;
        return (stablecoinExposed, protocolExposed);
    }

    function _calcRiskExposure(SystemState memory sysState, bool treatLifeguardAsCurve)
        private
        view
        returns (ExposureState memory expState)
    {
        address[N_COINS] memory vaults = _controller().vaults();
        uint256 pCount = protocolCount;
        expState.protocolExposure = new uint256[](pCount);
        if (sysState.totalCurrentAssetsUsd == 0) {
            return expState;
        }
        // Stablecoin exposure
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 vaultAssetsPercent = sysState.vaultCurrentAssetsUsd[i].mul(PERCENTAGE_DECIMAL_FACTOR).div(
                sysState.totalCurrentAssetsUsd
            );
            expState.stablecoinExposure[i] = vaultAssetsPercent;
            // Protocol exposure
            for (uint256 j = 0; j < pCount; j++) {
                uint256 percentOfSystem = calculatePercentOfSystem(
                    vaults[i],
                    j,
                    vaultAssetsPercent,
                    sysState.vaultCurrentAssets[i]
                );
                expState.protocolExposure[j] = expState.protocolExposure[j].add(percentOfSystem);
            }
        }
        if (treatLifeguardAsCurve) {
            // Curve exposure is calculated by adding the Curve vaults total assets and any
            // assets in the lifeguard which are poised to be invested into the Curve vault
            expState.curveExposure = sysState.curveCurrentAssetsUsd.add(sysState.lifeguardCurrentAssetsUsd);
        } else {
            expState.curveExposure = sysState.curveCurrentAssetsUsd;
        }
        expState.curveExposure = expState.curveExposure.mul(PERCENTAGE_DECIMAL_FACTOR).div(
            sysState.totalCurrentAssetsUsd
        );

        // Calculate stablecoin exposures
        expState.stablecoinExposure = calculateStableCoinExposure(expState.stablecoinExposure, expState.curveExposure);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../common/StructDefinitions.sol";
import "../common/Constants.sol";
import "../common/Controllable.sol";
import "../common/Whitelist.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/IAllocation.sol";
import "../interfaces/ILifeGuard.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IBuoy.sol";

/// @notice Contract for setting allocation targets for current protocol setup.
///     This contract will need to be upgraded if strategies in the protocol change.
///     --------------------------------------------------------
///     Current protocol setup:
///     --------------------------------------------------------
///     Stablecoins: DAI, USDC, USDT
///     LP tokens: 3Crv
///     Vaults: DAIVault, USDCVault, USDTVault, 3Crv vault
///     Strategy (exposures):
///         - Compound
///         - Idle finance
///         - Yearn Generic Lender:
///             - Cream
///         - CurveXpool:
///             - Curve3Pool
///             - CurveMetaPool
///             - Yearn
contract Allocation is Constants, Controllable, Whitelist, IAllocation {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Threshold used to make sure that small change in token value don't trigger rebalances
    uint256 public swapThreshold;
    // Threshold for determining if assets should be moved from the Curve vault
    uint256 public curvePercentThreshold;

    event LogNewSwapThreshold(uint256 threshold);
    event LogNewCurveThreshold(uint256 threshold);

    function setSwapThreshold(uint256 _swapThreshold) external onlyOwner {
        swapThreshold = _swapThreshold;
        emit LogNewSwapThreshold(_swapThreshold);
    }

    function setCurvePercentThreshold(uint256 _curvePercentThreshold) external onlyOwner {
        curvePercentThreshold = _curvePercentThreshold;
        emit LogNewCurveThreshold(_curvePercentThreshold);
    }

    /// @notice Calculate the difference between the protocol target allocations and
    ///     the actual protocol exposures (refered to as delta). This is used to determine
    ///     how the system needs to be rebalanced in the case that its getting close to being
    ///     overexposed.
    /// @param sysState Struct holding system state info
    /// @param expState Struct holding exposure state info
    function calcSystemTargetDelta(SystemState memory sysState, ExposureState memory expState)
        public
        view
        override
        returns (AllocationState memory allState)
    {
        // Strategy targets in stablecoin vaults are determined by the pwrd/gvt utilisationRatio
        allState.strategyTargetRatio = calcStrategyPercent(sysState.utilisationRatio);
        // Curve target is determined by governance (insurance - curveVaultPercent)
        allState.stableState = _calcVaultTargetDelta(sysState, false, true);
        // Calculate exposure delta - difference between targets and current assets
        (uint256 protocolExposedDeltaUsd, uint256 protocolExposedIndex) = calcProtocolExposureDelta(
            expState.protocolExposure,
            sysState
        );
        allState.protocolExposedIndex = protocolExposedIndex;
        if (protocolExposedDeltaUsd > allState.stableState.swapInTotalAmountUsd) {
            // If the rebalance cannot be achieved by simply moving assets from one vault, the
            // system needs to establish how to withdraw assets from all vaults and their
            // underlying strategies. Calculate protocol withdrawals based on all vaults,
            // each strategy above target withdraws: delta of current assets - target assets
            allState.needProtocolWithdrawal = true;
            allState.protocolWithdrawalUsd = calcProtocolWithdraw(allState, protocolExposedIndex);
        }
    }

    /// @notice Calculate the difference between target allocations for vault, and
    ///     actual exposures
    /// @param sysState Struct holding system state info
    /// @param onlySwapOut Calculation only for moving assets out of vault
    function calcVaultTargetDelta(SystemState memory sysState, bool onlySwapOut)
        public
        view
        override
        returns (StablecoinAllocationState memory)
    {
        return _calcVaultTargetDelta(sysState, onlySwapOut, false);
    }

    /// @notice Calculate how much assets should be moved out of strategies
    /// @param allState Struct holding system allocation info
    /// @param protocolExposedIndex Index of protocol for which exposures is being calculated
    /// @dev Protocol exposures are considered on their highest level - This means
    ///     that we can consider each strategy to have one exposure, even though they
    ///     might have several lower level exposures. For this to be true, the following
    ///     assumptions need to be true:
    ///     - Exposure overlap cannot occure among strategies:
    ///         - Strategies can't share protocol exposures. If two strategies are exposed
    ///             to Compound, the system level exposure to Compound may be higher than
    ///             the sum exposure of any individual strategy, e.g.:
    ///             Consider the following 2 strategies:
    ///                 - Strat A: Invest to protocol X
    ///                 - Strat B: Invest to protocol X and Y, through protocol Z
    ///             There is now a possibility that the total exposure to protocol X is higher
    ///             than the tolerated exposure level, and thus there would have to be
    ///             seperate logic to split out the exposure calculations in strat B
    ///             If on the other hand we have the following scenario:
    ///                 - Strat A: Invest to protocol X
    ///                 - Strat B: Invets to protocol Y, through protocol Z
    ///             We no longer need to consider the underlying exposures, but can rather look
    ///             at the total investment into the strategies as our current exposure
    ///     - Strategies in different vaults need to be ordered based on their exposure:
    ///         - To simplify the calculations, the order of strategies in vaults is important,
    ///             as the protocol exposures are addative for each strategy
    function calcProtocolWithdraw(AllocationState memory allState, uint256 protocolExposedIndex)
        private
        view
        returns (uint256[N_COINS] memory protocolWithdrawalUsd)
    {
        address[N_COINS] memory vaults = _controller().vaults();
        // How much to withdraw from each protocol
        uint256 strategyCurrentUsd;
        uint256 strategyTargetUsd;
        ILifeGuard lg = ILifeGuard(_controller().lifeGuard());
        IBuoy buoy = IBuoy(lg.getBuoy());
        // Loop over each vault
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 strategyAssets = IVault(vaults[i]).getStrategyAssets(protocolExposedIndex);
            // If the strategy has assets, determine the USD value of the asset
            if (strategyAssets > 0) {
                strategyCurrentUsd = buoy.singleStableToUsd(strategyAssets, i);
            }
            // Determine the USD value of the strategy asset target
            strategyTargetUsd = allState
            .stableState
            .vaultsTargetUsd[i]
            .mul(allState.strategyTargetRatio[protocolExposedIndex])
            .div(PERCENTAGE_DECIMAL_FACTOR);
            // If the strategy is over exposed, assets can be removed
            if (strategyCurrentUsd > strategyTargetUsd) {
                protocolWithdrawalUsd[i] = strategyCurrentUsd.sub(strategyTargetUsd);
            }
            // If the strategy is empty or under exposed, assets can be added
            if (protocolWithdrawalUsd[i] > 0 && protocolWithdrawalUsd[i] < allState.stableState.swapInAmountsUsd[i]) {
                protocolWithdrawalUsd[i] = allState.stableState.swapInAmountsUsd[i];
            }
        }
    }

    /// @notice Calculate how much assets should be moved in or out of vaults
    /// @param sysState Struct holding info about current system state
    /// @param onlySwapOut Do assets only need to be added to the vaults
    /// @param includeCurveVault Does the Curve vault need to considered in the rebalance
    function _calcVaultTargetDelta(
        SystemState memory sysState,
        bool onlySwapOut,
        bool includeCurveVault
    ) private view returns (StablecoinAllocationState memory stableState) {
        ILifeGuard lg = ILifeGuard(_controller().lifeGuard());
        IBuoy buoy = IBuoy(lg.getBuoy());

        uint256 amountToRebalance;
        // The rebalance may only be possible by moving assets out of the Curve vault,
        //  as Curve adds exposure to all stablecoins
        if (includeCurveVault && needCurveVault(sysState)) {
            stableState.curveTargetUsd = sysState.totalCurrentAssetsUsd.mul(sysState.curvePercent).div(
                PERCENTAGE_DECIMAL_FACTOR
            );
            // Estimate how much needs to be moved out of the Curve vault
            amountToRebalance = sysState.totalCurrentAssetsUsd.sub(stableState.curveTargetUsd);
            // When establishing current Curve exposures, we include uninvested assets in the lifeguard
            // as part of the Curve vault, otherwise I rebalance could temporarily fix an overexposure,
            // just to have to deal with the same overexposure when the lifeguard assets get invested
            // into the Curve vault.
            uint256 curveCurrentAssetsUsd = sysState.lifeguardCurrentAssetsUsd.add(sysState.curveCurrentAssetsUsd);
            stableState.curveTargetDeltaUsd = curveCurrentAssetsUsd > stableState.curveTargetUsd
                ? curveCurrentAssetsUsd.sub(stableState.curveTargetUsd)
                : 0;
        } else {
            // If we dont have to consider the Curve vault, Remove Curve assets and the part in lifeguard for Curve
            // from the rebalance calculations
            amountToRebalance = sysState
            .totalCurrentAssetsUsd
            .sub(sysState.curveCurrentAssetsUsd)
            .sub(sysState.lifeguardCurrentAssetsUsd)
            .add(lg.availableUsd());
        }

        // Calculate the strategy amount by vaultAssets * percentOfStrategy
        uint256 swapOutTotalUsd = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            // Compare allocation targets with actual assets in vault -
            //   if onlySwapOut = True, we don't consider the the current assets in the vault,
            //   but rather how much we need to remove from the vault based on target allocations.
            //   This means that the removal amount gets split throughout the vaults based on
            //   the allocation targets, rather than the difference between the allocation target
            //   and the actual amount of assets in the vault.
            uint256 vaultTargetUsd = amountToRebalance.mul(sysState.stablePercents[i]).div(PERCENTAGE_DECIMAL_FACTOR);
            uint256 vaultTargetAssets;
            if (!onlySwapOut) {
                vaultTargetAssets = vaultTargetUsd == 0 ? 0 : buoy.singleStableFromUsd(vaultTargetUsd, int128(i));
                stableState.vaultsTargetUsd[i] = vaultTargetUsd;
            }

            // More than target
            if (sysState.vaultCurrentAssetsUsd[i] > vaultTargetUsd) {
                if (!onlySwapOut) {
                    stableState.swapInAmounts[i] = sysState.vaultCurrentAssets[i].sub(vaultTargetAssets);
                    stableState.swapInAmountsUsd[i] = sysState.vaultCurrentAssetsUsd[i].sub(vaultTargetUsd);
                    // Make sure that that the change in vault asset is large enough to
                    // justify rebalancing the vault
                    if (invalidDelta(swapThreshold, stableState.swapInAmountsUsd[i])) {
                        stableState.swapInAmounts[i] = 0;
                        stableState.swapInAmountsUsd[i] = 0;
                    } else {
                        stableState.swapInTotalAmountUsd = stableState.swapInTotalAmountUsd.add(
                            stableState.swapInAmountsUsd[i]
                        );
                    }
                }
                // Less than target
            } else {
                stableState.swapOutPercents[i] = vaultTargetUsd.sub(sysState.vaultCurrentAssetsUsd[i]);
                // Make sure that that the change in vault asset is large enough to
                // justify rebalancing the vault
                if (invalidDelta(swapThreshold, stableState.swapOutPercents[i])) {
                    stableState.swapOutPercents[i] = 0;
                } else {
                    swapOutTotalUsd = swapOutTotalUsd.add(stableState.swapOutPercents[i]);
                }
            }
        }

        // Establish percentage (BP) amount for change in each vault
        uint256 percent = PERCENTAGE_DECIMAL_FACTOR;
        for (uint256 i = 0; i < N_COINS - 1; i++) {
            if (stableState.swapOutPercents[i] > 0) {
                stableState.swapOutPercents[i] = stableState.swapOutPercents[i].mul(PERCENTAGE_DECIMAL_FACTOR).div(
                    swapOutTotalUsd
                );
                percent = percent.sub(stableState.swapOutPercents[i]);
            }
        }
        stableState.swapOutPercents[N_COINS - 1] = percent;
    }

    /// @notice Calculate assets distribution to strategies
    /// @param utilisationRatio Ratio of gvt to pwrd
    /// @dev The distribution of assets between the primary and secondary
    ///     strategies are based on the pwrd/gvt utilisation ratio
    function calcStrategyPercent(uint256 utilisationRatio)
        public
        pure
        override
        returns (uint256[] memory targetPercent)
    {
        targetPercent = new uint256[](2);
        uint256 primaryTarget = PERCENTAGE_DECIMAL_FACTOR.mul(PERCENTAGE_DECIMAL_FACTOR).div(
            PERCENTAGE_DECIMAL_FACTOR.add(utilisationRatio)
        );

        targetPercent[0] = primaryTarget; // Primary
        targetPercent[1] = PERCENTAGE_DECIMAL_FACTOR // Secondary
        .sub(targetPercent[0]);
    }

    /// @notice Loops over the protocol exposures and calculate the delta between the exposure
    ///     and target threshold if the protocol is over exposed. For the Curve protocol, the delta is the
    ///     difference between the current exposure and target allocation.
    /// @param protocolExposure Exposure percent of protocols
    /// @param sysState Struct holding info of the systems current state
    /// @return protocolExposedDeltaUsd Difference between the overExposure and the target protocol exposure.
    ///     By defenition, only one protocol can exceed exposure in the current setup.
    /// @return protocolExposedIndex The index of the corresponding protocol of protocolDelta
    function calcProtocolExposureDelta(uint256[] memory protocolExposure, SystemState memory sysState)
        private
        pure
        returns (uint256 protocolExposedDeltaUsd, uint256 protocolExposedIndex)
    {
        for (uint256 i = 0; i < protocolExposure.length; i++) {
            // If the exposure is greater than the rebalance threshold...
            if (protocolExposedDeltaUsd == 0 && protocolExposure[i] > sysState.rebalanceThreshold) {
                // ...Calculate the delta between exposure and target
                uint256 target = sysState.rebalanceThreshold.sub(sysState.targetBuffer);
                protocolExposedDeltaUsd = protocolExposure[i].sub(target).mul(sysState.totalCurrentAssetsUsd).div(
                    PERCENTAGE_DECIMAL_FACTOR
                );
                protocolExposedIndex = i;
            }
        }
    }

    /// @notice Check if the change in a vault is above a certain threshold.
    ///     This stops a rebalance occurring from stablecoins going slightly off peg
    /// @param threshold Threshold for difference to be considered valid
    /// @param delta Difference between current exposure and target
    function invalidDelta(uint256 threshold, uint256 delta) private pure returns (bool) {
        return delta > 0 && threshold > 0 && delta < threshold.mul(DEFAULT_DECIMALS_FACTOR);
    }

    /// @notice Check if Curve vault needs to be considered in rebalance action
    /// @param sysState Struct holding info about system current state
    function needCurveVault(SystemState memory sysState) private view returns (bool) {
        uint256 currentPercent = sysState
        .curveCurrentAssetsUsd
        .add(sysState.lifeguardCurrentAssetsUsd)
        .mul(PERCENTAGE_DECIMAL_FACTOR)
        .div(sysState.totalCurrentAssetsUsd);
        return currentPercent > curvePercentThreshold;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/IInsurance.sol";

contract MockInsurance is IInsurance {
    address[] public underlyingVaults;
    address controller;
    uint256 public vaultDeltaIndex = 3;
    uint256[3] public vaultDeltaOrder = [1, 0, 2];

    mapping(uint256 => uint256) public underlyingTokensPercents;

    function calculateDepositDeltasOnAllVaults() external view override returns (uint256[3] memory deltas) {
        deltas[0] = 3333;
        deltas[1] = 3333;
        deltas[2] = 3333;
    }

    function rebalanceTrigger() external view override returns (bool sysNeedRebalance) {}

    function rebalance() external override {}

    function setController(address _controller) external {
        controller = _controller;
    }

    function setupTokens() external {
        underlyingTokensPercents[0] = 3000;
        underlyingTokensPercents[1] = 3000;
        underlyingTokensPercents[2] = 4000;
    }

    function rebalanceForWithdraw(uint256 withdrawUsd, bool pwrd) external override returns (bool) {}

    function setVaultDeltaIndex(uint256 _vaultDeltaIndex) external {
        require(_vaultDeltaIndex < 3, "invalid index");
        vaultDeltaIndex = _vaultDeltaIndex;
    }

    function getVaultDeltaForDeposit(uint256 amount)
        external
        view
        override
        returns (
            uint256[3] memory,
            uint256[3] memory,
            uint256
        )
    {
        amount;
        uint256[3] memory empty;
        if (vaultDeltaIndex == 3) {
            return (empty, vaultDeltaOrder, 3);
        } else {
            uint256[3] memory indexes;
            indexes[0] = vaultDeltaIndex;
            return (empty, indexes, 1);
        }
    }

    function calcSkim() external view override returns (uint256) {}

    function getStrategiesTargetRatio(uint256 utilRatio) external view override returns (uint256[] memory result) {
        result = new uint256[](2);
        result[0] = 5000;
        result[1] = 5000;
    }

    function getDelta(uint256 withdrawUsd) external view override returns (uint256[3] memory delta) {
        withdrawUsd;
        delta[0] = 3000;
        delta[1] = 3000;
        delta[2] = 4000;
    }

    function setUnderlyingTokenPercent(uint256 coinIndex, uint256 percent) external override {
        underlyingTokensPercents[coinIndex] = percent;
    }

    function sortVaultsByDelta(bool bigFirst) external view override returns (uint256[3] memory) {
        return vaultDeltaOrder;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/ICurve.sol";

// Mock curve 3pool
contract MockCurvePool is ICurve3Pool {
    address[] public override coins;

    uint256 N_COINS = 3;
    uint256[] public PRECISION_MUL = [1, 1000000000000, 1000000000000];
    uint256[] public decimals = [18, 6, 6];
    uint256[] public rates = [1001835600000000000, 999482, 999069];
    uint256 constant vp = 1005330723799997871;
    uint256[] vpSingle = [996343755718242128, 994191500557422927, 993764724471177721];

    constructor(address[] memory _tokens) public {
        coins = _tokens;
    }

    function setTokens(
        address[] calldata _tokens,
        uint256[] calldata _precisions,
        uint256[] calldata _rates
    ) external {
        coins = _tokens;
        N_COINS = _tokens.length;
        PRECISION_MUL = _precisions;
        rates = _rates;
    }

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view override returns (uint256) {
        return (vpSingle[uint256(i)] * _token_amount) / ((uint256(10)**18) * PRECISION_MUL[uint256(i)]);
    }

    function calc_token_amount(uint256[3] calldata inAmounts, bool deposit) external view override returns (uint256) {
        deposit;
        uint256 totalAmount;
        for (uint256 i = 0; i < vpSingle.length; i++) {
            totalAmount += (inAmounts[i] * vpSingle[i]) / (10**decimals[i]);
        }
        return totalAmount;
    }

    function balances(int128 i) external view override returns (uint256) {
        i;
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        dx;
        uint256 x = rates[uint256(i)] * PRECISION_MUL[uint256(i)] * (10**decimals[uint256(j)]);
        uint256 y = rates[uint256(j)] * PRECISION_MUL[uint256(j)];
        return x / y;
    }

    function get_virtual_price() external view override returns (uint256) {
        return vp;
    }
}

/*
    Copyright 2019 dYdX Trading Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Interest} from "./ISoloMargin.sol";

/**
 * @title IInterestSetter
 * @author dYdX
 *
 * Interface that Interest Setters for Solo must implement in order to report interest rates.
 */
interface IInterestSetter {
    // ============ Public Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    ) external view returns (Interest.Rate memory);
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {BaseStrategy, StrategyParams, VaultAPI} from "../BaseStrategy.sol";

// NOTE: Imported 3rd party contract left in it's own style


/*
 * This Strategy serves as both a mock Strategy for testing, and an example
 * for integrators on how to use BaseStrategy
 */

contract TestStrategy is BaseStrategy {
    bool public doReentrancy;

    constructor(address _vault) public BaseStrategy(_vault) {}

    function name() external override view returns (string memory) {
        return string(abi.encodePacked("TestStrategy ", apiVersion()));
    }

    // NOTE: This is a test-only function to simulate losses
    function _takeFunds(uint256 amount) public {
        want.transfer(msg.sender, amount);
    }

    // NOTE: This is a test-only function to enable reentrancy on withdraw
    function _toggleReentrancyExploit() public {
        doReentrancy = !doReentrancy;
    }

    function estimatedTotalAssets() public override view returns (uint256) {
        // For mock, this is just everything we have
        return want.balanceOf(address(this));
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // During testing, send this contract some tokens to simulate "Rewards"
        uint256 totalAssets = want.balanceOf(address(this));
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        if (totalAssets > _debtOutstanding) {
            _debtPayment = _debtOutstanding;
            totalAssets = totalAssets.sub(_debtOutstanding);
        } else {
            _debtPayment = totalAssets;
            totalAssets = 0;
        }
        totalDebt = totalDebt.sub(_debtPayment);

        if (totalAssets > totalDebt) {
            _profit = totalAssets.sub(totalDebt);
        } else {
            _loss = totalDebt.sub(totalAssets);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // Whatever we have "free", consider it "invested" now
    }

    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        if (doReentrancy) {
            // simulate a malicious protocol or reentrancy situation triggered by strategy withdraw interactions
            uint256 stratBalance = VaultAPI(address(vault)).balanceOf(address(this));
            VaultAPI(address(vault)).withdraw(stratBalance, address(this));
        }

        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            _loss = _amountNeeded.sub(totalAssets);
        } else {
            // NOTE: Just in case something was stolen from this contract
            if (totalDebt > totalAssets) {
                _loss = totalDebt.sub(totalAssets);
                if (_loss > _amountNeeded) _loss = _amountNeeded;
            }
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        // Nothing needed here because no additional tokens/tokenized positions for mock
    }

    function protectedTokens() internal override view returns (address[] memory) {
        return new address[](0); // No additional tokens/tokenized positions for mock
    }

    function expectedReturn() external view returns (uint256) {
        uint256 estimateAssets = estimatedTotalAssets();

        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (debt > estimateAssets) {
            return 0;
        } else {
            return estimateAssets - debt;
        }
    }
}

// SPDX-License-Identifier: AGPLv3
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function decimals() external view returns (uint256);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GToken.sol";

/// @notice NonRebasing token implementation of the GToken.
///     This contract defines the Gro Vault Token (GVT) - A yield baring token used in
///     gro protocol. The NonRebasing token has a fluctuating price, defined as:
///         BASE (10**18) / factor (total supply / total assets)
///     where the total supply is the number of minted tokens, and the total assets
///     is the USD value of the underlying assets used to mint the token.
contract NonRebasingGToken is GToken {
    uint256 public constant INIT_BASE = 3333333333333333;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event LogTransfer(address indexed sender, address indexed recipient, uint256 indexed amount, uint256 factor);

    constructor(string memory name, string memory symbol) public GToken(name, symbol) {}

    /// @notice Return the base supply of the token - This is similar
    ///     to the original ERC20 totalSupply method for NonRebasingGTokens
    function totalSupply() public view override returns (uint256) {
        return totalSupplyBase();
    }

    /// @notice Amount of token the user owns
    function balanceOf(address account) public view override returns (uint256) {
        return balanceOfBase(account);
    }

    /// @notice Transfer override - does the same thing as the standard
    ///     ERC20 transfer function (shows number of tokens transfered)
    /// @param recipient Recipient of transfer
    /// @param amount Amount to transfer
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        super._transfer(msg.sender, recipient, amount, amount);
        emit LogTransfer(msg.sender, recipient, amount, factor());
        return true;
    }

    /// @notice Price per token (USD)
    function getPricePerShare() public view override returns (uint256) {
        uint256 f = factor();
        return f > 0 ? applyFactor(BASE, f, false) : 0;
    }

    /// @notice Price of a set amount of shared
    /// @param shares Number of shares
    function getShareAssets(uint256 shares) public view override returns (uint256) {
        return applyFactor(shares, getPricePerShare(), true);
    }

    /// @notice Get amount USD value of users assets
    /// @param account Target account
    function getAssets(address account) external view override returns (uint256) {
        return getShareAssets(balanceOf(account));
    }

    function getInitialBase() internal pure override returns (uint256) {
        return INIT_BASE;
    }

    /// @notice Mint NonRebasingGTokens
    /// @param account Target account
    /// @param _factor factor to use for mint
    /// @param amount Mint amount in USD
    function mint(
        address account,
        uint256 _factor,
        uint256 amount
    ) external override onlyWhitelist {
        require(account != address(0), "mint: 0x");
        require(amount > 0, "Amount is zero.");
        // Divide USD amount by factor to get number of tokens to mint
        amount = applyFactor(amount, _factor, true);
        _mint(account, amount, amount);
    }

    /// @notice Burn NonRebasingGTokens
    /// @param account Target account
    /// @param _factor Factor to use for mint
    /// @param amount Burn amount in USD
    function burn(
        address account,
        uint256 _factor,
        uint256 amount
    ) external override onlyWhitelist {
        require(account != address(0), "burn: 0x");
        require(amount > 0, "Amount is zero.");
        // Divide USD amount by factor to get number of tokens to burn
        amount = applyFactor(amount, _factor, true);
        _burn(account, amount, amount);
    }

    /// @notice Burn all tokens for user (used by withdraw all methods to avoid dust)
    /// @param account Target account
    function burnAll(address account) external override onlyWhitelist {
        require(account != address(0), "burnAll: 0x");
        uint256 amount = balanceOfBase(account);
        _burn(account, amount, amount);
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}