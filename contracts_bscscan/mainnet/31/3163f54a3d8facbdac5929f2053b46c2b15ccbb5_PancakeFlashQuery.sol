/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

abstract contract PancakeFactory  {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    function allPairsLength() external view virtual returns (uint);
}

// In order to quickly load up data from Pancake-like market, this contract allows easy iteration with a single eth_call
contract PancakeFlashQuery {
    function getReservesByPairs(IPancakePair[] calldata _pairs) external view returns (uint256[3][] memory) {
        uint256[3][] memory result = new uint256[3][](_pairs.length);
        for (uint i = 0; i < _pairs.length; i++) {
            (result[i][0], result[i][1], result[i][2]) = _pairs[i].getReserves();
        }
        return result;
    }

    function getPairsByIndexRange(PancakeFactory _pancakeFactory, uint256 _start, uint256 _stop) external view returns (address[3][] memory)  {
        uint256 _allPairsLength = _pancakeFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }
        require(_stop >= _start, "start cannot be higher than stop");
        uint256 _qty = _stop - _start;
        address[3][] memory result = new address[3][](_qty);
        for (uint i = 0; i < _qty; i++) {
            IPancakePair _pancakePair = IPancakePair(_pancakeFactory.allPairs(_start + i));
            result[i][0] = _pancakePair.token0();
            result[i][1] = _pancakePair.token1();
            result[i][2] = address(_pancakePair);
        }
        return result;
    }

    function getPairReservesByIndexRange(PancakeFactory _pancakeFactory, uint256 _start, uint256 _stop) external view returns (address[3][] memory, uint256[3][] memory)  {
        uint256 _allPairsLength = _pancakeFactory.allPairsLength();
        if (_stop > _allPairsLength) {
            _stop = _allPairsLength;
        }
        require(_stop >= _start, "start cannot be higher than stop");
        uint256 _qty = _stop - _start;
        address[3][] memory pairs = new address[3][](_qty);
        uint256[3][] memory reserves = new uint256[3][](_qty);
        for (uint i = 0; i < _qty; i++) {
            IPancakePair _pancakePair = IPancakePair(_pancakeFactory.allPairs(_start + i));
            pairs[i][0] = _pancakePair.token0();
            pairs[i][1] = _pancakePair.token1();
            pairs[i][2] = address(_pancakePair);
            (reserves[i][0], reserves[i][1], reserves[i][2]) = _pancakePair.getReserves();
        }
        return (pairs, reserves);
    }
}