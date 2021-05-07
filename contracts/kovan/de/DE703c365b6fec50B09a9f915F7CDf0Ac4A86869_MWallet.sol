// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

contract MWallet {
    address owner;

    event Withdraw(address _sender, uint _amount);
    event Received(address _sender, uint _amount);
    event Call(address _sender, string message);

    constructor(){
        owner = msg.sender;
    }

    fallback() external payable{
        emit Call(msg.sender, "Call was successful");
    }

    receive() external payable{
        emit Received(msg.sender, msg.value);
    }

    function send(address payable recipient, uint amount) public payable{
        require(msg.sender == owner, "Transaction denied: sender is has no permissions!");
        require(owner.balance >= amount, "Transaction denied: not enough wei to send!");
        recipient.transfer(amount);
        emit Withdraw(owner, amount);
    }

    function info() public view returns(address, uint256){ 
        require(msg.sender == owner, "Request denied: Caller is not the owner");
        return (owner, address(this).balance);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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