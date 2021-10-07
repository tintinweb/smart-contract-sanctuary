/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

contract EncodeTest
{
    function encodeTest(
        address _msgSender,
        address _fromAsset,
        uint256 _fromAmount,
        uint256 _toExpectedAmount,
        uint32 _refCode,
        uint256 _timestamp) external pure returns (bytes memory) {

        return abi.encode(
            _msgSender,
            _fromAsset,
            _fromAmount,
            _toExpectedAmount,
            _refCode,
            _timestamp);
    }
}