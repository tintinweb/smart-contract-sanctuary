pragma solidity ^0.4.25;

contract IncCounter {
    
    uint private counter;
    address public owner;
    address public approvedAddress;
    
    constructor() {
        
        owner = msg.sender;
    }
    
    
    function setApprovedAddress(address _setApprovedAddress){
        
        if (_setApprovedAddress == msg.sender)
        
        approvedAddress = _setApprovedAddress;
        
    }
    
    
    function incremCounter() public {
        
       if (msg.sender == owner || msg.sender == approvedAddress)
       
       counter = counter + 1; 
        
    }
    
    function getCount() public view returns (uint256){
    
        return counter;
    }
    
    
    
    
}