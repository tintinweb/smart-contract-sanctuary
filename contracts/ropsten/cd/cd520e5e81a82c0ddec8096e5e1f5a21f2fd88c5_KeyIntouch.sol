/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract KeyIntouch{

    uint256 s;
    constructor(uint256 init) public{
       s = init;
    }
    
    function JommyJom(uint256 value) public{
        s += value;
    }
}