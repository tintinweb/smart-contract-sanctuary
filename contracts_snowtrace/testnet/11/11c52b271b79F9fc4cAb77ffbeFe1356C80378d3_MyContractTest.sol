/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;

contract MyContractTest {
    string public myString = "Hello world!";

    uint256 public myUint;

    function setMyUint(uint256 _myUint) public {
        myUint = _myUint;
    }

    function increaseMyUint(uint _increaseUint) public {
        myUint = myUint - _increaseUint;
    }

}