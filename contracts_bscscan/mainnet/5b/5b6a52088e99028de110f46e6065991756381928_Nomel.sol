/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Nomel {

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    string private name_;
    string private symbol_;
    uint256 private totalSupply_;
    uint256 private totalBurn_;

    /// @dev Emitted when `value` tokens are moved from one account (`from`) to
    /// another (`to`). Note that `value` may be zero.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by
    /// a call to {approve}. `value` is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _supply){
      name_ = _name;
      symbol_ = _symbol;
      totalSupply_ = _supply * 1e18;
      balances[msg.sender] = _supply * 1e18;
      emit Transfer(address(0), msg.sender, _supply * 1e18);
    }

    /// @dev Returns the name of the token.
    function name() public view returns (string memory) {
        return name_;
    }

    /// @dev Returns the symbol of the token, usually a shorter version of the
    /// name.
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256) {
      return totalSupply_;
    }

    /// @dev Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256){
      return balances[account];
    }

    /// @dev Returns the amount of tokens burned.
    function getTotalBurned() external view returns (uint256){
      return totalBurn_;
    }

    /// @dev Moves `amount` tokens from the caller's account to `recipient`.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// Emits a {Transfer} event.
    function transfer(address recipient, uint256 amount) external returns (bool){
      require(amount <= balances[msg.sender], "ERC20: Insufficient balance");
      require(recipient != address(0), "ERC20: Cannot send to zero address");

      balances[msg.sender] -= amount;
      balances[recipient] += amount;

      emit Transfer(msg.sender, recipient, amount);
      return true;
    }

    /// @dev Moves `amount` tokens from `sender` to `recipient` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// Emits a {Transfer} event.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
      require(sender != address(0), "ERC20: Cannot receive from zero address");
      require(recipient != address(0), "ERC20: Cannot send to zero address");
      require(amount <= balances[sender], "ERC20: Insufficient balance");
      require(allowances[sender][msg.sender] >= amount, "ERC20: Insufficient allowance");

      balances[sender] -= amount;
      balances[recipient] += amount;

      emit Transfer(sender, recipient, amount);
      return true;
    }

    /// @dev Returns the remaining number of tokens that `spender` will be
    /// allowed to spend on behalf of `owner` through {transferFrom}. This is
    /// zero by default.
    /// This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256){
      return allowances[owner][spender];
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk
    /// that someone may use both the old and the new allowance by unfortunate
    /// transaction ordering. One possible solution to mitigate this race
    /// condition is to first reduce the spender's allowance to 0 and set the
    /// desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// Emits an {Approval} event.
    function approve(address spender, uint256 amount) external returns (bool){
      require(spender != address(0), "ERC20: Spender cannot be zero address");

      allowances[msg.sender][spender] = amount;

      emit Approval(msg.sender, spender, amount);
      return true;
    }

    /// @dev Increase the amount of tokens that an owner allowed to a spender.
    /// approve should be called when allowed_[_spender] == 0. To increment
    /// allowed value is better to use this function to avoid 2 calls (and wait until
    /// the first transaction is mined)
    /// @param spender The address which will spend the funds.
    /// @param addedValue The amount of tokens to increase the allowance by.
    function increaseAllowance(
      address spender,
      uint256 addedValue
    )
      public
      returns (bool)
    {
      require(spender != address(0));

      allowances[msg.sender][spender] = (
        allowances[msg.sender][spender] + addedValue
        );

      emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
      return true;
    }

    /// @dev Decrease the amount of tokens that an owner allowed to a spender.
    /// approve should be called when allowed_[_spender] == 0. To decrement
    /// allowed value is better to use this function to avoid 2 calls (and wait until
    /// the first transaction is mined)
    /// @param spender The address which will spend the funds.
    /// @param subtractedValue The amount of tokens to decrease the allowance by.
    function decreaseAllowance(
      address spender,
      uint256 subtractedValue
    )
      public
      returns (bool)
    {
      require(spender != address(0));

      allowances[msg.sender][spender] = (
        allowances[msg.sender][spender] - subtractedValue
        );

      emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
      return true;
    }

    /// @dev Reduces the 'msg.sender' balance and 'totalSupply' by 'amount'.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// Emits a {Transfer} event.
    /// @param amount is number of tokens to be removed from supply.
    function burn(uint256 amount) external returns (bool) {
      require(amount <= balances[msg.sender], "NOMEL: Insufficient balance to burn");
      require(amount > 0, "NOMEL: Cannot burn zero tokens");

      balances[msg.sender] -= amount;
      totalSupply_ -= amount;
      totalBurn_ += amount;

      emit Transfer(msg.sender, address(0), amount);
      return true;
    }
}