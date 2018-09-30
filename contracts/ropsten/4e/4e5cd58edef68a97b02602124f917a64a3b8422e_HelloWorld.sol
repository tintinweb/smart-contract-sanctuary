pragma solidity ^0.4.18;
contract HelloWorld {
    uint balance = 2;
    function update(uint amount) returns(address,uint){
        balance+=amount;
        return(msg.sender,balance);
    }
}