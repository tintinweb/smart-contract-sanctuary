/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract SueToken {
    uint256 totalSupply_;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor(uint256 total) {
       totalSupply_ = total;
       balances[msg.sender] = totalSupply_;
    }
}