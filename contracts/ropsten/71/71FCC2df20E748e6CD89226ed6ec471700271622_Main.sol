pragma solidity ^0.8.6;

contract Main {
    address public owner;
    uint16 public number;
    event SecondaryCreated(address indexed mainContract, uint16 indexed number, address connectedContract);

    constructor() {
        owner = msg.sender;
        number = 0;
        generate();
        
        
    }

    function generate() public {
        number+=1;
        Secondary secondary = new Secondary(msg.sender,number);
        emit SecondaryCreated(msg.sender,number,address(secondary)); 

    }

}

contract Secondary {
    address public owner;
    uint16 public number;

    constructor(address _owner,uint16 num) {
        owner = _owner;
        number = num;
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