/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity >= 0.4.22 <0.7.0;

contract Donate
{
    int persons = 0;
    function Donation() public payable
    {
        persons = persons + 1;
    }
}