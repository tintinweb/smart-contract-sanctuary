/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    uint256 private number;

    event Store(address indexed account, uint256 indexed value);
    constructor(uint256 initValue) {
        number = initValue;
    }

    function store(uint256 num) public {
        number = num;
        emit Store(msg.sender, num);
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}