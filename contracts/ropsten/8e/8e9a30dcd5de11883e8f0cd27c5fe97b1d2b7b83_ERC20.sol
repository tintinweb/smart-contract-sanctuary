// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";

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


contract ERC20 is Ownable, IERC20, IERC20Metadata {


    mapping (address => uint256) private _balances;

    // 地址锁仓数额
    mapping (address => uint256) private _lockedBalances;

    // 释放间隔时间(单位:秒)，结束时间为释放时间+锁仓时长
    mapping (address => uint256) private _releaseInterval;

    // 锁仓释放数量，多次释放时值不为0，单次锁仓值为0
    mapping (address => uint256) private _releaseAmount;

    // 释放开始时间(具体到某天某日某时某分某秒)
    mapping (address => uint256) private _releaseStartTimer;

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
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 initialSupply) Ownable() {
        _name = name_;
        _symbol = symbol_;
        _mint(_msgSender(), initialSupply);
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

    function lockedBalance() public view virtual returns (uint256) {
        return _lockedBalances[_msgSender()];
    }

    function releaseAmount() public view virtual returns(uint256) {
        return _releaseAmount[_msgSender()];
    }

    function releaseStart() public view virtual returns(uint256) {
        return _releaseStartTimer[_msgSender()];
    }

    function releaseInterval() public view virtual returns(uint256) {
        return _releaseInterval[_msgSender()];
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

    function transfertoLocked(address recipient, uint256 amount, uint256 lockedAmount, uint256 rInterval, uint256 rAmount, uint256 startTime) public virtual returns (bool) {
        require(owner() == _msgSender(), "ERC20: caller is not the owner");
        _transferLocked(_msgSender(), recipient, amount, lockedAmount, rInterval, rAmount, startTime);
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

    function updateLock(address account, uint256 startTime, uint256 rInterval, uint256 rAmount) public virtual returns (bool) {
        _updateLock(_msgSender(), account, startTime, rInterval, rAmount);
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

        uint256 availableBalance = _computeAvailableBalancesAndUpdate(sender);
        uint256 senderBalance = _balances[sender];
        require(availableBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    function _updateLock(address sender, address account, uint256 startTime, uint256 rInterval, uint256 rAmount) internal virtual {
        require(sender == owner(), "ERC20: caller is not the owner");
        require(account != address(0), "ERC20: update to the zero address");
        
        uint256 locked = _lockedBalances[account];
        require(locked > 0, "ERC20: The account is not locked");

        if (startTime > block.timestamp + 600) {
            _releaseStartTimer[account] = startTime;
        }

        if (rAmount > 0 && rAmount < locked) {
            _releaseAmount[account] = rAmount;
        }

        if (rInterval > 600) {
            _releaseInterval[account] = rInterval;
        }
        

        emit Transfer(account, address(0), 0);
    }

    function _computeAvailableBalancesAndUpdate(address sender) internal virtual returns (uint256){
        uint256 releaseTime = _releaseStartTimer[sender];
        uint256 balance = _balances[sender];
        uint256 locked = _lockedBalances[sender];

        if (locked > 0) { //账户锁仓金额
            if (block.timestamp < releaseTime) { //计算是否开始释放
                return balance - locked;
            } else {
                uint256 nowTime = block.timestamp;
                uint256 release = 0;
                while(releaseTime <= nowTime && releaseTime > 0) {
                    release += _releaseAmount[sender];
                    releaseTime += _releaseInterval[sender];
                    if (locked <= release) { //已经释放完成
                        delete _lockedBalances[sender];
                        delete _releaseStartTimer[sender];
                        return balance;
                    }
                }

                _releaseStartTimer[sender] = releaseTime;
                _lockedBalances[sender] = locked - release;

                return balance - locked + release;
            }
        }

        return balance;
    }

    function _transferLocked(address sender, address recipient, uint256 amount, uint256 lockedAmount, uint256 rInterval, uint256 rAmount, uint256 startTime) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(rInterval > 600, "ERC20: The release time interval is reduced to 10 minutes");
        require(lockedAmount <= amount, "ERC20: locked amount exceeds transfer balance");
        require(rAmount <= lockedAmount, "ERC20: release amount exceeds locked amount");
        require(block.timestamp < startTime, "ERC20: The start time cannot be before the block output time");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 balance = _lockedBalances[recipient];

        require(balance == 0, "ERC20: The receiving account has been locked");

        uint256 availableBalance = _computeAvailableBalancesAndUpdate(sender);
        uint256 senderBalance = _balances[sender];
        require(availableBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
        _lockedBalances[recipient] = lockedAmount; 
        _releaseAmount[recipient] = rAmount;
        _releaseInterval[recipient] = rInterval;
        _releaseStartTimer[recipient] = startTime;
    
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
        require(owner() == _msgSender(), "ERC20: caller is not the owner");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _computeAvailableBalancesAndUpdate(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _burnFromAccount(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(owner() == _msgSender(), "ERC20: caller is not the owner");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 balance = _balances[account];
        uint256 accountBalance = _computeAvailableBalancesAndUpdate(account);
        // require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        if (balance <= amount) {
            delete _balances[account];
            delete _lockedBalances[account];
            delete _releaseStartTimer[account];
            delete _releaseInterval[account];
            delete _releaseAmount[account];
        } else {
            _balances[account] = balance - amount;
            if (accountBalance < amount) {
                _lockedBalances[account] = balance - amount;
            }
        }
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
     }
}