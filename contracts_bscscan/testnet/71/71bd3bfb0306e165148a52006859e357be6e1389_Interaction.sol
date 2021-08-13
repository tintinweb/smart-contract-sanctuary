/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity ^0.4.24;


// SPDX-License-Identifier: MIT

interface IgenRan {
    function expandX(uint256 randomVa, uint256 nn, uint256 xx) external view returns (uint256);
    //function increment() external;
}

contract Interaction {


    function getCount(uint256 randomValue, uint256 n, uint256 x) external view returns (uint256) {
        return IgenRan(0xee514eD5875D1E2Ee5Add8f319038DF38827fEaa).expandX(randomValue,  n,  x);
    }
}