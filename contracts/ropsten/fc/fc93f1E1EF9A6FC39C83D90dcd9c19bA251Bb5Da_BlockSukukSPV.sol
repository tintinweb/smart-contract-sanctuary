/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract BlockSukukSPV {
    address owner;
    uint maturity;
    uint faceValue;
    uint paymentFrequency;
    uint issueSize;
    uint sakk;
    address obligor;
    string profitRate;
    string sukukType;
    uint SCoin;
    
constructor() { 
    owner = msg.sender; 
    faceValue = 1000;
    issueSize = 1000000000;
    sakk = 1000000;
    profitRate = "4%";
    sukukType= "Murabaha";
    SCoin= 1000000000;
    paymentFrequency = block.timestamp+ 3 minutes;
    maturity = block.timestamp+ 5*365 days;
}
 
uint numInvestors;
address[] investorList;
uint[]  transactionList;
uint numTransactions;
uint  numSukuk;
uint  proceedsPayment;
uint  ID = 786;
      
function registerObligor() public {
    obligor= msg.sender;
}      
      
function enterProceeds(uint amount) public {
    if(msg.sender!=obligor){ revert();}
     SCoin+=100;
     amount-=100;
     proceedsPayment+= amount;
     
}

struct Investor{
      address investor;
      uint ownSukuk;
      uint[] transactionID;
      string name;
      uint investorID;
      uint time;
      uint sukukCoin;
      uint profitReceived;
  }

mapping (address=>Investor)investors;	

struct Transaction{
    address sender;
    uint receiverID;
    uint ID;
    uint amount;
    uint time;  
} 

mapping(uint=>Transaction)transactions;

function newInvestor(string memory name) public {
         numInvestors++;
         investors[msg.sender].name=name;
         investors[msg.sender].investor=msg.sender;
         investors[msg.sender].investorID=numInvestors;
         investors[msg.sender].ownSukuk=0;
         investors[msg.sender].sukukCoin=0;
         investorList.push(msg.sender);
   
        }

function buyCoins( uint amount) public {
        
         investors[msg.sender].sukukCoin += amount;
         numTransactions++;
         transactions[numTransactions].ID=numTransactions;
         transactions[numTransactions].sender=msg.sender;
         transactions[numTransactions].receiverID=786;
         transactions[numTransactions].ID=numTransactions;
         transactions[numTransactions].amount=amount;
         transactionList.push(numTransactions);
         transactions[numTransactions].time=block.timestamp;
    }

function investInSukuk(uint amount) public {
       
        if(investors[msg.sender].sukukCoin<amount){ revert(); }
        investors[msg.sender].sukukCoin -= amount;
        uint noSakk = amount/1000;
        numSukuk+= noSakk;
	investors[msg.sender].ownSukuk = noSakk; 
        numTransactions++;
        Transaction storage t=transactions[numTransactions];
        t.sender=msg.sender;
        t.receiverID=786;
        t.ID=numTransactions++;
        t.amount=amount;
        transactionList.push(t.ID);
        t.time=block.timestamp;
	
    }

function automaticPayment()public {
    require(block.timestamp >= paymentFrequency);
    if(msg.sender!=owner){revert();}
    uint track;
    uint counter=numInvestors;
    while(counter>0){
              address i= investorList[track];
              uint factor=investors[i].ownSukuk;
              uint profit = (factor*4*proceedsPayment)/100;
              investors[i].profitReceived=profit;
              investors[i].sukukCoin+=profit;
              proceedsPayment-=profit;
              Transaction storage t=transactions[numTransactions++];
              t.sender=msg.sender;
              t.receiverID=investors[i].investorID;
              t.ID=numTransactions++;
              t.amount=investors[i].profitReceived;
              transactionList.push(t.ID);
              t.time=block.timestamp;
              track++;
              counter--;      
              }         
    }

function getInvestor()public view returns(string memory name, uint sukukCoin, uint ownSukuk, uint profitReceived, uint[] memory transactionID){
       name=investors[msg.sender].name;
       sukukCoin=investors[msg.sender].sukukCoin;
       ownSukuk=investors[msg.sender].ownSukuk;
       transactionID=investors[msg.sender].transactionID;
       profitReceived = investors[msg.sender].profitReceived;
      return (name, sukukCoin, ownSukuk, profitReceived, transactionID);
  }
  
function getTransactionById(uint tID)public view returns(address sender, uint receiverID, uint amount, uint time){
       sender=transactions[tID].sender;
       receiverID=transactions[tID].receiverID;
       amount=transactions[tID].amount;
       time=transactions[tID].time;
      return (sender, receiverID, amount, time);
  }

function getOwner()public view returns(address ownersc){
        return owner;
    }  
  
function getTransactionList()public view returns(uint[] memory List){
      uint[] storage list= transactionList;
      return list;
  } 
  
function getInvestorList()public view returns(address[] memory List){
      List= investorList;
      return List;
  }
}