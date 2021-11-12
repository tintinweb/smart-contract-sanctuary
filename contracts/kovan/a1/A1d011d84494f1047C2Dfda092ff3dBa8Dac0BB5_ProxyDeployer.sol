// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

contract ProxyDeployer {
    function deploy(bytes memory salt, bytes memory bytecode) public returns(address){
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        return addr; 
    }
}