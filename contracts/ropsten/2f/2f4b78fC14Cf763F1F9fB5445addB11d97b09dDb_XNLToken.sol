/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// File: @openzeppelin/contracts/utils/Context.sol

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
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

// File: @openzeppelin/contracts/security/Pausable.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



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
	constructor (string memory name_, string memory symbol_) {
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
}

// File: @openzeppelin/contracts/access/Ownable.sol



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
	constructor (address __owner) {
		_owner = __owner;
		emit OwnershipTransferred(address(0), _owner);
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

// File: contracts/VerifiedAccount.sol



pragma solidity 0.8.3;



abstract contract VerifiedAccount is ERC20, Ownable {

	mapping(address => bool) private _isRegistered;

	constructor () {
		// The smart contract starts off registering itself, since address is known.
		registerAccount();
	}

	event AccountRegistered(address indexed account);

	/**
	 * This registers the calling wallet address as a known address. Operations that transfer responsibility
	 * may require the target account to be a registered account, to protect the system from getting into a
	 * state where administration or a large amount of funds can become forever inaccessible.
	 */
	function registerAccount() public {
		_isRegistered[msg.sender] = true;
		emit AccountRegistered(msg.sender);
	}

	function isRegistered(address account) public view returns (bool) {
		return _isRegistered[account];
	}

	function _accountExists(address account) internal view returns (bool) {
		return account == msg.sender || _isRegistered[account];
	}

	modifier onlyExistingAccount(address account) {
		require(_accountExists(account), "account not registered");
		_;
	}

	modifier onlyOwnerOrSelf(address account) {
		require(owner() == _msgSender() || msg.sender == account, "onlyOwnerOrSelf");
		_;
	}

	// =========================================================================
	// === Safe ERC20 methods
	// =========================================================================

	function safeTransfer(address to, uint256 value) public onlyExistingAccount(to) returns (bool) {
		if(value == 0) return false;
		require(transfer(to, value), "error in transfer");
		return true;
	}

	function safeApprove(address spender, uint256 value) public onlyExistingAccount(spender) returns (bool) {
		require(approve(spender, value), "error in approve");
		return true;
	}

	function safeTransferFrom(address from, address to, uint256 value) public onlyExistingAccount(to) returns (bool) {
		if(value == 0) return false;
		require(transferFrom(from, to, value), "error in transferFrom");
		return true;
	}


	// =========================================================================
	// === Safe ownership transfer
	// =========================================================================

	/**
	 * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
	function transferOwnership(address newOwner) public override onlyExistingAccount(newOwner) onlyOwner {
		super.transferOwnership(newOwner);
	}
}

// File: contracts/IERC20Vestable.sol



pragma solidity 0.8.3;

interface IERC20Vestable {

	function grantVestingTokens(
		address beneficiary,
		uint256 totalAmount,
		uint256 vestingAmount,
		uint32 startDay,
		uint32 duration,
		uint32 cliffDuration,
		uint32 interval
	) external returns (bool ok);

	function today() external view returns (uint32 dayNumber);

	function vestingForAccountAsOf(
		address grantHolder,
		uint32 onDayOrToday
	)
	external
	view
	returns (
		uint256 amountVested,
		uint256 amountNotVested,
		uint256 amountOfGrant,
		uint32 vestStartDay,
		uint32 cliffDuration,
		uint32 vestDuration,
		uint32 vestIntervalDays
	);

	function vestingAsOf(uint32 onDayOrToday) external view returns (
		uint256 amountVested,
		uint256 amountNotVested,
		uint256 amountOfGrant,
		uint32 vestStartDay,
		uint32 cliffDuration,
		uint32 vestDuration,
		uint32 vestIntervalDays
	);

	event VestingScheduleCreated(
		address indexed vestingLocation,
		uint32 cliffDuration,
		uint32 indexed duration,
		uint32 interval);

	event VestingTokensGranted(
		address indexed beneficiary,
		uint256 indexed vestingAmount,
		uint32 startDay,
		address vestingLocation,
		address indexed grantor);
}

// File: contracts/ERC20Vestable.sol



pragma solidity 0.8.3;




/**
 * @title Contract for grantable ERC20 token vesting schedules
 *
 * @notice Adds to an ERC20 support for grantor wallets, which are able to grant vesting tokens to
 *   beneficiary wallets, following per-wallet custom vesting schedules.
 *
 * @dev Contract which gives subclass contracts the ability to act as a pool of funds for allocating
 *   tokens to any number of other addresses. Token grants support the ability to vest over time in
 *   accordance a predefined vesting schedule. A given wallet can receive no more than one token grant.
 *
 *   Tokens are transferred from the pool to the recipient at the time of grant, but the recipient
 *   will only able to transfer tokens out of their wallet after they have vested. Transfers of non-
 *   vested tokens are prevented.
 *
 *   Two types of toke grants are supported:
 *   - Irrevocable grants, intended for use in cases when vesting tokens have been issued in exchange
 *     for value, such as with tokens that have been purchased in an ICO.
 *   - Revocable grants, intended for use in cases when vesting tokens have been gifted to the holder,
 *     such as with employee grants that are given as compensation.
 */
abstract contract ERC20Vestable is ERC20, IERC20Vestable, VerifiedAccount {

	// Date-related constants for sanity-checking dates to reject obvious erroneous inputs
	// and conversions from seconds to days and years that are more or less leap year-aware.
	uint32 private constant THOUSAND_YEARS_DAYS = 365243;                   /* See https://www.timeanddate.com/date/durationresult.html?m1=1&d1=1&y1=2000&m2=1&d2=1&y2=3000 */
	uint32 private constant TEN_YEARS_DAYS = THOUSAND_YEARS_DAYS / 100;     /* Includes leap years (though it doesn't really matter) */
	uint32 private constant SECONDS_PER_DAY = 24 * 60 * 60;                 /* 86400 seconds in a day */
	uint32 private constant JAN_1_3000_DAYS = 4102444800;  /* Wednesday, January 1, 2100 0:00:00 (GMT) (see https://www.epochconverter.com/) */

	struct vestingSchedule {
		bool isValid;               /* true if an entry exists and is valid */
		uint32 cliffDuration;       /* Duration of the cliff, with respect to the grant start day, in days. */
		uint32 duration;            /* Duration of the vesting schedule, with respect to the grant start day, in days. */
		uint32 interval;            /* Duration in days of the vesting interval. */
	}

	struct tokenGrant {
		bool isActive;              /* true if this vesting entry is active and in-effect entry. */
		uint32 startDay;            /* Start day of the grant, in days since the UNIX epoch (start of day). */
		address vestingLocation;    /* Address of wallet that is holding the vesting schedule. */
		address grantor;            /* Grantor that made the grant */
		uint256 amount;             /* Total number of tokens that vest. */
	}

	mapping(address => vestingSchedule) private _vestingSchedules;
	mapping(address => tokenGrant) private _tokenGrants;

	// =========================================================================
	// === Methods for administratively creating a vesting schedule for an account.
	// =========================================================================

	/**
	 * @dev This one-time operation permanently establishes a vesting schedule in the given account.
     *
     * For standard grants, this establishes the vesting schedule in the beneficiary's account.
     *
     * @param vestingLocation = Account into which to store the vesting schedule. Can be the account
     *   of the beneficiary (for one-off grants) or the account of the grantor (for uniform grants
     *   made from grant pools).
     * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
     * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
     * @param interval = Number of days between vesting increases.
     *   be revoked (i.e. tokens were purchased).
     */
	function _setVestingSchedule(
		address vestingLocation,
		uint32 cliffDuration,
		uint32 duration,
		uint32 interval
	) internal returns (bool) {

		// Check for a valid vesting schedule given (disallow absurd values to reject likely bad input).
		require(
			duration > 0 && duration <= TEN_YEARS_DAYS
			&& cliffDuration < duration
			&& interval >= 1,
			"invalid vesting schedule"
		);

		// Make sure the duration values are in harmony with interval (both should be an exact multiple of interval).
		require(
			duration % interval == 0 && cliffDuration % interval == 0,
			"invalid cliff/duration for interval"
		);

		// Create and populate a vesting schedule.
		_vestingSchedules[vestingLocation] = vestingSchedule(
			true,cliffDuration, duration, interval
		);

		// Emit the event and return success.
		emit VestingScheduleCreated(
			vestingLocation,
			cliffDuration, duration, interval);
		return true;
	}

	function _hasVestingSchedule(address account) internal view returns (bool) {
		return _vestingSchedules[account].isValid;
	}

	// =========================================================================
	// === Token grants (general-purpose)
	// === Methods to be used for administratively creating one-off token grants with vesting schedules.
	// =========================================================================

	/**
	 * @dev Immediately grants tokens to an account, referencing a vesting schedule which may be
     * stored in the same account (individual/one-off) or in a different account (shared/uniform).
     *
     * @param beneficiary = Address to which tokens will be granted.
     * @param totalAmount = Total number of tokens to deposit into the account.
     * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
     * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
     *   (start of day). The startDay may be given as a date in the future or in the past, going as far
     *   back as year 2000.
     * @param vestingLocation = Account where the vesting schedule is held (must already exist).
     * @param grantor = Account which performed the grant. Also the account from where the granted
     *   funds will be withdrawn.
     */
	function _grantVestingTokens(
		address beneficiary,
		uint256 totalAmount,
		uint256 vestingAmount,
		uint32 startDay,
		address vestingLocation,
		address grantor
	)
	internal returns (bool)
	{
		// Make sure no prior grant is in effect.
		require(!_tokenGrants[beneficiary].isActive, "grant already exists");

		// Check for valid vestingAmount
		require(
			vestingAmount <= totalAmount && vestingAmount > 0
			&& startDay >= this.today() && startDay < JAN_1_3000_DAYS,
			"invalid vesting params");

		// Make sure the vesting schedule we are about to use is valid.
		require(_hasVestingSchedule(vestingLocation), "no such vesting schedule");

		// Transfer the total number of tokens from grantor into the account's holdings.
		_transfer(grantor, beneficiary, totalAmount);
		/* Emits a Transfer event. */

		// Create and populate a token grant, referencing vesting schedule.
		_tokenGrants[beneficiary] = tokenGrant(
			true/*isActive*/,
			startDay,
			vestingLocation, /* The wallet address where the vesting schedule is kept. */
			grantor,             /* The account that performed the grant (where revoked funds would be sent) */
			vestingAmount
		);

		// Emit the event and return success.
		emit VestingTokensGranted(beneficiary, vestingAmount, startDay, vestingLocation, grantor);
		return true;
	}

	/**
	 * @dev Immediately grants tokens to an address, including a portion that will vest over time
     * according to a set vesting schedule. The overall duration and cliff duration of the grant must
     * be an even multiple of the vesting interval.
     *
     * @param beneficiary = Address to which tokens will be granted.
     * @param totalAmount = Total number of tokens to deposit into the account.
     * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
     * @param startDay = Start day of the grant's vesting schedule, in days since the UNIX epoch
     *   (start of day). The startDay may be given as a date in the future or in the past, going as far
     *   back as year 2000.
     * @param duration = Duration of the vesting schedule, with respect to the grant start day, in days.
     * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in days.
     * @param interval = Number of days between vesting increases.
     *   be revoked (i.e. tokens were purchased).
     */
	function grantVestingTokens(
		address beneficiary,
		uint256 totalAmount,
		uint256 vestingAmount,
		uint32 startDay,
		uint32 duration,
		uint32 cliffDuration,
		uint32 interval
	) public onlyOwner override returns (bool) {
		// Make sure no prior vesting schedule has been set.
		require(!_tokenGrants[beneficiary].isActive, "grant already exists");

		// The vesting schedule is unique to this wallet and so will be stored here,
		require(_setVestingSchedule(beneficiary, cliffDuration, duration, interval), "error in establishing a vesting schedule");

		// Issue grantor tokens to the beneficiary, using beneficiary's own vesting schedule.
		require(_grantVestingTokens(beneficiary, totalAmount, vestingAmount, startDay, beneficiary, msg.sender), "error in granting tokens");

		return true;
	}

	/**
	 * @dev This variant only grants tokens if the beneficiary account has previously self-registered.
     */
	function safeGrantVestingTokens(
		address beneficiary,
		uint256 totalAmount,
		uint256 vestingAmount,
		uint32 startDay,
		uint32 duration,
		uint32 cliffDuration,
		uint32 interval
	) public onlyOwner onlyExistingAccount(beneficiary) returns (bool) {

		return grantVestingTokens(
			beneficiary, totalAmount, vestingAmount,
			startDay, duration, cliffDuration, interval);
	}


	// =========================================================================
	// === Check vesting.
	// =========================================================================

	/**
	 * @dev returns the day number of the current day, in days since the UNIX epoch.
     */
	function today() public view override returns (uint32) {
		return uint32(block.timestamp / SECONDS_PER_DAY);
	}

	function _effectiveDay(uint32 onDayOrToday) internal view returns (uint32) {
		return onDayOrToday == 0 ? today() : onDayOrToday;
	}

	/**
	 * @dev Determines the amount of tokens that have not vested in the given account.
     *
     * The math is: not vested amount = vesting amount * (end date - on date)/(end date - start date)
     *
     * @param grantHolder = The account to check.
     * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     */
	function _getNotVestedAmount(address grantHolder, uint32 onDayOrToday) internal view returns (uint256) {
		tokenGrant storage grant = _tokenGrants[grantHolder];
		vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
		uint32 onDay = _effectiveDay(onDayOrToday);

		// If there's no schedule, or before the vesting cliff, then the full amount is not vested.
		if (!grant.isActive || onDay < grant.startDay + vesting.cliffDuration)
		{
			// None are vested (all are not vested)
			return grant.amount;
		}
		// If after end of vesting, then the not vested amount is zero (all are vested).
		else if (onDay >= grant.startDay + vesting.duration)
		{
			// All are vested (none are not vested)
			return uint256(0);
		}
		// Otherwise a fractional amount is vested.
		else
		{
			// Compute the exact number of days vested.
			uint32 daysVested = onDay - grant.startDay;
			// Adjust result rounding down to take into consideration the interval.
			// Examples for vesting interval = 30 days
			// Example 1 - daysVested = 15: (15 / 30) * 30 = 0 * 30 = 0;
			// Example 2 - daysVested = 30: (30 / 30) * 30 = 1 * 30 = 30;
			// Example 3 - daysVested = 65: (65 / 30) * 30 = 2 * 30 = 60;
			uint32 effectiveDaysVested = (daysVested / vesting.interval) * vesting.interval;

			// Compute the fraction vested from schedule using 224.32 fixed point math for date range ratio.
			// Note: This is safe in 256-bit math because max value of X billion tokens = X*10^27 wei, and
			// typical token amounts can fit into 90 bits. Scaling using a 32 bits value results in only 125
			// bits before reducing back to 90 bits by dividing. There is plenty of room left, even for token
			// amounts many orders of magnitude greater than mere billions.
			// uint256 vested = grant.amount.mul(effectiveDaysVested).div(vesting.duration);
			uint256 vested = (grant.amount * effectiveDaysVested) / vesting.duration;
			return grant.amount - vested;
		}
	}

	/**
	 * @dev Computes the amount of funds in the given account which are available for use as of
     * the given day. If there's no vesting schedule then 0 tokens are considered to be vested and
     * this just returns the full account balance.
     *
     * The math is: available amount = total funds - notVestedAmount.
     *
     * @param grantHolder = The account to check.
     * @param onDay = The day to check for, in days since the UNIX epoch.
     */
	function _getAvailableAmount(address grantHolder, uint32 onDay) internal view returns (uint256) {
		uint256 totalTokens = balanceOf(grantHolder);
		return totalTokens - _getNotVestedAmount(grantHolder, onDay);
	}

	/*
	 * @dev returns all information about the grant's vesting as of the given day
     * for the given account. Only callable by the account holder or a grantor, so
     * this is mainly intended for administrative use.
     *
     * @param grantHolder = The address to do this for.
     * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     * @return = A tuple with the following values:
     *   amountVested = the amount out of vestingAmount that is vested
     *   amountNotVested = the amount that is vested (equal to vestingAmount - vestedAmount)
     *   amountOfGrant = the amount of tokens subject to vesting.
     *   vestStartDay = starting day of the grant (in days since the UNIX epoch).
     *   vestDuration = grant duration in days.
     *   cliffDuration = duration of the cliff.
     *   vestIntervalDays = number of days between vesting periods.
     */
	function vestingForAccountAsOf(
		address grantHolder,
		uint32 onDayOrToday
	)
	public
	view
	override
	onlyOwnerOrSelf(grantHolder)
	returns (
		uint256 amountVested,
		uint256 amountNotVested,
		uint256 amountOfGrant,
		uint32 vestStartDay,
		uint32 vestDuration,
		uint32 cliffDuration,
		uint32 vestIntervalDays
	)
	{
		tokenGrant storage grant = _tokenGrants[grantHolder];
		vestingSchedule storage vesting = _vestingSchedules[grant.vestingLocation];
		uint256 notVestedAmount = _getNotVestedAmount(grantHolder, onDayOrToday);
		uint256 grantAmount = grant.amount;

		return (
		grantAmount - notVestedAmount,
		notVestedAmount,
		grantAmount,
		grant.startDay,
		vesting.duration,
		vesting.cliffDuration,
		vesting.interval
		);
	}

	/*
	 * @dev returns all information about the grant's vesting as of the given day
     * for the current account, to be called by the account holder.
     *
     * @param onDayOrToday = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     * @return = A tuple with the following values:
     *   amountVested = the amount out of vestingAmount that is vested
     *   amountNotVested = the amount that is vested (equal to vestingAmount - vestedAmount)
     *   amountOfGrant = the amount of tokens subject to vesting.
     *   vestStartDay = starting day of the grant (in days since the UNIX epoch).
     *   cliffDuration = duration of the cliff.
     *   vestDuration = grant duration in days.
     *   vestIntervalDays = number of days between vesting periods.
     */
	function vestingAsOf(uint32 onDayOrToday) public override view returns (
		uint256 amountVested,
		uint256 amountNotVested,
		uint256 amountOfGrant,
		uint32 vestStartDay,
		uint32 vestDuration,
		uint32 cliffDuration,
		uint32 vestIntervalDays
	)
	{
		return vestingForAccountAsOf(msg.sender, onDayOrToday);
	}

	/**
	 * @dev returns true if the account has sufficient funds available to cover the given amount,
     *   including consideration for vesting tokens.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     * @param onDay = The day to check for, in days since the UNIX epoch.
     */
	function _fundsAreAvailableOn(address account, uint256 amount, uint32 onDay) internal view returns (bool) {
		return (amount <= _getAvailableAmount(account, onDay));
	}

	/**
	 * @dev Modifier to make a function callable only when the amount is sufficiently vested right now.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     */
	modifier onlyIfFundsAvailableNow(address account, uint256 amount) {
		// Distinguish insufficient overall balance from insufficient vested funds balance in failure msg.
		require(_fundsAreAvailableOn(account, amount, today()),
			balanceOf(account) < amount ? "insufficient funds" : "insufficient vested funds");
		_;
	}

	// =========================================================================
	// === Overridden ERC20 functionality
	// =========================================================================

	/**
	 * @dev Methods transfer() and approve() require an additional available funds check to
     * prevent spending held but non-vested tokens. Note that transferFrom() does NOT have this
     * additional check because approved funds come from an already set-aside allowance, not from the wallet.
     */
	function transfer(address to, uint256 value) public override onlyIfFundsAvailableNow(msg.sender, value) returns (bool) {
		return super.transfer(to, value);
	}

	/**
	 * @dev Additional available funds check to prevent spending held but non-vested tokens.
     */
	function approve(address spender, uint256 value) public override virtual onlyIfFundsAvailableNow(msg.sender, value) returns (bool) {
		return super.approve(spender, value);
	}
}

// File: contracts/XNLToken.sol



pragma solidity 0.8.3;


/**
 * @title XNLToken
 * @dev Implementation of ERC20Token using Standard token from OpenZeppelin library
 * with ability to pause transfers, approvals and set vesting period for owner until ownership is renounced.
 * All token are assigned to owner.
 */

contract XNLToken is ERC20Vestable, Pausable {

	uint public INITIAL_SUPPLY = 100000000 * (uint(10) ** 18); // 100,000,000 XNL

	constructor(address __owner) Ownable(__owner) ERC20("Chronicle","XNL") {
		_mint(__owner, INITIAL_SUPPLY);
	}

	function pause() onlyOwner() external  {
		_pause();
	}

	function unpause() onlyOwner() external {
		_unpause();
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override whenNotPaused {
		require(to != address(this), "ERC20: transfer to the contract address");
		super._beforeTokenTransfer(from, to, amount);
	}

	function approve(address spender, uint256 amount) public virtual override whenNotPaused returns (bool) {
		return super.approve(spender, amount);
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual override whenNotPaused returns (bool)  {
		return super.increaseAllowance(spender, addedValue);
	}

	function decreaseAllowance(address spender, uint256 addedValue) public virtual override whenNotPaused returns (bool)  {
		return super.decreaseAllowance(spender, addedValue);
	}

}