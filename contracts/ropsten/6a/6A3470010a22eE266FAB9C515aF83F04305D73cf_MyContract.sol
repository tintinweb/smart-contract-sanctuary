/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;


contract MyContract {

    uint8 number;
    address private owner;

    constructor(uint8 val) {
        number = val;
        owner = msg.sender;
    }

    function guess(uint8 num) public view {
        require(num == number, "correct! Get address with get_adress!");
        require(num < number, "it is higher, try again!");
        require(num > number, "it is lower, try again!");
    }


    function get_address(uint8 num) external view returns (address){
        require(num == number, "wrong number, guess it with guess()");
        return owner;
    }
}