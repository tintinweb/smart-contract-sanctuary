pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

import "./SafeMath.sol";
import "./BEP20.sol";
import "./Ownable.sol";

contract Shit2 is BEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _minimumSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  uint8 private _burnPercentage;
  uint8 private _mgtPercentage;
  uint8 private _lpPercentage;
  uint8 private _donationPercentage;
  uint8 private _whaleProofingPercentage;
  address private _mgtAddress;
  address private _lpAddress;
  address private _donationAddress;
  bool private _isBurnActive;

  constructor() {
    _name = "Shit2";
    _symbol = "SHT2v1";
    _decimals = 9;
    _totalSupply = 10**9 * 10 ** uint256(_decimals);
    _minimumSupply = _totalSupply / 2;
    _burnPercentage = 2;
    _lpPercentage = 2;
    _mgtPercentage = 1;
    _whaleProofingPercentage = 5;
    _donationPercentage = 5;
    _balances[msg.sender] = _totalSupply;
    _mgtAddress = address(0);
    _lpAddress = address(0);
    _donationAddress = address(0);
    _isBurnActive = false;

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

  function setLpAddress(address account) external onlyOwner {
    _lpAddress = account;
  }

  function setMgtAddress(address account) external onlyOwner {
    _mgtAddress = account;
  }

  function setDonationAddress(address account) external onlyOwner {
    _donationAddress = account;
  }

  function activateBurn() external onlyOwner {
    _isBurnActive = true;
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

    if (_lpAddress != address(0)) {
      uint256 lpAmount = _balances[_lpAddress];
      require(amount <= lpAmount.mul(_whaleProofingPercentage).div(100), "Whale alert!");
    }

    uint256 remainingAmount = amount;
    (uint256 toBurn, uint256 toLp, uint256 toMgt, uint256 toDonation) = _calculateFees(amount);
    if (toBurn > 0 && _isBurnActive) {
      _burn(msg.sender, toBurn);
      remainingAmount = remainingAmount.sub(toBurn);
    }
    if (toLp > 0) {
      // Sending fee to liquidity pool
      _transfer(sender, _lpAddress, toLp);
      remainingAmount = remainingAmount.sub(toLp);
    }
    if (toMgt > 0) {
      // Sending fee to management
      _transfer(sender, _mgtAddress, toMgt);
      remainingAmount = remainingAmount.sub(toMgt);
    }
    if (toDonation > 0) {
      // Sending fee to management
      _transfer(sender, _donationAddress, toDonation);
      remainingAmount = remainingAmount.sub(toDonation);
    }
    _transfer(sender, recipient, remainingAmount);
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
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
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
    uint256 burnAmount,
    uint256 lpAmount,
    uint256 mgtAmount,
    uint donationAmount) {
    burnAmount = 0;
    if (_totalSupply > _minimumSupply) {
      burnAmount = amount.mul(_burnPercentage).div(100);
      uint256 availableBurn = _totalSupply.sub(_minimumSupply);
      if (burnAmount > availableBurn) {
        burnAmount = availableBurn;
      }
    }
    lpAmount = 0;
    if (_lpAddress != address(0)) {
      lpAmount = amount.mul(_lpPercentage).div(100);
    }
    mgtAmount = 0;
    if (_mgtAddress != address(0)) {
      mgtAmount = amount.mul(_mgtPercentage).div(100);
    }
    donationAmount = 0;
    if (_donationAddress != address(0)) {
      donationAmount = amount.mul(_donationPercentage).div(100);
    }
  }
}