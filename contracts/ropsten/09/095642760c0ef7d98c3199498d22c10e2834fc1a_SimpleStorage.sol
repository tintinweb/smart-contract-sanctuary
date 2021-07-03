/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity >=0.4.0 <0.7.0;

contract SimpleStorage {
    // put the state variable here
    uint storedData;
    
    function set(uint _storedData) public returns (uint) {
        storedData = _storedData + storedData;
    }
    
   function get() public view returns (uint256) {
    return storedData;
  }
}

// SPDX-License-Identifier: <SPDX-License>