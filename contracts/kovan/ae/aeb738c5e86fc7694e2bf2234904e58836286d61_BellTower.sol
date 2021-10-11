/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.8.4;

contract BellTower{
    uint public bellRung;

    //for logging purpose
    event BellRung(uint rangForTheNthTime, address whoRang);

    function ringTheBell() public {
        bellRung++;
        emit BellRung(bellRung, msg.sender);
    }
}