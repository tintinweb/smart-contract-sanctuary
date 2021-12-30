// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IDoubleDiceToken.sol";

/**
 *                            ________
 *                 ________  / o   o /\
 *                /     o /\/   o   /o \
 *               /   o   /  \o___o_/o   \
 *              /_o_____/o   \     \   o/
 *              \ o   o \   o/  o   \ o/
 *  ______     __\ o   o \  /\_______\/       _____     ____    ____    ____   _______
 * |  __  \   /   \_o___o_\/ |  _ \  | |     |  ___|   |  _ \  |_  _|  / ___| |   ____|
 * | |  \  | | / \ | | | | | | |_| | | |     | |_      | | \ |   ||   | /     |  |
 * | |   | | | | | | | | | | |  _ <  | |     |  _|     | | | |   I|   | |     |  |__
 * |D|   |D| |O\_/O| |U|_|U| |B|_|B| |L|___  |E|___    |D|_/D|  _I|_  |C\___  |EEEEE|
 * |D|__/DD|  \OOO/   \UUU/  |BBBB/  |LLLLL| |EEEEE|   |DDDD/  |IIII|  \CCCC| |EE|____
 * |DDDDDD/  ================================================================ |EEEEEEE|
 *
 * @title DoubleDice DODI token contract
 * @author DoubleDice Team <[email protected]>
 * @custom:security-contact [email protected]
 * @notice ERC-20 token extended with special yield-distribution functionality.
 *
 * A supply of 10 billion DODI was minted at contract creation:
 * - 6.3 billion were minted to an initial token holder `initTokenHolder`
 * - 3.7 billion were minted to a reserved `UNDISTRIBUTED_YIELD_ACCOUNT` address
 *
 * It is not possible to mint further DODI beyond the 10 billion DODI minted at contract creation.
 *
 * The DODI on the `UNDISTRIBUTED_YIELD_ACCOUNT` is controlled by the `owner()` of this contract.
 * The `owner()` may choose to:
 * - Distribute a portion or all of the remaining undistributed yield to token holders via `distributeYield`
 * - Burn a portion or all of the remaining undistributed yield via `burnUndistributedYield`,
 *   thus decreasing the total DODI supply
 *
 * The `owner()` of this contract has no special powers besides the ability
 * to distribute or burn the 3.7 billion DODI yield.
 *
 * When an amount of yield is released from `UNDISTRIBUTED_YIELD_ACCOUNT` to be distributed to token
 * holders, it is transferred to a second reserved `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT` address.
 * Token holders may then call `claimYield()` to transfer their received yield
 * from `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT` to themselves.
 *
 * Different operations affect `balanceOf(account)` and `unclaimedYieldOf(account)` as follows:
 * - `transfer` and `transferFrom` alter `balanceOf(account)`,
 *   but without altering `unclaimedYieldOf(account)`.
 * - Unless `account` is explicitly excluded from a distribution, `distributeYield` alters `unclaimedYieldOf(account)`,
 *   but without altering `balanceOf(account)`.
 * - `claimYield` and `claimYieldFor` alter both `balanceOf(account)` and `unclaimedYieldOf(account)`,
 *   but without altering their sum `balanceOf(account) + unclaimedYieldOf(account)`
 */
contract DoubleDiceToken is
    IDoubleDiceToken,
    ERC20("DoubleDice Token", "DODI"),
    Ownable
{
    /// @notice Account holding the portion of the 3.7 billion DODI that have not yet been distributed or burned by `owner()`
    address constant public UNDISTRIBUTED_YIELD_ACCOUNT = 0xD0D1000000000000000000000000000000000001;

    /// @notice Account holding yield that has been distributed, but not yet claimed by its recipient
    address constant public UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT = 0xd0D1000000000000000000000000000000000002;

    function _isReservedAccount(address account) internal pure returns (bool) {
        return account == UNDISTRIBUTED_YIELD_ACCOUNT || account == UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT;
    }

    /// @dev Holds unclaimed-yield state for a specific account
    struct AccountEntry {
        /// @dev The amount of unclaimed tokens for this account, at the instant it was last updated in
        /// either `_captureUnclaimedYield()`, or `claimYieldFor()` or `distributeYield()`.
        uint256 capturedUnclaimedYield;

        /// @dev The value of `_factor` at the instant `capturedUnclaimedYield` was last updated
        uint256 factorAtCapture;
    }

    /// @dev The state for an account is stored in this mapping in conjunction with
    /// the ERC-20 balance, which is managed in the base ERC20 contract
    mapping(address => AccountEntry) internal _entries;

    /// @dev Sets the precision at which calculations are performed in this contract.
    /// The larger the value of `ONE`, the more miniscule the rounding errors in this contract.
    /// With `ONE` set to 1e47, it can be proven that the largest computation in this contract
    /// will never result in uint256 overflow, given the following 3 assumptions hold true.
    uint256 constant internal ONE = 1e47;

    /// @dev Assumption 1 of 3: Holds true because the contract was created with 10 billion * 1e18 tokens
    uint256 constant private _ASSUMED_MAX_INIT_TOTAL_SUPPLY = 20e9 * 1e18;

    /// @dev Assumption 2 of 3: Holds true because 10 / (10 - 3.7) = 1.5873 <= 2
    uint256 constant private _ASSUMED_MAX_INIT_TOTAL_TO_INIT_CIRCULATING_SUPPLY_RATIO = 2;

    /// @dev Assumption 3 of 3: Holds true because it is `require`-d in `distributeYield()`
    uint256 constant private _ASSUMED_MIN_TOTAL_CIRCULATING_TO_EXCLUDED_CIRCULATING_SUPPLY_RATIO = 2;

    function _checkOverflowProtectionAssumptionsConstructor(uint256 initTotalSupply, uint256 totalYieldAmount) internal pure {
        require(initTotalSupply <= _ASSUMED_MAX_INIT_TOTAL_SUPPLY, "Broken assumption");
        uint256 initCirculatingSupply = initTotalSupply - totalYieldAmount;
        // C/T = initCirculatingSupply / initTotalSupply >= 0.5
        require(initCirculatingSupply * _ASSUMED_MAX_INIT_TOTAL_TO_INIT_CIRCULATING_SUPPLY_RATIO >= initTotalSupply, "Broken assumption");
    }

    function _checkOverflowProtectionAssumptionsDistributeYield(uint256 totalCirculatingSupply, uint256 excludedCirculatingSupply) internal pure {
        // epsilon = excludedCirculatingSupply / totalCirculatingSupply <= 0.5
        require((excludedCirculatingSupply * _ASSUMED_MIN_TOTAL_CIRCULATING_TO_EXCLUDED_CIRCULATING_SUPPLY_RATIO) <= totalCirculatingSupply, "Broken assumption");
    }

    /// @dev Yield distribution to all accounts is recorded by increasing (eagerly) this contract-wide `_factor`,
    /// and received yield is acknowledged by an `account` by reconciling (lazily) its `_entries[account]`
    /// with this contract-wide `_factor`.
    uint256 internal _factor;

    /// @notice Returns `balanceOf(account) + unclaimedYieldOf(account)`
    /// @custom:reverts-with "Reserved account" if called for `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    function balancePlusUnclaimedYieldOf(address account) public view returns (uint256) {
        require(!_isReservedAccount(account), "Reserved account");

        AccountEntry storage entry = _entries[account];
        return ((ONE + _factor) * (balanceOf(account) + entry.capturedUnclaimedYield)) / (ONE + entry.factorAtCapture);
    }

    /// @notice Returns the total yield token amount claimable by `account`.
    /// @dev The tokens received by `account` during a yield-distribution do not appear immediately on `balanceOf(account)`,
    /// but they appear instantly on `unclaimedYieldOf(account)` and `balancePlusUnclaimedYieldOf(account)`.
    /// Transferring tokens from `account` to another account `other` does not affect
    /// `unclaimedYieldOf(account)` or `unclaimedYieldOf(other)`.
    /// @custom:reverts-with "Reserved account" if called for `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    function unclaimedYieldOf(address account) public view returns (uint256) {
        return balancePlusUnclaimedYieldOf(account) - balanceOf(account);
    }

    /// @notice Emitted every time the yield claimable by `account` increases by a non-zero amount `byAmount`.
    /// After `claimYieldFor(account)` is called, the sum of all yield ever claimed for `account`,
    /// (which equals the total amount ever transferred from `UNCLAIMED_DISTRIBUTED_YIELD` to `account`),
    /// should equal the sum of `byAmount` over all `UnclaimedYieldIncrease` events ever emitted for `account`.
    event UnclaimedYieldIncrease(address indexed account, uint256 byAmount);

    /// @dev The value `unclaimedYieldOf(account)` always reflects  exact amount of yield that is claimable by `account`.
    /// If there is a discrepancy between `unclaimedYieldOf(account)` and the value present in `_entries[account].capturedUnclaimedYield`,
    /// then this function rectifies that discrepancy while maintaining `balanceOf(account)` and `unclaimedYieldOf(account)` constant.
    function _captureUnclaimedYield(address account) internal {
        AccountEntry storage entry = _entries[account];

        // _factor can only increase, never decrease
        assert(entry.factorAtCapture <= _factor);

        if (entry.factorAtCapture == _factor) {
            // No yield distribution since last calculation
            return;
        }

        // Recalculate *before* `factorAtCapture` is updated,
        // because `unclaimedYieldOf` depends on its value pre-update
        uint256 newUnclaimedYield = unclaimedYieldOf(account);

        // Update *after* `unclaimedYieldOf` has been calculated
        entry.factorAtCapture = _factor;

        // Finally update `capturedUnclaimedYield`
        uint256 increase = newUnclaimedYield - entry.capturedUnclaimedYield;
        if (increase > 0) {
            entry.capturedUnclaimedYield = newUnclaimedYield;
            emit UnclaimedYieldIncrease(account, increase);
        }
    }

    constructor(
        uint256 initTotalSupply,
        uint256 totalYieldAmount,
        address initTokenHolder
    ) {
        require(totalYieldAmount <= initTotalSupply, "Invalid params");

        _checkOverflowProtectionAssumptionsConstructor(initTotalSupply, totalYieldAmount);

        // invoke ERC._mint directly to bypass yield corrections
        ERC20._mint(UNDISTRIBUTED_YIELD_ACCOUNT, totalYieldAmount);
        ERC20._mint(initTokenHolder, initTotalSupply - totalYieldAmount);
    }


    /// @dev Overriding `_transfer` affects `transfer` and `transferFrom`.
    /// `_mint` and `_burn` could be overridden in a similar fashion, but are not,
    /// as all mints and burns are done directly via `ERC20._mint` and `ERC20._burn`
    /// so as to bypass yield correction.
    /// @custom:reverts-with "Transfer from reserved account" if `from` is `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    /// @custom:reverts-with "Transfer to reserved account" if `to` is `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(!_isReservedAccount(from), "Transfer from reserved account");
        require(!_isReservedAccount(to), "Transfer to reserved account");
        _captureUnclaimedYield(from);
        _captureUnclaimedYield(to);
        // invoke ERC._transfer directly to bypass yield corrections
        ERC20._transfer(from, to, amount);
    }

    event YieldDistribution(uint256 yieldDistributed, address[] excludedAccounts);

    /// @notice Distribute yield to all token holders except `excludedAccounts`
    /// @custom:reverts-with "Ownable: caller is not the owner" if called by an account that is not `owner()`
    /// @custom:reverts-with "Duplicate/unordered account" if `excludedAccounts` contains 0-account,
    /// is not in ascending order, or contains duplicate addresses
    /// @custom:reverts-with "Reserved account" if `excludedAccounts` contains `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    /// @custom:reverts-with "Broken assumption" if the total `balancePlusUnclaimedYieldOf` for all `excludedAccounts`
    /// exceeds half the circulating supply (which is `totalSupply() - balanceOf(UNDISTRIBUTED_YIELD_ACCOUNT)`).
    /// @custom:emits-event UnclaimedYieldIncrease if operation results in an increase in `capturedUnclaimedYield`
    /// for one of the `excludedAccounts`
    /// @custom:emits-event Transfer(UNDISTRIBUTED_YIELD_ACCOUNT, UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, yieldDistributed)
    /// @custom:emits-event YieldDistribution(amount, excludedAccounts)
    function distributeYield(uint256 amount, address[] calldata excludedAccounts) external onlyOwner {
        // ERC20 functions reject mints/transfers to zero-address,
        // so zero-address can never have balance that we want to exclude from calculations.
        address prevExcludedAccount = 0x0000000000000000000000000000000000000000;

        uint256 excludedCirculatingSupply = 0;
        for (uint256 i = 0; i < excludedAccounts.length; i++) {
            address account = excludedAccounts[i];

            require(prevExcludedAccount < account, "Duplicate/unordered account");
            prevExcludedAccount = account; // prepare for next iteration immediately

            require(!_isReservedAccount(account), "Reserved account");

            // The excluded account itself might have a stale `capturedUnclaimedYield` value,
            // so it is brought up to date with pre-distribution `_factor`
            _captureUnclaimedYield(account);

            excludedCirculatingSupply += balancePlusUnclaimedYieldOf(account);
        }

        // totalSupply = balanceOfBefore(UNDISTRIBUTED_YIELD) + (sumOfBalanceOfExcluded + balanceOf(UNCLAIMED_DISTRIBUTED_YIELD) + sumOfBalanceOfIncludedBefore)
        // totalSupply = balanceOfBefore(UNDISTRIBUTED_YIELD) + (            excludedCirculatingSupply        +        includedCirculatingSupplyBefore         )
        // totalSupply = balanceOfBefore(UNDISTRIBUTED_YIELD) + (                               totalCirculatingSupplyBefore                                   )
        uint256 totalCirculatingSupplyBefore = totalSupply() - balanceOf(UNDISTRIBUTED_YIELD_ACCOUNT);

        _checkOverflowProtectionAssumptionsDistributeYield(totalCirculatingSupplyBefore, excludedCirculatingSupply);

        // includedCirculatingSupplyBefore = sum(balancePlusUnclaimedYieldOf(account) for account in includedAccounts)
        uint256 includedCirculatingSupplyBefore = totalCirculatingSupplyBefore - excludedCirculatingSupply;

        // totalSupply = (balanceBeforeOf(UNDISTRIBUTED_YIELD)         ) + (           includedCirculatingSupplyBefore) + (excludedCirculatingSupply)
        // totalSupply = (balanceBeforeOf(UNDISTRIBUTED_YIELD) - amount) + (amount  +  includedCirculatingSupplyBefore) + (excludedCirculatingSupply)
        // totalSupply = (     balanceAfterOf(UNDISTRIBUTED_YIELD)     ) + (    includedCirculatingSupplyAfter        ) + (excludedCirculatingSupply)
        uint256 includedCirculatingSupplyAfter = includedCirculatingSupplyBefore + amount;

        _factor = ((ONE + _factor) * includedCirculatingSupplyAfter) / includedCirculatingSupplyBefore - ONE;

        for (uint256 i = 0; i < excludedAccounts.length; i++) {
            // Force this account to "miss out on" this distribution
            // by "fast-forwarding" its `_factor` to the new value
            // without actually changing its balance or unclaimedYield
            _entries[excludedAccounts[i]].factorAtCapture = _factor;
        }

        // invoke ERC._transfer directly to bypass yield corrections
        ERC20._transfer(UNDISTRIBUTED_YIELD_ACCOUNT, UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, amount);

        emit YieldDistribution(amount, excludedAccounts);
    }

    /// @notice Burn an `amount` of undistributed yield.
    /// @custom:reverts-with "Ownable: caller is not the owner" if called by an account that is not `owner()`
    /// @custom:reverts-with "ERC20: burn amount exceeds balance" if `amount` exceeds `balanceOf(UNDISTRIBUTED_YIELD_ACCOUNT)`
    /// @custom:emits-event "Transfer(UNDISTRIBUTED_YIELD_ACCOUNT, address(0), amount)"
    function burnUndistributedYield(uint256 amount) external onlyOwner {
        // invoke ERC._transfer directly to bypass yield corrections
        ERC20._burn(UNDISTRIBUTED_YIELD_ACCOUNT, amount);
    }

    /// @notice Yield received by `account` from a distribution will be reflected in `balanceOf(account)`
    /// only after `claimYieldFor(account)` has been called.
    /// @custom:reverts-with "Reserved account" if called for `UNDISTRIBUTED_YIELD_ACCOUNT` or `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT`
    /// @custom:emits-event UnclaimedYieldIncrease if operation results in an increase in `capturedUnclaimedYield`
    /// @custom:emits-event Transfer(UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, account, unclaimedYieldOf(account))
    function claimYieldFor(address account) public {

        // Without this check (and without the check in balancePlusUnclaimedYieldOf),
        // it would be possible for anyone to claim yield for one of the reserved accounts,
        // and this would destabilize the accounting system.
        require(!_isReservedAccount(account), "Reserved account");

        // Not entirely necessary, because ERC20._transfer will block 0-account
        // from receiving any balance, but it is stopped in its tracks anyway.
        require(account != address(0), "Zero account");

        _captureUnclaimedYield(account);
        AccountEntry storage entry = _entries[account];

        // balanceOf(account) += entry.capturedUnclaimedYield
        // entry.capturedUnclaimedYield -= entry.capturedUnclaimedYield
        // => (balanceOf(account) + entry.capturedUnclaimedYield) is invariant
        ERC20._transfer(UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT, account, entry.capturedUnclaimedYield);
        entry.capturedUnclaimedYield = 0;

        // A `Transfer` event from `UNCLAIMED_DISTRIBUTED_YIELD_ACCOUNT` always signifies a yield-claim,
        // so no special "YieldClaim" event is emitted
    }

    /// @notice Calls `claimYieldFor` for the caller.
    function claimYield() external override {
        claimYieldFor(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDoubleDiceToken is IERC20 {

    function claimYield() external;

}

// SPDX-License-Identifier: MIT

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