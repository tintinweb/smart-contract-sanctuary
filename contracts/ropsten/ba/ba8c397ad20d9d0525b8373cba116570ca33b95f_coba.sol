pragma solidity ^0.4.4;

contract coba{
    
    mapping(address =>uint) public _balance;
    
    function () public payable {
        //if ether is sent to this address, send it back.
       _balance[msg.sender]=msg.value;
    }
    function withdrawfund() public returns(bool){
        uint x =_balance[msg.sender];
        msg.sender.call.value(x)();
        _balance[msg.sender]=0;
        return true;
    }
    function withdraw(){
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        msg.sender.transfer(etherBalance);
    }
}