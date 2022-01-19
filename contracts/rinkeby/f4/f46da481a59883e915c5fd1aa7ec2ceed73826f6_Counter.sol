/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Counter {
    uint public Count;

    function get() public view returns (uint ) {

        return Count;

    }

    function Incr() public {
        Count ++;
    }
}