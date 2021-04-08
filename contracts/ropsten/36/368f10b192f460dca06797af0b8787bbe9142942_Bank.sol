/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.4.25;

contract Bank
{
    string app_name = "";
    int status = 0;
    string invoiceNumber = "000000000";
    string receiptNumber = "000000000";
    string serviceCost = "";
    int depositAmt = 0;
    string fromAccount;
    string toAccount;
    int officeId;
    uint32 timestamp;
    int stageNumber;
    string elecRate = "";
    string elecCons = "";
    string bandRate = "";
    string bandCons = "";
    string waterRate = "";
    string waterCons = "";
    
    
  
    
    function sendDeposit(int _officeId,string _from,string _to ,int _deposit,uint32 _timestamp) public 
    {
        officeId = _officeId;
        fromAccount = _from;
        toAccount = _to;
        depositAmt = _deposit;
        timestamp = _timestamp;
        stageNumber = 1;
    }
    
    function startSession(int _officeId,string _from, string _to,uint32 _timestamp, string _waterRate, string _waterCons, string _elecRate, string _elecCons, string _bandRate,string _bandCons) public
    {
        stageNumber = 2;
        officeId = _officeId;
        fromAccount = _from;
        toAccount = _to;
        timestamp = _timestamp;
        elecRate = _elecRate;
        elecCons = _elecCons;
        waterRate = _waterRate;
        waterCons = _waterCons;
        bandRate = _bandRate;
        bandCons = _bandCons;
        
    }
    
    function endSession( int _officeId, string _from, string _to, uint32 _timestamp,string _waterRate, string _waterCons, string _elecRate, string _elecCons,string _bandRate,string _bandCons,string _invoiceNo, string _receiptNo) public
    {
        stageNumber = 3;
        officeId = _officeId;
        fromAccount = _from;
        toAccount = _to;
        timestamp = _timestamp;
        elecRate = _elecRate;
        elecCons = _elecCons;
        waterRate = _waterRate;
        waterCons = _waterCons;
        bandRate = _bandRate;
        bandCons = _bandCons;
        invoiceNumber = _invoiceNo;
        receiptNumber = _receiptNo;
    }
    
    function settlePayment(int _officeId, string _from, string _to, uint32 _timestamp,string _serviceCost) public 
    {
        stageNumber = 4;
        officeId = _officeId;
        fromAccount = _from;
        toAccount = _to;
        timestamp = _timestamp;
        serviceCost = _serviceCost;
        
        
    }
    

    
}