pragma solidity ^0.4.24;

contract returnBalance{
    
    constructor () public payable{
        
    }
    
    function returnSender() public view returns (address){
        return msg.sender;  
    }
    
    function returnSenderBalance() public view returns (uint256){
        return msg.sender.balance;  
    }
    
    function transferMoney(address _to) public payable {
        
        _to.transfer(msg.value);
        
    }
    
}