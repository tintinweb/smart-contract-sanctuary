/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MintBot {
    
    function test() external pure returns(bytes memory){
        bytes memory payload = abi.encodeWithSignature("mintCreature(uint256)", 1);
        return payload;
    }
    
    function Mint() external payable returns(bool) {
        address contractAddress = 0x3Cd3BFEfbFCDF0406f61211E30723A37Ce97dBa0;
        bytes memory payload = abi.encodeWithSignature("mintCreature(uint256)", 1);
        (bool success,) = contractAddress.call{value: msg.value, gas: 248187}(payload);
        return success;
    }
    
    function withdraw() public returns(bool){
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        return success;
    }
    
}