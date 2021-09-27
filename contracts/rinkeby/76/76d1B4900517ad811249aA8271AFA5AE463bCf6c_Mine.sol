/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


interface RemoteInterface {
    function getSender() external view returns(address);
        
    function getString123() external view returns (string memory);
}

contract Mine {
    RemoteInterface remoteInterface = RemoteInterface(0xFc336bE721906759084885e03A3324da76c6aD49);
    
    function getRemoteSender() public view returns(address) {
        return remoteInterface.getSender();
    }
    
    function getString() public view returns(string memory) {
        return remoteInterface.getString123();
    }
    
}