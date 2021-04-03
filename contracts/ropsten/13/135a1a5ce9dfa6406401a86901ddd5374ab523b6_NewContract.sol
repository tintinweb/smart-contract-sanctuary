/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract NewContract{
    uint256 obj;

    constructor(uint256 init) public {
       obj = init;
    }
    
    function add(uint256 vol) public {
       obj += vol;
    }
    
}