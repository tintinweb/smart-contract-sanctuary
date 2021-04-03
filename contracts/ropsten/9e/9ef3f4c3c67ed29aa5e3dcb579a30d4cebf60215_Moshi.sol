/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Moshi {
    uint256 o;
    mapping(uint256 => address) nft;
    mapping(address => uint256) balance;
    
    uint256 s;
    constructor(uint256 init) public{
        s = init;
    }
    
    function add(uint256 val) public {
        s += val;
    }
}