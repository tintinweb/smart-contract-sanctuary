/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * All rights reserved Premium Block
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
    mapping (address => uint256) internal _balances;

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
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
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
    function decimals() external view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
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

contract PRB is ERC20 {
    
    // EVENTS TO BE EMITTED UPON LOCKS ARE APPLIED & REMOVED
    event LockApplied(address indexed account, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops);
    event LockRemoved(address indexed account);

    // INITIALIZE AN ERC20 TOKEN BASED ON THE OPENZEPPELIN VERSION
    constructor() ERC20("PREMIUM TEST", "PRT") {

        // INITIALLY MINT TOTAL SUPPLY TO CREATOR
        _mint(_msgSender(), 2000000 * (10 ** 18));
    }
    // REPRESENTS A LOCK WHICH MIGHT BE APPLIED ON AN ADDRESS
    struct Lock {
        uint256 tokenAmount;    // HOW MANY TOKENS ARE LOCKED
        uint32 hardLockUntil;   // UNTIL WHEN NO LOCKED TOKENS CAN BE ACCESSED
        uint32 softLockUntil;   // UNTIL WHEN LOCKED TOKENS CAN BE GRADUALLY RELEASED
        uint8 allowedHops;      // HOW MANY TRANSFERS LEFT WITH SAME LOCK PARAMS
        uint32 lastUnlock;      // LAST GRADUAL UNLOCK TIME (SOFTLOCK PERIOD)
        uint256 unlockPerSec;   // HOW MANY TOKENS ARE UNLOCKABLE EACH SEC FROM HL -> SL
    }

    // THIS MAPS LOCK PARAMS TO CERTAIN ADDRESSES WHICH RECEIVED LOCKED TOKENS
    mapping (address => Lock) private _locks;

    // RETURNS LOCK INFORMATION OF A GIVEN ADDRESS
    function lockOf(address account) external view virtual returns (Lock memory) {
        return _locks[account];
    }

    // RETURN THE BALANCE OF UNLOCKED AND LOCKED TOKENS COMBINED
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account] + _locks[account].tokenAmount;
    }

    // TRANSFER FUNCTION WITH LOCK PARAMETERS
    function transferLocked(address recipient, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops) external returns (bool) {

        // ONLY ONE LOCKED TRANSACTION ALLOWED PER RECIPIENT
        require(_locks[recipient].tokenAmount == 0, "Only one lock per address allowed!");

        // SENDER MUST HAVE ENOUGH TOKENS (UNLOCKED + LOCKED BALANCE COMBINED)
        require(_balances[_msgSender()] + _locks[_msgSender()].tokenAmount >= amount, "Transfer amount exceeds balance");

        // IF SENDER HAS ENOUGH UNLOCKED BALANCE, THEN LOCK PARAMS CAN BE CHOSEN
        if(_balances[_msgSender()] >= amount){

            // DEDUCT SENDER BALANCE
            _balances[_msgSender()] = _balances[_msgSender()] - amount;

            // APPLY LOCK
            return _applyLock(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        }

        // OTHERWISE REQUIRE THAT THE CHOSEN LOCK PARAMS ARE SAME / STRICTER (allowedHops) THAN THE SENDER'S
        require(
            hardLockUntil >= _locks[_msgSender()].hardLockUntil && 
            softLockUntil >= _locks[_msgSender()].softLockUntil && 
            allowedHops < _locks[_msgSender()].allowedHops
        );

        // IF SENDER HAS ENOUGH LOCKED BALANCE
        if(_locks[_msgSender()].tokenAmount >= amount){

            // DECREASE LOCKED BALANCE OF SENDER
            _locks[_msgSender()].tokenAmount = _locks[_msgSender()].tokenAmount - amount;

            // APPLY LOCK
            return _applyLock(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        }

        // IF NO CONDITIONS WERE MET SO FAR, DEDUCT FROM THE UNLOCKED BALANCE
        _balances[_msgSender()] = _balances[_msgSender()] - (amount - _locks[_msgSender()].tokenAmount);

        // THEN SPEND LOCKED BALANCE OF SENDER FIRST
        _locks[_msgSender()].tokenAmount = 0;

        // APPLY LOCK
        return _applyLock(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
    }

    // APPLIES LOCK TO RECIPIENT WITH SPECIFIED PARAMS AND EMITS A TRANSFER EVENT
    function _applyLock(address recipient, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops) private returns (bool) {

        // MAKE SURE THAT SOFTLOCK IS AFTER HARDLOCK
        require(softLockUntil > hardLockUntil, "SoftLock must be greater than HardLock!");

        // APPLY LOCK, EMIT TRANSFER EVENT
        _locks[recipient] = Lock(amount, hardLockUntil, softLockUntil, allowedHops, hardLockUntil, amount / (softLockUntil - hardLockUntil));
        emit LockApplied(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function lockedBalanceOf(address account) external view virtual returns (uint256) {
        return _locks[account].tokenAmount;
    }

    function unlockedBalanceOf(address account) external view virtual returns (uint256) {
        return _balances[account];
    }

    function unlockableBalanceOf(address account) public view virtual returns (uint256) {

        // IF THE HARDLOCK HAS NOT PASSED YET, THERE ARE NO UNLOCKABLE TOKENS
        if(block.timestamp < _locks[account].hardLockUntil) {
            return 0;
        }

        // IF THE SOFTLOCK PERIOD PASSED, ALL CURRENTLY TOKENS ARE UNLOCKABLE
        if(block.timestamp > _locks[account].softLockUntil) {
            return _locks[account].tokenAmount;
        }

        // OTHERWISE THE PROPORTIONAL AMOUNT IS UNLOCKABLE
        return (block.timestamp - _locks[account].lastUnlock) * _locks[account].unlockPerSec;
    }

    function unlock(address account) external returns (bool) {

        // CALCULATE UNLOCKABLE BALANCE
        uint256 unlockable = unlockableBalanceOf(account);

        // ONLY ADDRESSES OWNING LOCKED TOKENS AND BYPASSED HARDLOCK TIME ARE UNLOCKABLE
        require(unlockable > 0 && _locks[account].tokenAmount > 0 && block.timestamp > _locks[account].hardLockUntil, "No unlockable tokens!");

        // SET LAST UNLOCK TIME, DEDUCT FROM LOCKED BALANCE & CREDIT TO REGULAR BALANCE
        _locks[account].lastUnlock = uint32(block.timestamp);
        _locks[account].tokenAmount = _locks[account].tokenAmount - unlockable;
        _balances[account] = _balances[account] + unlockable;

        // IF NO MORE LOCKED TOKENS LEFT, REMOVE LOCK OBJECT FROM ADDRESS
        if(_locks[account].tokenAmount == 0){
            delete _locks[account];
            emit LockRemoved(account);
        }

        // UNLOCK SUCCESSFUL
        emit Transfer(account, account, unlockable);
        return true;
    }
}