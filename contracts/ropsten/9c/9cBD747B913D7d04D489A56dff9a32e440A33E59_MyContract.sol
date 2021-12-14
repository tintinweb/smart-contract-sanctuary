/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyContract {

    address owner;

    event Buy(address indexed buyer, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns ( address )  {
        return owner;
    }

    function buy() public payable {
        require(msg.sender.balance > msg.value, "Insufficient amount");
        payable(owner).transfer(msg.value);
        emit Buy(msg.sender, msg.value);
    } 
}