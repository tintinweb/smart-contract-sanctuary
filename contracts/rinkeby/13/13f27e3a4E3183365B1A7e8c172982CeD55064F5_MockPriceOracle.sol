/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.5.16;

contract MockPriceOracle {
    function getUnderlyingPrice(address cToken) public view returns (uint) {
        // Shh -- currently unused
        cToken;
        return 2e18;
    }
}