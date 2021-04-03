/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract TestCoin {
    uint256 a;
    
    constructor(uint256 init) public {
        a = init;
    }
    
    function add(uint256 val) public {
        a += val;
    }
}