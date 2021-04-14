/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.6.12;

contract ChainlinkOracle {

    constructor() public {
    }

    /**
     * Returns the latest price
     */
    function getPrice() public pure returns (uint256) {
        return 2 * 10**21;
    }
}