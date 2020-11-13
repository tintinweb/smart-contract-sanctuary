pragma solidity ^0.6.12;

import "./ERC20Mintable.sol";

contract MockPrizePool {

  IERC20 public payment;

  constructor (IERC20 _payment) public {
    payment = _payment;
  }

  function depositTo(address to, uint256 amount, address controlledToken, address referrer) external {
    payment.transferFrom(msg.sender, address(this), amount);
    ERC20Mintable(controlledToken).mint(to, amount);
  }

}
