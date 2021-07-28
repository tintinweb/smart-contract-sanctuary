/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.6.6;

contract Test {


function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
    
}