/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Ohm{

    uint256 number;
    string name;
    mapping(uint256 => address) nft;
    mapping(address => uint256) balance;
    
    constructor(uint256 init)public{
        number = init;
    }
    
    function add(uint256 num) public{
        number += num;
    }
}