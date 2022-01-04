// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ContractA {
  address public admin;

  constructor(address _admin) {
    admin = _admin;
  }

  function payWinnerTest(address winnerAddress) payable public {
    require(msg.sender == admin, "This operation can only be performed by admins...");
    payable(winnerAddress).transfer(0.01 ether);
  }
}