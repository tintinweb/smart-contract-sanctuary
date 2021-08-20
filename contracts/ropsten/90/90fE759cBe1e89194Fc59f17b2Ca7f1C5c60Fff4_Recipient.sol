pragma solidity ^0.7.0;

contract Recipient {
    address payable owner;
    uint public interactions;
    event Received(address indexed from, uint value);
    
    constructor(address payable _owner) {
        owner = _owner;
    }

    receive() external payable {
        emit Received(tx.origin, msg.value); 
    }  
    
    fallback() external {
        interactions += 1;
    }
    
    function transferToOwner() public payable {
        owner.transfer(address(this).balance);
    } 
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
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