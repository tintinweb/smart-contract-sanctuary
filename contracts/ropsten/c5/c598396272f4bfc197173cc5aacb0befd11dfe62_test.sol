/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: Unlicensed
    pragma solidity ^0.8.4;

   contract test {

        uint _multiplier;

        function testmultiply(uint multiplier)public{
             _multiplier = multiplier;
        }

        function multiply(uint a) public view returns(uint d) {
             return a * _multiplier;
        }
    }