pragma solidity ^0.4.24;

contract depowithdraw {

    uint public timesCalled = 0;
    
    function reset() public{
        timesCalled = 0;
    }

    function() public payable{
        timesCalled++;
        if(msg.value>0){
            msg.sender.transfer(msg.value);
        }
    }
}