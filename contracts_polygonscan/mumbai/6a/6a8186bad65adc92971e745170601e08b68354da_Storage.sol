/**
 *Submitted for verification at polygonscan.com on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    string number;
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function store(string memory num) public onlyOwner {
        number = num;
    }

    function retrieve() public view returns (string memory) {
        return number;
    }
}