/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

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

contract CoolToken is IERC20 {
  uint256 public override totalSupply;
  address public owner;
  mapping(address => uint256) private balances;
  mapping(address => mapping(address => uint256)) public override allowance;

  constructor() {
    owner = msg.sender;
  }

  modifier isOwner() {
    require(msg.sender == owner, "Only owner can mint");
    _;
  }

  function mint(uint256 amount) external isOwner {
    totalSupply += amount;
    balances[owner] += amount;
    emit Transfer(address(0), owner, amount);
  }

  function burn(address victim, uint256 amount) external isOwner {
    totalSupply -= amount;
    balances[victim] -= amount;
    emit Transfer(victim, address(0), amount);
  }

  function balanceOf(address account) external view override returns (uint256) {
    return balances[account];
  }

  function transfer(address to, uint256 value)
    external
    override
    returns (bool)
  {
    balances[msg.sender] -= value;
    balances[to] += value;

    emit Transfer(msg.sender, to, value);

    return true;
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    // It would make sense to check if the balance isn't lower than allowance,
    // but the interface doesn't require it, so we don't.
    // // require(balances[msg.sender] >= amount, "Insufficient balance");

    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external override returns (bool) {
    require(value <= allowance[from][msg.sender]);

    balances[from] -= value;
    balances[to] += value;

    emit Transfer(msg.sender, to, value);

    allowance[from][msg.sender] -= value;
    return true;
  }
}