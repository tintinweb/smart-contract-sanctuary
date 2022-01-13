/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


error NoTokensLeft();

contract test {
    uint256 private devMints = 0;

    constructor () {

    }

    modifier devMintLimit() {
        require(devMints < 6, "Devs only promised 3 free mints each");
        _;
    }

    function devMint(uint16 amount) external devMintLimit() {
        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                devMints++;
            }
        }
    }

}