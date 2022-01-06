/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT

// TEST CONTRACT. 

pragma solidity ^0.8.7;

contract gasTest {

    bool gasLimit = false;
    uint256 private gasPriceLimit = 10000000000; // 10 nAvax

    function setGasLimit(bool Argument) public {
        gasLimit = Argument;
    }

    function getGasLimit() public view returns(bool) {
      return gasLimit;
    }


}