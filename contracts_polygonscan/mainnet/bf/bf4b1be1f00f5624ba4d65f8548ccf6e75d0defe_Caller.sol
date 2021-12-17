/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Caller {

    function send(bytes memory bytecode, uint hash) public returns (bytes memory){
        address call_contract = deploy(bytecode, hash);
        (bool success, bytes memory ret) = call_contract.call(abi.encodeWithSignature("exec()"));
        require(success, "call failed");
        return ret;
    }

    function deploy(bytes memory code, uint256 salt) internal returns (address addr){
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }
}