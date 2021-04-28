pragma solidity 0.6.12;

contract Migrations {
  address public owner;

  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor()  public{
    owner = msg.sender;
  }


  function setCompleted(uint completed)external restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) external {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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