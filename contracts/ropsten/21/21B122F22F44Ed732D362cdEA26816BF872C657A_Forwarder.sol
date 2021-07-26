/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity ^0.8.6;

contract Forwarder 
{
    function forward(address payable _to)
    payable
    public
    {
        _to.transfer(address(this).balance);
    }
}