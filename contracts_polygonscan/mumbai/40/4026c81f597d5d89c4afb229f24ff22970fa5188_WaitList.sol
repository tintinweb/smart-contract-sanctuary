/**
 *Submitted for verification at polygonscan.com on 2021-11-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

contract WaitList {
    mapping(address => bool) public whiteListedAddress;
    address[] public addressList;
    event WhiteListed(address indexed ListedAddress);

    function addWhiteList() public {
        require(
            whiteListedAddress[msg.sender] == false,
            "Address is already white Listed"
        );
        whiteListedAddress[msg.sender] = true;
        addressList.push(msg.sender);
        emit WhiteListed(msg.sender);
    }
}