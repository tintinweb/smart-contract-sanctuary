// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Gambling
 * @dev Double or lose all your Eth
 */
contract Gambling {

    uint8 public number;

    /**
     * @dev Sends money to store in the contract
     */
    function sendMoney() public payable{
        
    }

    /**
     * @dev Return value 
     * @return value of eth stored in contract
     */
    function retrieve() public view returns (uint256){
        return address(this).balance;
    }
    
    
    function gamble() public payable{
        require(msg.value <= (address(this).balance),"value must be less than pot");
        number= uint8(uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender))) % 2);
        if (number == 1){
            payable(msg.sender).transfer(msg.value*2);
        }
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