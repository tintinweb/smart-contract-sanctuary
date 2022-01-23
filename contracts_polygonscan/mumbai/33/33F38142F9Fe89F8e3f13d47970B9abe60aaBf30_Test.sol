// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IHumanCheck {
    function isValid(uint256 input) external returns (bool valid_);
}

contract Test {

    uint256 number;
    IHumanCheck humanChecker;

    function setHumanChecker(address humanCheckerAddress_) external {
        humanChecker = IHumanCheck(humanCheckerAddress_);
    }

    function store(uint256 num) external {
        require(humanChecker.isValid(num), "Not Human");
        number = num;
    }

    function retrieve() external view returns (uint256){
        return number;
    }
}