pragma solidity ^0.4.24;

contract returnbalance{
    
    function returnsenderbalance() public view returns (uint){
        return msg.sender.balance;  
    }
    
}