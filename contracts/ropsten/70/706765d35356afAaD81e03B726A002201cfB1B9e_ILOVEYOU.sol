/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;



contract ILOVEYOU{

string _name;

constructor(string memory name){

    name = _name;
}

function getName() public view returns(string memory name){
    return _name;
}

}