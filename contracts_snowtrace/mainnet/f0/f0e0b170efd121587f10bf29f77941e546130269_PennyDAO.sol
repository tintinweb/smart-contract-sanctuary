/**
 *Submitted for verification at snowtrace.io on 2021-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  // function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  // function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  // function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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

contract ERC20 is IERC20 {
  mapping(address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) public allowance;

  uint256 public totalSupply;

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = allowance[sender][msg.sender];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
      _approve(sender, msg.sender, currentAllowance - amount);
    }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = allowance[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = balanceOf[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      balanceOf[sender] = senderBalance - amount;
    }
    balanceOf[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    totalSupply += amount;
    balanceOf[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = balanceOf[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      balanceOf[account] = accountBalance - amount;
    }
    totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    allowance[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal {}
}

contract PennyDAO is ERC20 {
  string public constant name = "Penny DAO";
  string public constant symbol = "APNY";
  uint8 public constant decimals = 18;

  address public owner;
  address public treasury;
  uint256 public price;
  bool public isOpen;

  event PriceUpdated(uint256);

  constructor(address _treasury, uint256 _price) {
    owner = msg.sender;
    treasury = _treasury;
    price = _price;
  }

  function onlyOwner() internal view {
    require(msg.sender == owner);
  }

  function onlyOpen() internal view {
    require(isOpen);
  }

  function updatePrice() internal {
    price = (address(this).balance * ((1e18 * 10100) / 10000)) / totalSupply;
    emit PriceUpdated(price);
  }

  function mint() external payable {
    onlyOpen();
    require(msg.value > 0);
    uint256 amount = (msg.value * 1e18) / price;
    _mint(msg.sender, amount);
    updatePrice();
  }

  function redeem(uint256 amount) external {
    onlyOpen();
    _burn(msg.sender, amount);
    uint256 value = (amount * ((price * 10000) / 10100)) / 1e18;
    uint256 fee = value / 100;
    payable(treasury).transfer(fee);
    payable(msg.sender).transfer(value - fee);
    updatePrice();
  }

  function setTreasury(address _treasury) external {
    onlyOwner();
    treasury = _treasury;
  }

  function setOpen(bool _isOpen) external {
    onlyOwner();
    isOpen = _isOpen;
  }

  function setOwner(address _owner) external {
    onlyOwner();
    owner = _owner;
  }
}