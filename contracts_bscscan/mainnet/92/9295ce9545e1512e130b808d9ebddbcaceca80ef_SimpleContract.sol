/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

pragma solidity ^0.5.5;

contract SimpleContract {
    string message;
    
    function setMessage(string memory _message) public {
        message=_message;
    }
}