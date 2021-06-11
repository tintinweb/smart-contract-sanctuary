pragma solidity ^0.5.16;

contract BitswapDeployer {
   address public result;
   address public owner;

   modifier onlyDeployerOwner() {
       require(owner == msg.sender, "FORBIDEN");
       _;
   }

   constructor() public {
       owner = msg.sender;
   }

   function deploy(bytes memory _byteCode, bytes32 salt) public onlyDeployerOwner {
       bytes memory bytecode = _byteCode;
       address addr;

       assembly {
           addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
       }

       result = addr;
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