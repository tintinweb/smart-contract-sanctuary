// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract Storage {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    function fund() public payable {
        payable(address(this)).transfer(msg.value);
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

}