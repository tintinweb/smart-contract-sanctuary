/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract numero {

    uint private num;

    function setNum(uint _num)external {

        num=_num;

    }

    function getNum()external view returns(uint){

        return num;

    }
}