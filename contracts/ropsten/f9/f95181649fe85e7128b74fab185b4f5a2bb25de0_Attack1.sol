pragma solidity ^0.4.24;


contract Attack1 {


    string public message;
    
    constructor() public{
    }
    
    function editMessage(string _msg) public {
        message = _msg;
    }




}