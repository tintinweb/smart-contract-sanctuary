// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

/**
    @title Dummy MPHMinter that doesn't mint anything. For legacy support.
*/
contract MPHMinterLegacy {
    function mintDepositorReward(
        address, /*to*/
        uint256, /*depositAmount*/
        uint256, /*depositPeriodInSeconds*/
        uint256 /*interestAmount*/
    ) external pure returns (uint256) {
        return 0;
    }

    function takeBackDepositorReward(
        address, /*from*/
        uint256, /*mintMPHAmount*/
        bool /*early*/
    ) external pure returns (uint256) {
        return 0;
    }

    function mintFunderReward(
        address, /*to*/
        uint256, /*depositAmount*/
        uint256, /*fundingCreationTimestamp*/
        uint256, /*maturationTimestamp*/
        uint256, /*interestPayoutAmount*/
        bool /*early*/
    ) external pure returns (uint256) {
        return 0;
    }
}

