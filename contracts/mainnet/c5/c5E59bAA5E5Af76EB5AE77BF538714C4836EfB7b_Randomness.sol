// SPDX-License-Identifier: --GRISE--
pragma solidity =0.7.6;

import "./nreAPI.sol";

contract Randomness is usingNRE { 
    
   function stateRandomNumber() public returns (uint256) {
       uint256 randomNumber;
       randomNumber = (rm()%(10**5));
       return randomNumber;
    }
 
}