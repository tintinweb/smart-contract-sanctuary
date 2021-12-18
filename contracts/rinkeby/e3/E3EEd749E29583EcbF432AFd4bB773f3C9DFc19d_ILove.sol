/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ILove {

    string _message;

    constructor(string memory message){
        _message = message;
    }

    function Hello() public view returns(string memory){
        return _message;
    }
}