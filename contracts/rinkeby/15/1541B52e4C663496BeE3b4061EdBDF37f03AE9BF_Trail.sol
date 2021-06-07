/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Trail {
    uint public count = 0;
    address[] public trail;
    mapping(address => uint) public index;
    mapping(address => bool) public register;

    function join() external {
        require(!register[msg.sender], "You can only join once");
        trail.push(msg.sender);
        index[msg.sender] = count;
        count++;
        register[msg.sender] = true;          
    }

    function isRegistered(address _address) external view returns (bool) {
        return register[_address];
    }

    function getIndex(address _address) external view returns (uint) {
        return index[_address];
    }
}