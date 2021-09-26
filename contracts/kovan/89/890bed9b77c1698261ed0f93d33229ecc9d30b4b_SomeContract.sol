/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity ^0.5.15;

contract SomeContract{
    uint public myUint = 10;
    function setUint(uint _myUint) public{
        myUint = _myUint;
    }
}