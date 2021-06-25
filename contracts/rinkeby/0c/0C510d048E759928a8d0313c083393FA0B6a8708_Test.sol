/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity ^0.6.2;

contract Test {
    uint256 private constant MAX = ~uint256(0); // Testing

    function expand(
        uint256 randomValue,
        uint256 n,
        uint256 length
    ) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            uint256 tes = MAX / (randomValue - i + length);
            expandedValues[i] =
                (uint256(keccak256(abi.encode(randomValue, tes)))) %
                length;
        }
        return expandedValues;
    }
}