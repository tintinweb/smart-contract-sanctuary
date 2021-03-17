/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity >=0.4.22 <0.9.0;

contract SimpleStorage {
    string message;

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage() public {
        message = "hello";
    }
}