/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity ^0.4.17;

/**
 * Inbox contract.
 */
contract Inbox {
    string public message;

    function Inbox(string initialMessage) public {
        message = initialMessage;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
    
    function getMessage() public view returns (string) {
        return message;
    }
}