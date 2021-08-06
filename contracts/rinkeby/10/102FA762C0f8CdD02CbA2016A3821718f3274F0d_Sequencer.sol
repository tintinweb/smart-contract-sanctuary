// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Sequencer{
    
    event Interaction(address from, uint8 instrumentType, uint8 note);
    
    
    /**
     * @dev Add new sequencer interaction
     */
    function addInteraction() public {
        uint160 addressAsNumber = uint160(msg.sender);
        
        // extract first half of address as number for instrument type
        uint8 instrumentType = uint8(addressAsNumber >> 80);
        
        // extract second half of address as number for note number
        uint8 note = uint8(addressAsNumber);
        
        emit Interaction(msg.sender, instrumentType, note);
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