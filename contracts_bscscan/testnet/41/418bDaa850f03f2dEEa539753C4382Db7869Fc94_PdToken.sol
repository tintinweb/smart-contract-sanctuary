pragma solidity 0.8.6;
// SPDX-License-Identifier: Unlicensed

import "./SafeMath.sol";
import "./BEP20.sol";
import "./Ownable.sol";

contract PdToken is BEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => bool) private _isExcludedFromFee;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _minimumSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  uint8 private _marketingPercentage;
  uint8 private _charityPercentage;
  uint8 private _devPercentage;

  address private _marketingAddress;
  address private _charityAddress;
  address private _devAddress;

  constructor(address marketingAddress, address charityAddress) {
    _name = "PdToken";
    _symbol = "PdTokenV1";
    _decimals = 9;
    _totalSupply = 10**9 * 10 ** uint256(_decimals);
    _minimumSupply = _totalSupply / 2;

    _marketingPercentage = 4;
    _charityPercentage = 1;
    _devPercentage = 2;

    _balances[msg.sender] = _totalSupply;

    _marketingAddress = marketingAddress;
    _charityAddress = charityAddress;
    _devAddress = owner();

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view override returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }


  function setMarketingAddress(address account) external onlyOwner {
    _marketingAddress = account;
  }

  function setCharityAddress(address account) external onlyOwner {
    _charityAddress = account;
  }

  function setDevAddress(address account) external onlyOwner {
    _devAddress = account;
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function isExcludedFromFee(address account) public view returns(bool) {
    return _isExcludedFromFee[account];
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
    _transferWithFees(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function removeFeatures() external onlyOwner {
    _charityAddress = address(0);
    _marketingAddress = address(0);
    _devAddress = address(0);
  }

  function addFeatures(address marketingAddress, address charityAddress, address devAddress) external onlyOwner {
    _marketingAddress = marketingAddress;
    _charityAddress = charityAddress;
    _devAddress = devAddress;
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
    _transferWithFees(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
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
  function _transferWithFees(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");

    if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
      _transfer(sender, recipient, amount);
    } else {
      uint256 remainingAmount = amount;
      (uint256 toMarketing, uint256 toCharity, uint256 toDev) = _calculateFees(amount);

      if (toMarketing > 0) {
        // Sending fee to management
        _transfer(sender, _marketingAddress, toMarketing);
        remainingAmount = remainingAmount.sub(toMarketing);
      }
      if (toCharity > 0) {
        // Sending fee to management
        _transfer(sender, _charityAddress, toCharity);
        remainingAmount = remainingAmount.sub(toCharity);
      }

      if (toDev > 0) {
        _transfer(sender, _devAddress, toDev);
        remainingAmount = remainingAmount.sub(toDev);
      }

      _transfer(sender, recipient, remainingAmount);
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
    require(recipient != address(0), "BEP20: transfer to zero address");

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

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

  function _calculateFees(uint256 amount) internal view returns (
    uint256 marketingAmount,
    uint256 charityAmount,
    uint256 devAmount) {
    marketingAmount = 0;
    if (_marketingAddress != address(0)) {
      marketingAmount = amount.mul(_marketingPercentage).div(100);
    }
    charityAmount = 0;
    if (_charityAddress != address(0)) {
      charityAmount = amount.mul(_charityPercentage).div(100);
    }
    devAmount = 0;
    if (_devAddress != address(0)) {
      devAmount = amount.mul(_devPercentage).div(100);
    }
  }
}