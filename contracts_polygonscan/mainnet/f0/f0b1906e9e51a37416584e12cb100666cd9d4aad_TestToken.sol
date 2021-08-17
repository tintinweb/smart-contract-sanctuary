/**
 *Submitted for verification at polygonscan.com on 2021-08-17
*/

pragma solidity 0.8.6;

contract TestToken {
    string public symbol;
    string public  name;
    uint8 public decimals;
 
    constructor() {
        symbol = "JOHNNYTEST";
        name = "Johnny Test";
        decimals = 18;
    }
}