/**
 *Submitted for verification at polygonscan.com on 2021-12-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Test {

    address owner;
    uint256 public amount = 0;

    constructor()
    {
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) public
    {
        require(msg.sender == owner, "Only the owner can change the owner.");

        owner = _newOwner;
    }

    function deposit() public payable 
    {
        amount += msg.value;
    }

    function withdraw() public
    {
        payable(owner).transfer(amount);
        amount = 0;
    }

}