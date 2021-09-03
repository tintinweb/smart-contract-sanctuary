/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

pragma solidity ^0.4.24;

contract DoesDustyEatAss {
    string myMessage;

    function setMessage() public {
        myMessage = "dusty come culo";
    }

    function getMessage() public view returns (string) {
        return myMessage;
    }
}