/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

abstract contract DistributorBase {
    event Distribute(address indexed from, address indexed to, uint256 amount);

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
            emit Distribute(msg.sender, addresses[i], amounts[i]);
        }
        require(
            address(this).balance == 0,
            "Ether input must equal the sum of outputs"
        );
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