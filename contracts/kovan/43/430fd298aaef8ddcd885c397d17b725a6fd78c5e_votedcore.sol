/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
// Created by: CC wardener
pragma solidity ^0.8.0;

struct Issue {
    mapping(address => bool) voted;
    address addressForPay;
    address[]   addr;
    uint policy;
    uint timeStart;
    uint timeEnd; 
    uint payamount ;
    bool executed;
    uint value;
    uint[] VoteScores;

}

contract votedcore
{
    mapping(uint => Issue) issues;
    uint issueId;
    event CreatVote(uint indexed issueId,uint Policy,uint TimeStart,uint TimeEnd,uint  Amount ,address AddressForPay);
    /* 
    
    option ?
      |time   | value vote |vote|target value|
      - โหวต ในเวลาที่กำหนด >=78.6% ในการโหวต 
      | 2 Day | >=78.6%    |  2 |  16 BNB    | Yes No voteing ....   
      | >=2day? & Yes/(No+Yes)>=0.786? & (No+yes)> 16BNB?  
        ===> yes   if 25BNB > 16BNB ?  ==>   16BNB ---> CreatPolicy & 9BNB -->  9/Number of Votes ---> Votes
        ===> No       25BNB/Number of Votes ---> Votes
       Created The Yes/No Question Vote >> policy  timeStart  timeEnd  amount  addressForPay
       policy == ipfs Hash 
       timeStart > block.timestamp
       timeEnd   > timeStart
       amount   >= 0

    */
function Created(uint _policy,  uint _timeStart,  uint _timeEnd,  uint _payamount,  address _addressForPay ) public 
     {
       require(_timeStart >  block.timestamp, "There must be more than 1 option.");
       require(_timeEnd  >  _timeStart, "There must be more than 2 option.");
       if(_payamount==0)
       {
       require((_addressForPay!=address(0)), "_payamount ");
       }
      // require((_payamount ^ _addressForPay)== 0, "_payamount ");
       
       issueId++;
       issues[issueId].addressForPay = _addressForPay ;
       issues[issueId].policy = _policy;  
       issues[issueId].timeStart = _timeStart;
       issues[issueId].timeEnd = _timeEnd;
       issues[issueId].payamount = _payamount;
       issues[issueId].VoteScores = new uint[](2);
       emit  CreatVote(issueId,_policy,_timeStart,_timeEnd,_payamount,_addressForPay);

     }

  function voted(uint _issueId ,uint amount)public payable
   {
    require(block.timestamp >=issues[_issueId].timeStart , "There must be more than 1 option.");
    require(block.timestamp <= issues[_issueId].timeEnd , "There must be more than 1 option.");
    require(msg.value > 0, "deposit money is zero"); ///เงินที่โหวตต้องมากกว่า 0
    require(amount >=0 && amount<=1,"amount") ;

      issues[_issueId].VoteScores[amount]+=msg.value;
      issues[_issueId].value+=msg.value;
      if(!issues[_issueId].voted[msg.sender])
      {
         issues[_issueId].voted[msg.sender] = true;
         issues[_issueId].addr.push(msg.sender);
      }
     
   } 

 function execute(uint _issueId ) public payable
 {
   require(block.timestamp > issues[_issueId].timeEnd,"");
   require(issues[_issueId].executed == false,"executed");
   if(issues[_issueId].value>=issues[_issueId].payamount)
   {
      /// หักออก = issues[issueId].payamount
      payable(issues[_issueId].addressForPay).transfer(issues[_issueId].payamount);
      issues[_issueId].value -= issues[_issueId].payamount;
   }
   uint i;
   for(i= 0;i<issues[_issueId].addr.length;i++)
   {
     payable(issues[_issueId].addr[i]).transfer(issues[_issueId].value/issues[_issueId].addr.length);
     issues[_issueId].value -= issues[_issueId].value/issues[_issueId].addr.length;
   }

 }
 function scores(uint _issueId) public view returns(uint[] memory) 
   {
        require(_issueId > 0, "There must be more than 0 ");
        return issues[_issueId].VoteScores;
   }
   
   function  getTime()  public view returns(uint) 
   {
     return block.timestamp;
   }

}