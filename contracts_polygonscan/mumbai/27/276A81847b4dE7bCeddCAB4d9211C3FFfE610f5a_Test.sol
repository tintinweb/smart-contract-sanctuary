// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IHumanCheck {
    function isValid(uint256 input) external returns (bool valid_);
}

contract Test {

    uint256 number;
    IHumanCheck humanChecker;

    constructor(address humanCheckerAddress_) {
        humanChecker = IHumanCheck(humanCheckerAddress_);
    }

    function store(uint256 num) public {
        require(humanChecker.isValid(num), "Not Human");
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}