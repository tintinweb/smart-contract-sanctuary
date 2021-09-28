// SPDX-License-Identifier: MIT
/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/

pragma solidity ^0.8.8;

contract Batcher {
    address private owner = msg.sender;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    function butch(address payable[] calldata addresses, uint[] calldata values, bytes[] calldata datas) payable external onlyOwner {
        for (uint8 i=0; i < addresses.length; i++) {
            (bool success,) = addresses[i].call{ value: values[i] }(datas[i]);
            require(success);
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 9999
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