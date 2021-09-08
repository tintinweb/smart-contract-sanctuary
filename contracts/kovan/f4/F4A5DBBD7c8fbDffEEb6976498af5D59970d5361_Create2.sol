/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: NLPL
pragma solidity ^0.8.0;

contract Create2 {
    function deploy(bytes memory _bytecode, bytes32 _salt)
    public
    payable
    returns (address)
    {
        address addr;
        assembly {
            addr := create2(
                callvalue(),
                add(_bytecode, 0x20),
                mload(_bytecode),
                _salt
            )
        }
        require(addr != address(0), "deployment failed");
        return addr;
    }

    function computeAddress(bytes memory _bytecode, bytes32 _salt)
    public
    view
    returns (address)
    {
        return computeAddress(_bytecode, _salt, address(this));
    }

    function computeAddress(bytes memory _bytecode, bytes32 _salt, address deployer)
    public
    pure
    returns (address)
    {
        bytes32 hash = keccak256(abi.encodePacked(
            bytes1(0xff),
            deployer,
            _salt,
            keccak256(_bytecode)
        ));
        return address(uint160(uint(hash)));
    }
}