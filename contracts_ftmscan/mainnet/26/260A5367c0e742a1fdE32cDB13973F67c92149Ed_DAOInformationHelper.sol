/**
 *Submitted for verification at FtmScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStakingContract {
    struct Epoch {
        uint256 length;
        uint256 number;
        uint256 endBlock;
        uint256 distribute;
    }

    function epoch() external view returns (Epoch memory _epoch);
    function index() external view returns (uint256 _index);
}

interface IStakedToken {
    function circulatingSupply() external view returns (uint256 _circulatingSupply);
    function decimals() external view returns (uint8 _decimals);
    function balanceOf(address owner) external view returns (uint256 _balance);
}

interface ITimeTracker {
    function PRECISION() external view returns (uint8 _precision);
    function average() external view returns (uint256 _average);
}

contract DAOInformationHelper {
    struct Information {
        uint256 epochNumber;
        uint256 epochLength;
        uint256 epochEndBlock;
        uint256 epochDistribute;
        uint256 blockNumber;
        uint256 stakingIndex;
        uint8 stakedDecimals;
        uint256 stakedCirculatingSupply;
        uint256 blockAverage;
        uint8 blockPrecision;
        uint256 stakingBalance;
    }
    
    function info(address stakingContract, address stakedToken, address timeTracker, address stakingWallet) public view returns (
        uint256 epochNumber, 
        uint256 epochLength, 
        uint256 epochEndBlock, 
        uint256 epochDistribute,
        uint256 blockNumber, 
        uint256 stakingIndex, 
        uint8 stakedDecimals, 
        uint256 stakedCirculatingSupply,
        uint256 blockAverage,
        uint8 blockPrecision,
        uint256 stakingBalance) {
        IStakingContract.Epoch memory epoch = IStakingContract(stakingContract).epoch();

        epochNumber = epoch.number;
        epochLength = epoch.length;
        epochEndBlock = epoch.endBlock;
        epochDistribute = epoch.distribute;
        blockNumber = block.number;
        stakingIndex = IStakingContract(stakingContract).index();
        stakedDecimals = IStakedToken(stakedToken).decimals();
        stakedCirculatingSupply = IStakedToken(stakedToken).circulatingSupply();
        blockAverage = ITimeTracker(timeTracker).average();
        blockPrecision = ITimeTracker(timeTracker).PRECISION();
        stakingBalance = IStakedToken(stakedToken).balanceOf(stakingWallet);
    }
}