/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

/// SPDX-License-Identifier: MIT
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

contract Vault {
  enum Permission {
    None,
    Liquidate,
    Partial,
    Full
  }

  uint public LIQUIDATION_TIME = 30 days;
  uint public ADD_USER_TIME = 10 days;

  mapping (address => Permission) users;
  mapping (address => uint) userActive;
  uint public nextLiquidation = type(uint).max;

  constructor(
    address[] memory fullUsers,
    address[] memory partialUsers,
    address[] memory liquidators
  ) {
    for (uint8 x = 0; x < fullUsers.length; x++) {
      users[fullUsers[x]] = Permission.Full;
    }
    for (uint8 x = 0; x < liquidators.length; x++) {
      users[liquidators[x]] = Permission.Liquidate;
    }
    for (uint8 x = 0; x < partialUsers.length; x++) {
      users[partialUsers[x]] = Permission.Partial;
    }
  }

  receive () external payable {}

  function requireActiveUser(address user, Permission perm) public view {
    require(users[user] >= perm);
    require(userActive[user] < block.timestamp);
  }

  function requireActiveLiquidation() public view {
    require(nextLiquidation < block.timestamp);
  }

  function addUser(address user, Permission perm) public {
    requireActiveUser(msg.sender, Permission.Partial);
    users[user] = perm;
    userActive[user] = block.timestamp + ADD_USER_TIME;
  }

  function removeUser(address user) public {
    requireActiveUser(msg.sender, Permission.Partial);
    users[user] = Permission.None;
    userActive[user] = 0;
  }

  function withdrawEther(uint amount, address destination) public {
    requireActiveUser(msg.sender, Permission.Full);
    (bool sent, ) = destination.call{value: amount}("");
    require(sent);
  }

  function withdrawToken(address token, uint amount, address destination) public {
    requireActiveUser(msg.sender, Permission.Full);
    require(IERC20(token).transfer(destination, amount));
  }

  function beginLiquidation() public {
    requireActiveUser(msg.sender, Permission.Liquidate);
    nextLiquidation = block.timestamp + LIQUIDATION_TIME;
  }

  function cancelLiquidation() public {
    requireActiveUser(msg.sender, Permission.Partial);
    nextLiquidation = type(uint).max;
  }

  function liquidateWithdrawEther(uint amount, address destination) public {
    requireActiveUser(msg.sender, Permission.Liquidate);
    requireActiveLiquidation();
    (bool sent, ) = destination.call{value: amount}("");
    require(sent);
  }

  function liquidateWithdrawToken(address token, uint amount, address destination) public {
    requireActiveUser(msg.sender, Permission.Liquidate);
    requireActiveLiquidation();
    require(IERC20(token).transfer(destination, amount));
  }

}