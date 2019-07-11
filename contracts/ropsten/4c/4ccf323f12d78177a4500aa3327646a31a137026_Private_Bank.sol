/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.24;

contract Private_Bank
{
    mapping (address => uint) public balances;
    
    uint public MinDeposit = 0.1 ether;
    
    Log TransferLog;

    event FLAG(string b64email, string slogan);
    


    constructor(address _log) { 
        TransferLog = Log(_log);
     }

    function Airdrop() public {
        if(balances[msg.sender] == 0) {
            balances[msg.sender]+=1 ether;
        }
    }

    function Transfer(address to, uint val) public {
        if(val > balances[msg.sender]) {
            revert();
        }
        balances[to]+=val;
        balances[msg.sender]-=val;
    }

    function CaptureTheFlag(string b64email) public returns(bool){
      require (balances[msg.sender] > 500 ether);
      emit FLAG(b64email, "Congratulations to capture the flag!");
    }

    
    function Deposit()
    public
    payable
    {
        if(msg.value > MinDeposit)
        {
            balances[msg.sender]+= msg.value;
            TransferLog.AddMessage(msg.sender,msg.value,"Deposit");
        }
    }
    
    function CashOut(uint _am) public 
    {
        if(_am<=balances[msg.sender])
        {
            
            if(msg.sender.call.value(_am)())
            {
                balances[msg.sender]-=_am;
                TransferLog.AddMessage(msg.sender,_am,"CashOut");
                revert();
            }
        }
    }
    
    function() public payable{}    
    
}

contract Log 
{
   
    struct Message
    {
        address Sender;
        string  Data;
        uint Val;
        uint  Time;
    }
    
    Message[] public History;
    
    Message LastMsg;
    
    function AddMessage(address _adr,uint _val,string _data)
    public
    {
        LastMsg.Sender = _adr;
        LastMsg.Time = now;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}