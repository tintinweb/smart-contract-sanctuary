/**
 *Submitted for verification at BscScan.com on 2021-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StratX2.sol";

contract StratX2_PCS is StratX2 {
    constructor(
        address[] memory _addresses,
        uint256 _pid,
        bool[] memory _flags,
        address[] memory _earnedToCHERRYPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _entranceFeeFactor,
        uint256 _distributionRatio,
        uint256 _withdrawFeeFactor
    ) public {
        wbnbAddress = _addresses[0];
        govAddress = _addresses[1];
        cherryFarmAddress = _addresses[2];
        CHERRYAddress = _addresses[3];

        wantAddress = _addresses[4];
        token0Address = _addresses[5];
        token1Address = _addresses[6];
        earnedAddress = _addresses[7];

        farmContractAddress = _addresses[8];
        pid = _pid;
        isCAKEStaking = _flags[0];
        isSameAssetDeposit = _flags[1];
        isCherryComp = _flags[2];
        isVaultComp = _flags[3];

        uniRouterAddress = _addresses[9];
        earnedToCHERRYPath = _earnedToCHERRYPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;

        controllerFee = _controllerFee;
        rewardsAddress = _addresses[10];
        buyBackRate = _buyBackRate;
        buyBackAddress = _addresses[11];
        depositFeeFundAddress = _addresses[12];
        delegateFundAddress = _addresses[13];
        entranceFeeFactor = _entranceFeeFactor;
        distributionDepositRatio = _distributionRatio;
        withdrawFeeFactor = _withdrawFeeFactor;

        transferOwnership(cherryFarmAddress);
    }
}