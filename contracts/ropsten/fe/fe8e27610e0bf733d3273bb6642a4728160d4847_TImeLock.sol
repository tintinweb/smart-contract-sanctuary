/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: GPL-3.0

// linkdin,twitter,github username: @imHukam

//this timelock contract is test on 5 mintues(300 second) timelock

pragma solidity ^0.8.7;

contract TImeLock{

    uint256 time;
    address payable receiver;

    constructor(address payable _receiver, uint256 _time){
        receiver=_receiver;
        time= block.timestamp+ _time;
    }

    function deposit() public payable{}

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function withdraw() public {
        require(msg.sender== receiver, "only receipient can withdraw fund");
        require(block.timestamp>=time, "deadline has not passed");
        receiver.transfer(address(this).balance);
    }
}