/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SendEth {
    address public receiveAddress;
    address public addr;

    function transferEth() public payable {
        payable(receiveAddress).transfer(uint(msg.value));
        //payable(msg.sender).transfer(address(receiveAddress).balance);
    }

    function getAddress(address addressName) public returns(address) {
        receiveAddress = addressName;
        return receiveAddress;
    }
}