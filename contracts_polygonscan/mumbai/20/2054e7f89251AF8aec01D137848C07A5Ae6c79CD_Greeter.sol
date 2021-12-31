/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0<0.9.0;

contract Greeter{

    uint public count=0;

    constructor(){
        count++;
    }

    function incrementCount()public{
        count++;
    }

    function decrementCount()public{
        count--;
    }

}