/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity ^0.8.4;

contract BellTower {
    uint public bellRung;

    event BellRung(uint nth, address who);

    function ring() public {
        bellRung++;
        emit BellRung(bellRung, msg.sender);
    }
}