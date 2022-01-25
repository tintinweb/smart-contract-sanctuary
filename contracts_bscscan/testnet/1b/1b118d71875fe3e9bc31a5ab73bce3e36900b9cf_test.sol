/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test{


    mapping(uint256=>string) public name;

    function add(uint256 _num) public {
        name[_num] = "ss";
    }

    function add10w()public{
        for(uint256 i=1;i<=100000;i++){
            name[i]="ss";
        }
    }
}