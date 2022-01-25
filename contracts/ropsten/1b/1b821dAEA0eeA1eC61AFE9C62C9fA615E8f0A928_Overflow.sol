/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity ^0.8.11;

contract Overflow {
    uint8 public a = 130;
    uint8 public b = 235;

    function add() public {
        uint8 res;
        res = a + b;
    }

    function sub() public {
        uint8 res;
        res = a - b;
    }
}