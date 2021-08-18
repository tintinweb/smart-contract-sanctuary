/**
 *Submitted for verification at polygonscan.com on 2021-08-18
*/

pragma solidity 0.5.17;

contract TipbotTracker
{
    address payable public  tipbotAddress;
    
    constructor (address payable _tipbotAddress)
    public
    {
        tipbotAddress = _tipbotAddress;
    }
    
    event DepositReceived (uint amount, uint discordUserid);
   
    function deposit (uint discordUserid)
    payable
    public
    {
        require (msg.value != 0, "cannot deposit zero tokens");
        tipbotAddress.transfer(msg.value);
        emit DepositReceived (msg.value, discordUserid);
       
    }
       
}