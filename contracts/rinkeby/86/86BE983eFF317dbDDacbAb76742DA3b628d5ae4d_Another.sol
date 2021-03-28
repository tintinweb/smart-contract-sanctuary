/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

//Test.sol
pragma solidity ^0.8.0;

contract Another {
    uint public balance;
    function sendToAnother() public {
        balance += 10;
    }
}