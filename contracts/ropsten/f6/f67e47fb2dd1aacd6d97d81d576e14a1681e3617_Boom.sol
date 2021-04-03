/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Boom {
    uint256 s;
    //Called when deploy
    constructor(uint256 balance) public {
        s = balance;
    }
    
    // mapping (uint256 => address) nft;
    function add(uint256 val) public {
        s += val;
    }
    
}