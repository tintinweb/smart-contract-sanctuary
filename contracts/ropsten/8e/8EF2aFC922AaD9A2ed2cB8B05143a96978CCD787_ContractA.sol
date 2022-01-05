// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ContractA {
  address public admin;

  constructor(address _admin) {
    admin = payable(_admin);
  }

  // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}

  function getBalance() public view returns (uint) {
      return address(this).balance;
  }

  function testOutput(string memory inputString) public view returns (string memory) {
    return inputString;
  }

  //payableAmount is in wei, 0.5 eth is 0.5*10**18 or ether as 0.5 ether
  function payWinnerTest(address payable winnerAddress) payable public {
    require(msg.sender == admin, "This operation can only be performed by admin...");
    uint payOut = 0.1 ether;
    winnerAddress.transfer(payOut);
  }
}