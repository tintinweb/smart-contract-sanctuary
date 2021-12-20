/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Payable {
    //  Payable address can receive Ether
    address payable public owner;

    //  Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    //  Function to deposit Ether into this contract
    function deposit() public payable {}

    // Function to withdraw all Ether from this contract
    function withdraw() public {
        //  get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        //  send all Ether to owner
        //  Owner can receive Ether since the address of owner is payable
        (bool success , ) = owner.call{value: amount}("");
        require(success, "Filed to send Ether");
    }
}