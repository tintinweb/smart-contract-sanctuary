/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// File: contracts/AprilFools.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * Follow me on Twitter https://moo9000
 */
contract AprilFools {

    string public aprilFools;

    constructor() {
        // Create initial supply on the deployer account
        aprilFools = "April Fools!";
    }
}