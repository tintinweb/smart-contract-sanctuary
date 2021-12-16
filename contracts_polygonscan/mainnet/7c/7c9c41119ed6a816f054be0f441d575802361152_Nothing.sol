/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

contract Nothing{

    bool public switched = false;

    constructor(){

    }

    function Switch() public{
        require(switched==false,"Already switched");
        switched = true;
    }

    function resetSwitch() public{
        switched = false;
    }

}