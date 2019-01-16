pragma solidity ^0.4.23;

contract Test {
    uint256 public count;
    mapping(address => uint256) public balances;


    constructor(uint256 _initialCoins) public{
        balances[msg.sender] = _initialCoins;
    }
}