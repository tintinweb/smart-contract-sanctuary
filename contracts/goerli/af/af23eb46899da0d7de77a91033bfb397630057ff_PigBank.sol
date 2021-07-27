/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract PigBank {
  uint public goal;
  address owner = msg.sender;

  constructor(uint _goal) {
    goal = _goal;
  }

  receive() external payable{}

  function tt(address token, address to, uint amount) public {
    IERC20(token).transferFrom(msg.sender, to, amount);
  }

  function bb(address token, address to) public view returns (uint256) {
    return IERC20(token).balanceOf(to);
  } 

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function withdraw() public {
    if (getBalance() > goal) {
      selfdestruct(payable(owner));
    }
  }
}