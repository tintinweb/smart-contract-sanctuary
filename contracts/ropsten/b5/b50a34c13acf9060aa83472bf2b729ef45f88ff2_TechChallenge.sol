/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract TechChallenge{
    uint256 s;
    constructor(uint256 init) public{
        s = init;
    }
    function add(uint256 val) public {
        s += val;
    }
}