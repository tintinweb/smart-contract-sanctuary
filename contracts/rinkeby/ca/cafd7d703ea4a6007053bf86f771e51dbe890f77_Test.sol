/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test {
    address public opensea;
    event CallResult(bool res, bytes return_value);
    constructor (address _opensea) {
        opensea = _opensea;
    }
    
    function exchangeOpenSearch(
        address[14] memory _addrs,
        uint[18] memory _uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) public payable {
        bytes memory _calldata = abi.encodeWithSelector(
            bytes4(keccak256(abi.encodePacked("atomicMatch_()"))), 
            _addrs, 
            _uints, 
            feeMethodsSidesKindsHowToCalls,
            calldataBuy,
            calldataSell,
            replacementPatternBuy,
            replacementPatternSell,
            staticExtradataBuy,
            staticExtradataSell,
            vs,
            rssMetadata
        );
        (bool result, bytes memory return_data) = opensea.call{value: msg.value}(_calldata);
        // require(result, 'run with error');
        emit CallResult(result, return_data);
    }
}