pragma solidity ^0.7;
contract Bank {

    receive() external payable { }
    
    function deposit() public payable {
        payable(address(this)).transfer(msg.value);
    }
    
    function withdraw(uint amount) public payable {
        msg.sender.transfer(amount * 1 ether);
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
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