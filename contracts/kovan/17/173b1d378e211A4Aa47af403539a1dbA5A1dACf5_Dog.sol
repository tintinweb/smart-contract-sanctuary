pragma solidity ^0.6.12;

contract Dog {
    address payable public _charityWalletAddress;
    address payable public _marketingWalletAddress;
    address payable public _devWalletAddress;

    constructor(
        address payable charityWalletAddress,
        address payable marketingWalletAddress,
        address payable devWalletAddress
    ) public {
        _charityWalletAddress = charityWalletAddress;
        _marketingWalletAddress = marketingWalletAddress;
        _devWalletAddress = devWalletAddress;
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
  },
  "libraries": {}
}