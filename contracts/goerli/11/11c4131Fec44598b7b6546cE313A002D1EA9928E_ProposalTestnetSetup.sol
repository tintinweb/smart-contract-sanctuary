/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ProposalTestnetSetup {
    
    event DeploymentOf(string name, address addr);
    
 
    
    function te() public {
        emit DeploymentOf("XUI", address(this));
    }
    
}