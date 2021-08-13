/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7 <0.9.0;

contract DeployFactory {

    
    function deploy(bytes memory bytecode) public {
        
        bytes32 salt = "DePlutus";
        address addr;
      
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }
}