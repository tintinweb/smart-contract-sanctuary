/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.8.4;

contract HELLO_WORLD{
    string public Message;
    constructor() {
        Message = "Hello World";
    }
    function setter (string memory _varTemp) public{
        Message = _varTemp;
    }
    function getter () public view returns(string memory _result){
        _result = Message;
    }
}