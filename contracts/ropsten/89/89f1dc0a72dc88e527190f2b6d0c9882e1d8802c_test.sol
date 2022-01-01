/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

pragma solidity ^0.7.1;

    contract test {

        uint _multiplier;

        constructor (uint multiplier){
             _multiplier = multiplier;
        }

        function multiply(uint a) public view returns (uint)  {
            return a * _multiplier;
        }

    }