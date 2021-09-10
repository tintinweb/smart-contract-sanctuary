/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity ^0.5.4;

contract Hello {
    string public hello = "Hello world";

    function setHello(string memory newHello) public {
        hello = newHello;
    }
}