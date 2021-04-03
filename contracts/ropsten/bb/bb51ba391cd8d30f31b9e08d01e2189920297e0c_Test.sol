/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Test{
    // // data type
    // // int
    // int a
    // uint a
    // uint a;
    // uint256 a;
    // // 
    // string a;
    // // 
    // bool a;
    // // 
    // mapping (uint256 => string) a;
    // // 
    // address a;
    // // 
    // // Json Key : Value
    // mapping (uint256 => address) nft;
    
    // Deploy Smart Contact
    uint256 s;
    constructor(uint256 name) public {
        s = name;
    }
    
    function add(uint256 val) public {
        s += val;
    }
}