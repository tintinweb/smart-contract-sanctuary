// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./PoolShare.sol";

/// @dev Token representing the yield shares of a pool.
contract YieldShare is PoolShare {
    constructor(
        ITempusPool _pool,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) PoolShare(ShareKind.Yield, _pool, name, symbol, decimals) {}

    // solhint-disable-previous-line no-empty-blocks

    function getPricePerFullShare() external override returns (uint256) {
        return pool.pricePerYieldShare();
    }

    function getPricePerFullShareStored() external view override returns (uint256) {
        return pool.pricePerYieldShareStored();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./ERC20OwnerMintableToken.sol";
import "../ITempusPool.sol";

/// Token representing the principal or yield shares of a pool.
abstract contract PoolShare is IPoolShare, ERC20OwnerMintableToken {
    /// The kind of the share.
    ShareKind public immutable override kind;

    /// The pool this share is part of.
    ITempusPool public immutable override pool;

    uint8 internal immutable tokenDecimals;

    constructor(
        ShareKind _kind,
        ITempusPool _pool,
        string memory name,
        string memory symbol,
        uint8 _decimals
    ) ERC20OwnerMintableToken(name, symbol) {
        kind = _kind;
        pool = _pool;
        tokenDecimals = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return tokenDecimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// This is a simplified implementation, but compatible with
/// OpenZeppelin's ERC20Mintable and ERC20Burnable extensions.
contract ERC20OwnerMintableToken is ERC20 {
    /// The manager who is allowed to mint and burn.
    address public immutable manager;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        manager = msg.sender;
    }

    /// Creates `amount` new tokens for `to`.
    /// @param account Recipient address to mint tokens to
    /// @param amount Number of tokens to mint
    function mint(address account, uint256 amount) external {
        require(msg.sender == manager, "mint: only manager can mint");
        _mint(account, amount);
    }

    /// Destroys `amount` tokens from the caller.
    /// @param amount Number of tokens to burn.
    function burn(uint256 amount) external {
        require(msg.sender == manager, "burn: only manager can burn");
        _burn(manager, amount);
    }

    /// Destroys `amount` tokens from `account`.
    /// @param account Source address to burn tokens from
    /// @param amount Number of tokens to burn
    function burnFrom(address account, uint256 amount) external {
        require(msg.sender == manager, "burn: only manager can burn");
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

import "./token/IPoolShare.sol";
import "./utils/IOwnable.sol";
import "./utils/IVersioned.sol";

/// Setting and transferring of fees are restricted to the owner.
interface ITempusFees is IOwnable {
    /// The fees are in terms of yield bearing token (YBT).
    struct FeesConfig {
        uint256 depositPercent;
        uint256 earlyRedeemPercent;
        uint256 matureRedeemPercent;
    }

    /// Returns the current fee configuration.
    function getFeesConfig() external view returns (FeesConfig memory);

    /// Replace the current fee configuration with a new one.
    /// By default all the fees are expected to be set to zero.
    /// @notice This function can only be called by the owner.
    function setFeesConfig(FeesConfig calldata newFeesConfig) external;

    /// @return Maximum possible fee percentage that can be set for deposit
    function maxDepositFee() external view returns (uint256);

    /// @return Maximum possible fee percentage that can be set for early redeem
    function maxEarlyRedeemFee() external view returns (uint256);

    /// @return Maximum possible fee percentage that can be set for mature redeem
    function maxMatureRedeemFee() external view returns (uint256);

    /// Accumulated fees available for withdrawal.
    function totalFees() external view returns (uint256);

    /// Transfers accumulated Yield Bearing Token (YBT) fees
    /// from this pool contract to `recipient`.
    /// @param recipient Address which will receive the specified amount of YBT
    /// @notice This function can only be called by the owner.
    function transferFees(address recipient) external;
}

/// All state changing operations are restricted to the controller.
interface ITempusPool is ITempusFees, IVersioned {
    /// @return The name of underlying protocol, for example "Aave" for Aave protocol
    function protocolName() external view returns (bytes32);

    /// This token will be used as a token that user can deposit to mint same amounts
    /// of principal and interest shares.
    /// @return The underlying yield bearing token.
    function yieldBearingToken() external view returns (address);

    /// This is the address of the actual backing asset token
    /// in the case of ETH, this address will be 0
    /// @return Address of the Backing Token
    function backingToken() external view returns (address);

    /// @return uint256 value of one backing token, in case of 18 decimals 1e18
    function backingTokenONE() external view returns (uint256);

    /// @return This TempusPool's Tempus Principal Share (TPS)
    function principalShare() external view returns (IPoolShare);

    /// @return This TempusPool's Tempus Yield Share (TYS)
    function yieldShare() external view returns (IPoolShare);

    /// @return The TempusController address that is authorized to perform restricted actions
    function controller() external view returns (address);

    /// @return Start time of the pool.
    function startTime() external view returns (uint256);

    /// @return Maturity time of the pool.
    function maturityTime() external view returns (uint256);

    /// @return Time of exceptional halting of the pool.
    /// In case the pool is still in operation, this must return type(uint256).max.
    function exceptionalHaltTime() external view returns (uint256);

    /// @return The maximum allowed time (in seconds) to pass with negative yield.
    function maximumNegativeYieldDuration() external view returns (uint256);

    /// @return True if maturity has been reached and the pool was finalized.
    ///         This also includes the case when maturity was triggered due to
    ///         exceptional conditions (negative yield periods).
    function matured() external view returns (bool);

    /// Finalizes the pool. This can only happen on or after `maturityTime`.
    /// Once finalized depositing is not possible anymore, and the behaviour
    /// redemption will change.
    ///
    /// Can be called by anyone and can be called multiple times.
    function finalize() external;

    /// Yield bearing tokens deposit hook.
    /// @notice Deposit will fail if maturity has been reached.
    /// @notice This function can only be called by TempusController
    /// @notice This function assumes funds were already transferred to the TempusPool from the TempusController
    /// @param yieldTokenAmount Amount of yield bearing tokens to deposit in YieldToken decimal precision
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    /// @return mintedShares Amount of TPS and TYS minted to `recipient`
    /// @return depositedBT The YBT value deposited, denominated as Backing Tokens
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the deposit
    function onDepositYieldBearing(uint256 yieldTokenAmount, address recipient)
        external
        returns (
            uint256 mintedShares,
            uint256 depositedBT,
            uint256 fee,
            uint256 rate
        );

    /// Backing tokens deposit hook.
    /// @notice Deposit will fail if maturity has been reached.
    /// @notice This function can only be called by TempusController
    /// @notice This function assumes funds were already transferred to the TempusPool from the TempusController
    /// @param backingTokenAmount amount of Backing Tokens to be deposited to underlying protocol in BackingToken decimal precision
    /// @param recipient Address which will receive Tempus Principal Shares (TPS) and Tempus Yield Shares (TYS)
    /// @return mintedShares Amount of TPS and TYS minted to `recipient`
    /// @return depositedYBT The BT value deposited, denominated as Yield Bearing Tokens
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the deposit
    function onDepositBacking(uint256 backingTokenAmount, address recipient)
        external
        payable
        returns (
            uint256 mintedShares,
            uint256 depositedYBT,
            uint256 fee,
            uint256 rate
        );

    /// Redeems yield bearing tokens from this TempusPool
    ///      msg.sender will receive the YBT
    ///      NOTE #1 Before maturity, principalAmount must equal to yieldAmount.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param from Address to redeem its Tempus Shares
    /// @param principalAmount Amount of Tempus Principal Shares (TPS) to redeem for YBT in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yield Shares (TYS) to redeem for YBT in YieldShare decimal precision
    /// @param recipient Address to which redeemed YBT will be sent
    /// @return redeemableYieldTokens Amount of Yield Bearing Tokens redeemed to `recipient`
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the redemption
    function redeem(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        returns (
            uint256 redeemableYieldTokens,
            uint256 fee,
            uint256 rate
        );

    /// Redeems TPS+TYS held by msg.sender into backing tokens
    ///      `msg.sender` must approve TPS and TYS amounts to this TempusPool.
    ///      `msg.sender` will receive the backing tokens
    ///      NOTE #1 Before maturity, principalAmount must equal to yieldAmount.
    ///      NOTE #2 This function can only be called by TempusController
    /// @param from Address to redeem its Tempus Shares
    /// @param principalAmount Amount of Tempus Principal Shares (TPS) to redeem in PrincipalShare decimal precision
    /// @param yieldAmount Amount of Tempus Yield Shares (TYS) to redeem in YieldShare decimal precision
    /// @param recipient Address to which redeemed BT will be sent
    /// @return redeemableYieldTokens Amount of Backing Tokens redeemed to `recipient`, denominated in YBT
    /// @return redeemableBackingTokens Amount of Backing Tokens redeemed to `recipient`
    /// @return fee The fee which was deducted (in terms of YBT)
    /// @return rate The interest rate at the time of the redemption
    function redeemToBacking(
        address from,
        uint256 principalAmount,
        uint256 yieldAmount,
        address recipient
    )
        external
        payable
        returns (
            uint256 redeemableYieldTokens,
            uint256 redeemableBackingTokens,
            uint256 fee,
            uint256 rate
        );

    /// Gets the estimated amount of Principals and Yields after a successful deposit
    /// @param amount Amount of BackingTokens or YieldBearingTokens that would be deposited
    /// @param isBackingToken If true, @param amount is in BackingTokens, otherwise YieldBearingTokens
    /// @return Amount of Principals (TPS) and Yields (TYS) in Principal/YieldShare decimal precision
    ///         TPS and TYS are minted in 1:1 ratio, hence a single return value.
    function estimatedMintedShares(uint256 amount, bool isBackingToken) external view returns (uint256);

    /// Gets the estimated amount of YieldBearingTokens or BackingTokens received when calling `redeemXXX()` functions
    /// @param principals Amount of Principals (TPS) in PrincipalShare decimal precision
    /// @param yields Amount of Yields (TYS) in YieldShare decimal precision
    /// @param toBackingToken If true, redeem amount is estimated in BackingTokens instead of YieldBearingTokens
    /// @return Amount of YieldBearingTokens or BackingTokens in YBT/BT decimal precision
    function estimatedRedeem(
        uint256 principals,
        uint256 yields,
        bool toBackingToken
    ) external view returns (uint256);

    /// @dev This returns the stored Interest Rate of the YBT (Yield Bearing Token) pool
    ///      it is safe to call this after updateInterestRate() was called
    /// @return Stored Interest Rate, decimal precision depends on specific TempusPool implementation
    function currentInterestRate() external view returns (uint256);

    /// @return Initial interest rate of the underlying pool,
    ///         decimal precision depends on specific TempusPool implementation
    function initialInterestRate() external view returns (uint256);

    /// @return Interest rate at maturity of the underlying pool (or 0 if maturity not reached yet)
    ///         decimal precision depends on specific TempusPool implementation
    function maturityInterestRate() external view returns (uint256);

    /// @return Rate of one Tempus Yield Share expressed in Asset Tokens
    function pricePerYieldShare() external returns (uint256);

    /// @return Rate of one Tempus Principal Share expressed in Asset Tokens
    function pricePerPrincipalShare() external returns (uint256);

    /// Calculated with stored interest rates
    /// @return Rate of one Tempus Yield Share expressed in Asset Tokens,
    function pricePerYieldShareStored() external view returns (uint256);

    /// Calculated with stored interest rates
    /// @return Rate of one Tempus Principal Share expressed in Asset Tokens
    function pricePerPrincipalShareStored() external view returns (uint256);

    /// @dev This returns actual Backing Token amount for amount of YBT (Yield Bearing Tokens)
    ///      For example, in case of Aave and Lido the result is 1:1,
    ///      and for compound is `yieldTokens * currentInterestRate`
    /// @param yieldTokens Amount of YBT in YBT decimal precision
    /// @param interestRate The current interest rate
    /// @return Amount of Backing Tokens for specified @param yieldTokens
    function numAssetsPerYieldToken(uint yieldTokens, uint interestRate) external view returns (uint);

    /// @dev This returns amount of YBT (Yield Bearing Tokens) that can be converted
    ///      from @param backingTokens Backing Tokens
    /// @param backingTokens Amount of Backing Tokens in BT decimal precision
    /// @param interestRate The current interest rate
    /// @return Amount of YBT for specified @param backingTokens
    function numYieldTokensPerAsset(uint backingTokens, uint interestRate) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "../ITempusPool.sol";

/// Interface of Tokens representing the principal or yield shares of a pool.
interface IPoolShare {
    enum ShareKind {
        Principal,
        Yield
    }

    /// @return The kind of the share.
    function kind() external view returns (ShareKind);

    /// @return The pool this share is part of.
    function pool() external view returns (ITempusPool);

    /// @dev Price per single share expressed in Backing Tokens of the underlying pool.
    ///      This is for the purpose of TempusAMM api support.
    ///      Example: exchanging Tempus Yield Share to DAI
    /// @return 1e18 decimal conversion rate per share
    function getPricePerFullShare() external returns (uint256);

    /// @return 1e18 decimal stored conversion rate per share
    function getPricePerFullShareStored() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

/// Implements Ownable with a two step transfer of ownership
interface IOwnable {
    /**
     * @dev Change of ownership proposed.
     * @param currentOwner The current owner.
     * @param proposedOwner The proposed owner.
     */
    event OwnershipProposed(address indexed currentOwner, address indexed proposedOwner);

    /**
     * @dev Ownership transferred.
     * @param previousOwner The previous owner.
     * @param newOwner The new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Proposes a transfer of ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Accepts ownership of the contract by a proposed account.
     * Can only be called by the proposed owner.
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;

/// Implements versioning
interface IVersioned {
    struct Version {
        uint16 major;
        uint16 minor;
        uint16 patch;
    }

    /// @return The version of the contract.
    function version() external view returns (Version memory);
}