/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

contract Tester {
    uint8 constant private left = 0;
    uint8 constant private right = 1;
    
    struct Component {
        address a;
        uint256 x;
        uint256 y;
    }

    struct Pair {
        uint256 id;
        Component[][2] components;
    }

    mapping(uint256 => Pair) public pairs;
    uint256 private pairsEnd;

    constructor() {
    }

    function add(Component[] calldata _left, Component[] calldata _right) external {
        uint i;
        for (i = 0; i < _left.length; i++) {
            pairs[pairsEnd].components[left].push(_left[i]);
        }
        for (i = 0; i < _right.length; i++) {
            pairs[pairsEnd].components[right].push(_right[i]);
        }
        pairsEnd += 1;
    }

    function pair(uint256 _pairId) view public returns(Pair memory) {
        require(_pairId < pairsEnd, "Invalid pairId");
        return pairs[_pairId];
    }
}