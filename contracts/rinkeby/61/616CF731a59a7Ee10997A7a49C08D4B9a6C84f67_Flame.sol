// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Flame {
    string public jsCode;
    bool public finalized;
    address private deployer;

    constructor() public {
        deployer = msg.sender;
    }

    function setJsCode(string memory newJsCode) public {
        require(msg.sender == deployer, "must be deployer");
        require(!finalized, "js code already set");
        jsCode = newJsCode;
        finalized = true;
    }

    function getJsCode() public view returns (string memory) {
        return jsCode;
    }
}

