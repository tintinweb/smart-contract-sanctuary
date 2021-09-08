// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title DegenGang Treasury Contract
 */
contract Treasury is Ownable {
    using SafeMath for uint256;

    address public clientAddress;
    address public devAddress;
    address public teamMemberA;
    address public teamMemberB;
    address public communityAddress;

    constructor(
        address client,
        address dev,
        address memberA,
        address memberB,
        address community
    ) {
        clientAddress = client;
        devAddress = dev;
        teamMemberA = memberA;
        teamMemberB = memberB;
        communityAddress = community;
    }

    receive() external payable {}

    /**
     * Withdraw the Treasury from Opensea Fee
     */
    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 restAmount = totalBalance;

        uint256 clientAmount = totalBalance.mul(1750).div(10000); // 17.5% of All Amount - 0.875% of Opensea Fee (5%)
        restAmount = restAmount.sub(clientAmount);

        uint256 devAmount = totalBalance.mul(1750).div(10000); // 17.5% of All Amount - 0.875% of Opensea Fee (5%)
        restAmount = restAmount.sub(devAmount);

        uint256 memberAAmount = totalBalance.mul(1750).div(10000); // 17.5% of All Amount - 0.875% of Opensea Fee (5%)
        restAmount = restAmount.sub(memberAAmount);

        uint256 memberBAmount = totalBalance.mul(1750).div(10000); // 17.5% of All Amount - 0.875% of Opensea Fee (5%)
        restAmount = restAmount.sub(memberBAmount);

        uint256 communityAmount = restAmount;    // 30% of All Amount - 1.5% of Opensea Fee (5%)

        // Withdraw To Client
        (bool withdrawClient, ) = clientAddress.call{value: clientAmount}("");
        require(withdrawClient, "Withdraw Failed To Client.");

        // Withdraw To Dev
        (bool withdrawDev, ) = devAddress.call{value: devAmount}("");
        require(withdrawDev, "Withdraw Failed To Dev");

        // Withdraw To MemberA
        (bool withdrawMemberA, ) = teamMemberA.call{value: memberAAmount}("");
        require(withdrawMemberA, "Withdraw Failed To Member A");

        // Withdraw To MemberB
        (bool withdrawMemberB, ) = teamMemberB.call{value: memberBAmount}("");
        require(withdrawMemberB, "Withdraw Failed To Member B");

        // Withdraw To Community
        (bool withdrawCommunity, ) = communityAddress.call{value: communityAmount}("");
        require(withdrawCommunity, "Withdraw Failed To Community");
    }
}