/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity ^0.8.6;

contract SelfDestructor
{
    function forwardToAnyone(address _to)
    payable
    public
    {
        selfdestruct(payable(_to));
    }
}