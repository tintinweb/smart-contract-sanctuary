/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.4.24;

contract HelloGame{
    
    uint totalSupply=0;
    mapping (address => uint256) public balances;

    event GetBouns(address _who, uint bouns);

    function getBonus(uint bouns) public returns (uint){
        require(balances[msg.sender]<1000);
        require(bouns<200);
        balances[msg.sender]+=bouns;
        totalSupply+=bouns;

        emit GetBouns(msg.sender, bouns);

        return balances[msg.sender];
    }
}