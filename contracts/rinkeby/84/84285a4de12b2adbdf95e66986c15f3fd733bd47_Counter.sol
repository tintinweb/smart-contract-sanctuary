/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

contract Counter {

    // This is our contract. Do not renege on your promises
    // There will be conseguences!
    uint256 public count = 0;

    // When the total gets to 20, you will be issued with the location of your
    // artwork. Until then pay us each day as discussed. 
    
    function increment() public {
        count += 1;
    }

    // Mystiko{etherium_contract_guru}
    function getCount() public view returns (uint256) {
        return count;
    }

}