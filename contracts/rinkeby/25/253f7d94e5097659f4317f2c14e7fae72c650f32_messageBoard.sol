/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity ^0.4.23;

contract messageBoard {
    string public message;
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string _editMessage) public{
        message = _editMessage;
    }
    function viewMessage() public returns(string){
       return message;
    }
}