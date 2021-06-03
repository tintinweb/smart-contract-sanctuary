/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity ^0.4.23;
contract messageBoard {
    string public message;
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string editMessage) public {
        message = editMessage;
    }
}