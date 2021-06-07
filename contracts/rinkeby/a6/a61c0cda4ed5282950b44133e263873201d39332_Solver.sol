/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity ^0.8.0;

interface IRobot {
    function ping(address challenger) external;
}

contract Solver {
    function solve() public {
        IRobot irobot = IRobot(0x31b4fe4120e55D92792A6ee0Dd06606E88F25635);
        irobot.ping(msg.sender);
    }
}