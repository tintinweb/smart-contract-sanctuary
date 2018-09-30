pragma solidity ^0.4.0;

contract Hello{
    
    address owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    function etherBack() payable{
        msg.sender.transfer(msg.value);
    }
}