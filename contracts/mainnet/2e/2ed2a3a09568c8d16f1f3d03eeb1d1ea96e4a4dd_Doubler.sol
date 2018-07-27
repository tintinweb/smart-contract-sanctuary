contract Doubler
{
    address owner;

    function Doubler() payable
    {
        owner = msg.sender;
    }
    
    function() payable{
        
        if (!msg.sender.call(msg.value*2))
            revert();
    }
    
    function kill()
    {
        if (msg.sender==owner)
            suicide(owner);
    }
}