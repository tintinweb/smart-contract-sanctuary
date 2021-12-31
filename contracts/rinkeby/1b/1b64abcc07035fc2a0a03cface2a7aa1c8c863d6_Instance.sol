/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// hevm: flattened sources of src/Factory.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

////// src/Instance.sol
/* pragma solidity ^0.8.0; */

contract Instance {

    event TestCall();

    constructor() {}
    
    function testCall() external {
        emit TestCall();
    }
    
}