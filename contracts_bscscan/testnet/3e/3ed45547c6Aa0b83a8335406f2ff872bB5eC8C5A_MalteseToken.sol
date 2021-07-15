// SPDX-License-Identifier: Rhythm
pragma solidity ^0.8.0;

import "Context.sol";
import "IBEP20.sol";
import "Ownable.sol";

contract MalteseToken is Context, IBEP20, Ownable {

  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _excludeBalances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply = 10000 * 10**6 * 10**9;
  
  uint8 public _decimals = 9;
  string public _symbol = "MALT";
  string public _name = "Maltese Token";

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

  constructor() {

    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external override view returns (uint256) {
        if (_isExcluded[account]) return _excludeBalances[account];
        return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
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
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {

    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }
        
    return true;
  }

    function isExcluded(address account) external view returns (bool) {
        return _isExcluded[account];
    }
    
    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");

        if(_balances[account] > 0) {
            _excludeBalances[account] = _balances[account];
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _excludeBalances[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
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
  function _transfer(address sender, address recipient, uint256 amount) internal {

    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
        if (_isExcluded[sender]) {
            _excludeBalances[sender] = _excludeBalances[sender] - amount;
        }
    }
    
    _balances[recipient] += amount;
    if (_isExcluded[recipient]) {
        _excludeBalances[recipient] += amount;
    }
        
    emit Transfer(sender, recipient, amount);
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
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

    function _getCurrentSupply() private view returns(uint256) {

        uint256 tSupply = _totalSupply;
        
        for (uint256 i = 0; i < _excluded.length; i++) {
            tSupply = tSupply - _excludeBalances[_excluded[i]];
        }

        return tSupply;
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