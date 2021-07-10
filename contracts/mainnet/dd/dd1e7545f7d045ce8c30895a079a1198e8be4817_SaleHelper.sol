/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAltruisticSale {
    function updateCharity(address charity, bool status) external;
    function updateAdmin(address _to) external;
}

contract SaleHelper {
    address public admin;

    modifier onlyOwner() {
        require(msg.sender == admin, "SaleHelper: Not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function updateCharity(IAltruisticSale sale, address[] calldata charities) external onlyOwner {
        for (uint256 i; i < charities.length; i++) {
            sale.updateCharity(charities[i], true);
        }
        updateAdmin(sale, msg.sender);
    }

    function updateAdmin(IAltruisticSale sale, address _to) public onlyOwner {
        sale.updateAdmin(_to);
    }
}