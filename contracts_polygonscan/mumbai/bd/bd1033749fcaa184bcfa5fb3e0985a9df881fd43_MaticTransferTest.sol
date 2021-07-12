/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.8.4;

// test to move matic from contract to contract caller

contract MaticTransferTest
{
    address payable public safety = payable(msg.sender);
   
    fallback() external payable{}
   
    function withdraw() payable public
    {
        require(msg.sender == safety);
        safety.transfer(address(this).balance);
    }
    
    // transfer function
    function maticTransfer(address payable adr) payable public
    {
        if(msg.value>=address(this).balance)
        {        
            adr.transfer(address(this).balance+msg.value);
        }
    }
}