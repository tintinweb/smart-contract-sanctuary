/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity ^0.8.4;

contract BellTower {
    uint public bellRung;

    event BellRung(address sender, uint rangTime);

    function ringTheBell() public {
        bellRung++;

        emit BellRung(msg.sender, bellRung);
    }
}