/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

abstract contract DistributorBase {
    function _distribute(
        address payable[] calldata addresses,
        uint256[] calldata amounts
    ) internal {
        require(
            addresses.length == amounts.length,
            "Address array and amount array must have the same length"
        );
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            addresses[i].transfer(amounts[i]);
        }
        require(
            address(this).balance == 0,
            "Ether input must equal the sum of outputs"
        );
    }
}

contract DistributorOwned is DistributorBase {
    address public owner;

    constructor(address o) {
        owner = o;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function distribute(
        address payable[] calldata addresses,
        uint256[] calldata amounts
    ) public payable onlyOwner {
        _distribute(addresses, amounts);
    }
}

contract Distributor is DistributorBase {
    function distribute(
        address payable[] calldata addresses,
        uint256[] calldata amounts
    ) public payable {
        _distribute(addresses, amounts);
    }
}