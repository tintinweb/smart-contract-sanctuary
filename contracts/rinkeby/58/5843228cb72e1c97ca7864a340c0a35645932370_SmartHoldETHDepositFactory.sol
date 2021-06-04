/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract SmartHoldETHDepositFactory {
  address[] public deposits;

  function createDeposit(uint _lockForDays, uint _minimumPrice) payable public {
    address newDeposit = address(new SmartHoldETHDeposit(
      msg.sender,
      _lockForDays,
      _minimumPrice
    ));

    payable(newDeposit).transfer(msg.value);
    deposits.push(newDeposit);
  }

  function getDeposits() public view returns (address[] memory) {
    return deposits;
  }
}

contract SmartHoldETHDeposit {
  address public owner = msg.sender;
  uint public depositedAt;
  uint public lockForDays;
  uint public minimumPrice;

  modifier restricted() {
    require(msg.sender == owner, "Access denied!");
    _;
  }

  constructor(address _creator, uint _lockForDays, uint _minimumPrice) {
    owner = _creator;
    lockForDays = _lockForDays;
    minimumPrice = _minimumPrice;
  }

  function widthraw() public restricted {

  }

  receive() external payable {}

  function getTime() view public returns(uint) {
    return block.timestamp;
  }
}