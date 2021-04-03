/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity >=0.7.0 <0.9.0;
//use for bitkub day
contract CountUser {
    uint256 s;
    constructor(uint256 init)public{
       s = init;
    }
    function add(uint256 val) public{
    s += val;
    }
}