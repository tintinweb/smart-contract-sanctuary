/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17; //decalre version

contract RedGrapeJuice {
    //data types
    int a; //default int256
    uint256 s; //unsigned integer
    string c;
    bool d;
    mapping (uint256 => string) e; //maps like a dictionary
    address f;
    mapping (uint256 => address) nft;
    mapping (address => uint256) balance;
    
    //called when deployed
    constructor(uint256 init) public {
        s = init;
    }
    
    function add(uint256 val) public {
        s += val;
    }
}