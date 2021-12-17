/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}

// Another order for 150 USD.
// Modify this contract https://snowtrace.io/token/0x863b6b50088c120baa37fe0a10a6fd90ca47a9f5
// Main issue here is reflection of other token.
// Can we make sure reflection works, even if the reflection token is paired to MIM token, not AVAX?
// Our token may be paired to either AVAX or MIM too ( https://snowtrace.io/address/0x130966628846BFd36ff31a822705796e8cb8C18D )
// Maybe you test and see that it should work without modifications. But my friend told me that when they deploy the token in pair to AVAX, they cannot get reflection from a token which is paired to MIM.So main requirement: make sure reflection still works as on original contract, despite the reflection token is paired to MIM instead of AVAX (as on original token).