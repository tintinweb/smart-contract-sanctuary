/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity 0.4.25;

contract HelloWorld {
    string private message = "HelloWorld";
    string private message2="";
    string private to="";

    function getMessage() public view returns(string memory) {
        return message;
    }
    function setMessage(string memory newTo,string memory newMessage,string memory newMessage2) public {
        message = newMessage;
        to=newTo;
        message2=newMessage2;
    }

}