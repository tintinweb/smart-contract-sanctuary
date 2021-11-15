// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITier } from "../tier/ITier.sol";
import { TierByConstruction } from "../tier/TierByConstruction.sol";

/// @title TierByConstructionClaim
/// @notice `TierByConstructionClaim` is a base contract for other contracts to
/// inherit from.
///
/// It builds on `TierByConstruction` with a `claim` function and `_afterClaim`
/// hook.
///
/// The `claim` function checks `onlyTier` and exposes `isTier` for
/// `_afterClaim` hooks so that accounts can self-mint rewards such as erc20,
/// erc1155, erc721, etc. if they meet the tier requirements.
///
/// The `claim` function can only be called once per account.
///
/// Note that `claim` is an unrestricted function and only the tier of the
/// _recipient_ is checked.
///
/// Implementing contracts must be careful to avoid griefing attacks where an
/// attacker calls `claim` against a third party in such a way that their
/// reward is minimised or damaged in some way.
///
/// For example, `ERC20BalanceTier` used with `TierByConstructionClaim` opens
/// the ability for an attacker to `claim` every address they know that has not
/// reached the minimum balance, permanently voiding that address for future
/// claims even if they reach the minimum balance at a later date.
///
/// Another example, `data_` is set to some empty value by the attacker for the
/// `claim` call that voids the ability for the recipient to receive more
/// rewards, had the `data_` been set to some meaningful value.
///
/// The simplest fix is to require `msg.sender` and recipient account are the
/// same, thus requiring the receiver to ensure for themselves that they claim
/// only when and how they want. Of course, this also precludes a whole class
/// of delegated claims processing that may provide a superior user experience.
///
/// Inheriting contracts MUST implement `_afterClaim` with restrictions that
/// are appropriate to the nature of the claim.
///
/// @dev Contract that can be inherited by anything that wants to manage claims
/// of erc20/721/1155/etc. based on tier.
/// The tier must be held continously since the contract construction according
/// to the tier contract.
/// In general it is INSECURE to inherit `TierByConstructionClaim` without
/// implementing `_afterClaim` with appropriate access checks.
contract TierByConstructionClaim is TierByConstruction {
    /// The minimum tier required for an address to claim anything at all.
    /// This tier must have been held continuously since before this
    /// contract was constructed.
    ITier.Tier public immutable minimumTier;

    /// Tracks every address that has already claimed to prevent duplicate
    /// claims.
    mapping(address => bool) public claims;

    /// A claim has been successfully processed for an account.
    event Claim(address indexed account, bytes data);

    /// Nothing special needs to happen in the constructor.
    /// Simply forwards the desired ITier contract to the `TierByConstruction`
    /// constructor.
    /// The minimum tier is set for `claim` logic.
    constructor(ITier tierContract_, ITier.Tier minimumTier_)
        public
        TierByConstruction(tierContract_)
    {
        minimumTier = minimumTier_;
    }

    /// The `onlyTier` modifier checks the claimant against minimumTier.
    /// The ITier contract decides for itself whether the claimant is
    /// `minimumTier` __as at the block this contract was constructed__.
    /// This may be ambiguous for `ReadOnlyTier` contracts that may not have
    /// accurate block times and fallback to `0` when the block is unknown.
    ///
    /// If `account_` gained `minimumTier` after this contract was deployed
    /// but hold it at the time of calling `claim` they are NOT eligible.
    ///
    /// The claim can only be called successfully once per account.
    ///
    /// NOTE: This function is callable by anyone and can only be
    /// called at most once per account.
    /// The `_afterClaim` function can and MUST enforce all appropriate access
    /// restrictions on when/how a claim is valid.
    ///
    /// Be very careful to manage griefing attacks when the `msg.sender` is not
    /// `account_`, for example:
    /// - An `ERC20BalanceTier` has no historical information so
    /// anyone can claim for anyone else based on their balance at any time.
    /// - `data_` may be set arbitrarily by `msg.sender` so could be
    /// consumed frivilously at the expense of `account_`.
    ///
    /// @param account_ The account that receives the benefits of the claim.
    /// @param data_ Additional data that may inform the claim process.
    function claim(address account_, bytes memory data_)
        external
        onlyTier(account_, minimumTier)
    {
        // Prevent duplicate claims for a given account.
        require(!claims[account_], "DUPLICATE_CLAIM");

        // Record that a claim has been made for this account.
        claims[account_] = true;

        // Log the claim.
        emit Claim(account_, data_);

        // Process the claim.
        // Inheriting contracts will need to override this to make
        // the claim useful.
        _afterClaim(account_, tierContract.report(account_), data_);
    }

    /// Implementing contracts need to define what is claimed.
    // Slither false positive. This is intended to overridden.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _afterClaim(
        address account_,
        uint256 report_,
        bytes memory data_
    )
        internal virtual
    { } // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

/// @title ITier
/// @notice `ITier` is a simple interface that contracts can
/// implement to provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving,
/// conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITier`:
/// - MUST represent held tiers with the `Tier` enum.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the block each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at ONE; ZERO is implied if no tier has ever
///     been held.
///   - `Tier.ZERO` is NOT encoded in the report, it is simply the fallback
///     value.
///   - If a tier is lost the block data is erased for that tier and will be
///     set if/when the tier is regained to the new block.
///   - If the historical block information is not available the report MAY
///     return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
/// - SHOULD implement `setTier`.
///   - Contracts SHOULD revert with `SET_TIER` error if they cannot
///     meaningfully set a tier directly.
///     For example a contract that can only derive a membership tier by
///     reading the state of an external contract cannot set tiers.
///   - Contracts implementing `setTier` SHOULD error with `SET_ZERO_TIER`
///     if `Tier.ZERO` is being set.
/// - MUST emit `TierChange` when `setTier` successfully writes a new tier.
///   - Contracts that cannot meaningfully set a tier are exempt.
interface ITier {
    /// 9 Possible tiers.
    /// Fits nicely as uint32 in uint256 which is helpful for internal storage
    /// concerns.
    /// 8 tiers can be achieved, ZERO is the tier when no tier has been
    /// achieved.
    enum Tier {
        ZERO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE,
        SIX,
        SEVEN,
        EIGHT
    }

    /// Every time a Tier changes we log start and end Tier against the
    /// account.
    /// This MAY NOT be emitted if reports are being read from the state of an
    /// external contract.
    event TierChange(
        address indexed account,
        Tier indexed startTier,
        Tier indexed endTier
    );

    /// @notice Users can set their own tier by calling `setTier`.
    ///
    /// The contract that implements `ITier` is responsible for checking
    /// eligibility and/or taking actions required to set the tier.
    ///
    /// For example, the contract must take/refund any tokens relevant to
    /// changing the tier.
    ///
    /// Obviously the user is responsible for any approvals for this action
    /// prior to calling `setTier`.
    ///
    /// When the tier is changed a `TierChange` event will be emmited as:
    /// ```
    /// event TierChange(address account, Tier startTier, Tier endTier);
    /// ```
    ///
    /// The `setTier` function includes arbitrary data as the third
    /// parameter. This can be used to disambiguate in the case that
    /// there may be many possible options for a user to achieve some tier.
    ///
    /// For example, consider the case where `Tier.THREE` can be achieved
    /// by EITHER locking 1x rare NFT or 3x uncommon NFTs. A user with both
    /// could use `data` to explicitly state their intent.
    ///
    /// NOTE however that _any_ address can call `setTier` for any other
    /// address.
    ///
    /// If you implement `data` or anything that changes state then be very
    /// careful to avoid griefing attacks.
    ///
    /// The `data` parameter can also be ignored by the contract implementing
    /// `ITier`. For example, ERC20 tokens are fungible so only the balance
    /// approved by the user is relevant to a tier change.
    ///
    /// The `setTier` function SHOULD prevent users from reassigning
    /// `Tier.ZERO` to themselves.
    ///
    /// The `Tier.ZERO` status represents never having any status.
    /// @dev Updates the tier of an account.
    ///
    /// The implementing contract is responsible for all checks and state
    /// changes required to set the tier. For example, taking/refunding
    /// funds/NFTs etc.
    ///
    /// Contracts may disallow directly setting tiers, preferring to derive
    /// reports from other onchain data.
    /// In this case they should `revert("SET_TIER");`.
    ///
    /// @param account Account to change the tier for.
    /// @param endTier Tier after the change.
    /// @param data Arbitrary input to disambiguate ownership
    /// (e.g. NFTs to lock).
    function setTier(
        address account,
        Tier endTier,
        bytes memory data
    )
        external;

    /// @notice A tier report is a `uint256` that contains each of the block
    /// numbers each tier has been held continously since as a `uint32`.
    /// There are 9 possible tier, starting with `Tier.ZERO` for `0` offset or
    /// "never held any tier" then working up through 8x 4 byte offsets to the
    /// full 256 bits.
    ///
    /// Low bits = Lower tier.
    ///
    /// In hexadecimal every 8 characters = one tier, starting at `Tier.EIGHT`
    /// from high bits and working down to `Tier.ONE`.
    ///
    /// `uint32` should be plenty for any blockchain that measures block times
    /// in seconds, but reconsider if deploying to an environment with
    /// significantly sub-second block times.
    ///
    /// ~135 years of 1 second blocks fit into `uint32`.
    ///
    /// `2^8 / (365 * 24 * 60 * 60)`
    ///
    /// When a user INCREASES their tier they keep all the block numbers they
    /// already had, and get new block times for each increased tiers they have
    /// earned.
    ///
    /// When a user DECREASES their tier they return to `0xFFFFFFFF` (never)
    /// for every tier level they remove, but keep their block numbers for the
    /// remaining tiers.
    ///
    /// GUIs are encouraged to make this dynamic very clear for users as
    /// round-tripping to a lower status and back is a DESTRUCTIVE operation
    /// for block times.
    ///
    /// The intent is that downstream code can provide additional benefits for
    /// members who have maintained a certain tier for/since a long time.
    /// These benefits can be provided by inspecting the report, and by
    /// on-chain contracts directly,
    /// rather than needing to work with snapshots etc.
    /// @dev Returns the earliest block the account has held each tier for
    /// continuously.
    /// This is encoded as a uint256 with blocks represented as 8x
    /// concatenated uint32.
    /// I.e. Each 4 bytes of the uint256 represents a u32 tier start time.
    /// The low bits represent low tiers and high bits the high tiers.
    /// Implementing contracts should return 0xFFFFFFFF for lost &
    /// never-held tiers.
    ///
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256);
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { TierUtil } from "../libraries/TierUtil.sol";
import { ITier } from "./ITier.sol";

/// @title TierByConstruction
/// @notice `TierByConstruction` is a base contract for other
/// contracts to inherit from.
///
/// It exposes `isTier` and the corresponding modifier `onlyTier`.
///
/// This ensures that the address has held at least the given tier
/// since the contract was constructed.
///
/// We check against the construction time of the contract rather
/// than the current block to avoid various exploits.
///
/// Users should not be able to gain a tier for a single block, claim
/// benefits then remove the tier within the same block.
///
/// The construction block provides a simple and generic reference
/// point that is difficult to manipulate/predict.
///
/// Note that `ReadOnlyTier` contracts must carefully consider use
/// with `TierByConstruction` as they tend to return `0x00000000` for
/// any/all tiers held. There needs to be additional safeguards to
/// mitigate "flash tier" attacks.
///
/// Note that an account COULD be `TierByConstruction` then lower/
/// remove a tier, then no longer be eligible when they regain the
/// tier. Only _continuously held_ tiers are valid against the
/// construction block check as this is native behaviour of the
/// `report` function in `ITier`.
///
/// Technically the `ITier` could re-enter the `TierByConstruction`
/// so the `onlyTier` modifier runs AFTER the modified function.
///
/// @dev Enforces tiers held by contract contruction block.
/// The construction block is compared against the blocks returned by `report`.
/// The `ITier` contract is paramaterised and set during construction.
contract TierByConstruction {
    ITier public tierContract;
    uint256 public constructionBlock;

    constructor(ITier tierContract_) public {
        tierContract = tierContract_;
        constructionBlock = block.number;
    }

    /// Check if an account has held AT LEAST the given tier according to
    /// `tierContract` since construction.
    /// The account MUST have held the tier continuously from construction
    /// until the "current" state according to `report`.
    /// Note that `report` PROBABLY is current as at the block this function is
    /// called but MAYBE NOT.
    /// The `ITier` contract is free to manage reports however makes sense.
    ///
    /// @param account_ Account to check status of.
    /// @param minimumTier_ Minimum tier for the account.
    /// @return True if the status is currently held.
    function isTier(address account_, ITier.Tier minimumTier_)
        public
        view
        returns (bool)
    {
        return constructionBlock >= TierUtil.tierBlock(
            tierContract.report(account_),
            minimumTier_
        );
    }

    /// Modifier that restricts access to functions depending on the tier
    /// required by the function.
    ///
    /// `isTier` involves an external call to tierContract.report.
    /// `require` happens AFTER the modified function to avoid rentrant
    /// `ITier` code.
    /// Also `report` from `ITier` is `view` so the compiler will error on
    /// attempted state modification.
    // solhint-disable-next-line max-line-length
    /// https://consensys.github.io/smart-contract-best-practices/recommendations/#use-modifiers-only-for-checks
    ///
    /// Do NOT use this to guard setting the tier on an `ITier` contract.
    /// The initial tier would be checked AFTER it has already been
    /// modified which is unsafe.
    ///
    /// @param account_ Account to enforce tier of.
    /// @param minimumTier_ Minimum tier for the account.
    modifier onlyTier(address account_, ITier.Tier minimumTier_) {
        _;
        require(
            isTier(account_, minimumTier_),
            "MINIMUM_TIER"
        );
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ITier } from "../tier/ITier.sol";

/// @title TierUtil
/// @notice `TierUtil` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtBlockFromReport`: Returns the highest status achieved relative to
/// a block number and report. Statuses gained after that block are ignored.
/// - `tierBlock`: Returns the block that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateBlocksForTierRange`: Updates a report with a block
/// number for every tier in a range.
/// - `updateReportWithTierAtBlock`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this factors
/// that out.
library TierUtil {

    /// UNINITIALIZED report is 0xFF.. as no tier has been held.
    uint256 constant public UNINITIALIZED = uint256(-1);

    /// Returns the highest tier achieved relative to a block number
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.number` but not always. Tiers gained after the
    /// reference block are ignored.
    ///
    /// When the `report` comes from a later block than the `blockNumber` this
    /// means the user must have held the tier continuously from `blockNumber`
    /// _through_ to the report block.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITier`.
    /// @param blockNumber_ The block number to check the tiers against.
    /// @return The highest tier held since `blockNumber` as per `report`.
    function tierAtBlockFromReport(
        uint256 report_,
        uint256 blockNumber_
    )
        internal pure returns (ITier.Tier)
    {
        for (uint256 i_ = 0; i_ < 8; i_++) {
            if (uint32(uint256(report_ >> (i_*32))) > uint32(blockNumber_)) {
                return ITier.Tier(i_);
            }
        }
        return ITier.Tier(8);
    }

    /// Returns the block that a given tier has been held since from a report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtBlockFromReport`.
    ///
    /// @param report_ The report to read a block number from.
    /// @param tier_ The Tier to read the block number for.
    /// @return The block number this has been held since.
    function tierBlock(uint256 report_, ITier.Tier tier_)
        internal
        pure
        returns (uint256)
    {
        // ZERO is a special case. Everyone has always been at least ZERO,
        // since block 0.
        if (tier_ == ITier.Tier.ZERO) { return 0; }

        uint256 offset_ = (uint256(tier_) - 1) * 32;
        return uint256(uint32(
            uint256(
                report_ >> offset_
            )
        ));
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(uint256 report_, ITier.Tier tier_)
        internal
        pure
        returns (uint256)
    {
        uint256 offset_ = uint256(tier_) * 32;
        uint256 mask_ = (UNINITIALIZED >> offset_) << offset_;
        return report_ | mask_;
    }

    /// Updates a report with a block number for every status integer in a
    /// range.
    ///
    /// Does nothing if the end status is equal or less than the start status.
    /// @param report_ The report to update.
    /// @param startTier_ The `Tier` at the start of the range (exclusive).
    /// @param endTier_ The `Tier` at the end of the range (inclusive).
    /// @param blockNumber_ The block number to set for every status
    /// in the range.
    /// @return The updated report.
    function updateBlocksForTierRange(
        uint256 report_,
        ITier.Tier startTier_,
        ITier.Tier endTier_,
        uint256 blockNumber_
    )
        internal pure returns (uint256)
    {
        uint256 offset_;
        for (uint256 i_ = uint256(startTier_); i_ < uint256(endTier_); i_++) {
            offset_ = i_ * 32;
            report_ =
                (report_ & ~uint256(uint256(uint32(UNINITIALIZED)) << offset_))
                | uint256(blockNumber_ << offset_);
        }
        return report_;
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and
    /// `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the
    /// current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when
    /// calling this function and need to do other things in the calling scope
    /// with it.
    ///
    /// @param report_ The report to update.
    /// @param startTier_ The tier to start updating relative to. Data above
    /// this tier WILL BE LOST so probably should be the current tier.
    /// @param endTier_ The new highest tier held, at the given block number.
    /// @param blockNumber_ The block number to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return The updated report.
    function updateReportWithTierAtBlock(
        uint256 report_,
        ITier.Tier startTier_,
        ITier.Tier endTier_,
        uint256 blockNumber_
    )
        internal pure returns (uint256)
    {
        return endTier_ < startTier_
            ? truncateTiersAbove(report_, endTier_)
            : updateBlocksForTierRange(
                report_,
                startTier_,
                endTier_,
                blockNumber_
            );
    }

}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import { ITier } from "../tier/ITier.sol";

import { Factory } from "../factory/Factory.sol";
import { Trust, TrustConfig } from "../trust/Trust.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20Factory } from "../redeemableERC20/RedeemableERC20Factory.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20, RedeemableERC20Config } from "../redeemableERC20/RedeemableERC20.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20PoolFactory } from "../pool/RedeemableERC20PoolFactory.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20Pool, RedeemableERC20PoolConfig } from "../pool/RedeemableERC20Pool.sol";
import { SeedERC20Factory } from "../seed/SeedERC20Factory.sol";
import { SeedERC20Config } from "../seed/SeedERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// solhint-disable-next-line max-line-length
import { TrustRedeemableERC20Config, TrustRedeemableERC20PoolConfig } from "./Trust.sol";

/// Everything required to construct a `TrustFactory`.
struct TrustFactoryConfig {
    // The RedeemableERC20Factory on the current network.
    // This is an address published by Beehive Trust or deployed locally
    // during testing.
    RedeemableERC20Factory redeemableERC20Factory;
    // The RedeemableERC20PoolFactory on the current network.
    // This is an address published by Beehive Trust or deployed locally
    // during testing.
    RedeemableERC20PoolFactory redeemableERC20PoolFactory;
    // The SeedERC20Factory on the current network.
    // This is an address published by Beehive Trust or deployed locally
    // during testing.
    SeedERC20Factory seedERC20Factory;
}

struct TrustFactoryTrustConfig {
    // Address of the creator who will receive reserve assets on successful
    // distribution.
    address creator;
    // Minimum amount to raise for the creator from the distribution period.
    // A successful distribution raises at least this AND also the seed fee and
    // `redeemInit`;
    // On success the creator receives these funds.
    // On failure the creator receives `0`.
    uint256 minimumCreatorRaise;
    // Either an EOA (externally owned address) or `address(0)`.
    // If an EOA the seeder account must transfer seed funds to the newly
    // constructed `Trust` before distribution can start.
    // If `address(0)` a new `SeedERC20` contract is built in the `Trust`
    // constructor.
    address seeder;
    // The reserve amount that seeders receive in addition to what they
    // contribute IFF the raise is successful.
    // An absolute value, so percentages etc. must be calculated off-chain and
    // passed in to the constructor.
    uint256 seederFee;
    // Total seed units to be mint and sold.
    // 100% of all seed units must be sold for seeding to complete.
    // Recommended to keep seed units to a small value (single-triple digits).
    // The ability for users to buy/sell or not buy/sell dust seed quantities
    // is likely NOT desired.
    uint16 seederUnits;
    // Cooldown duration in blocks for seed/unseed cycles.
    // Seeding requires locking funds for at least the cooldown period.
    // Ideally `unseed` is never called and `seed` leaves funds in the contract
    // until all seed tokens are sold out.
    // A failed raise cannot make funds unrecoverable, so `unseed` does exist,
    // but it should be called rarely.
    uint16 seederCooldownDuration;
    // The amount of reserve to back the redemption initially after trading
    // finishes. Anyone can send more of the reserve to the redemption token at
    // any time to increase redemption value. Successful the redeemInit is sent
    // to token holders, otherwise the failed raise is refunded instead.
    uint256 redeemInit;
}

struct TrustFactoryTrustRedeemableERC20Config {
    // Name forwarded to ERC20 constructor.
    string name;
    // Symbol forwarded to ERC20 constructor.
    string symbol;
    // Tier contract to compare statuses against on transfer.
    ITier tier;
    // Minimum status required for transfers in `Phase.ZERO`. Can be `0`.
    ITier.Tier minimumStatus;
    // Number of redeemable tokens to mint.
    uint256 totalSupply;
}

struct TrustFactoryTrustRedeemableERC20PoolConfig {
    // The reserve erc20 token.
    // The reserve token anchors our newly minted redeemable tokens to an
    // existant value system.
    // The weights and balances of the reserve token and the minted token
    // define a dynamic spot price in the AMM.
    IERC20 reserve;
    // Amount of reserve token to initialize the pool.
    // The starting/final weights are calculated against this.
    uint256 reserveInit;
    // Initial marketcap of the token according to the balancer pool
    // denominated in reserve token.
    // Th spot price of the token is ( market cap / token supply ) where market
    // cap is defined in terms of the reserve.
    // The spot price of a balancer pool token is a function of both the
    // amounts of each token and their weights.
    // This bonding curve is described in the balancer whitepaper.
    // We define a valuation of newly minted tokens in terms of the deposited
    // reserve. The reserve weight is set to the minimum allowable value to
    // achieve maximum capital efficiency for the fund raising.
    uint256 initialValuation;
    // Final valuation is treated the same as initial valuation.
    // The final valuation will ONLY be achieved if NO TRADING OCCURS.
    // Any trading activity that net deposits reserve funds into the pool will
    // increase the spot price permanently.
    uint256 finalValuation;
    // Minimum duration IN BLOCKS of the trading on Balancer.
    // The trading does not stop until the `anonEndDistribution` function is
    // called.
    uint256 minimumTradingDuration;
}

/// @title TrustFactory
/// @notice The `TrustFactory` contract is the only contract that the
/// deployer uses to deploy all contracts for a single project
/// fundraising event. It takes references to
/// `RedeemableERC20Factory`, `RedeemableERC20PoolFactory` and
/// `SeedERC20Factory` contracts, and builds a new `Trust` contract.
/// @dev Factory for creating and registering new Trust contracts.
contract TrustFactory is Factory {
    using SafeMath for uint256;
    using SafeERC20 for RedeemableERC20;

    RedeemableERC20Factory public immutable redeemableERC20Factory;
    RedeemableERC20PoolFactory public immutable redeemableERC20PoolFactory;
    SeedERC20Factory public immutable seedERC20Factory;

    /// @param config_ All configuration for the `TrustFactory`.
    constructor(TrustFactoryConfig memory config_) public {
        redeemableERC20Factory = config_.redeemableERC20Factory;
        redeemableERC20PoolFactory = config_.redeemableERC20PoolFactory;
        seedERC20Factory = config_.seedERC20Factory;
    }

    /// Allows calling `createChild` with TrustConfig,
    /// TrustRedeemableERC20Config and
    /// TrustRedeemableERC20PoolConfig parameters.
    /// Can use original Factory `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param trustFactoryTrustConfig_ Trust constructor configuration.
    /// @param trustFactoryTrustRedeemableERC20Config_ RedeemableERC20
    /// constructor configuration.
    /// @param trustFactoryTrustRedeemableERC20PoolConfig_ RedeemableERC20Pool
    /// constructor configuration.
    /// @return New Trust child contract address.
    function createChild(
        TrustFactoryTrustConfig
        calldata
        trustFactoryTrustConfig_,
        TrustFactoryTrustRedeemableERC20Config
        calldata
        trustFactoryTrustRedeemableERC20Config_,
        TrustFactoryTrustRedeemableERC20PoolConfig
        calldata
        trustFactoryTrustRedeemableERC20PoolConfig_
    ) external returns(address) {
        return this.createChild(abi.encode(
            trustFactoryTrustConfig_,
            trustFactoryTrustRedeemableERC20Config_,
            trustFactoryTrustRedeemableERC20PoolConfig_
        ));
    }

    /// @inheritdoc Factory
    function _createChild(
        bytes calldata data_
    ) internal virtual override returns(address) {
        (
            TrustFactoryTrustConfig
            memory
            trustFactoryTrustConfig_,
            TrustFactoryTrustRedeemableERC20Config
            memory
            trustFactoryTrustRedeemableERC20Config_,
            TrustFactoryTrustRedeemableERC20PoolConfig
            memory
            trustFactoryTrustRedeemableERC20PoolConfig_
        ) = abi.decode(
            data_,
            (
                TrustFactoryTrustConfig,
                TrustFactoryTrustRedeemableERC20Config,
                TrustFactoryTrustRedeemableERC20PoolConfig
            )
        );

        address trust_ = address(new Trust(
            TrustConfig(
                trustFactoryTrustConfig_.creator,
                trustFactoryTrustConfig_.minimumCreatorRaise,
                seedERC20Factory,
                trustFactoryTrustConfig_.seeder,
                trustFactoryTrustConfig_.seederFee,
                trustFactoryTrustConfig_.seederUnits,
                trustFactoryTrustConfig_.seederCooldownDuration,
                trustFactoryTrustConfig_.redeemInit
            ),
            TrustRedeemableERC20Config(
                redeemableERC20Factory,
                trustFactoryTrustRedeemableERC20Config_.name,
                trustFactoryTrustRedeemableERC20Config_.symbol,
                trustFactoryTrustRedeemableERC20Config_.tier,
                trustFactoryTrustRedeemableERC20Config_.minimumStatus,
                trustFactoryTrustRedeemableERC20Config_.totalSupply
            ),
            TrustRedeemableERC20PoolConfig(
                redeemableERC20PoolFactory,
                trustFactoryTrustRedeemableERC20PoolConfig_.reserve,
                trustFactoryTrustRedeemableERC20PoolConfig_.reserveInit,
                trustFactoryTrustRedeemableERC20PoolConfig_.initialValuation,
                trustFactoryTrustRedeemableERC20PoolConfig_.finalValuation,
                trustFactoryTrustRedeemableERC20PoolConfig_
                    .minimumTradingDuration
            )
        ));

        return trust_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { IFactory } from "./IFactory.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Factory
/// @notice Base contract for deploying and registering child contracts.
abstract contract Factory is IFactory, ReentrancyGuard {
    mapping(address => bool) private contracts;

    /// Implements `IFactory`.
    ///
    /// `_createChild` hook must be overridden to actually create child
    /// contract.
    ///
    /// Implementers may want to overload this function with a typed equivalent
    /// to expose domain specific structs etc. to the compiled ABI consumed by
    /// tooling and other scripts. To minimise gas costs for deployment it is
    /// expected that the tooling will consume the typed ABI, then encode the
    /// arguments and pass them to this function directly.
    ///
    /// @param data_ ABI encoded data to pass to child contract constructor.
    // Slither false positive. This is intended to overridden.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _createChild(bytes calldata data_)
        internal
        virtual
        returns(address)
    { } // solhint-disable-line no-empty-blocks

    /// Implements `IFactory`.
    ///
    /// Calls the _createChild hook, which inheriting contracts must override.
    /// Registers child contract address such that `isChild` is `true`.
    /// Emits `NewContract` event.
    ///
    /// @param data_ Encoded data to pass down to child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_)
        external
        virtual
        override
        nonReentrant
        returns(address) {
        // Create child contract using hook.
        address child_ = _createChild(data_);
        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewContract` event with child contract address.
        emit IFactory.NewContract(child_);
        return child_;
    }

    /// Implements `IFactory`.
    ///
    /// Checks if address is registered as a child contract of this factory.
    ///
    /// @param maybeChild_ Address of child contract to look up.
    /// @return Returns `true` if address is a contract created by this
    /// contract factory, otherwise `false`.
    function isChild(address maybeChild_)
        external
        virtual
        override
        returns(bool)
    {
        return contracts[maybeChild_];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol" as ERC20;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { ITier } from "../tier/ITier.sol";

import { Phase } from "../phased/Phased.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20, RedeemableERC20Config } from "../redeemableERC20/RedeemableERC20.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20Pool, RedeemableERC20PoolConfig } from "../pool/RedeemableERC20Pool.sol";
import { SeedERC20, SeedERC20Config } from "../seed/SeedERC20.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20Factory } from "../redeemableERC20/RedeemableERC20Factory.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20PoolFactory, RedeemableERC20PoolFactoryRedeemableERC20PoolConfig } from "../pool/RedeemableERC20PoolFactory.sol";
import { SeedERC20Factory } from "../seed/SeedERC20Factory.sol";

/// Summary of every contract built or referenced internally by `Trust`.
struct TrustContracts {
    // Reserve erc20 token used to provide value to the created Balancer pool.
    address reserveERC20;
    // Redeemable erc20 token that is minted and distributed.
    address redeemableERC20;
    // Contract that builds, starts and exits the balancer pool.
    address redeemableERC20Pool;
    // Address that provides the initial reserve token seed.
    address seeder;
    // Address that defines and controls tier levels for users.
    address tier;
    // The Balancer `ConfigurableRightsPool` deployed for this distribution.
    address crp;
    // The Balancer pool that holds and trades tokens during the distribution.
    address pool;
}

/// High level state of the distribution.
/// An amalgamation of the phases and states of the internal contracts.
enum DistributionStatus {
    // Trust is created but does not have reserve funds required to start the
    // distribution.
    Pending,
    // Trust has enough reserve funds to start the distribution.
    Seeded,
    // The balancer pool is funded and trading.
    Trading,
    // The last block of the balancer pool gradual weight changes is in the
    // past.
    TradingCanEnd,
    // The balancer pool liquidity has been removed and distribution is
    // successful.
    Success,
    // The balancer pool liquidity has been removed and distribution is a
    // failure.
    Fail
}

/// High level stats of the current state of the distribution.
/// Includes the `DistributionStatus` and key configuration and metrics.
struct DistributionProgress {
    // `DistributionStatus` as above.
    DistributionStatus distributionStatus;
    // First block that the distribution can be traded.
    // Will be `-1` before trading.
    uint32 distributionStartBlock;
    // First block that the distribution can be ended.
    // Will be `-1` before trading.
    uint32 distributionEndBlock;
    // Current reserve balance in the Balancer pool.
    // Will be `0` before trading.
    // Will be the exit dust after trading.
    uint256 poolReserveBalance;
    // Current token balance in the Balancer pool.
    // Will be `0` before trading.
    // Will be `0` after distribution due to burn.
    uint256 poolTokenBalance;
    // Initial reserve used to build the Balancer pool.
    uint256 reserveInit;
    // Minimum creator reserve value for the distribution to succeed.
    uint256 minimumCreatorRaise;
    // Seeder fee paid in reserve if the distribution is a success.
    uint256 seederFee;
    // Initial reserve value forwarded to minted redeemable tokens on success.
    uint256 redeemInit;
}

/// Configuration specific to constructing the `Trust`.
/// `Trust` contracts also take inner config for the pool and token.
struct TrustConfig {
    // Address of the creator who will receive reserve assets on successful
    // distribution.
    address creator;
    // Minimum amount to raise for the creator from the distribution period.
    // A successful distribution raises at least this AND also the seed fee and
    // `redeemInit`;
    // On success the creator receives these funds.
    // On failure the creator receives `0`.
    uint256 minimumCreatorRaise;
    // The `SeedERC20Factory` on the current network.
    SeedERC20Factory seedERC20Factory;
    // Either an EOA (externally owned address) or `address(0)`.
    // If an EOA the seeder account must transfer seed funds to the newly
    // constructed `Trust` before distribution can start.
    // If `address(0)` a new `SeedERC20` contract is built in the `Trust`
    // constructor.
    address seeder;
    // The reserve amount that seeders receive in addition to what they
    // contribute IFF the raise is successful.
    // An absolute value, so percentages etc. must be calculated off-chain and
    // passed in to the constructor.
    uint256 seederFee;
    // Total seed units to be mint and sold.
    // 100% of all seed units must be sold for seeding to complete.
    // Recommended to keep seed units to a small value (single-triple digits).
    // The ability for users to buy/sell or not buy/sell dust seed quantities
    // is likely NOT desired.
    uint16 seederUnits;
    // Cooldown duration in blocks for seed/unseed cycles.
    // Seeding requires locking funds for at least the cooldown period.
    // Ideally `unseed` is never called and `seed` leaves funds in the contract
    // until all seed tokens are sold out.
    // A failed raise cannot make funds unrecoverable, so `unseed` does exist,
    // but it should be called rarely.
    uint16 seederCooldownDuration;
    // The amount of reserve to back the redemption initially after trading
    // finishes. Anyone can send more of the reserve to the redemption token at
    // any time to increase redemption value. Successful the redeemInit is sent
    // to token holders, otherwise the failed raise is refunded instead.
    uint256 redeemInit;
}

struct TrustRedeemableERC20Config {
    // The `RedeemableERC20Factory` on the current network.
    RedeemableERC20Factory redeemableERC20Factory;
    // Name forwarded to `ERC20` constructor.
    string name;
    // Symbol forwarded to `ERC20` constructor.
    string symbol;
    // `ITier` contract to compare statuses against on transfer.
    ITier tier;
    // Minimum status required for transfers in `Phase.ZERO`. Can be `0`.
    ITier.Tier minimumStatus;
    // Number of redeemable tokens to mint.
    uint256 totalSupply;
}

struct TrustRedeemableERC20PoolConfig {
    // The `RedeemableERC20PoolFactory` on the current network.
    RedeemableERC20PoolFactory redeemableERC20PoolFactory;
    // The reserve erc20 token.
    // The reserve token anchors our newly minted redeemable tokens to an
    // existant value system.
    // The weights and balances of the reserve token and the minted token
    // define a dynamic spot price in the AMM.
    IERC20 reserve;
    // Amount of reserve token to initialize the pool.
    // The starting/final weights are calculated against this.
    uint256 reserveInit;
    // Initial marketcap of the token according to the balancer pool
    // denominated in reserve token.
    // Th spot price of the token is ( market cap / token supply ) where market
    // cap is defined in terms of the reserve.
    // The spot price of a balancer pool token is a function of both the
    // amounts of each token and their weights.
    // This bonding curve is described in the balancer whitepaper.
    // We define a valuation of newly minted tokens in terms of the deposited
    // reserve. The reserve weight is set to the minimum allowable value to
    // achieve maximum capital efficiency for the fund raising.
    uint256 initialValuation;
    // Final valuation is treated the same as initial valuation.
    // The final valuation will ONLY be achieved if NO TRADING OCCURS.
    // Any trading activity that net deposits reserve funds into the pool will
    // increase the spot price permanently.
    uint256 finalValuation;
    // Minimum duration IN BLOCKS of the trading on Balancer.
    // The trading does not stop until the `anonEndDistribution` function is
    // called.
    uint256 minimumTradingDuration;
}

/// @title Trust
/// @notice Coordinates the mediation and distribution of tokens
/// between stakeholders.
///
/// The `Trust` contract is responsible for configuring the
/// `RedeemableERC20` token, `RedeemableERC20Pool` Balancer wrapper
/// and the `SeedERC20` contract.
///
/// Internally the `TrustFactory` calls several admin/owner only
/// functions on its children and these may impose additional
/// restrictions such as `Phased` limits.
///
/// The `Trust` builds and references `RedeemableERC20`,
/// `RedeemableERC20Pool` and `SeedERC20` contracts internally and
/// manages all access-control functionality.
///
/// The major functions of the `Trust` contract, apart from building
/// and configuring the other contracts, is to start and end the
/// fundraising event, and mediate the distribution of funds to the
/// correct stakeholders:
///
/// - On `Trust` construction, all minted `RedeemableERC20` tokens
///   are sent to the `RedeemableERC20Pool`
/// - `anonStartDistribution` can be called by anyone to begin the
///   Dutch Auction. This will revert if this is called before seeder reserve
///   funds are available on the `Trust`.
/// - `anonEndDistribution` can be called by anyone (only when
///   `RedeemableERC20Pool` is in `Phase.TWO`) to end the Dutch Auction
///   and distribute funds to the correct stakeholders, depending on
///   whether or not the auction met the fundraising target.
///   - On successful raise
///     - seed funds are returned to `seeder` address along with
///       additional `seederFee` if configured
///     - `redeemInit` is sent to the `redeemableERC20` address, to back
///       redemptions
///     - the `creator` gets the remaining balance, which should
///       equal or exceed `minimumCreatorRaise`
///   - On failed raise
///     - seed funds are returned to `seeder` address
///     - the remaining balance is sent to the `redeemableERC20` address, to
///       back redemptions
///     - the `creator` gets nothing
/// @dev Mediates stakeholders and creates internal Balancer pools and tokens
/// for a distribution.
///
/// The goals of a distribution:
/// - Mint and distribute a `RedeemableERC20` as fairly as possible,
///   prioritising true fans of a creator.
/// - Raise a minimum reserve so that a creator can deliver value to fans.
/// - Provide a safe space through membership style filters to enhance
///   exclusivity for fans.
/// - Ensure that anyone who seeds the raise (not fans) by risking and
///   providing capital is compensated.
///
/// Stakeholders:
/// - Creator: Have a project of interest to their fans
/// - Fans: Will purchase project-specific tokens to receive future rewards
///   from the creator
/// - Seeder(s): Provide initial reserve assets to seed a Balancer trading pool
/// - Deployer: Configures and deploys the `Trust` contract
///
/// The creator is nominated to receive reserve assets on a successful
/// distribution. The creator must complete the project and fans receive
/// rewards. There is no on-chain mechanism to hold the creator accountable to
/// the project completion. Requires a high degree of trust between creator and
/// their fans.
///
/// Fans are willing to trust and provide funds to a creator to complete a
/// project. Fans likely expect some kind of reward or "perks" from the
/// creator, such as NFTs, exclusive events, etc.
/// The distributed tokens are untransferable after trading ends and merely act
/// as records for who should receive rewards.
///
/// Seeders add the initial reserve asset to the Balancer pool to start the
/// automated market maker (AMM).
/// Ideally this would not be needed at all.
/// Future versions of `Trust` may include a bespoke distribution mechanism
/// rather than Balancer contracts. Currently it is required by Balancer so the
/// seeder provides some reserve and receives a fee on successful distribution.
/// If the distribution fails the seeder is returned their initial reserve
/// assets. The seeder is expected to promote and mentor the creator in
/// non-financial ways.
///
/// The deployer has no specific priviledge or admin access once the `Trust` is
/// deployed. They provide the configuration, including nominating
/// creator/seeder, and pay gas but that is all.
/// The deployer defines the conditions under which the distribution is
/// successful. The seeder/creator could also act as the deployer.
///
/// Importantly the `Trust` contract is the owner/admin of the contracts it
/// creates. The `Trust` never transfers ownership so it directly controls all
/// internal workflows. No stakeholder, even the deployer or creator, can act
/// as owner of the internals.
contract Trust is ReentrancyGuard {

    using SafeMath for uint256;
    using Math for uint256;

    using SafeERC20 for IERC20;
    using SafeERC20 for RedeemableERC20;

    /// Creator from the initial config.
    address public immutable creator;
    /// minimum creator raise from the initial config.
    uint256 public immutable minimumCreatorRaise;
    /// Seeder from the initial config.
    address public immutable seeder;
    /// Seeder fee from the initial config.
    uint256 public immutable seederFee;
    /// Seeder units from the initial config.
    uint16 public immutable seederUnits;
    /// Seeder cooldown duration from the initial config.
    uint16 public immutable seederCooldownDuration;
    /// Redeem init from the initial config.
    uint256 public immutable redeemInit;
    /// SeedERC20Factory from the initial config.
    SeedERC20Factory public immutable seedERC20Factory;
    /// Balance of the reserve asset in the Balance pool at the moment
    /// `anonEndDistribution` is called. This must be greater than or equal to
    /// `successBalance` for the distribution to succeed.
    /// Will be uninitialized until `anonEndDistribution` is called.
    /// Note the finalBalance includes the dust that is permanently locked in
    /// the Balancer pool after the distribution.
    /// The actual distributed amount will lose roughly 10 ** -7 times this as
    /// locked dust.
    /// The exact dust can be retrieved by inspecting the reserve balance of
    /// the Balancer pool after the distribution.
    uint256 public finalBalance;
    /// Pool reserveInit + seederFee + redeemInit + minimumCreatorRaise.
    /// Could be calculated as a view function but that would require external
    /// calls to the pool contract.
    uint256 public immutable successBalance;

    /// The redeemable token minted in the constructor.
    RedeemableERC20 public immutable token;
    /// The `RedeemableERC20Pool` pool created for trading.
    RedeemableERC20Pool public immutable pool;

    /// Sanity checks configuration.
    /// Creates the `RedeemableERC20` contract and mints the redeemable ERC20
    /// token.
    /// Creates the `RedeemableERC20Pool` contract.
    /// (optional) Creates the `SeedERC20` contract. Pass a non-zero address to
    /// bypass this.
    /// Adds the Balancer pool contracts to the token sender/receiver lists as
    /// needed.
    /// Adds the Balancer pool reserve asset as the first redeemable on the
    /// `RedeemableERC20` contract.
    ///
    /// Note on slither:
    /// Slither detects a benign reentrancy in this constructor.
    /// However reentrancy is not possible in a contract constructor.
    /// Further discussion with the slither team:
    /// https://github.com/crytic/slither/issues/887
    ///
    /// @param config_ Config for the Trust.
    // Slither false positive. Constructors cannot be reentrant.
    // https://github.com/crytic/slither/issues/887
    // slither-disable-next-line reentrancy-benign
    constructor (
        TrustConfig memory config_,
        TrustRedeemableERC20Config memory trustRedeemableERC20Config_,
        TrustRedeemableERC20PoolConfig memory trustRedeemableERC20PoolConfig_
    ) public {
        require(config_.creator != address(0), "CREATOR_0");
        // There are additional minimum reserve init and token supply
        // restrictions enforced by `RedeemableERC20` and
        // `RedeemableERC20Pool`. This ensures that the weightings and
        // valuations will be in a sensible range according to the internal
        // assumptions made by Balancer etc.
        require(
            trustRedeemableERC20Config_.totalSupply
            >= trustRedeemableERC20PoolConfig_.reserveInit,
            "MIN_TOKEN_SUPPLY"
        );

        uint256 successBalance_ = trustRedeemableERC20PoolConfig_.reserveInit
            .add(config_.seederFee)
            .add(config_.redeemInit)
            .add(config_.minimumCreatorRaise);

        creator = config_.creator;
        seederFee = config_.seederFee;
        seederUnits = config_.seederUnits;
        seederCooldownDuration = config_.seederCooldownDuration;
        redeemInit = config_.redeemInit;
        minimumCreatorRaise = config_.minimumCreatorRaise;
        seedERC20Factory = config_.seedERC20Factory;
        successBalance = successBalance_;

        RedeemableERC20 redeemableERC20_ = RedeemableERC20(
            trustRedeemableERC20Config_.redeemableERC20Factory
                .createChild(abi.encode(
                    RedeemableERC20Config(
                        address(this),
                        trustRedeemableERC20Config_.name,
                        trustRedeemableERC20Config_.symbol,
                        trustRedeemableERC20Config_.tier,
                        trustRedeemableERC20Config_.minimumStatus,
                        trustRedeemableERC20Config_.totalSupply
        ))));

        RedeemableERC20Pool redeemableERC20Pool_ = RedeemableERC20Pool(
            trustRedeemableERC20PoolConfig_.redeemableERC20PoolFactory
                .createChild(abi.encode(
                    RedeemableERC20PoolFactoryRedeemableERC20PoolConfig(
                        trustRedeemableERC20PoolConfig_.reserve,
                        redeemableERC20_,
                        trustRedeemableERC20PoolConfig_.reserveInit,
                        trustRedeemableERC20PoolConfig_.initialValuation,
                        trustRedeemableERC20PoolConfig_.finalValuation,
                        trustRedeemableERC20PoolConfig_.minimumTradingDuration
        ))));

        token = redeemableERC20_;
        pool = redeemableERC20Pool_;

        require(
            redeemableERC20Pool_.finalValuation() >= successBalance_,
            "MIN_FINAL_VALUATION"
        );

        if (config_.seeder == address(0)) {
            require(
                trustRedeemableERC20PoolConfig_
                    .reserveInit
                    .mod(
                        config_.seederUnits) == 0,
                        "SEED_PRICE_MULTIPLIER"
                    );
            config_.seeder = address(config_.seedERC20Factory
                .createChild(abi.encode(SeedERC20Config(
                    trustRedeemableERC20PoolConfig_.reserve,
                    address(redeemableERC20Pool_),
                    // seed price.
                    redeemableERC20Pool_
                        .reserveInit()
                        .div(config_.seederUnits),
                    config_.seederUnits,
                    config_.seederCooldownDuration,
                    "",
                    ""
                )))
            );
        }
        seeder = config_.seeder;

        // Need to grant transfers for a few balancer addresses to facilitate
        // setup and exits.
        redeemableERC20_.grantRole(
            redeemableERC20_.RECEIVER(),
            redeemableERC20Pool_.crp().bFactory()
        );
        redeemableERC20_.grantRole(
            redeemableERC20_.RECEIVER(),
            address(redeemableERC20Pool_.crp())
        );
        redeemableERC20_.grantRole(
            redeemableERC20_.RECEIVER(),
            address(redeemableERC20Pool_)
        );
        redeemableERC20_.grantRole(
            redeemableERC20_.SENDER(),
            address(redeemableERC20Pool_.crp())
        );

        // The trust needs the ability to burn the distributor.
        redeemableERC20_.grantRole(
            redeemableERC20_.DISTRIBUTOR_BURNER(),
            address(this)
        );

        // The pool reserve must always be one of the treasury assets.
        redeemableERC20_.newTreasuryAsset(
            address(trustRedeemableERC20PoolConfig_.reserve)
        );

        // There is no longer any reason for the redeemableERC20 to have an
        // admin.
        redeemableERC20_.renounceRole(
            redeemableERC20_.DEFAULT_ADMIN_ROLE(),
            address(this)
        );

        // Send all tokens to the pool immediately.
        // When the seed funds are raised `anonStartDistribution` on the
        // `Trust` will build a pool from these.
        redeemableERC20_.safeTransfer(
            address(redeemableERC20Pool_),
            trustRedeemableERC20Config_.totalSupply
        );
    }

    /// Accessor for the `TrustContracts` of this `Trust`.
    function getContracts() external view returns(TrustContracts memory) {
        return TrustContracts(
            address(pool.reserve()),
            address(token),
            address(pool),
            address(seeder),
            address(token.tierContract()),
            address(pool.crp()),
            address(pool.crp().bPool())
        );
    }

    /// Accessor for the `TrustConfig` of this `Trust`.
    function getTrustConfig() external view returns(TrustConfig memory) {
        return TrustConfig(
            address(creator),
            minimumCreatorRaise,
            seedERC20Factory,
            address(seeder),
            seederFee,
            seederUnits,
            seederCooldownDuration,
            redeemInit
        );
    }

    /// Accessor for the `DistributionProgress` of this `Trust`.
    function getDistributionProgress()
        external
        view
        returns(DistributionProgress memory)
    {
        address balancerPool_ = address(pool.crp().bPool());
        uint256 poolReserveBalance_;
        uint256 poolTokenBalance_;
        if (balancerPool_ != address(0)) {
            poolReserveBalance_ = pool.reserve().balanceOf(balancerPool_);
            poolTokenBalance_ = token.balanceOf(balancerPool_);
        }
        else {
            poolReserveBalance_ = 0;
            poolTokenBalance_ = 0;
        }

        return DistributionProgress(
            getDistributionStatus(),
            pool.phaseBlocks(0),
            pool.phaseBlocks(1),
            poolReserveBalance_,
            poolTokenBalance_,
            pool.reserveInit(),
            minimumCreatorRaise,
            seederFee,
            redeemInit
        );
    }

    /// Accessor for the `DistributionStatus` of this `Trust`.
    function getDistributionStatus() public view returns (DistributionStatus) {
        Phase poolPhase_ = pool.currentPhase();
        if (poolPhase_ == Phase.ZERO) {
            if (
                pool.reserve().balanceOf(address(pool)) >= pool.reserveInit()
            ) {
                return DistributionStatus.Seeded;
            } else {
                return DistributionStatus.Pending;
            }
        }
        else if (poolPhase_ == Phase.ONE) {
            return DistributionStatus.Trading;
        }
        else if (poolPhase_ == Phase.TWO) {
            return DistributionStatus.TradingCanEnd;
        }
        else if (poolPhase_ == Phase.THREE) {
            if (finalBalance >= successBalance) {
                return DistributionStatus.Success;
            }
            else {
                return DistributionStatus.Fail;
            }
        }
    }

    /// Anyone can end the distribution.
    /// The requirement is that the `minimumTradingDuration` has elapsed.
    /// If the `successBalance` is reached then the creator receives the raise
    /// and seeder earns a fee.
    /// Else the initial reserve is refunded to the seeder and sale proceeds
    /// rolled forward to token holders (not the creator).
    function anonEndDistribution() external nonReentrant {
        finalBalance = pool.reserve().balanceOf(address(pool.crp().bPool()));

        pool.ownerEndDutchAuction();
        // Burning the distributor moves the token to its `Phase.ONE` and
        // unlocks redemptions.
        // The distributor is the `bPool` itself.
        // Requires that the `Trust` has been granted `ONLY_DISTRIBUTOR_BURNER`
        // role on the `redeemableERC20`.
        token.burnDistributor(
            address(pool.crp().bPool())
        );

        // Balancer traps a tiny amount of reserve in the pool when it exits.
        uint256 poolDust_ = pool.reserve()
            .balanceOf(address(pool.crp().bPool()));
        // The dust is included in the final balance for UX reasons.
        // We don't want to fail the raise due to dust, even if technically it
        // was a failure.
        // To ensure a good UX for creators and token holders we subtract the
        // dust from the seeder.
        uint256 availableBalance_ = pool.reserve().balanceOf(address(this));

        // Base payments for each fundraiser.
        uint256 seederPay_ = pool.reserveInit().sub(poolDust_);
        uint256 creatorPay_ = 0;

        // Set aside the redemption and seed fee if we reached the minimum.
        if (finalBalance >= successBalance) {
            // The seeder gets an additional fee on success.
            seederPay_ = seederPay_.add(seederFee);

            // The creators get new funds raised minus redeem and seed fees.
            // Can subtract without underflow due to the inequality check for
            // this code block.
            // Proof (assuming all positive integers):
            // final balance >= success balance
            // AND seed pay = seed init + seed fee
            // AND success = seed init + seed fee + token pay + min raise
            // SO success = seed pay + token pay + min raise
            // SO success >= seed pay + token pay
            // SO success - (seed pay + token pay) >= 0
            // SO final balance - (seed pay + token pay) >= 0
            //
            // Implied is the remainder of finalBalance_ as redeemInit
            // This will be transferred to the token holders below.
            creatorPay_ = availableBalance_.sub(seederPay_.add(redeemInit));
        }

        if (creatorPay_ > 0) {
            pool.reserve().safeTransfer(
                creator,
                creatorPay_
            );
        }

        pool.reserve().safeTransfer(
            seeder,
            seederPay_
        );

        // Send everything left to the token holders.
        // Implicitly the remainder of the finalBalance_ is:
        // - the redeem init if successful
        // - whatever users deposited in the AMM if unsuccessful
        uint256 remainder_ = pool.reserve().balanceOf(address(this));
        if (remainder_ > 0) {
            pool.reserve().safeTransfer(
                address(token),
                remainder_
            );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { Factory } from "../factory/Factory.sol";
import { RedeemableERC20, RedeemableERC20Config } from "./RedeemableERC20.sol";
import { ITier } from "../tier/ITier.sol";

/// @title RedeemableERC20Factory
/// @notice Factory for deploying and registering `RedeemableERC20` contracts.
contract RedeemableERC20Factory is Factory {

    /// @inheritdoc Factory
    function _createChild(
        bytes calldata data_
    ) internal virtual override returns(address) {
        (RedeemableERC20Config memory config_) = abi.decode(
            data_,
            (RedeemableERC20Config)
        );
        RedeemableERC20 redeemableERC20_ = new RedeemableERC20(config_);
        return address(redeemableERC20_);
    }

    /// Allows calling `createChild` with `RedeemableERC20Config` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `RedeemableERC20` constructor configuration.
    /// @return New `RedeemableERC20` child contract address.
    function createChild(RedeemableERC20Config calldata config_)
        external
        returns(address)
    {
        return this.createChild(abi.encode(config_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
// solhint-disable-next-line max-line-length
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// solhint-disable-next-line max-line-length
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import { TierByConstruction } from "../tier/TierByConstruction.sol";
import { ITier } from "../tier/ITier.sol";

import { Phase, Phased } from "../phased/Phased.sol";

/// Everything required by the `RedeemableERC20` constructor.
struct RedeemableERC20Config {
    // Account that will be the admin for the `RedeemableERC20` contract.
    // Useful for factory contracts etc.
    address admin;
    // Name forwarded to ERC20 constructor.
    string name;
    // Symbol forwarded to ERC20 constructor.
    string symbol;
    // Tier contract to compare statuses against on transfer.
    ITier tier;
    // Minimum status required for transfers in `Phase.ZERO`. Can be `0`.
    ITier.Tier minimumStatus;
    // Number of redeemable tokens to mint.
    uint256 totalSupply;
}

/// @title RedeemableERC20
/// @notice This is the ERC20 token that is minted and distributed.
///
/// During `Phase.ZERO` the token can be traded and so compatible with the
/// Balancer pool mechanics.
///
/// During `Phase.ONE` the token is frozen and no longer able to be traded on
/// any AMM or transferred directly.
///
/// The token can be redeemed during `Phase.ONE` which burns the token in
/// exchange for pro-rata erc20 tokens held by the `RedeemableERC20` contract
/// itself.
///
/// The token balances can be used indirectly for other claims, promotions and
/// events as a proof of participation in the original distribution by token
/// holders.
///
/// The token can optionally be restricted by the `Tier` contract to only allow
/// receipients with a specified membership status.
///
/// @dev `RedeemableERC20` is an ERC20 with 2 phases.
///
/// `Phase.ZERO` is the distribution phase where the token can be freely
/// transfered but not redeemed.
/// `Phase.ONE` is the redemption phase where the token can be redeemed but no
/// longer transferred.
///
/// Redeeming some amount of `RedeemableERC20` burns the token in exchange for
/// some other tokens held by the contract. For example, if the
/// `RedeemableERC20` token contract holds 100 000 USDC then a holder of the
/// redeemable token can burn some of their tokens to receive a % of that USDC.
/// If they redeemed (burned) an amount equal to 10% of the redeemable token
/// supply then they would receive 10 000 USDC.
///
/// To make the treasury assets discoverable anyone can call `newTreasuryAsset`
/// to emit an event containing the treasury asset address. As malicious and/or
/// spam users can emit many treasury events there is a need for sensible
/// indexing and filtering of asset events to only trusted users. This contract
/// is agnostic to how that trust relationship is defined for each user.
///
/// Users must specify all the treasury assets they wish to redeem to the
/// `redeem` function. After `redeem` is called the redeemed tokens are burned
/// so all treasury assets must be specified and claimed in a batch atomically.
/// Note: The same amount of `RedeemableERC20` is burned, regardless of which
/// treasury assets were specified. Specifying fewer assets will NOT increase
/// the proportion of each that is returned.
///
/// `RedeemableERC20` has several owner administrative functions:
/// - Owner can add senders and receivers that can send/receive tokens even
///   during `Phase.ONE`
/// - Owner can end `Phase.ONE` during `Phase.ZERO` by specifying the address
///   of a distributor, which will have any undistributed tokens burned.
///
/// The redeem functions MUST be used to redeem and burn RedeemableERC20s
/// (NOT regular transfers).
///
/// `redeem` will simply revert if called outside `Phase.ONE`.
/// A `Redeem` event is emitted on every redemption (per treasury asset) as
/// `(redeemer, asset, redeemAmount)`.
contract RedeemableERC20 is
    AccessControl,
    Phased,
    TierByConstruction,
    ERC20,
    ReentrancyGuard,
    ERC20Burnable
    {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant SENDER = keccak256("SENDER");
    bytes32 public constant RECEIVER = keccak256("RECEIVER");
    bytes32 public constant DISTRIBUTOR_BURNER =
        keccak256("DISTRIBUTOR_BURNER");

    /// Redeemable token added by creator.
    event TreasuryAsset(address indexed emitter, address indexed asset);

    /// Redeemable token burn for reserve.
    event Redeem(
        // Account burning and receiving.
        address indexed redeemer,
        // The treasury asset being sent to the burner.
        address indexed treasuryAsset,
        // The amounts of the redeemable and treasury asset as
        // `[redeemAmount, assetAmount]`
        uint256[2] redeemAmounts
    );

    /// RedeemableERC20 uses the standard/default 18 ERC20 decimals.
    /// The minimum supply enforced by the constructor is "one" token which is
    /// `10 ** 18`.
    /// The minimum supply does not prevent subsequent redemption/burning.
    uint256 public constant MINIMUM_INITIAL_SUPPLY = 10 ** 18;

    /// The minimum status that a user must hold to receive transfers during
    /// `Phase.ZERO`.
    /// The tier contract passed to `TierByConstruction` determines if
    /// the status is held during `_beforeTokenTransfer`.
    /// Not immutable because it is read during the constructor by the `_mint`
    /// call.
    ITier.Tier public minimumTier;

    /// Mint the full ERC20 token supply and configure basic transfer
    /// restrictions.
    /// @param config_ Constructor configuration.
    constructor (
        RedeemableERC20Config memory config_
    )
        public
        ERC20(config_.name, config_.symbol)
        TierByConstruction(config_.tier)
    {
        require(
            config_.totalSupply >= MINIMUM_INITIAL_SUPPLY,
            "MINIMUM_INITIAL_SUPPLY"
        );
        minimumTier = config_.minimumStatus;

        _setupRole(DEFAULT_ADMIN_ROLE, config_.admin);
        _setupRole(RECEIVER, config_.admin);
        // Minting and burning must never fail.
        _setupRole(SENDER, address(0));
        _setupRole(RECEIVER, address(0));

        _mint(config_.admin, config_.totalSupply);
    }

    /// The admin can burn all tokens of a single address to end `Phase.ZERO`.
    /// The intent is that during `Phase.ZERO` there is some contract
    /// responsible for distributing the tokens.
    /// The admin specifies the distributor to end `Phase.ZERO` and all
    /// undistributed tokens are burned.
    /// The distributor is NOT set during the constructor because it likely
    /// doesn't exist at that point. For example, Balancer needs the paired
    /// erc20 tokens to exist before the trading pool can be built.
    /// @param distributorAccount_ The distributor according to the admin.
    function burnDistributor(address distributorAccount_)
        external
        onlyPhase(Phase.ZERO)
    {
        require(
            hasRole(DISTRIBUTOR_BURNER, msg.sender),
            "ONLY_DISTRIBUTOR_BURNER"
        );
        scheduleNextPhase(uint32(block.number));
        _burn(distributorAccount_, balanceOf(distributorAccount_));
    }

    /// Anyone can emit a `TreasuryAsset` event to notify token holders that
    /// an asset could be redeemed by burning `RedeemableERC20` tokens.
    /// As this is callable by anon the events should be filtered by the
    /// indexer to those from trusted entities only.
    function newTreasuryAsset(address newTreasuryAsset_) external {
        emit TreasuryAsset(msg.sender, newTreasuryAsset_);
    }

    /// Redeem (burn) tokens for treasury assets.
    /// Tokens can be redeemed but NOT transferred during `Phase.ONE`.
    ///
    /// Calculate the redeem value of tokens as:
    ///
    /// ```
    /// ( redeemAmount / redeemableErc20Token.totalSupply() )
    /// * token.balanceOf(address(this))
    /// ```
    ///
    /// This means that the users get their redeemed pro-rata share of the
    /// outstanding token supply burned in return for a pro-rata share of the
    /// current balance of each treasury asset.
    ///
    /// I.e. whatever % of redeemable tokens the sender burns is the % of the
    /// current treasury assets they receive.
    function redeem(
        IERC20[] memory treasuryAssets_,
        uint256 redeemAmount_
    )
        public
        onlyPhase(Phase.ONE)
        nonReentrant
    {
        // The fraction of the assets we release is the fraction of the
        // outstanding total supply of the redeemable burned.
        // Every treasury asset is released in the same proportion.
        uint256 supplyBeforeBurn_ = totalSupply();

        // Redeem __burns__ tokens which reduces the total supply and requires
        // no approval.
        // `_burn` reverts internally if needed (e.g. if burn exceeds balance).
        // This function is `nonReentrant` but we burn before redeeming anyway.
        _burn(msg.sender, redeemAmount_);

        for(uint256 i_ = 0; i_ < treasuryAssets_.length; i_++) {
            IERC20 ithRedeemable_ = treasuryAssets_[i_];
            uint256 assetAmount_ = ithRedeemable_
                .balanceOf(address(this))
                .mul(redeemAmount_)
                .div(supplyBeforeBurn_);
            emit Redeem(
                msg.sender,
                address(ithRedeemable_),
                [redeemAmount_, assetAmount_]
            );
            ithRedeemable_.safeTransfer(
                msg.sender,
                assetAmount_
            );
        }
    }

    /// Sanity check to ensure `Phase.ONE` is the final phase.
    /// @inheritdoc Phased
    // Slither false positive. This is overriding an Open Zeppelin hook.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _beforeScheduleNextPhase(uint32 nextPhaseBlock_)
        internal
        override
        virtual
    {
        super._beforeScheduleNextPhase(nextPhaseBlock_);
        assert(currentPhase() < Phase.TWO);
    }

    /// Apply phase sensitive transfer restrictions.
    /// During `Phase.ZERO` only tier requirements apply.
    /// During `Phase.ONE` all transfers except burns are prevented.
    /// If a transfer involves either a sender or receiver with the relevant
    /// `unfreezables` state it will ignore these restrictions.
    /// @inheritdoc ERC20
    // Slither false positive. This is overriding an Open Zeppelin hook.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _beforeTokenTransfer(
        address sender_,
        address receiver_,
        uint256 amount_
    )
        internal
        override
        virtual
    {
        super._beforeTokenTransfer(sender_, receiver_, amount_);

        // Sending tokens to this contract (e.g. instead of redeeming) is
        // always an error.
        require(receiver_ != address(this), "TOKEN_SEND_SELF");

        // Some contracts may attempt a preflight (e.g. Balancer) of a 0 amount
        // transfer.
        // We don't want to accidentally cause external errors due to zero
        // value transfers.
        if (amount_ > 0
            // The sender and receiver lists bypass all access restrictions.
            && !(hasRole(SENDER, sender_) || hasRole(RECEIVER, receiver_))) {
            // During `Phase.ZERO` transfers are only restricted by the
            // tier of the recipient.
            if (currentPhase() == Phase.ZERO) {
                require(
                    isTier(receiver_, minimumTier),
                    "MIN_TIER"
                );
            }
            // During `Phase.ONE` only token burns are allowed.
            else if (currentPhase() == Phase.ONE) {
                require(receiver_ == address(0), "FROZEN");
            }
            // There are no other phases.
            else { assert(false); }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { Factory } from "../factory/Factory.sol";
// solhint-disable-next-line max-line-length
import { RedeemableERC20Pool, RedeemableERC20PoolConfig } from "./RedeemableERC20Pool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { RedeemableERC20 } from "../redeemableERC20/RedeemableERC20.sol";

/// Everything required to construct a `RedeemableERC20PoolFactory`.
struct RedeemableERC20PoolFactoryConfig {
    // The `CRPFactory` on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address crpFactory;
    // The `BFactory` on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address balancerFactory;
}

/// Everything else required to construct new `RedeemableERC20Pool` child
/// contracts.
struct RedeemableERC20PoolFactoryRedeemableERC20PoolConfig {
    // The reserve erc20 token.
    // The reserve token anchors our newly minted redeemable tokens to an
    // existant value system.
    // The weights and balances of the reserve token and the minted token
    // define a dynamic spot price in the AMM.
    IERC20 reserve;
    // The newly minted redeemable token contract.
    // 100% of the total supply of the token MUST be transferred to the
    // `RedeemableERC20Pool` for it to function.
    // This implies a 1:1 relationship between redeemable pools and tokens.
    // IMPORTANT: It is up to the caller to define a reserve that will remain
    // functional and outlive the RedeemableERC20.
    // For example, USDC could freeze the tokens owned by the RedeemableERC20
    // contract or close their business.
    RedeemableERC20 token;
    // Amount of reserve token to initialize the pool.
    // The starting/final weights are calculated against this.
    uint256 reserveInit;
    // Initial marketcap of the token according to the balancer pool
    // denominated in reserve token.
    // Th spot price of the token is ( market cap / token supply ) where market
    // cap is defined in terms of the reserve.
    // The spot price of a balancer pool token is a function of both the
    // amounts of each token and their weights.
    // This bonding curve is described in the balancer whitepaper.
    // We define a valuation of newly minted tokens in terms of the deposited
    // reserve. The reserve weight is set to the minimum allowable value to
    // achieve maximum capital efficiency for the fund raising.
    uint256 initialValuation;
    // Final valuation is treated the same as initial valuation.
    // The final valuation will ONLY be achieved if NO TRADING OCCURS.
    // Any trading activity that net deposits reserve funds into the pool will
    // increase the spot price permanently.
    uint256 finalValuation;
    // Minimum duration IN BLOCKS of the trading on Balancer.
    // The trading does not stop until the `anonEndDistribution` function is
    // called.
    uint256 minimumTradingDuration;
}

/// @title RedeemableERC20PoolFactory
/// @notice Factory for creating and registering new `RedeemableERC20Pool`
/// contracts.
contract RedeemableERC20PoolFactory is Factory {
    /// ConfigurableRightsPool factory.
    address public immutable crpFactory;
    /// Balancer factory.
    address public immutable balancerFactory;

    /// @param config_ All configuration for the `RedeemableERC20PoolFactory`.
    constructor(RedeemableERC20PoolFactoryConfig memory config_) public {
        crpFactory = config_.crpFactory;
        balancerFactory = config_.balancerFactory;
    }

    /// @inheritdoc Factory
    function _createChild(
        bytes calldata data_
    ) internal virtual override returns(address) {
        (
            RedeemableERC20PoolFactoryRedeemableERC20PoolConfig
            memory
            config_
        ) = abi.decode(
            data_,
            (RedeemableERC20PoolFactoryRedeemableERC20PoolConfig)
        );
        RedeemableERC20Pool pool_ = new RedeemableERC20Pool(
            RedeemableERC20PoolConfig(
                crpFactory,
                balancerFactory,
                config_.reserve,
                config_.token,
                config_.reserveInit,
                config_.initialValuation,
                config_.finalValuation,
                config_.minimumTradingDuration
            )
        );
        /// Transfer Balancer pool ownership to sender (e.g. `Trust`).
        pool_.transferOwnership(msg.sender);
        return address(pool_);
    }

    /// Allows calling `createChild` with
    /// `RedeemableERC20PoolFactoryRedeemableERC20PoolConfig` struct.
    /// Can use original Factory `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `RedeemableERC20Pool` constructor configuration.
    /// @return New `RedeemableERC20Pool` child contract address.
    function createChild(
        RedeemableERC20PoolFactoryRedeemableERC20PoolConfig
        calldata
        config_
    )
        external
        returns(address)
    {
        return this.createChild(abi.encode(config_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { Rights } from "./IRightsManager.sol";
import { ICRPFactory } from "./ICRPFactory.sol";
// solhint-disable-next-line max-line-length
import { PoolParams, IConfigurableRightsPool } from "./IConfigurableRightsPool.sol";

import { IBalancerConstants } from "./IBalancerConstants.sol";

import { Phase, Phased } from "../phased/Phased.sol";
import { RedeemableERC20 } from "../redeemableERC20/RedeemableERC20.sol";

/// Everything required to construct a `RedeemableERC20Pool`.
struct RedeemableERC20PoolConfig {
    // The CRPFactory on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address crpFactory;
    // The BFactory on the current network.
    // This is an address published by Balancer or deployed locally during
    // testing.
    address balancerFactory;
    // The reserve erc20 token.
    // The reserve token anchors our newly minted redeemable tokens to an
    // existant value system.
    // The weights and balances of the reserve token and the minted token
    // define a dynamic spot price in the AMM.
    IERC20 reserve;
    // The newly minted redeemable token contract.
    // 100% of the total supply of the token MUST be transferred to the
    // `RedeemableERC20Pool` for it to function.
    // This implies a 1:1 relationship between redeemable pools and tokens.
    // IMPORTANT: It is up to the caller to define a reserve that will remain
    // functional and outlive the RedeemableERC20.
    // For example, USDC could freeze the tokens owned by the RedeemableERC20
    // contract or close their business.
    RedeemableERC20 token;
    // Amount of reserve token to initialize the pool.
    // The starting/final weights are calculated against this.
    uint256 reserveInit;
    // Initial marketcap of the token according to the balancer pool
    // denominated in reserve token.
    // The spot price of the token is ( market cap / token supply ) where
    // market cap is defined in terms of the reserve.
    // The spot price of a balancer pool token is a function of both the
    // amounts of each token and their weights.
    // This bonding curve is described in the Balancer whitepaper.
    // We define a valuation of newly minted tokens in terms of the deposited
    // reserve. The reserve weight is set to the minimum allowable value to
    // achieve maximum capital efficiency for the fund raising.
    uint256 initialValuation;
    // Final valuation is treated the same as initial valuation.
    // The final valuation will ONLY be achieved if NO TRADING OCCURS.
    // Any trading activity that net deposits reserve funds into the pool will
    // increase the spot price permanently.
    uint256 finalValuation;
    // Minimum duration IN BLOCKS of the trading on Balancer.
    // The trading does not stop until the `anonEndDistribution` function is
    // called on the owning `Trust`.
    uint256 minimumTradingDuration;
}

/// @title RedeemableERC20Pool
/// @notice The Balancer functionality is wrapped by the
/// `RedeemableERC20Pool` contract.
///
/// Balancer pools require significant configuration so this contract helps
/// decouple the implementation from the `Trust`.
///
/// It also ensures the pool tokens created during the initialization of the
/// Balancer LBP are owned by the `RedeemableERC20Pool` and never touch either
/// the `Trust` nor an externally owned account (EOA).
///
/// `RedeemableERC20Pool` has several phases:
///
/// - `Phase.ZERO`: Deployed not trading but can be by owner calling
/// `ownerStartDutchAuction`
/// - `Phase.ONE`: Trading open
/// - `Phase.TWO`: Trading open but can be closed by owner calling
/// `ownerEndDutchAuction`
/// - `Phase.THREE`: Trading closed
///
/// @dev Deployer and controller for a Balancer ConfigurableRightsPool.
/// This contract is intended in turn to be owned by a `Trust`.
///
/// Responsibilities of `RedeemableERC20Pool`:
/// - Configure and deploy Balancer contracts with correct weights, rights and
///   balances
/// - Allowing the owner to start and end a dutch auction raise modelled as
///   Balancer's "gradual weights" functionality
/// - Tracking and enforcing 3 phases: unstarted, started, ended
/// - Burning unsold tokens after the raise and forwarding all raised and
///   initial reserve back to the owner
///
/// Responsibilities of the owner:
/// - Providing all token and reserve balances
/// - Calling start and end raise functions
/// - Handling the reserve proceeds of the raise
contract RedeemableERC20Pool is Ownable, Phased {
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for RedeemableERC20;

    /// Balancer requires a minimum balance of `10 ** 6` for all tokens at all
    /// times.
    uint256 public constant MIN_BALANCER_POOL_BALANCE = 10 ** 6;
    /// To ensure that the dust at the end of the raise is dust-like, we
    /// enforce a minimum starting reserve balance 100x the minimum.
    uint256 public constant MIN_RESERVE_INIT = 10 ** 8;

    /// RedeemableERC20 token.
    RedeemableERC20 public immutable token;

    /// Minimum trading duration from the initial config.
    uint256 public immutable minimumTradingDuration;

    /// Reserve token.
    IERC20 public immutable reserve;
    /// Initial reserve balance of the pool.
    uint256 public immutable reserveInit;

    /// The `ConfigurableRightsPool` built during construction.
    IConfigurableRightsPool public immutable crp;

    /// The final weight on the last block of the raise.
    /// Note the spot price is unknown until the end because we don't know
    /// either of the final token balances.
    uint256 public immutable finalWeight;
    uint256 public immutable finalValuation;

    /// @param config_ All configuration for the `RedeemableERC20Pool`.
    // Slither false positive. Constructors cannot be reentrant.
    // https://github.com/crytic/slither/issues/887
    // slither-disable-next-line reentrancy-benign
    constructor (RedeemableERC20PoolConfig memory config_) public {
        require(
            config_.reserveInit >= MIN_RESERVE_INIT,
            "RESERVE_INIT_MINIMUM"
        );
        require(
            config_.initialValuation >= config_.finalValuation,
            "MIN_INITIAL_VALUTION"
        );

        token = config_.token;
        reserve = config_.reserve;
        reserveInit = config_.reserveInit;

        finalWeight = valuationWeight(
            config_.reserveInit,
            config_.finalValuation
        );
        finalValuation = config_.finalValuation;

        require(config_.minimumTradingDuration > 0, "0_TRADING_DURATION");
        minimumTradingDuration = config_.minimumTradingDuration;

        // Build the CRP.
        // The addresses in the `RedeemableERC20Pool`, as `[reserve, token]`.
        address[] memory poolAddresses_ = new address[](2);
        poolAddresses_[0] = address(config_.reserve);
        poolAddresses_[1] = address(config_.token);

        uint256[] memory poolAmounts_ = new uint256[](2);
        poolAmounts_[0] = config_.reserveInit;
        poolAmounts_[1] = config_.token.totalSupply();
        require(poolAmounts_[1] > 0, "TOKEN_INIT_0");

        uint256[] memory initialWeights_ = new uint256[](2);
        initialWeights_[0] = IBalancerConstants.MIN_WEIGHT;
        initialWeights_[1] = valuationWeight(
            config_.reserveInit,
            config_.initialValuation
        );

        address crp_ = ICRPFactory(config_.crpFactory).newCrp(
            config_.balancerFactory,
            PoolParams(
                "R20P",
                "RedeemableERC20Pool",
                poolAddresses_,
                poolAmounts_,
                initialWeights_,
                IBalancerConstants.MIN_FEE
            ),
            Rights(
                // 0. Pause
                false,
                // 1. Change fee
                false,
                // 2. Change weights
                // (`true` needed to set gradual weight schedule)
                true,
                // 3. Add/remove tokens
                false,
                // 4. Whitelist LPs (default behaviour for `true` is that
                //    nobody can `joinPool`)
                true,
                // 5. Change cap
                false
            )
        );
        crp = IConfigurableRightsPool(crp_);

        // Preapprove all tokens and reserve for the CRP.
        require(
            config_.reserve.approve(address(crp_), config_.reserveInit),
            "RESERVE_APPROVE"
        );
        require(
            config_.token.approve(address(crp_),
            config_.token.totalSupply()),
            "TOKEN_APPROVE"
        );
    }

    /// https://balancer.finance/whitepaper/
    /// Spot = ( Br / Wr ) / ( Bt / Wt )
    /// => ( Bt / Wt ) = ( Br / Wr ) / Spot
    /// => Wt = ( Spot x Bt ) / ( Br / Wr )
    ///
    /// Valuation = Spot * Token supply
    /// Valuation / Supply = Spot
    /// => Wt = ( ( Val / Supply ) x Bt ) / ( Br / Wr )
    ///
    /// Bt = Total supply
    /// => Wt = ( ( Val / Bt ) x Bt ) / ( Br / Wr )
    /// => Wt = Val / ( Br / Wr )
    ///
    /// Wr = Min weight = 1
    /// => Wt = Val / Br
    ///
    /// Br = reserve init (assumes zero trading)
    /// => Wt = Val / reserve init
    /// @param valuation_ Valuation as ( market cap * price ) denominated in
    /// reserve to calculate a weight for.
    function valuationWeight(uint256 reserveInit_, uint256 valuation_)
        private
        pure
        returns (uint256)
    {
        uint256 weight_ = valuation_
            .mul(IBalancerConstants.BONE)
            .div(reserveInit_);
        require(
            weight_ >= IBalancerConstants.MIN_WEIGHT,
            "MIN_WEIGHT_VALUATION"
        );
        // The combined weight of both tokens cannot exceed the maximum even
        // temporarily during a transaction so we need to subtract one for
        // headroom.
        require(
            IBalancerConstants.MAX_WEIGHT.sub(IBalancerConstants.BONE)
            >= IBalancerConstants.MIN_WEIGHT.add(weight_),
            "MAX_WEIGHT_VALUATION"
        );
        return weight_;
    }

    /// Allow anyone to start the Balancer style dutch auction.
    /// The auction won't start unless this contract owns enough of both the
    /// tokens for the pool, so it is safe for anon to call.
    /// `Phase.ZERO` indicates the auction can start.
    /// `Phase.ONE` indicates the auction has started.
    /// `Phase.TWO` indicates the auction can be ended.
    /// `Phase.THREE` indicates the auction has ended.
    /// Creates the pool via. the CRP contract and configures the weight change
    /// curve.
    function startDutchAuction() external onlyPhase(Phase.ZERO)
    {
        uint256 finalAuctionBlock_ = minimumTradingDuration + block.number;
        // Move to `Phase.ONE` immediately.
        scheduleNextPhase(uint32(block.number));
        // Schedule `Phase.TWO` for `1` block after auctions weights have
        // stopped changing.
        scheduleNextPhase(uint32(finalAuctionBlock_ + 1));

        // Define the weight curve.
        uint256[] memory finalWeights_ = new uint256[](2);
        finalWeights_[0] = IBalancerConstants.MIN_WEIGHT;
        finalWeights_[1] = finalWeight;

        // Max pool tokens to minimise dust on exit.
        // No minimum weight change period.
        // No time lock (we handle our own locks in the trust).
        crp.createPool(IBalancerConstants.MAX_POOL_SUPPLY, 0, 0);
        crp.updateWeightsGradually(
            finalWeights_,
            block.number,
            finalAuctionBlock_
        );
    }

    /// Allow the owner to end the Balancer style dutch auction.
    /// Moves from `Phase.TWO` to `Phase.THREE` to indicate the auction has
    /// ended.
    /// `Phase.TWO` is scheduled by `startDutchAuction`.
    /// Removes all LP tokens from the Balancer pool.
    /// Burns all unsold redeemable tokens.
    /// Forwards the reserve balance to the owner.
    function ownerEndDutchAuction() external onlyOwner onlyPhase(Phase.TWO) {
        // Move to `Phase.THREE` immediately.
        // In `Phase.THREE` all `RedeemableERC20Pool` functions are no longer
        // callable.
        scheduleNextPhase(uint32(block.number));

        // Balancer enforces a global minimum pool LP token supply as
        // `MIN_POOL_SUPPLY`.
        // Balancer also indirectly enforces local minimums on pool token
        // supply by enforcing minimum erc20 token balances in the pool.
        // The real minimum pool LP token supply is the largest of:
        // - The global minimum
        // - The LP token supply implied by the reserve
        // - The LP token supply implied by the token
        uint256 minReservePoolTokens = MIN_BALANCER_POOL_BALANCE
            .mul(IBalancerConstants.MAX_POOL_SUPPLY)
            .div(reserve.balanceOf(crp.bPool()));
        // The minimum redeemable token supply is `10 ** 18` so it is near
        // impossible to hit this before the reserve or global pool minimums.
        uint256 minRedeemablePoolTokens = MIN_BALANCER_POOL_BALANCE
            .mul(IBalancerConstants.MAX_POOL_SUPPLY)
            .div(token.balanceOf(crp.bPool()));
        uint256 minPoolSupply_ = IBalancerConstants.MIN_POOL_SUPPLY
            .max(minReservePoolTokens)
            .max(minRedeemablePoolTokens);

        // This removes as much as is allowable which leaves behind some dust.
        // The reserve dust will be trapped.
        // The redeemable token will be burned when it moves to its own
        // `Phase.ONE`.
        crp.exitPool(
            IERC20(address(crp)).balanceOf(address(this)) - minPoolSupply_,
            new uint256[](2)
        );

        // Burn all unsold token inventory.
        token.burn(token.balanceOf(address(this)));

        // Send reserve back to owner (`Trust`) to be distributed to
        // stakeholders.
        reserve.safeTransfer(
            owner(),
            reserve.balanceOf(address(this))
        );
    }

    /// Enforce `Phase.THREE` as the last phase.
    /// @inheritdoc Phased
    function _beforeScheduleNextPhase(uint32 nextPhaseBlock_)
        internal
        override
        virtual
    {
        super._beforeScheduleNextPhase(nextPhaseBlock_);
        assert(currentPhase() < Phase.THREE);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { Factory } from "../factory/Factory.sol";
import { SeedERC20, SeedERC20Config } from "./SeedERC20.sol";

/// @title SeedERC20Factory
/// @notice Factory for creating and deploying `SeedERC20` contracts.
contract SeedERC20Factory is Factory {

    /// @inheritdoc Factory
    function _createChild(
        bytes calldata data_
    ) internal virtual override returns(address) {
        (SeedERC20Config memory config_) = abi.decode(
            data_,
            (SeedERC20Config)
        );
        return address(new SeedERC20(config_));
    }

    /// Allows calling `createChild` with `SeedERC20Config` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `SeedERC20` constructor configuration.
    /// @return New `SeedERC20` child contract address.
    function createChild(SeedERC20Config calldata config_)
        external
        returns(address)
    {
        return this.createChild(abi.encode(config_));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Phase, Phased } from "../phased/Phased.sol";
import { Cooldown } from "../cooldown/Cooldown.sol";

/// Everything required to construct a `SeedERC20` contract.
struct SeedERC20Config {
    // Reserve erc20 token contract used to purchase seed tokens.
    IERC20 reserve;
    // Recipient address for all reserve funds raised when seeding is complete.
    address recipient;
    // Price per seed unit denominated in reserve token.
    uint256 seedPrice;
    // Total seed units to be mint and sold.
    // 100% of all seed units must be sold for seeding to complete.
    // Recommended to keep seed units to a small value (single-triple digits).
    // The ability for users to buy/sell or not buy/sell dust seed quantities
    // is likely NOT desired.
    uint16 seedUnits;
    // Cooldown duration in blocks for seed/unseed cycles.
    // Seeding requires locking funds for at least the cooldown period.
    // Ideally `unseed` is never called and `seed` leaves funds in the contract
    // until all seed tokens are sold out.
    // A failed raise cannot make funds unrecoverable, so `unseed` does exist,
    // but it should be called rarely.
    uint16 cooldownDuration;
    // ERC20 name.
    string name;
    // ERC20 symbol.
    string symbol;
}

/// @title SeedERC20
/// @notice Facilitates raising seed reserve from an open set of seeders.
///
/// When a single seeder address cannot be specified at the time the
/// `Trust` is constructed a `SeedERC20` will be deployed.
///
/// The `SeedERC20` has two phases:
///
/// - `Phase.ZERO`: Can swap seed tokens for reserve assets with
/// `seed` and `unseed`
/// - `Phase.ONE`: Can redeem seed tokens pro-rata for reserve assets
///
/// When the last seed token is distributed the `SeedERC20`
/// immediately moves to `Phase.ONE` atomically within that
/// transaction and forwards all reserve to the configured recipient.
///
/// For our use-case the recipient is a `Trust` contract but `SeedERC20`
/// could be used as a mini-fundraise contract for many purposes. In the case
/// that a recipient is not a `Trust` the recipient will need to be careful not
/// to fall afoul of KYC and securities law.
///
/// @dev Facilitates a pool of reserve funds to forward to a named recipient
/// contract.
/// The funds to raise and the recipient is fixed at construction.
/// The total is calculated as `( seedPrice * seedUnits )` and so is a fixed
/// amount. It is recommended to keep seedUnits relatively small so that each
/// unit represents a meaningful contribution to keep dust out of the system.
///
/// The contract lifecycle is split into two phases:
///
/// - `Phase.ZERO`: the `seed` and `unseed` functions are callable by anyone.
/// - `Phase.ONE`: holders of the seed erc20 token can redeem any reserve funds
///   in the contract pro-rata.
///
/// When `seed` is called the `SeedERC20` contract takes ownership of reserve
/// funds in exchange for seed tokens.
/// When `unseed` is called the `SeedERC20` contract takes ownership of seed
/// tokens in exchange for reserve funds.
///
/// When the last `seed` token is transferred to an external address the
/// `SeedERC20` contract immediately:
///
/// - Moves to `Phase.ONE`, disabling both `seed` and `unseed`
/// - Transfers the full balance of reserve from itself to the recipient
///   address.
///
/// Seed tokens are standard ERC20 so can be freely transferred etc.
///
/// The recipient (or anyone else) MAY transfer reserve back to the `SeedERC20`
/// at a later date.
/// Seed token holders can call `redeem` in `Phase.ONE` to burn their tokens in
/// exchange for pro-rata reserve assets.
contract SeedERC20 is Ownable, ERC20, Phased, Cooldown {

    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Seed token burn for reserve.
    event Redeem(
        // Account burning and receiving.
        address indexed redeemer,
        // Number of seed tokens burned.
        // Number of reserve redeemed for burned seed tokens.
        // `[seedAmount, reserveAmount]`
        uint256[2] redeemAmounts
    );

    event Seed(
        // Account seeding.
        address indexed seeder,
        // Number of tokens seeded.
        // Number of reserve sent for seed tokens.
        uint256[2] seedAmounts
    );

    event Unseed(
        // Account unseeding.
        address indexed unseeder,
        // Number of tokens unseeded.
        // Number of reserve tokens returned for unseeded tokens.
        uint256[2] unseedAmounts
    );

    /// Reserve erc20 token contract used to purchase seed tokens.
    IERC20 public immutable reserve;
    /// Recipient address for all reserve funds raised when seeding is
    /// complete.
    address public immutable recipient;
    /// Price in reserve for a unit of seed token.
    uint256 public immutable seedPrice;

    /// Sanity checks on configuration.
    /// Store relevant config as contract state.
    /// Mint all seed tokens.
    /// @param config_ All config required to construct the contract.
    constructor (SeedERC20Config memory config_)
    public
    ERC20(config_.name, config_.symbol)
    Cooldown(config_.cooldownDuration) {
        require(config_.seedPrice > 0, "PRICE_0");
        require(config_.seedUnits > 0, "UNITS_0");
        require(config_.recipient != address(0), "RECIPIENT_0");
        seedPrice = config_.seedPrice;
        reserve = config_.reserve;
        recipient = config_.recipient;
        _setupDecimals(0);
        _mint(address(this), config_.seedUnits);
    }

    /// Take reserve from seeder as `units * seedPrice`.
    ///
    /// When the final unit is sold the contract immediately:
    ///
    /// - enters `Phase.ONE`
    /// - transfers its entire reserve balance to the recipient
    ///
    /// The desired units may not be available by the time this transaction
    /// executes. This could be due to high demand, griefing and/or
    /// front-running on the contract.
    /// The caller can set a range between `minimumUnits_` and `desiredUnits_`
    /// to mitigate errors due to the contract running out of stock.
    /// The maximum available units up to `desiredUnits_` will always be
    /// processed by the contract. Only the stock of this contract is checked
    /// against the seed unit range, the caller is responsible for ensuring
    /// their reserve balance.
    /// Seeding enforces the cooldown configured in the constructor.
    /// @param minimumUnits_ The minimum units the caller will accept for a
    /// successful `seed` call.
    /// @param desiredUnits_ The maximum units the caller is willing to fund.
    function seed(uint256 minimumUnits_, uint256 desiredUnits_)
        external
        onlyPhase(Phase.ZERO)
        onlyAfterCooldown
    {
        require(desiredUnits_ > 0, "DESIRED_0");
        require(minimumUnits_ <= desiredUnits_, "MINIMUM_OVER_DESIRED");
        uint256 remainingStock_ = balanceOf(address(this));
        require(minimumUnits_ <= remainingStock_, "INSUFFICIENT_STOCK");

        uint256 units_ = desiredUnits_.min(remainingStock_);
        uint256 reserveAmount_ = seedPrice.mul(units_);

        // If `remainingStock_` is less than units then the transfer below will
        // fail and rollback.
        if (remainingStock_ == units_) {
            scheduleNextPhase(uint32(block.number));
        }
        _transfer(address(this), msg.sender, units_);

        reserve.safeTransferFrom(
            msg.sender,
            address(this),
            reserveAmount_
        );
        // Immediately transfer to the recipient.
        // The transfer is immediate rather than only approving for the
        // recipient.
        // This avoids the situation where a seeder immediately redeems their
        // units before the recipient can withdraw.
        // It also introduces a failure case where the reserve errors on
        // transfer. If this fails then everyone can call `unseed` after their
        // individual cooldowns to exit.
        if (currentPhase() == Phase.ONE) {
            reserve.safeTransfer(recipient, reserve.balanceOf(address(this)));
        }

        emit Seed(
            msg.sender,
            [units_, reserveAmount_]
        );
    }

    /// Send reserve back to seeder as `( units * seedPrice )`.
    ///
    /// Allows addresses to back out until `Phase.ONE`.
    /// Unlike `redeem` the seed tokens are NOT burned so become newly
    /// available for another account to `seed`.
    ///
    /// In `Phase.ONE` the only way to recover reserve assets is:
    /// - Wait for the recipient or someone else to deposit reserve assets into
    ///   this contract.
    /// - Call redeem and burn the seed tokens
    ///
    /// @param units_ Units to unseed.
    function unseed(uint256 units_)
        external
        onlyPhase(Phase.ZERO)
        onlyAfterCooldown
    {
        uint256 reserveAmount_ = seedPrice.mul(units_);
        _transfer(msg.sender, address(this), units_);

        // Reentrant reserve transfer.
        reserve.safeTransfer(msg.sender, reserveAmount_);

        Unseed(
            msg.sender,
            [units_, reserveAmount_]
        );
    }

    /// Burn seed tokens for pro-rata reserve assets.
    ///
    /// ```
    /// (units * reserve held by seed contract) / total seed token supply
    /// = reserve transfer to `msg.sender`
    /// ```
    ///
    /// The recipient or someone else must first transfer reserve assets to the
    /// `SeedERC20` contract.
    /// The recipient MUST be a TRUSTED contract or third party.
    /// This contract has no control over the reserve assets once they are
    /// transferred away at the start of `Phase.ONE`.
    /// It is the caller's responsibility to monitor the reserve balance of the
    /// `SeedERC20` contract.
    ///
    /// For example, if `SeedERC20` is used as a seeder for a `Trust` contract
    /// (in this repo) it will receive a refund or refund + fee.
    /// @param units_ Amount of seed units to burn and redeem for reserve
    /// assets.
    function redeem(uint256 units_) external onlyPhase(Phase.ONE) {
        uint256 _supplyBeforeBurn = totalSupply();
        _burn(msg.sender, units_);

        uint256 _currentReserveBalance = reserve.balanceOf(address(this));
        // Guard against someone accidentally calling redeem before any reserve
        // has been returned.
        require(_currentReserveBalance > 0, "RESERVE_BALANCE");
        uint256 reserveAmount_ = units_
            .mul(_currentReserveBalance)
            .div(_supplyBeforeBurn);
        emit Redeem(
            msg.sender,
            [units_, reserveAmount_]
        );
        reserve.safeTransfer(
            msg.sender,
            reserveAmount_
        );
    }

    /// Sanity check the last phase is `Phase.ONE`.
    /// @inheritdoc Phased
    function _beforeScheduleNextPhase(uint32 nextPhaseBlock_)
        internal
        override
        virtual
    {
        super._beforeScheduleNextPhase(nextPhaseBlock_);
        // Phase.ONE is the last phase.
        assert(currentPhase() < Phase.ONE);
    }
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

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

interface IFactory {
    /// Whenever a new child contract is deployed, a `NewContract` event
    /// containing the new child contract address MUST be emitted.
    event NewContract(address indexed _contract);

    /// Creates a new child contract.
    ///
    /// @param data_ Domain specific data for the child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_) external returns(address);

    /// Checks if address is registered as a child contract of this factory.
    ///
    /// Addresses that were not deployed by `createChild` MUST NOT return
    /// `true` from `isChild`. This is CRITICAL to the security guarantees for
    /// any contract implementing `IFactory`.
    ///
    /// @param maybeChild_ Address to check registration for.
    /// @return `true` if address was deployed by this contract factory,
    /// otherwise `false`.
    function isChild(address maybeChild_) external returns(bool);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

/// Defines all possible phases.
/// `Phased` begins in `Phase.ZERO` and moves through each phase sequentially.
enum Phase {
    ZERO,
    ONE,
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX,
    SEVEN,
    EIGHT
}

/// @title Phased
/// @notice `Phased` is an abstract contract that defines up to `9` phases that
/// an implementing contract moves through.
///
/// `Phase.ZERO` is always the first phase and does not, and cannot, be set
/// expicitly. Effectively it is implied that `Phase.ZERO` has been active
/// since block zero.
///
/// Each subsequent phase `Phase.ONE` through `Phase.EIGHT` must be
/// scheduled sequentially and explicitly at a block number.
///
/// Only the immediate next phase can be scheduled with `scheduleNextPhase`,
/// it is not possible to schedule multiple phases ahead.
///
/// Multiple phases can be scheduled in a single block if each scheduled phase
/// is scheduled for the current block.
///
/// Several utility functions and modifiers are provided.
///
/// A single hook `_beforeScheduleNextPhase` is provided so contracts can
/// implement additional phase shift checks.
///
/// One event `PhaseShiftScheduled` is emitted each time a phase shift is
/// scheduled (not when the scheduled phase is reached).
///
/// @dev `Phased` contracts have a defined timeline with available
/// functionality grouped into phases.
/// Every `Phased` contract starts at `Phase.ZERO` and moves sequentially
/// through phases `ONE` to `EIGHT`.
/// Every `Phase` other than `Phase.ZERO` is optional, there is no requirement
/// that all 9 phases are implemented.
/// Phases can never be revisited, the inheriting contract always moves through
/// each achieved phase linearly.
/// This is enforced by only allowing `scheduleNextPhase` to be called once per
/// phase.
/// It is possible to call `scheduleNextPhase` several times in a single block
/// but the `block.number` for each phase must be reached each time to schedule
/// the next phase.
/// Importantly there are events and several modifiers and checks available to
/// ensure that functionality is limited to the current phase.
/// The full history of each phase shift block is recorded as a fixed size
/// array of `uint32`.
abstract contract Phased {
    /// Every phase block starts uninitialized.
    /// Only uninitialized blocks can be set by the phase scheduler.
    uint32 constant public UNINITIALIZED = uint32(-1);

    /// `PhaseShiftScheduled` is emitted when the next phase is scheduled.
    event PhaseShiftScheduled(uint32 indexed newPhaseBlock_);

    /// 8 phases each as 32 bits to fit a single 32 byte word.
    uint32[8] public phaseBlocks = [
        UNINITIALIZED,
        UNINITIALIZED,
        UNINITIALIZED,
        UNINITIALIZED,
        UNINITIALIZED,
        UNINITIALIZED,
        UNINITIALIZED,
        UNINITIALIZED
    ];

    /// Pure function to reduce an array of phase blocks and block number to a
    /// specific `Phase`.
    /// The phase will be the highest attained even if several phases have the
    /// same block number.
    /// If every phase block is after the block number then `Phase.ZERO` is
    /// returned.
    /// If every phase block is before the block number then `Phase.EIGHT` is
    /// returned.
    /// @param phaseBlocks_ Fixed array of phase blocks to compare against.
    /// @param blockNumber_ Determine the relevant phase relative to this block
    /// number.
    /// @return The "current" phase relative to the block number and phase
    /// blocks list.
    function phaseAtBlockNumber(
        uint32[8] memory phaseBlocks_,
        uint32 blockNumber_
    )
        public
        pure
        returns(Phase)
    {
        for(uint i_ = 0; i_<8; i_++) {
            if (blockNumber_ < phaseBlocks_[i_]) {
                return Phase(i_);
            }
        }
        return Phase(8);
    }

    /// Pure function to reduce an array of phase blocks and phase to a
    /// specific block number.
    /// `Phase.ZERO` will always return block `0`.
    /// Every other phase will map to a block number in `phaseBlocks_`.
    /// @param phaseBlocks_ Fixed array of phase blocks to compare against.
    /// @param phase_ Determine the relevant block number for this phase.
    /// @return The block number for the phase according to the phase blocks
    ///         list, as uint32.
    function blockNumberForPhase(uint32[8] calldata phaseBlocks_, Phase phase_)
        external
        pure
        returns(uint32)
    {
        return phase_ > Phase.ZERO ? phaseBlocks_[uint(phase_) - 1] : 0;
    }

    /// Impure read-only function to return the "current" phase from internal
    /// contract state.
    /// Simply wraps `phaseAtBlockNumber` for current values of `phaseBlocks`
    /// and `block.number`.
    function currentPhase() public view returns (Phase) {
        return phaseAtBlockNumber(phaseBlocks, uint32(block.number));
    }

    /// Modifies functions to only be callable in a specific phase.
    /// @param phase_ Modified functions can only be called during this phase.
    modifier onlyPhase(Phase phase_) {
        require(currentPhase() == phase_, "BAD_PHASE");
        _;
    }

    /// Modifies functions to only be callable in a specific phase OR if the
    /// specified phase has passed.
    /// @param phase_ Modified function only callable during or after this
    /// phase.
    modifier onlyAtLeastPhase(Phase phase_) {
        require(currentPhase() >= phase_, "MIN_PHASE");
        _;
    }

    /// Writes the block for the next phase.
    /// Only uninitialized blocks can be written to.
    /// Only the immediate next phase relative to `currentPhase` can be written
    /// to.
    /// Emits `PhaseShiftScheduled` with the next phase block.
    /// @param nextPhaseBlock_ The block for the next phase.
    function scheduleNextPhase(uint32 nextPhaseBlock_) internal {
        require(uint32(block.number) <= nextPhaseBlock_, "NEXT_BLOCK_PAST");
        require(nextPhaseBlock_ < UNINITIALIZED, "NEXT_BLOCK_UNINITIALIZED");

        // The next index is the current phase because `Phase.ZERO` doesn't
        // exist as an index.
        uint nextIndex_ = uint(currentPhase());
        require(UNINITIALIZED == phaseBlocks[nextIndex_], "NEXT_BLOCK_SET");

        _beforeScheduleNextPhase(nextPhaseBlock_);
        phaseBlocks[nextIndex_] = nextPhaseBlock_;

        emit PhaseShiftScheduled(nextPhaseBlock_);
    }

    /// Hook called before scheduling the next phase.
    /// Useful to apply additional constraints or state changes on a phase
    /// change.
    /// Note this is called when scheduling the phase change, not on the block
    /// the phase change occurs.
    /// This is called before the phase change so that all functionality that
    /// is behind a phase gate is still available at the moment of applying the
    /// hook for scheduling the next phase.
    /// @param nextPhaseBlock_ The block for the next phase.
    function _beforeScheduleNextPhase(uint32 nextPhaseBlock_)
        internal
        virtual
    { } //solhint-disable-line no-empty-blocks
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

// Mirrors `Rights` from Balancer `configurable-rights-pool` repo.
// As we do not include balancer contracts as a dependency, we need to ensure
// that any calculations or values that cross the interface to their system are
// identical.
// solhint-disable-next-line max-line-length
// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/libraries/RightsManager.sol#L29
struct Rights {
    bool canPauseSwapping;
    bool canChangeSwapFee;
    bool canChangeWeights;
    bool canAddRemoveTokens;
    bool canWhitelistLPs;
    bool canChangeCap;
}

// SPDX-License-Identifier: CAL
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import { PoolParams } from "./IConfigurableRightsPool.sol";
import { Rights } from "./IRightsManager.sol";

/// Mirrors the Balancer `CRPFactory` functions relevant to
/// bootstrapping a pool. This is the minimal interface required for
/// `RedeemableERC20Pool` to function, much of the Balancer contract is elided
/// intentionally. Clients should use Balancer code directly.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/CRPFactory.sol#L27
interface ICRPFactory {
    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/CRPFactory.sol#L50
    function newCrp(
        address factoryAddress,
        PoolParams calldata poolParams,
        Rights calldata rights
    )
    external
    returns (address);
}

// SPDX-License-Identifier: CAL
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

/// Mirrors the `PoolParams` struct normally internal to a Balancer
/// `ConfigurableRightsPool`.
/// If nothing else, this fixes errors that prevent slither from compiling when
/// running the security scan.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L47
struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint[] tokenBalances;
    uint[] tokenWeights;
    uint swapFee;
}

/// Mirrors the Balancer `ConfigurableRightsPool` functions relevant to
/// bootstrapping a pool. This is the minimal interface required for
/// `RedeemableERC20Pool` to function, much of the Balancer contract is elided
/// intentionally. Clients should use Balancer code directly.
// solhint-disable-next-line max-line-length
/// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L41
interface IConfigurableRightsPool {
    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L61
    function bPool() external view returns (address);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L60
    function bFactory() external view returns (address);

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L318
    function createPool(
        uint initialSupply,
        uint minimumWeightChangeBlockPeriodParam,
        uint addTokenTimeLockInBlocksParam
    ) external;

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L393
    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    ) external;

    // solhint-disable-next-line max-line-length
    // https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/contracts/ConfigurableRightsPool.sol#L581
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external;
}

// SPDX-License-Identifier: CAL
pragma solidity 0.6.12;

// Mirrors all the constants from Balancer `configurable-rights-pool` repo.
// As we do not include balancer contracts as a dependency, we need to ensure
// that any calculations or values that cross the interface to their system are
// identical.
// solhint-disable-next-line max-line-length
// https://github.com/balancer-labs/configurable-rights-pool/blob/5bd63657ac71a9e5f8484ea561de572193b3317b/libraries/BalancerConstants.sol#L9
library IBalancerConstants {
    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = BONE / 10**6;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    uint public constant MIN_ASSET_LIMIT = 2;
    uint public constant MAX_ASSET_LIMIT = 8;
    uint public constant MAX_UINT = uint(-1);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

/// @title Cooldown
/// @notice `Cooldown` is an abstract contract that rate limits functions on
/// the contract per `msg.sender`.
///
/// Each time a function with the `onlyAfterCooldown` modifier is called the
/// `msg.sender` must wait N blocks before calling any modified function.
///
/// This does nothing to prevent sybils who can generate an arbitrary number of
/// `msg.sender` values in parallel to spam a contract.
///
/// `Cooldown` is intended to prevent rapid state cycling to grief a contract,
/// such as rapidly locking and unlocking a large amount of capital in the
/// `SeedERC20` contract.
///
/// Requiring a lock/deposit of significant economic stake that sybils will not
/// have access to AND applying a cooldown IS a sybil mitigation. The economic
/// stake alone is NOT sufficient if gas is cheap as sybils can cycle the same
/// stake between each other. The cooldown alone is NOT sufficient as many
/// sybils can be created, each as a new `msg.sender`.
///
/// @dev Base for anything that enforces a cooldown delay on functions.
/// Cooldown requires a minimum time in blocks to elapse between actions that
/// cooldown. The modifier `onlyAfterCooldown` both enforces and triggers the
/// cooldown. There is a single cooldown across all functions per-contract
/// so any function call that requires a cooldown will also trigger it for
/// all other functions.
///
/// Cooldown is NOT an effective sybil resistance alone, as the cooldown is
/// per-address only. It is always possible for many accounts to be created
/// to spam a contract with dust in parallel.
/// Cooldown is useful to stop a single account rapidly cycling contract
/// state in a way that can be disruptive to peers. Cooldown works best when
/// coupled with economic stake associated with each state change so that
/// peers must lock capital during the cooldown. Cooldown tracks the first
/// `msg.sender` it sees for a call stack so cooldowns are enforced across
/// reentrant code.
abstract contract Cooldown {
    /// Time in blocks to restrict access to modified functions.
    uint16 public immutable cooldownDuration;

    /// Every address has its own cooldown state.
    mapping (address => uint256) public cooldowns;
    address private caller;

    /// The cooldown duration is global to the contract.
    /// Cooldown duration must be greater than 0.
    /// @param cooldownDuration_ The global cooldown duration.
    constructor(uint16 cooldownDuration_) public {
        require(cooldownDuration_ > 0, "COOLDOWN_0");
        cooldownDuration = cooldownDuration_;
    }

    /// Modifies a function to enforce the cooldown for `msg.sender`.
    /// Saves the original caller so that cooldowns are enforced across
    /// reentrant code.
    modifier onlyAfterCooldown() {
        address caller_ = caller == address(0) ? caller = msg.sender : caller;
        require(cooldowns[caller_] <= block.number, "COOLDOWN");
        // Every action that requires a cooldown also triggers a cooldown.
        cooldowns[caller_] = block.number + cooldownDuration;
        _;
        delete caller;
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { TierUtil } from "../libraries/TierUtil.sol";
import { ValueTier } from "./ValueTier.sol";
import "./ReadWriteTier.sol";

/// @title ERC20TransferTier
/// @notice `ERC20TransferTier` inherits from `ReadWriteTier`.
///
/// In addition to the standard accounting it requires that users transfer
/// erc20 tokens to achieve a tier.
///
/// Data is ignored, the only requirement is that the user has approved
/// sufficient balance to gain the next tier.
///
/// To avoid griefing attacks where accounts remove tiers from arbitrary third
/// parties, we `require(msg.sender == account_);` when a tier is removed.
/// When a tier is added the `msg.sender` is responsible for payment.
///
/// The 8 values for gainable tiers and erc20 contract must be set upon
/// construction and are immutable.
///
/// The `_afterSetTier` simply transfers the diff between the start/end tier
/// to/from the user as required.
///
/// If a user sends erc20 tokens directly to the contract without calling
/// `setTier` the FUNDS ARE LOST.
///
/// @dev The `ERC20TransferTier` takes ownership of an erc20 balance by
/// transferring erc20 token to itself. The `msg.sender` must pay the
/// difference on upgrade; the tiered address receives refunds on downgrade.
/// This allows users to "gift" tiers to each other.
/// As the transfer is a state changing event we can track historical block
/// times.
/// As the tiered address moves up/down tiers it sends/receives the value
/// difference between its current tier only.
///
/// The user is required to preapprove enough erc20 to cover the tier change or
/// they will fail and lose gas.
///
/// `ERC20TransferTier` is useful for:
/// - Claims that rely on historical holdings so the tiered address
///   cannot simply "flash claim"
/// - Token demand and lockup where liquidity (trading) is a secondary goal
/// - erc20 tokens without additonal restrictions on transfer
contract ERC20TransferTier is ReadWriteTier, ValueTier {
    using SafeERC20 for IERC20;

    IERC20 public immutable erc20;

    /// @param erc20_ The erc20 token contract to transfer balances
    /// from/to during `setTier`.
    /// @param tierValues_ 8 values corresponding to minimum erc20
    /// balances for tiers ONE through EIGHT.
    constructor(IERC20 erc20_, uint256[8] memory tierValues_)
        public
        ValueTier(tierValues_)
    {
        erc20 = erc20_;
    }

    /// Transfers balances of erc20 from/to the tiered account according to the
    /// difference in values. Any failure to transfer in/out will rollback the
    /// tier change. The tiered account must ensure sufficient approvals before
    /// attempting to set a new tier.
    /// The `msg.sender` is responsible for paying the token cost of a tier
    /// increase.
    /// The tiered account is always the recipient of a refund on a tier
    /// decrease.
    /// @inheritdoc ReadWriteTier
    function _afterSetTier(
        address account_,
        ITier.Tier startTier_,
        ITier.Tier endTier_,
        bytes memory
    )
        internal
        override
    {
        // As _anyone_ can call `setTier` we require that `msg.sender` and
        // `account_` are the same if the end tier is lower.
        // Anyone can increase anyone else's tier as the `msg.sender` is
        // responsible to pay the difference.
        if (endTier_ <= startTier_) {
            require(msg.sender == account_, "DELEGATED_TIER_LOSS");
        }

        // Handle the erc20 transfer.
        // Convert the start tier to an erc20 amount.
        uint256 startValue_ = tierToValue(startTier_);
        // Convert the end tier to an erc20 amount.
        uint256 endValue_ = tierToValue(endTier_);

        // Short circuit if the values are the same for both tiers.
        if (endValue_ == startValue_) {
            return;
        }
        if (endValue_ > startValue_) {
            // Going up, take ownership of erc20 from the `msg.sender`.
            erc20.safeTransferFrom(msg.sender, address(this), SafeMath.sub(
                endValue_,
                startValue_
            ));
        } else {
            // Going down, process a refund for the tiered account.
            erc20.safeTransfer(account_, SafeMath.sub(
                startValue_,
                endValue_
            ));
        }
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ITier } from "./ITier.sol";

/// @title ValueTier
///
/// @dev A contract that is `ValueTier` expects to derive tiers from explicit
/// values. For example an address must send or hold an amount of something to
/// reach a given tier.
/// Anything with predefined values that map to tiers can be a `ValueTier`.
///
/// Note that `ValueTier` does NOT implement `ITier`.
/// `ValueTier` does include state however, to track the `tierValues` so is not
/// a library.
contract ValueTier {
    uint256 private immutable tierOne;
    uint256 private immutable tierTwo;
    uint256 private immutable tierThree;
    uint256 private immutable tierFour;
    uint256 private immutable tierFive;
    uint256 private immutable tierSix;
    uint256 private immutable tierSeven;
    uint256 private immutable tierEight;

    /// Set the `tierValues` on construction to be referenced immutably.
    constructor(uint256[8] memory tierValues_) public {
        tierOne = tierValues_[0];
        tierTwo = tierValues_[1];
        tierThree = tierValues_[2];
        tierFour = tierValues_[3];
        tierFive = tierValues_[4];
        tierSix = tierValues_[5];
        tierSeven = tierValues_[6];
        tierEight = tierValues_[7];
    }

    /// Complements the default solidity accessor for `tierValues`.
    /// Returns all the values in a list rather than requiring an index be
    /// specified.
    /// @return tierValues_ The immutable `tierValues`.
    function tierValues() public view returns(uint256[8] memory tierValues_) {
        tierValues_[0] = tierOne;
        tierValues_[1] = tierTwo;
        tierValues_[2] = tierThree;
        tierValues_[3] = tierFour;
        tierValues_[4] = tierFive;
        tierValues_[5] = tierSix;
        tierValues_[6] = tierSeven;
        tierValues_[7] = tierEight;
        return tierValues_;
    }

    /// Converts a Tier to the minimum value it requires.
    /// `Tier.ZERO` is always value 0 as it is the fallback.
    function tierToValue(ITier.Tier tier_) internal view returns(uint256) {
        return tier_ > ITier.Tier.ZERO ? tierValues()[uint256(tier_) - 1] : 0;
    }

    /// Converts a value to the maximum Tier it qualifies for.
    function valueToTier(uint256 value_) internal view returns(ITier.Tier) {
        for (uint256 i = 0; i < 8; i++) {
            if (value_ < tierValues()[i]) {
                return ITier.Tier(i);
            }
        }
        return ITier.Tier.EIGHT;
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ITier } from "./ITier.sol";
import { TierUtil } from "../libraries/TierUtil.sol";

/// @title ReadWriteTier
/// @notice `ReadWriteTier` is a base contract that other contracts are
/// expected to inherit.
///
/// It handles all the internal accounting and state changes for `report`
/// and `setTier`.
///
/// It calls an `_afterSetTier` hook that inheriting contracts can override to
/// enforce tier requirements.
///
/// @dev ReadWriteTier can `setTier` in addition to generating reports.
/// When `setTier` is called it automatically sets the current blocks in the
/// report for the new tiers. Lost tiers are scrubbed from the report as tiered
/// addresses move down the tiers.
contract ReadWriteTier is ITier {
    /// account => reports
    mapping(address => uint256) public reports;

    /// Either fetch the report from storage or return UNINITIALIZED.
    /// @inheritdoc ITier
    function report(address account_)
        public
        virtual
        override
        view
        returns (uint256)
    {
        // Inequality here to silence slither warnings.
        return reports[account_] > 0
            ? reports[account_]
            : TierUtil.UNINITIALIZED;
    }

    /// Errors if the user attempts to return to the `Tier.ZERO` tier.
    /// Updates the report from `report` using default `TierUtil` logic.
    /// Calls `_afterSetTier` that inheriting contracts SHOULD override to
    /// enforce status requirements.
    /// Emits `TierChange` event.
    /// @inheritdoc ITier
    function setTier(
        address account_,
        Tier endTier_,
        bytes memory data_
    )
        external virtual override
    {
        // The user must move to at least `Tier.ONE`.
        // The `Tier.ZERO` status is reserved for users that have never
        // interacted with the contract.
        require(endTier_ != Tier.ZERO, "SET_ZERO_TIER");

        uint256 report_ = report(account_);

        ITier.Tier startTier_ = TierUtil.tierAtBlockFromReport(
            report_,
            block.number
        );

        reports[account_] = TierUtil.updateReportWithTierAtBlock(
            report_,
            startTier_,
            endTier_,
            block.number
        );

        // Emit this event for ITier.
        emit TierChange(account_, startTier_, endTier_);

        // Call the `_afterSetTier` hook to allow inheriting contracts
        // to enforce requirements.
        // The inheriting contract MUST `require` or otherwise
        // enforce its needs to rollback a bad status change.
        _afterSetTier(account_, startTier_, endTier_, data_);
    }

    /// Inheriting contracts SHOULD override this to enforce requirements.
    ///
    /// All the internal accounting and state changes are complete at
    /// this point.
    /// Use `require` to enforce additional requirements for tier changes.
    ///
    /// @param account_ The account with the new tier.
    /// @param startTier_ The tier the account had before this update.
    /// @param endTier_ The tier the account will have after this update.
    /// @param data_ Additional arbitrary data to inform update requirements.
    // Slither false positive. This is intended to overridden.
    // https://github.com/crytic/slither/issues/929
    // slither-disable-next-line dead-code
    function _afterSetTier(
        address account_,
        Tier startTier_,
        Tier endTier_,
        bytes memory data_
    )
        internal virtual
    { } // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "./ReadOnlyTier.sol";
import { State, Status, Verify } from "../verify/Verify.sol";
import "../libraries/TierUtil.sol";

/// @title VerifyTier
///
/// @dev A contract that is `VerifyTier` expects to derive tiers from the time
/// the account was approved by the underlying `Verify` contract. The approval
/// block numbers defer to `State.since` returned from `Verify.state`.
contract VerifyTier is ReadOnlyTier {
    Verify public immutable verify;

    /// Sets the `verify` contract immutably.
    constructor(Verify verify_) public {
        verify = verify_;
    }

    /// Every tier will be the `State.since` block if `account_` is approved
    /// otherwise every tier will be uninitialized.
    /// @inheritdoc ITier
    function report(address account_) public override view returns (uint256) {
        State memory state_ = verify.state(account_);
        if (
            // This is comparing an enum variant so it must be equal.
            // slither-disable-next-line incorrect-equality
            verify.statusAtBlock(
                state_,
                uint32(block.number)
            ) == Status.Approved) {
            return TierUtil.updateBlocksForTierRange(
                0,
                Tier.ZERO,
                Tier.EIGHT,
                state_.approvedSince
            );
        }
        else {
            return uint256(-1);
        }
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { ITier } from "./ITier.sol";
import { TierUtil } from "../libraries/TierUtil.sol";

/// @title ReadOnlyTier
/// @notice `ReadOnlyTier` is a base contract that other contracts
/// are expected to inherit.
///
/// It does not allow `setStatus` and expects `report` to derive from
/// some existing onchain data.
///
/// @dev A contract inheriting `ReadOnlyTier` cannot call `setTier`.
///
/// `ReadOnlyTier` is abstract because it does not implement `report`.
/// The expectation is that `report` will derive tiers from some
/// external data source.
abstract contract ReadOnlyTier is ITier {
    /// Always reverts because it is not possible to set a read only tier.
    /// @inheritdoc ITier
    function setTier(
        address,
        Tier,
        bytes memory
    )
        external override
    {
        revert("SET_TIER");
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// Summary status derived from a `State` by comparing the `xSince` times
/// against a specific block number.
enum Status {
    // Either no Status has ever been held or it was removed.
    Nil,
    // The account and associated ID has been added, pending verification.
    Added,
    // The associated ID has been reviewed and verified.
    Approved,
    // The associated ID has been reviewed and banned.
    // (even if previously approved)
    Banned
}

/// Records the block a verify session reaches each status.
/// If a status is not reached it is left as UNINITIALIZED, i.e. 0xFFFFFFFF.
/// Most accounts will never be banned so most accounts will never reach every
/// status, which is a good thing.
struct State {
    uint256 id;
    uint32 addedSince;
    uint32 approvedSince;
    uint32 bannedSince;
}

/// @title Verify
/// Trust-minimised contract to record the state of some verification process.
/// When some off-chain identity is to be reified on chain there is inherently
/// some multi-party, multi-faceted trust relationship. For example, the DID
/// (Decentralized Identifiers) specification from W3C outlines that the
/// controller and the subject of an identity are two different entities.
///
/// This is because self-identification is always problematic to the point of
/// being uselessly unbelievable.
///
/// For example, I can simply say "I am the queen of England" and what
/// onchain mechanism could possibly check, let alone stop me?
/// The same problem exists in any situation where some priviledge or right is
/// associated with identity. Consider passports, driver's licenses,
/// celebrity status, age, health, accredited investor, social media account,
/// etc. etc.
///
/// Typically crypto can't and doesn't want to deal with this issue. The usual
/// scenario is that some system demands personal information, which leads to:
///
/// - Data breaches that put individual's safety at risk. Consider the December
///   2020 leak from Ledger that dumped 270 000 home addresses and phone
///   numbers, and another million emails, of hardware wallet owners on a
///   public forum.
/// - Discriminatory access, undermining an individual's self-sovereign right
///   to run a full node, self-host a GUI and broadcast transactions onchain.
///   Consider the dydx airdrop of 2021 where metadata about a user's access
///   patterns logged on a server were used to deny access to presumed
///   Americans over regulatory fears.
/// - An entrenched supply chain of centralized actors from regulators, to
///   government databases, through KYC corporations, platforms, etc. each of
///   which holds an effective monopoly over, and ability to manipulate user's
///   "own" identity.
///
/// These examples and others are completely antithetical to and undermine the
/// safety of an opt-in, permissionless system based on pseudonomous actors
/// self-signing actions into a shared space.
///
/// That said, one can hardly expect a permissionless pseudonomous system
/// founded on asynchronous value transfers to succeed without at least some
/// concept of curation and reputation.
///
/// Anon, will you invest YOUR money in anon's project?
///
/// Clearly for every defi blue chip there are 10 000 scams and nothing onchain
/// can stop a scam, this MUST happen at the social layer.
///
/// Rain protocol is agnostic to how this verification happens. A government
/// regulator is going to want a government issued ID cross-referenced against
/// international sanctions. A fan of some social media influencer wants to
/// see a verified account on that platform. An open source software project
/// should show a github profile. A security token may need evidence from an
/// accountant showing accredited investor status. There are so many ways in
/// which BOTH sides of a fundraise may need to verify something about
/// themselves to each other via a THIRD PARTY that Rain cannot assume much.
///
/// The trust model and process for Rain verification is:
///
/// - There are many `Verify` contracts, each represents a specific
///   verification method with a (hopefully large) set of possible reviewers.
/// - The verifyee compiles some evidence that can be referenced by ID in some
///   relevant system. It could be a session ID in a KYC provider's database or
///   a tweet from a verified account, etc. The ID is a `uint256` so should be
///   enough to fit just about any system ID, it is large enough to fit a hash,
///   2x UUIDs or literally any sequential ID.
/// - The verifyee calls `add` _for themselves_ to include their ID under their
///   account, after which they _cannot change_ their submission without
///   appealing to someone who can remove. This costs gas, so why don't we
///   simply ask the user to sign something and have an approver verify the
///   signed data? Because we want to leverage both the censorship resistance
///   and asynchronous nature of the underlying blockchain. Assuming there are
///   N possible approvers, we want ANY 1 of those N approvers to be able to
///   review and approve an application. If the user is forced to submit their
///   application directly to one SPECIFIC approver we lose this property. In
///   the gasless model the user must then rely on their specific approver both
///   being online and not to censor the request. It's also possible that many
///   accounts add the same ID, after all the ID will be public onchain, so it
///   is important for approvers to verify the PAIRING between account and ID.
/// - ANY account with the `APPROVER` role can review the added ID against the
///   records in the system referenced by the ID. IF the ID is valid then the
///   `approve` function should be called by the approver.
/// - ANY account with the `BANNER` role can veto either an add OR a prior
///   approval. In the case of a false positive, i.e. where an account was
///   mistakenly approved, an appeal can be made to a banner to update the
///   status. Bad accounts SHOULD BE BANNED NOT REMOVED. When an account is
///   removed, its onchain state is once again open for the attacker to
///   resubmit a new fraudulent session ID and potentially be reapproved.
///   Once an account is banned, any attempt by the account holder to change
///   their session ID, or an approver to approve will be rejected. Downstream
///   consumers of a `State` MUST check for an existing ban.
///   - ANY account with the `REMOVER` role can scrub the `State` from an
///   account. Of course, this is a blockchain so the state changes are all
///   still visible to full nodes and indexers in historical data, in both the
///   onchain history and the event logs for each state change. This allows an
///   account to appeal to a remover in the case of a MISTAKEN BAN or also in
///   the case of a MISTAKEN ADD (e.g. wrong ID value), effecting a
///   "hard reset" at the contract storage level.
///
/// Banning some account with an invalid session is NOT required. It is
/// harmless for an added session to remain as `Status.Added` indefinitely.
/// For as long as no approver decides to approve some invalid added session it
/// MUST be treated as equivalent to a ban by downstream contracts.
///
/// Rain uses standard Open Zeppelin `AccessControl` and is agnostic to how the
/// approver/remover/banner roles and associated admin roles are managed.
/// Ideally the more credibly neutral qualified parties assigend to each role
/// for each `Verify` contract the better. This improves the censorship
/// resistance of the verification process and the responsiveness of the
/// end-user experience.
///
/// Ideally the admin account assigned at deployment would renounce their admin
/// rights after establishing a more granular and appropriate set of accounts
/// with each specific role.
contract Verify is AccessControl {

    /// Any state never held is UNINITIALIZED.
    /// Note that as per default evm an unset state is 0 so always check the
    /// `addedSince` block on a `State` before trusting an equality check on
    /// any other block number.
    /// (i.e. removed or never added)
    uint32 constant public UNINITIALIZED = uint32(-1);

    /// Emitted when a session ID is first associated with an account.
    event Add(address indexed account, uint256 indexed id);
    /// Emitted when a previously added account is approved.
    event Approve(address indexed account);
    /// Emitted when an added or approved account is banned.
    event Ban(address indexed account);
    /// Emitted when an account is scrubbed from blockchain state.
    event Remove(address indexed account);

    /// Admin role for `APPROVER`.
    bytes32 public constant APPROVER_ADMIN = keccak256("APPROVER_ADMIN");
    /// Role for `APPROVER`.
    bytes32 public constant APPROVER = keccak256("APPROVER");

    /// Admin role for `REMOVER`.
    bytes32 public constant REMOVER_ADMIN = keccak256("REMOVER_ADMIN");
    /// Role for `REMOVER`.
    bytes32 public constant REMOVER = keccak256("REMOVER");

    /// Admin role for `BANNER`.
    bytes32 public constant BANNER_ADMIN = keccak256("BANNER_ADMIN");
    /// Role for `BANNER`.
    bytes32 public constant BANNER = keccak256("BANNER");

    // Account => State
    mapping (address => State) public states;

    /// Defines RBAC logic for each role under Open Zeppelin.
    constructor (address admin_) public {
        _setRoleAdmin(APPROVER, APPROVER_ADMIN);
        _setupRole(APPROVER_ADMIN, admin_);
        _setRoleAdmin(REMOVER, REMOVER_ADMIN);
        _setupRole(REMOVER_ADMIN, admin_);
        _setRoleAdmin(BANNER, BANNER_ADMIN);
        _setupRole(BANNER_ADMIN, admin_);

        // This is at the end of the constructor because putting it at the
        // start seems to break the source map from the compiler 🙈
        require(admin_ != address(0), "0_ACCOUNT");
    }

    /// Typed accessor into states.
    function state(address account_) external view returns (State memory) {
        return states[account_];
    }

    /// Derives a single `Status` from a `State` and a reference block number.
    function statusAtBlock(State calldata state_, uint32 blockNumber)
        external
        pure
        returns (Status)
    {
        // The state hasn't even been added so is picking up block zero as the
        // evm fallback value. In this case if we checked other blocks using
        // a `<=` equality they would incorrectly return `true` always due to
        // also having a `0` fallback value.
        if (state_.addedSince == 0) {
            return Status.Nil;
        }
        // Banned takes priority over everything.
        else if (state_.bannedSince <= blockNumber) {
            return Status.Banned;
        }
        // Approved takes priority over added.
        else if (state_.approvedSince <= blockNumber) {
            return Status.Approved;
        }
        // Added is lowest priority.
        else if (state_.addedSince <= blockNumber) {
            return Status.Added;
        }
        // The `addedSince` block is after `blockNumber` so `Status` is nil
        // relative to `blockNumber`.
        else {
            return Status.Nil;
        }
    }

    // An account adds their own verification session `id_`.
    // Internally `msg.sender` is used as delegated `add` is not supported.
    function add(uint256 id_) external {
        // Accounts may NOT change their ID once added.
        // This restriction is the main reason delegated add is not supported
        // as it would lead to griefing.
        // A mistaken add requires an appeal to a REMOVER to restart the
        // process OR a new `msg.sender` (i.e. different wallet address).
        require(id_ != 0, "0_ID");
        // The awkward < 1 here is to silence slither complaining about
        // equality checks against `0`. The intent is to ensure that
        // `addedSince` is not already set before we set it.
        require(states[msg.sender].addedSince < 1, "PRIOR_ADD");
        states[msg.sender] = State(
            id_,
            uint32(block.number),
            UNINITIALIZED,
            UNINITIALIZED
        );
        emit Add(msg.sender, id_);
    }

    // A `REMOVER` can scrub state mapping from an account.
    // A malicious account MUST be banned rather than removed.
    // Removal is useful to reset the whole process in case of some mistake.
    function remove(address account_) external {
        require(account_ != address(0), "0_ADDRESS");
        require(hasRole(REMOVER, msg.sender), "ONLY_REMOVER");
        delete(states[account_]);
        emit Remove(account_);
    }

    // An `APPROVER` can review an added session ID and approve the account.
    function approve(address account_) external {
        require(account_ != address(0), "0_ADDRESS");
        require(hasRole(APPROVER, msg.sender), "ONLY_APPROVER");
        // In theory we should also check the `addedSince` is lte the current
        // `block.number` but in practise no code path produces a future
        // `addedSince`.
        require(states[account_].addedSince > 0, "NOT_ADDED");
        require(
            states[account_].approvedSince == UNINITIALIZED,
            "PRIOR_APPROVE"
        );
        require(
            states[account_].bannedSince == UNINITIALIZED,
            "PRIOR_BAN"
        );
        states[account_].approvedSince = uint32(block.number);
        emit Approve(account_);
    }

    // A `BANNER` can ban an added OR approved account.
    function ban(address account_) external {
        require(account_ != address(0), "0_ADDRESS");
        require(hasRole(BANNER, msg.sender), "ONLY_BANNER");
        // In theory we should also check the `addedSince` is lte the current
        // `block.number` but in practise no code path produces a future
        // `addedSince`.
        require(states[account_].addedSince > 0, "NOT_ADDED");
        require(
            states[account_].bannedSince == UNINITIALIZED,
            "PRIOR_BAN"
        );
        states[account_].bannedSince = uint32(block.number);
        emit Ban(account_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.6.12;

import { Factory } from "../factory/Factory.sol";
import { Verify } from "./Verify.sol";

/// @title VerifyFactory
/// @notice Factory for creating and deploying `Verify` contracts.
contract VerifyFactory is Factory {

    /// @inheritdoc Factory
    function _createChild(
        bytes calldata data_
    ) internal virtual override returns(address) {
        (address admin_) = abi.decode(data_, (address));
        Verify verify_ = new Verify(admin_);
        return address(verify_);
    }

    /// Typed wrapper for `createChild` with admin address.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param admin_ `address` of the `Verify` admin.
    /// @return New `Verify` child contract address.
    function createChild(address admin_) external returns(address) {
        return this.createChild(abi.encode(admin_));
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { TierUtil } from "../libraries/TierUtil.sol";
import { ValueTier } from "./ValueTier.sol";
import { ITier } from "./ITier.sol";
import "./ReadOnlyTier.sol";

/// @title ERC20BalanceTier
/// @notice `ERC20BalanceTier` inherits from `ReadOnlyTier`.
///
/// There is no internal accounting, the balance tier simply reads the balance
/// of the user whenever `report` is called.
///
/// `setTier` always fails.
///
/// There is no historical information so each tier will either be `0x00000000`
/// or `0xFFFFFFFF` for the block number.
///
/// @dev The `ERC20BalanceTier` simply checks the current balance of an erc20
/// against tier values. As the current balance is always read from the erc20
/// contract directly there is no historical block data.
/// All tiers held at the current value will be 0x00000000 and tiers not held
/// will be 0xFFFFFFFF.
/// `setTier` will error as this contract has no ability to write to the erc20
/// contract state.
///
/// Balance tiers are useful for:
/// - Claim contracts that don't require backdated tier holding
///   (be wary of griefing!).
/// - Assets that cannot be transferred, so are not eligible for
///   `ERC20TransferTier`.
/// - Lightweight, realtime checks that encumber the tiered address
///   as little as possible.
contract ERC20BalanceTier is ReadOnlyTier, ValueTier {
    IERC20 public immutable erc20;

    /// @param erc20_ The erc20 token contract to check the balance
    /// of at `report` time.
    /// @param tierValues_ 8 values corresponding to minimum erc20
    /// balances for `Tier.ONE` through `Tier.EIGHT`.
    constructor(IERC20 erc20_, uint256[8] memory tierValues_)
        public
        ValueTier(tierValues_)
    {
        erc20 = erc20_;
    }

    /// Report simply truncates all tiers above the highest value held.
    /// @inheritdoc ITier
    function report(address account_) public view override returns (uint256) {
        return TierUtil.truncateTiersAbove(
            uint(ITier.Tier.ZERO),
            valueToTier(erc20.balanceOf(account_))
        );
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import "./ReadOnlyTier.sol";

/// @title NeverTier
/// @notice `NeverTier` inherits from `ReadOnlyTier`.
///
/// Never returns any tier, i.e. `0xFFFFFFFF` for every address and tier.
///
/// @dev `NeverTier` is intended as a primitive for combining tier contracts.
///
/// As the name implies:
/// - `NeverTier` is `ReadOnlyTier` and so can never call `setTier`.
/// - `report` is always `uint256(-1)` as every tier is unobtainable.
contract NeverTier is ReadOnlyTier {
    /// Every tier in the report is unobtainable.
    /// @inheritdoc ITier
    function report(address) public override view returns (uint256) {
        return uint256(-1);
    }
}

// SPDX-License-Identifier: CAL

pragma solidity 0.6.12;

import "./ReadOnlyTier.sol";

/// @title AlwaysTier
/// @notice `AlwaysTier` inherits from `ReadOnlyTier`.
///
/// Always returns every tier, i.e. `0x00000000` for every address and tier.
///
/// @dev `AlwaysTier` is intended as a primitive for combining tier contracts.
///
/// As the name implies:
/// - `AlwaysTier` is `ReadOnlyTier` and so can never call `setTier`.
/// - `report` is always `0x00000000` for every tier and every address.
contract AlwaysTier is ReadOnlyTier {
    /// Every address is always every tier.
    /// @inheritdoc ITier
    function report(address) public override view returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}