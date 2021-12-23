// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;


contract TestContract {

    address immutable public immutableDeployer;
    address public deployer;

    constructor() {
        deployer = msg.sender;
        immutableDeployer = msg.sender;
    }

    function foo() external pure returns (string memory) {
        return "bar";
    }
}