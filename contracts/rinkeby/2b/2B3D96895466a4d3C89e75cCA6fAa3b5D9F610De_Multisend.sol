// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Multisend {
    address private owner;
    IERC20 private token;

    constructor (address tokenAddress) {
        owner = msg.sender;
        token = IERC20(tokenAddress);
    }

    function multisend(address[] calldata addresses, uint256[] calldata amounts) external {
        require(owner == msg.sender, "!Owner");
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; ++i) {
            token.transfer(addresses[i], amounts[i]);
        }
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