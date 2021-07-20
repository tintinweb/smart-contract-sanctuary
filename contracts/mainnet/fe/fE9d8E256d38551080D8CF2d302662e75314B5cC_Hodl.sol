pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Hodl{
    
    
    address public owner;
    
    constructor() public{
        owner = msg.sender;
    }
   
    
    mapping (address =>uint) hodler;
    uint public lockuntil = 0;
    
    function deposit() payable public{
        hodler[msg.sender] = hodler[msg.sender]+msg.value;
    }
    
    function lockContract(uint newlock) public{
        require(msg.sender == owner, "YOU ARE NOT THE OWNER");
        require(newlock > lockuntil,"TIME MUST LATER THAN OLD LOCK");
        lockuntil = newlock;
    }
    
    
    function withdraw() public {
        require(block.timestamp > lockuntil,"ERROR NOT TIME FOR IT");
        payable(msg.sender).transfer(hodler[msg.sender]);
        hodler[msg.sender]=0;
    }
    
    function getHodlings() view public returns(uint hodl){
        return hodler[msg.sender];
    }
    
    function getTime() view public returns(uint){
        return block.timestamp;
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