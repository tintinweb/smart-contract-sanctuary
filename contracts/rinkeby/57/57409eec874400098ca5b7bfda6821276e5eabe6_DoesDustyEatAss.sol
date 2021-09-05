/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

pragma solidity ^0.4.24;

contract DoesDustyEatAss {
    string myMessage;

    function setMessage(string x) public {
        myMessage = x;
    }

    function getMessage() public view returns (string) {
        return myMessage;
    }
}