/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract RedGrapeJuice {
    // mapping (uint256 => string) a; 
    // address b;
    // mapping (uint256 => address) nft; // How to define a nft
    // mapping (address =>uint256) balance; // How to define a bank account
    uint256 namu;
    constructor(uint256 init) public {
        namu = init;
    }
    function add(uint256 value) public {
        namu += value;
    }
}