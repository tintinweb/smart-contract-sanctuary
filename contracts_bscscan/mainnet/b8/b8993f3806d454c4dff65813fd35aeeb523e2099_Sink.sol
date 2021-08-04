/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity ^0.6.0;

// This contract keeps all Ether sent to it with no way
// to get it back.
contract Sink {
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}