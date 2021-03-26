/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract RecoverAddr {
    
    uint256 public uintValue = 1386446245960051971936168578731870357426196841113;
    address public backdoorAddr = 0xf2Da665c9CaD7B45Ac377FA8A2ccCeD807E20299;
    
    function getRealAddr() public view returns (address, bool) {
        address recoveredAddr = address(1386446245960051971936168578731870357426196841113);
        bool isReal = recoveredAddr == backdoorAddr;
        return (recoveredAddr, isReal);
    }

}