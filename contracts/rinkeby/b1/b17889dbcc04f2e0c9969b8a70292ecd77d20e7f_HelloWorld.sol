/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

pragma solidity 0.4.25;

contract HelloWorld {
    string private message = "HelloWorld";

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}