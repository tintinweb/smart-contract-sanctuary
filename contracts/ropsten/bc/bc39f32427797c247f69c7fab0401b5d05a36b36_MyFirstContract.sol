/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract MyFirstContract {
    mapping (uint256 => address) nft;
    mapping (address => uint256) balance;
    
    uint256 public s;
    
    constructor(uint256 init) public{
        s = init;
    }
    
    function add(uint val) public {
        s += val;
    }
}