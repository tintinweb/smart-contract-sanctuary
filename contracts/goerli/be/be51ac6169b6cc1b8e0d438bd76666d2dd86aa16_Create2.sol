/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: NLPL
pragma solidity ^0.8.0;

contract Create2 {
    function deploy(bytes memory bytecode, bytes32 salt)
    public
    returns (address)
    {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    function computeAddress(bytes memory bytecode, bytes32 salt)
    public
    view
    returns (address)
    {
        return computeAddress(bytecode, salt, address(this));
    }

    function computeAddress(bytes memory bytecode, bytes32 salt, address deployer)
    public
    pure
    returns (address)
    {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(bytecode))
        );
        return address(bytes20(_data << 96));
    }

    function getHash(bytes memory bytecode)
    public
    pure
    returns (bytes32)
    {
        return keccak256(bytecode);
    }
}