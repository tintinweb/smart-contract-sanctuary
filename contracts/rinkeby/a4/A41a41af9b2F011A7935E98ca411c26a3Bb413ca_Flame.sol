// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Flame {
    string public jsCode1;
    string public jsCode2;
    bool public finalized;
    address private deployer;

    constructor() public {
        deployer = msg.sender;
    }

    function setJsCode1(string memory newJsCode) public {
        require(msg.sender == deployer, "must be deployer");
        require(!finalized, "js code already set");
        jsCode1 = newJsCode;
    }

    function setJsCode2(string memory newJsCode) public {
        require(msg.sender == deployer, "must be deployer");
        require(!finalized, "js code already set");
        jsCode2 = newJsCode;
        finalized = true;
    }

    function getJsCode() public view returns (string memory) {
        return string(abi.encodePacked(jsCode1, jsCode2));
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