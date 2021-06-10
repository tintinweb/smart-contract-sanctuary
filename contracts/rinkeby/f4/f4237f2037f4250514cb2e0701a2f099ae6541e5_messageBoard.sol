/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.4.23;
contract messageBoard {
    string public message;
    int public num = 123;
    int public people = 0;
    function messageBoard(string initMessage) public {
        message =initMessage;
    }
     function editMessage(string editMessage) public {
        message = editMessage;
    }
    function showMessage() public view{
        message = 'abcd';
    }
    function pay() public payable{
        people++;
    }
}