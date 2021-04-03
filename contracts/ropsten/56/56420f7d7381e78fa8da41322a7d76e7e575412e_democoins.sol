/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract democoins {
    uint256 s;
    constructor(uint256 init) public {
        // Is called automatically when deploy
        s = init;
    }
    
    // public keyword allow other smart contract to call this function
    function add(uint256 val) public {
        s += val;
    }
    
}