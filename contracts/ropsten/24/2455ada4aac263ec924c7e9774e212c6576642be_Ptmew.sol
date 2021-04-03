/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Ptmew {
    uint256 count;
    constructor(uint256 init) public{
        count = init;
    }
    
    function add(uint256 val) public{
        count += val;
        
    }
}