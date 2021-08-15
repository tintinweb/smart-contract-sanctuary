/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

abstract contract interfaceB {
    //INCLUDE ALL FUNCTION YOU WANT TO BE CALLED EXTERNALLY
    function helloWorld() external virtual pure returns (string memory);
}

contract B{
    function helloWorld() external pure returns (string memory){
        return "HELLOW WORLD FROM SMART CONTRACT B";
    }
}