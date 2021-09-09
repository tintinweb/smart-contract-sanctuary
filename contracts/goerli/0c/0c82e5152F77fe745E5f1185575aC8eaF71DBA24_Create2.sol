/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: NLPL
pragma solidity ^0.8.0;

contract Create2 {
    function deploy(bytes32 salt, bytes memory bytecode)
    public payable
    returns (address)
    {
        address addr;
        assembly {
            addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "deployment failed");
        return addr;
    }
}