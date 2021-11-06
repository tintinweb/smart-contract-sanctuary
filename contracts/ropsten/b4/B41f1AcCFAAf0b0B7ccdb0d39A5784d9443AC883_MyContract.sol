/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract{
    
    string _message;
    
    constructor(string memory message){
        _message=message;
    }
    
    
    
    /*function Bugge(string name){
        return "Bugge";
    }*/
    
    function Hello()public view returns(string memory){
        return _message;
    }
    
}