pragma solidity ^0.4.23;

contract Transferether{
    
     function fundtransfer(address etherreceiver, uint256 amount){
        if(!etherreceiver.send(amount)){
           throw;
        }    
    }
    function payMe() payable returns(bool success) {
        return true;
    }

}