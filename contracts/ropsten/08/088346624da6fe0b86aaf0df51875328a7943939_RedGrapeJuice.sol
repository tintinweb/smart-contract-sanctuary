/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract RedGrapeJuice {
    uint i;
    // string s;
    // mapping (string=>uint) m;
    // address adr;
    
    constructor(uint init) public {
        i = init;
    }
    
    function add(uint val) public {
        i += val;
    }
    
}