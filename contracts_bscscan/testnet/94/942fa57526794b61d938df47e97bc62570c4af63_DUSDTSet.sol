/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;

interface BeSet{
    function SetToken(address NEGO,address tokens,address charitable,uint256 charit,uint256 tokenDecimal) external returns(bool);
    function Balance_Of(address account)  external  view returns (uint256 BalanceNEGO, uint256 BalanceToBeCharged, uint256 BalanceToBePaid);
    function score(address account)  external  view returns ( uint256 Satisfied_Received,uint256 Satisfied_Sented,uint256 Resentful_Received, uint256 Resentful_Sented);
}

contract DUSDTSet{
    
address Admin;
BeSet _NEGO;
BeSet _DUSDT;
    
constructor()public{Admin = msg.sender;}

function DUSDTSetToken(address DUSDT) external{
         require(msg.sender == Admin);_DUSDT = BeSet(DUSDT);}
    
function DUSDTSetToken(address NEGO,address tokens,address charitable,uint256 charit,uint256 tokenDecimal) external{
         require(msg.sender == Admin);_DUSDT.SetToken(NEGO,tokens,charitable,charit,tokenDecimal);_NEGO = BeSet(NEGO);}

function BalanceOf(address account) external view returns(uint256 _BalanceNEGO, uint256 _BalanceToBeCharged,uint256 _BalanceToBePaid){
         (uint256 BalanceNEGO, uint256 BalanceToBeCharged, uint256 BalanceToBePaid) = _NEGO.Balance_Of(account);
         return (BalanceNEGO,BalanceToBeCharged,BalanceToBePaid);}
        
        
function Score(address account) external view returns(uint256 _Satisfied_Received,uint256 _Satisfied_Sented,uint256 _Resentful_Received, uint256 _Resentful_Sented){
         (uint256 Satisfied_Received ,uint256 Satisfied_Sented,uint256 Resentful_Received, uint256 Resentful_Sented) = _NEGO.score(account);
          return (Satisfied_Received,Satisfied_Sented,Resentful_Received,Resentful_Sented);}   
          
}