// contracts/AccountCreator.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

contract AccountCreator{

    uint256 constant startAddress = 1000;
    uint256 constant amountToSend = 1;
    uint256 accountsCreated;
    address lastCreatedAddress;

    constructor() payable{

    }

    function create(uint256 accountNumber) public payable returns(bool){
        for(uint256 i = 0; i < accountNumber; i++){
            address addr = address(uint160(startAddress + accountsCreated + 1));
            address payable recipient = payable(addr);
            recipient.transfer(amountToSend);
            accountsCreated++;
            lastCreatedAddress = addr;
        }
        return true;
    }

    function getLastCreatedAddress() public view returns (address){
      return lastCreatedAddress;
    }

    function getAccountsCreated() public view returns (uint256) {
        return accountsCreated;
    }

    receive() external payable {}

    fallback() external payable {}
}

{
  "optimizer": {
    "enabled": true,
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