/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract BlueBerry {
    // uint256 i;
    // string s;
    // bool b;
    // mapping(uint256 => string) dict;
    // address a; 
    // mapping(uint256 => address) nft;
    // mapping(address => address) balance; 
    uint256 s;
    constructor(uint256 init) public {              //this func will be called once when deployed, and will forever be in blockchain
        s = init;
    }
    
    function add(uint256 val) public {
        s += val;
    }
    
    // deploy: if deploy in JVM - your own computer
    // connect injected web3
    // the more lines of code, the more the gas fee costs
    // can check if the deployed contract is original be compare the long long address compiled
    
}