/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

/**
 * SPDX-License-Identifier: UNLICENSED
 * Submitted for verification at Etherscan.io on 2017-12-14
*/

pragma solidity ^0.7.0;


abstract contract DateTime {

    function getHour(uint timestamp) virtual public returns (uint8);
}

contract SlavContract {
    address private owner;

  	address constant private SLAV_ADDR = 0x0625fAaD99bCD3d22C91aB317079F6616e81e3c0;

    address constant private DATE_TIME_ADDR = 0x8Fc065565E3e44aef229F1D06aac009D6A524e82;
    DateTime dateTime = DateTime(DATE_TIME_ADDR);


    constructor()  {
        owner = msg.sender;
    }

    receive() external payable {

    }
    fallback () external payable {
        
    }

    function getMyCoinsPlease() public {
        uint8 hour = dateTime.getHour(block.timestamp);
        require (hour > 16, "after 16:00 UTC only");
        require (msg.sender == SLAV_ADDR);
        msg.sender.transfer(address(this).balance);
    }


    function getBalance() view public returns (uint256){
        return address(this).balance;
    }
}