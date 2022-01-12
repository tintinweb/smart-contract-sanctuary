/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.0;

/**======================================== Contract Context ========================================*/
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 * If for some reason msg.sender becomes obsolete, it's just a matter of changing
 * one line instead of multiple lines throughout multiple contracts (and possibly forgetting about some).
 * ex: msg.sender => tx.origin...
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deployingreturn msg.data;
  // an instance of this contract, which should be used via inheritance.
  constructor() {}

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}


/**======================================== Contract Ownable ========================================*/
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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
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
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
      return _msgSender() == _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal virtual {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _owner = newOwner;
    emit OwnershipTransferred(_owner, newOwner);
  }
}


/**======================================== Interface IBEP20 ========================================*/
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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


/**======================================== Contract IBEP20 =========================================*/
contract BEP20 is Context, Ownable, IBEP20 {
  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 internal _totalSupply;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    uint256 initialSupply_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    _totalSupply = initialSupply_;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns token total supply
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Returns token decimals
   */
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns token symbol
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns token name
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns token owner
   */
  function getOwner() public view virtual override returns (address) {
    return owner();
  }

  /**
   * @dev Returns amount of tokens owner by 'account'
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Move 'amount' tokens from the caller's account to 'recipient'
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev Returns the remaining number of tokens that 'spender' will be allowed to spend on behalf of owner
   */
  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev Sets 'amount' as the allowance of 'spender' over the caller's tokens.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * Returns a boolean value indicating whether the operation succeesed
   */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
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
   * problems described in {BEP20-approve}.
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
    require(currentAllowance >= subtractedValue, "BEP20: decreased allowance bellow zero");
    unchecked {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    }
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   * This is internal function is equivalent to {transfer}, and can be used to
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
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   * This is internal function is equivalent to `approve`, and can be used to
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

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "BEP20: mint to the zero address");

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
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint amount) internal virtual {
    require(account != address(0), "BEP20: burn from zero account");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 _accountBalance = _balances[account];
    require(_accountBalance >= amount, "BEP20: burn amount exceeds balance");
    unchecked {
      _balances[account] -= amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
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
}


/**======================================= Contract Pausable ========================================*/
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context, BEP20 {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

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

    /**
     * @dev See {BEP20-_beforeTokenTransfer}
     *
     * Requirements:
     *
     * - the contract must not be paused
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!_paused, "Pausable: token transfer while paused");
    }
}


/**======================================= Contract Burnable ========================================*/
/**
 * @dev Extension of {BEP20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract Burnable is Context, BEP20 {

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {BEP20-_burn}.
   */
  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {BEP20-_burn} and {BEP20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public virtual {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }

}


/**======================================== Contract Blacklist ======================================*/
/**
 * @dev Extension of {ERC20} that allow block a number of user evil
 */
abstract contract Blacklist is Ownable, BEP20 {
  mapping(address => bool) public isBlacklisted;

  /**
   * @dev Emitted when an user added to blacklist
   */
  event AddedBlacklist(address user);

  /**
   * @dev Emitted when an user removed to blacklist
   */
  event RemovedBlacklist(address user);

  /**
   * @dev Emitted when balance of evil user destroyed
   */
  event DestroyedBlackFunds(address blacklistedUser, uint balance);

  /**
   * @dev Check an user address is in blacklist or not
   */
  function getBlacklistStatus(address user) external view returns (bool) {
    return isBlacklisted[user];
  }

  /**
   * @dev Add an address to blacklist
   */
  function addBlacklist(address evilUser) public onlyOwner {
    isBlacklisted[evilUser] = true;
    emit AddedBlacklist(evilUser);
  }

  /**
   * @dev Remove an address from blacklist
   */
  function removeBlacklist(address clearedUser) public onlyOwner {
    isBlacklisted[clearedUser] = false;
    emit RemovedBlacklist(clearedUser);
  }

  /**
   * @dev Destroy all balance of an evil user
   */
  function destroyBlackFunds(address blacklistedUser) public onlyOwner {
    require(isBlacklisted[blacklistedUser], "Blacklist: destroy fund of account not exist in blacklist");
    uint dirtyFunds = balanceOf(blacklistedUser);
    _balances[blacklistedUser] = 0;
    _totalSupply -= dirtyFunds;
    emit DestroyedBlackFunds(blacklistedUser, dirtyFunds);
  }

  /**
   * @dev See {ERC20-_beforeTokenTransfer}
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    require(!isBlacklisted[from] && !isBlacklisted[to], "Blacklist: account from/to is in blacklist");
  }
}


/**======================================= Contract KAYToken ========================================*/
contract KAYToken is Pausable, Burnable, Blacklist {

  /**
   * @dev {BEP20} token, including:
   *
   *  - Preminted initial supply
   *  - Ability for holders to burn (destroy) their tokens
   *  - Ability to token minting (creation)
   *  - Ability to stop all token transfers
   *
   * The account that deploys the contract will be allowed mint and pause smart contract
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    uint256 initialSupply_
  ) BEP20(name_, symbol_, decimals_, initialSupply_) {}

  /**
   * @dev Create `amount` new tokens to `to`
   *
   * See {BEP20-_mint}
   *
   * Requirements:
   *
   */
  function mint(uint256 amount) public onlyOwner returns(bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   */
  function pause() public onlyOwner virtual {
      _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   */
  function unpause() public onlyOwner virtual {
      _unpause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(BEP20, Pausable, Blacklist) {
    super._beforeTokenTransfer(from, to, amount);
  }
}