/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract ILOVEYOU{

string _name;

constructor(string memory name){

    _name = name;
}

function getmylover() public view returns(string memory name){
    return _name;
}

}