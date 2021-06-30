/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// File: contracts/ExchangeRegistry.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExchangeRegistry {
    address owner;
    // frm asset -> to assets -> contract address
    mapping(address => mapping(address => address)) pairs;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getPair(address _from, address _to) public view returns (address) {
        return pairs[_from][_to];
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function addOrChangePair(
        address _from,
        address _to,
        address _contract
    ) external onlyOwner {
        require(_contract != address(0), "contract address should not be zero");
        pairs[_from][_to] = _contract;
    }

    function addOrChangePairBulk(
        address[] memory _fromList,
        address[] memory _toList,
        address[] memory _contractList
    ) external onlyOwner {
        for (uint256 i = 0; i < _contractList.length; i++) {
            require(
                _contractList[i] != address(0),
                "contract address should not be zero"
            );
            pairs[_fromList[i]][_toList[i]] = _contractList[i];
        }
    }

    function removePair(address _from, address _to) external onlyOwner {
        delete pairs[_from][_to];
    }
}