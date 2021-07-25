/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract PairVault {
    constructor() public {
    }
}

abstract contract PairsHolder {
    mapping(address => address) internal pair_vaults;
    address[] public pairs;

    function _addPairToTrack(address pair) internal {
        require(!isPair(pair), "Already tracking");
        require(pairs.length < 25, "Maximum 25 LP Pairs reached");
        pair_vaults[pair] = address(new PairVault());
        pairs.push(pair);
    }

    function isPair(address account) public view returns (bool) {
        return getPairVault(account) != address(0);
    }

    function getPairVault(address pair) public view returns (address) {
        return pair_vaults[pair];
    }

    function pairsLength() public view returns (uint256) {
        return pairs.length;
    }
}