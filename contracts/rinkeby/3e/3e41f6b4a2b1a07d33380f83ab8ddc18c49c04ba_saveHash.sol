/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity ^0.4.16;

contract saveHash {
    
    string hashValue;
    
    constructor(string _hash) public {
        hashValue = _hash;
    }
    // function setP(uint _n) payable public {
    //     value = _n;
    // }
    
    function set (string _hash) public {
        hashValue = _hash;
    }
    function get () public constant returns (string) {
        return hashValue;
    }
}