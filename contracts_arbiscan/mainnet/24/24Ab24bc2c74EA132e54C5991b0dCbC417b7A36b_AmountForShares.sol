/**
 *Submitted for verification at arbiscan.io on 2021-12-14
*/

pragma solidity 0.6.12;



contract AmountForShares {

    function generatePositionkey(address _hyperliquidrium, int24 tickLower, int24 tickUpper) public view returns(bytes32) {
        bytes32 positionKey = keccak256(abi.encodePacked(_hyperliquidrium, tickLower, tickUpper));
        return positionKey;
    }
}