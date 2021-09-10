// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Faucet {

    // Accept any incoming BNB amount
    receive() external payable {}

    // Sends the amount of token to the caller.
    function send(address payable recipient) external {

        // Check if faucet is empty
        require(address(this).balance > 1,"Faucet is empty");
        
        (bool success, ) = recipient.call{value: 5000000000000000}("");
        require(success, "Transfer failed.");
    }  
    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
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