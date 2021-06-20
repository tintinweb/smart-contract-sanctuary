/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract Donations{

    address payable owner;

    uint256 number = 0;

    modifier isOwner(){
        require(owner == msg.sender);
        _;
    }

    constructor(){
        owner = payable(msg.sender);
    }

    function retrieve() public view returns (uint256){
        return number;
    }

    function retrieveIncreasedNumber() public payable{
        number += 1;
    }

    function withdraw() public isOwner{
        uint balance = address(this).balance;
        owner.transfer(balance);
    }

}