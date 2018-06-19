pragma solidity 0.4.18;

contract Verification{
    function() payable public{
        msg.sender.transfer(msg.value);
    }
}