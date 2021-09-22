/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;



interface TestNFT {
    function mint() external;
}

contract Attack {
    TestNFT testContract;
    event MintSuccess(uint256 i);
    function attack() public {
        for(uint256 i = 0; i < 5; i++) {
            testContract.mint();
            emit MintSuccess(i);
        }
    }
    constructor(){
    }
}