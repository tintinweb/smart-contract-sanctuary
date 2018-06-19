pragma solidity ^0.4.11;

/*
    Contract to force hodl 
*/
contract Owned {
    address public owner;
    
}

/*
Master Contract for Forcing Users to Hodl.
*/
contract HodlContract{
    
    HodlStruct[] public hodls; 
    address FeeAddress;
    
    event hodlAdded(uint hodlID, address recipient, uint amount, uint waitTime);
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    
    
    struct HodlStruct {
        address recipient;
        uint amount;
        uint waitTime;
        bool executed;
    }
  
   function HodlEth(address beneficiary, uint daysWait) public payable returns (uint hodlID) 
   {
       uint FeeAmount;
       FeeAddress = 0x9979cCFF79De92fbC1fb43bcD2a3a97Bb86b6920; 
        FeeAmount = msg.value * 1/100; //1% fee because you don&#39;t have the self control to hodl yourself.
        FeeAddress.transfer(FeeAmount);
        
        hodlID = hodls.length++;
        HodlStruct storage p = hodls[hodlID];
        p.waitTime = now + daysWait * 1 days;
        p.recipient = beneficiary;
        p.amount = msg.value * 99/100;
        p.executed = false;

        hodlAdded(hodlID, beneficiary, msg.value, p.waitTime);
        return hodlID;
        
    }
    
    function Realize(uint hodlID) public payable returns (uint amount){
    HodlStruct storage p = hodls[hodlID];
    require (now > p.waitTime  //Didn&#39;t wait long enough.
    && !p.executed //Not already executed.
    && msg.sender == p.recipient); //Only recipient as sender can get ether back.
        
        msg.sender.transfer(p.amount); // transfer the ether to the sender.
        p.executed = true;
        return p.amount;
    }
    
    
    function FindID(address beneficiary) public returns (uint hodlID){ //Emergency if user lost HodlID
        HodlStruct storage p = hodls[hodlID];
        
        for (uint i = 0; i <  hodls.length; ++i) {
            if (p.recipient == beneficiary && !p.executed ) {
                return hodlID;
            } else {
                revert();
            }
        }
        
    }
    
}