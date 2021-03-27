/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface PTBinterface {
    function passTheBaton() external returns (string memory);
}

contract grab {
    string lastHolder;
    PTBinterface passTheBaton;
    
    event Middleman(string name);
    event Holder(string name);
    
    constructor() {
        passTheBaton = PTBinterface(0x2f1371db43b84899f1326a227b0d8E1aF3Efd040);
    }
    
    function writeHolder() public {
        string memory middleman = passTheBaton.passTheBaton();
        emit Middleman(middleman);
        lastHolder = middleman;
        emit Holder(lastHolder);
    }
}