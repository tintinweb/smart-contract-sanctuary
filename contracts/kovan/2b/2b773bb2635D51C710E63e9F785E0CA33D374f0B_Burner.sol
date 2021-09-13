// SPDX-License-Identifier: MIT
pragma solidity ^0.4.20;

// Modified from: https://ethereum.stackexchange.com/a/17617

contract Burner {
    uint256 public totalBurned;
    
    function Purge() public {
        // the caller of purge action receives 0.001% out of the
        // current balance.
        msg.sender.transfer(this.balance / 10000);
        assembly {
            mstore(0, 0x30ff)
            // transfer all funds to a new contract that will selfdestruct
            // and destroy all UBQ in the process.
            create(balance(address), 30, 2)
            pop
        }
    }
    
    function Burn() public payable {
        totalBurned += msg.value;
    }
}

{
  "libraries": {},
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}