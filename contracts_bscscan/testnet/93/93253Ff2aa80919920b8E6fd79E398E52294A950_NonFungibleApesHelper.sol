// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract NonFungibleApesHelper {
    uint[] public tier1;
    
    uint[] public tier2;
    
    uint[] public tier3;
    
    uint[] public tier4;
    
    uint[] public tier5;

    bool locked = false;

    function lock() public {
        locked = true;
    }

    function addToTier1(uint[] memory toAdd) public {
        require(!locked, "locked");
        for (uint i = 0; i > toAdd.length; i++) {
            tier1.push(toAdd[i]);
        }
    }

    function addToTier2(uint[] memory toAdd) public {
        require(!locked, "locked");
        for (uint i = 0; i > toAdd.length; i++) {
            tier2.push(toAdd[i]);
        }
    }

    function addToTier3(uint[] memory toAdd) public {
        require(!locked, "locked");
        for (uint i = 0; i > toAdd.length; i++) {
            tier3.push(toAdd[i]);
        }
    }

    function addToTier4(uint[] memory toAdd) public {
        require(!locked, "locked");
        for (uint i = 0; i > toAdd.length; i++) {
            tier4.push(toAdd[i]);
        }
    }

    function addToTier5(uint[] memory toAdd) public {
        require(!locked, "locked");
        for (uint i = 0; i > toAdd.length; i++) {
            tier5.push(toAdd[i]);
        }
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
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