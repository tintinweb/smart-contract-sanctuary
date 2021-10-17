/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

//SPDX-License-Identifier: <SPDX-License>

pragma solidity = 0.8.7;

contract BlockNumber{
    uint256 blocco;
    
    function getBlock() public payable returns (uint256){
        
        blocco=block.number;
        return blocco;
        
    }
    
    
    
}