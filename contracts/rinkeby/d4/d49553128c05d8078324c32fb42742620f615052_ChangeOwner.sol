/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface Target {
    function changeOwner(address _owner) external;
}


contract ChangeOwner {
    
    
    function changeOwner (address target, address owner) external returns (bool) {
        Target cont = Target(target);
        
        cont.changeOwner(owner);
        
        return true;
    }
}