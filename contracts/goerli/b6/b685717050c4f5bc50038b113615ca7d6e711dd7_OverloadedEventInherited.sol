/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.6.0;

contract OverloadedEvent {

    event TheEvent(address a);

    function emitAddrEvent(address _a) external {
        emit TheEvent(_a);
    }
}

contract OverloadedEventInherited is OverloadedEvent {

    event TheEvent(uint256 n);
    
    function emitUintEvent(uint256 _n) external {
        emit TheEvent(_n);
    }
}