/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.7.1;

contract test {

    int _multiplier;
    event Multiplied(int indexed a, address indexed sender, int result );

    constructor (int multiplier) {
        _multiplier = multiplier;
    }

    function multiply(int a) public returns (int r) {
       r = a * _multiplier;
       emit Multiplied(a, msg.sender, r);
       return r;
    }
 }