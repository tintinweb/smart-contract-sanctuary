/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract MyMelody {
    uint s;
    mapping (uint => address) nft;
    mapping (address => uint) balance;
    
    constructor(uint init) public {
        s = init; 
    }
    
    function add(uint val) public {
        s += val;
    }
}