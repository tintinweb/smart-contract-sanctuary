/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.5.8;

contract sender{
    address owner;
    constructor () public{
        owner = msg.sender;
    }

    function transferTo(address to, uint amount) public{
        (bool success,) = to.call.value(amount)("");
        require (success);
    }
    function() external payable{}
}