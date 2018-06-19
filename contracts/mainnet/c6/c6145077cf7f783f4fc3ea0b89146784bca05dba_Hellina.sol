pragma solidity ^0.4.21;

contract Hellina{
    address owner;
    function Hellina(){
        owner=msg.sender;
    }
    
    function Buy() payable{
        
    }
    
    function Withdraw(){
        owner.transfer(address(this).balance);
    }
}