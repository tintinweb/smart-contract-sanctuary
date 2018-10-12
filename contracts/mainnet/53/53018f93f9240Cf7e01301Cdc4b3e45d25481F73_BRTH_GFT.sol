pragma solidity ^0.4.20;

contract BRTH_GFT
{
    address sender;
    
    address reciver;
    
    bool closed = false;
    
    uint unlockTime;
 
    function Put_BRTH_GFT(address _reciver) public payable {
        if( (!closed&&(msg.value > 1 ether)) || sender==0x00 )
        {
            sender = msg.sender;
            reciver = _reciver;
            unlockTime = now;
        }
    }
    
    function SetGiftTime(uint _unixTime) public canOpen {
        if(msg.sender==sender)
        {
            unlockTime = _unixTime;
        }
    }
    
    function GetGift() public payable canOpen {
        if(reciver==msg.sender)
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    function CloseGift() public {
        if(sender == msg.sender && reciver != 0x0 )
        {
           closed=true;
        }
    }
    
    modifier canOpen(){
        if(now>unlockTime)_;
        else return;
    }
    
    function() public payable{}
}