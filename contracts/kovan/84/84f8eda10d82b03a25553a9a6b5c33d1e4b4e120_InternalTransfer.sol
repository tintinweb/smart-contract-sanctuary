/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity ^0.8.4;

contract InternalTransfer {
    
    event Send(address indexed from, address indexed to, uint256 value);
    
    function send(address payable receiver) public payable {
        receiver.transfer(msg.value);
        emit Send(msg.sender, receiver, msg.value);
    }
    
    function get() pure public returns (int)  {
        return 343;
    }
}