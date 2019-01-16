pragma solidity ^0.4.17;

contract Ping {
    event Pong(uint256 pong);
    uint256 public pings;
    function ping(uint256 value) external {
        pings++;
        emit Pong(pings + value);
    }
}