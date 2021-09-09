/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: NLPL
pragma solidity ^0.8.0;

contract Create2 {
    function deploy(bytes32 _salt, bytes memory _bytecode)
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
}