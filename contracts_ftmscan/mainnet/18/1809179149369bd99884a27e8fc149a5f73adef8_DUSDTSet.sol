/**
 *Submitted for verification at FtmScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.6.12;

interface BeSet{
    function OTCtransfer(address recipient, uint256 amount) external returns (bool);
    function GetUser() external view returns (address);
    function getOnBlackList (address OnBlackList) external view returns(bool);
    function setRefer(address Referee, uint256 number,uint256 Quantity) external returns(bool);
    function setArbitration (address arbitration) external returns (bool);
    function SetToken(address Stay,address charitable,address ARB,uint256 charit) external returns(bool);
    function Balance_Of(address account)  external  view returns (uint256 BalanceNEGO, uint256 BalanceToBeCharged, uint256 BalanceToBePaid);
    function score(address account)  external  view returns ( uint256 Satisfied_Received,uint256 Satisfied_Sented,uint256 Resentful_Received, uint256 Resentful_Sented);
}

contract DUSDTSet{
    
address Admin;
BeSet _NEGO;
BeSet _DUSDT;
BeSet _ARB;
uint256 _TokenDecimal;
    
constructor(uint256 tokenDecimal)public{Admin = msg.sender;_TokenDecimal=tokenDecimal;}

function SetToken(address DUSDT) external{
         require(msg.sender == Admin);_DUSDT = BeSet(DUSDT);}
    
function DUSDTSetToken(address NEGO,address ARB,address charitable,uint256 charit) external{
         require(msg.sender == Admin);_DUSDT.SetToken(NEGO,charitable,ARB,charit);_NEGO = BeSet(NEGO);_ARB = BeSet(ARB);_NEGO.setArbitration(ARB);}
         

function ARBSetToken(address Refer, uint256 number,uint256 Quantity) external{         
         require(msg.sender == Admin);  _ARB.setRefer(Refer, number, Quantity);}
         

         
function USD_Retrieve(address UserAccount, uint256 amount) external returns(bool){
        require(msg.sender == BeSet(UserAccount).GetUser());
        BeSet(UserAccount).OTCtransfer(msg.sender, amount*10**_TokenDecimal);
        return true;}         

function BalanceOf(address account) external view returns(uint256 _BalanceNEGO, uint256 _BalanceToBeCharged,uint256 _BalanceToBePaid){
         (uint256 BalanceNEGO, uint256 BalanceToBeCharged, uint256 BalanceToBePaid) = _NEGO.Balance_Of(account);
         return (BalanceNEGO,BalanceToBeCharged,BalanceToBePaid);}
        
        
function Score(address account) external view returns(uint256 _Satisfied_Received,uint256 _Satisfied_Sented,uint256 _Resentful_Received, uint256 _Resentful_Sented,bool OnBlackList){
         (uint256 Satisfied_Received ,uint256 Satisfied_Sented,uint256 Resentful_Received, uint256 Resentful_Sented) = _NEGO.score(account);
          return (Satisfied_Received,Satisfied_Sented,Resentful_Received,Resentful_Sented, _ARB.getOnBlackList (account));}   
          
}