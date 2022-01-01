/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

pragma solidity ^0.7.1;

    contract test {

        uint _multiplier;
        uint multipliedResult;

        constructor (uint multiplier){
             _multiplier = multiplier;
        }

        function multiply(uint a) public returns(uint)  {
            multipliedResult = a * _multiplier;
            return a * _multiplier;
        }

        function getMultiplier() public view returns (uint) {
            return multipliedResult;
        }
    }