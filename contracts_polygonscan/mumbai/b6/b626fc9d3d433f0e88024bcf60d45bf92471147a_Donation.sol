/**
 *Submitted for verification at polygonscan.com on 2022-01-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity > 0.7.0 < 0.9.0;

contract Donation{
    address payable owner;

    constructor(){
        owner = payable(msg.sender);
    }

    event Donate(address from, uint amount, string message);

    function newDonation(string memory _note) public payable{
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");
        emit Donate(msg.sender, msg.value, _note);
    }
}