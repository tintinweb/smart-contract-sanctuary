/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity >=0.4.22 <0.8.0;

// This is test contract invoked by TxProxy
// It can only record message and last sender
contract MessageBox {

    string public message;
    address public sender;

    constructor(string memory initialMessage) public{
        message = initialMessage;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
        sender = msg.sender;
    }

}