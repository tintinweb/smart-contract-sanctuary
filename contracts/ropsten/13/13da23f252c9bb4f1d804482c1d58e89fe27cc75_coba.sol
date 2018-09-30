pragma solidity ^0.4.4;

contract coba{
    
    function () public payable {
        //if ether is sent to this address, send it back.
       
    }
    
    function withdraw(){
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        msg.sender.transfer(etherBalance);
    }
}