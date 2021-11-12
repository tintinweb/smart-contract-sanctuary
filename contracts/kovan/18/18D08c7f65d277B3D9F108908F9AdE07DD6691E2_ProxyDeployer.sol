// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IOwnable {
    function transferOwnership(address owner) external;
}

contract ProxyDeployer {
    function deploy(bytes32 salt, bytes memory bytecode) public returns(address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }

    function deployOwanable(bytes32 salt, bytes memory bytecode, address owner) public returns(address addr) {
        addr = deploy(salt, bytecode);
        IOwnable(addr).transferOwnership(owner);
    }


}