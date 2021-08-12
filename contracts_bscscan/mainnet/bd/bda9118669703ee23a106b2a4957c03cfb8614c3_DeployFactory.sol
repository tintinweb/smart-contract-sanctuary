/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.7;

contract DeployFactory {

    event Deployed(address addr);

    function deploy(bytes32 salt, bytes memory bytecode, bytes memory abiConstructorArgs) public {
        // deploy contracts with constructor (address):
        bytes memory bytecodeWithConstructor = abi.encodePacked(bytecode, abiConstructorArgs);

        address addr;
        assembly {
            addr := create2(0, add(bytecodeWithConstructor, 0x20), mload(bytecodeWithConstructor), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        emit Deployed(addr);
    }
}