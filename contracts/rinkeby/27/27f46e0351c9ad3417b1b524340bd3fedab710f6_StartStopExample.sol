/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity ^0.8.1;

contract StartStopExample{
    
    //private variable
    address owner;
    bool public paused;
    
    constructor(){
        owner = msg.sender;
    }
    
    function getBalance()  public view returns (uint){
        return address(this).balance;
    }
    
    function sendMoney() public payable{
        
    }
    
    function setPaused(bool _paused) public{
        require(msg.sender == owner, "You are not allowed to pause");
        
        paused = _paused;
    }
    
    function withdrawAllMoney(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        require(!paused, "Contract is paused");
        
        _to.transfer(address(this).balance);
    }
    
    function destroySmartContract(address payable _to) public{
        require(msg.sender == owner, "You are not allowed to destruct the contract");
        selfdestruct(_to);
    }
}