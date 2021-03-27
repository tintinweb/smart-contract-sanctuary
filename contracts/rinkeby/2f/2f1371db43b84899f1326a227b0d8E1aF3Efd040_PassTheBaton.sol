/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface CheckInInterface {
    function getStudent(address student) external view returns (string memory);
}

contract PassTheBaton {
    event Middleman(string name);
    
    address private lastHolder;
    CheckInInterface private CheckIn;
    
    constructor() {
        lastHolder = msg.sender;
        CheckIn = CheckInInterface(0x628A5BDfEfbdf0dD98066bF80e36F2c2F9Bb8F00);
    }
    
    function passTheBaton() public returns (string memory) {
        string memory middleman = CheckIn.getStudent(lastHolder);
        emit Middleman(middleman);
        lastHolder = msg.sender;
        return middleman;
    }
}