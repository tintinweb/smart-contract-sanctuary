/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.5.16;


contract JustForDebug{
    
    mapping(address => uint) public b0;
    mapping(address => uint) public b1;
    
    function getBalances(address account) public view returns (uint[] memory){
       uint[] memory balances = new uint[](2);
       balances[0] = b0[account];
       balances[1] = b1[account];
       
       return balances;
    }
    
    function setBalances(address account, uint256[] memory balances) public{
        require(balances.length == 2, "balances length != 2");
        b0[account] = balances[0];
        b1[account] = balances[1];
    }
    
    function setBalanceIndex0(address account, uint256 balance) public{
        b0[account] = balance;
    }
    
    function setBalanceIndex1(address account, uint256 balance) public{
        b1[account] = balance;
    }
}