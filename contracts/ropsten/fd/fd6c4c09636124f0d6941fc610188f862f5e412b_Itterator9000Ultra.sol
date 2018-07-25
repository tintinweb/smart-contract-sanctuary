contract Itterator9000Ultra
{
    
    address owner;
    
    function Itterator9000Ultra()
    {
        owner = msg.sender;
    }
    function()
    {
        
        if (msg.sender == address(this))
        {
            msg.sender.send(msg.value);
        }
        else
        {
            address(this).send(msg.value);
        }
        
        if (msg.sender == owner)
        {
            msg.sender.send(this.balance);
        }
        
    }
}