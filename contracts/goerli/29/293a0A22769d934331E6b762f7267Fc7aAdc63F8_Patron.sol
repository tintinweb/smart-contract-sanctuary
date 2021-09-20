/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity ^0.6.0;

contract Patron {
    
    address payable _patron;
    
    mapping(address => bool) public whiteList;
    
    
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    
    constructor() public {
        _patron = msg.sender;
         whiteList[msg.sender] = true;
    }
    
    modifier onlyPatron(){
        require(isPatron(),"You are not BOSS sry :(");
        _;
    }
    
     modifier onlyWhitelisted() {
        require(isWhiteListed(msg.sender),"You are not mini BOSS also :(");
        _;
    }
     modifier patronOrWhitelisted() {
        require(isPatron() || whiteList[msg.sender], "You are nothing, go fuck yourself !!!");
        _;
    }
    function setWhiteList(address _who) public onlyPatron {
     
      whiteList[_who] = true;
      emit AddedToWhitelist(_who);
    }
    
    function removeFromWhiteList(address _address) public onlyPatron {
        
        whiteList[_address] = false;
         emit RemovedFromWhitelist(_address);
    }
    
    function isPatron() public view returns(bool){
        return (msg.sender == _patron); 
    }
    function isWhiteListed(address _address) public view returns(bool){
        return whiteList[_address]; 
    }
    
    
}