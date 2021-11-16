/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract MethodDemo {
    
    function getMethodByte(string memory method) public view returns (bytes4){
        return bytes4(keccak256(abi.encodePacked(method)));
    }
}