/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PippyBank {
    uint public goal;
    
    constructor (uint _goal) {
        goal = _goal;
    }
    
    receive() external payable {}
    
    function getMyBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function withdrow() public {
        if (getMyBalance() > goal) {
            selfdestruct(msg.sender);
        }
    }
}