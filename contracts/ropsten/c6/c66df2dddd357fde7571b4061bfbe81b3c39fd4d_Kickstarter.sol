/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.6;

contract Kickstarter {
    
    address payable project = 0xbb0f394fCE675a4FE349Fd59728E507aBd6FB8ff;
    uint goal = 1;
    
    function endorse() public payable {
        if( address(this).balance >= goal * 1 ether)
            project.transfer(address(this).balance);
    }
    
}