/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

pragma solidity 0.6.12;

contract GettingTime {
   
    constructor() public {}

    function gettingtime() public view returns (uint256) {
        return now;
    }
}