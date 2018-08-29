pragma solidity ^0.4.17;

contract EtherTransferTo{
    function () public payable{
        
    }
    
    function getBalance()public returns(uint){
        return address(this).balance;
    }
}