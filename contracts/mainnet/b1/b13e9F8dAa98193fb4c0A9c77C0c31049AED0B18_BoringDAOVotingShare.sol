/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

// Global Enums and Structs



struct LockAmount{
        uint unlockTime;
        uint amount;
    }

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
}

// Part: ITun

interface ITun {
    function borPledgeInfo(address user) external view returns (uint);
    function lockInfo(address user, uint index) external view returns (LockAmount memory);
    function userLockLength(address account) external view returns (uint);
}

// Part: IUniswapV2Pair

interface IUniswapV2Pair {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// File: BoringDAOVotingShare.sol

contract BoringDAOVotingShare {
    IERC20 constant bor = IERC20(0x3c9d6c1C73b31c837832c72E04D3152f051fc1A9);    
    ITun constant tunnel = ITun(0x258a1eb6537Ae84Cf612f06B557B6d53f49cC9A1);

    IUniswapV2Pair constant uniBor = IUniswapV2Pair(0xc9ca10d36441B5b45d5E63480139105f037972e0);
    IUniswapV2Pair constant sushiBor = IUniswapV2Pair(0x44D34985826578e5ba24ec78c93bE968549BB918);


    
    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "BoringDAO Voting Share";
    }

    function symbol() external pure returns (string memory) {
        return "BoringDAO VS";
    }

    function totalSupply() external view returns (uint) {
        return bor.totalSupply();
    }

    function uni(address account) public view returns (uint) {
        (uint112 borAmount,,) = uniBor.getReserves();
        uint lpAccount = uniBor.balanceOf(account);
        uint lpTotal = uniBor.totalSupply();
        return uint(borAmount) * lpAccount / lpTotal;
    }

    function sushi(address account) public view returns (uint) {
        (uint112 borAmount,,) = sushiBor.getReserves();
        uint lpAccount = sushiBor.balanceOf(account);
        uint lpTotal = sushiBor.totalSupply();
        return uint(borAmount) * lpAccount / lpTotal;
    }

    function tunnelBor(address _voter) public view returns (uint) {
        uint bor2 = tunnel.borPledgeInfo(_voter);
        uint lock;
        uint unlock;
        for (uint i; i < tunnel.userLockLength(_voter); i++) {
            if(block.timestamp >= tunnel.lockInfo(_voter,i).unlockTime) {
                unlock = unlock + tunnel.lockInfo(_voter, i).amount;
            } else {
                lock = lock + tunnel.lockInfo(_voter, i).amount;
            }
        }
        return bor2+lock+unlock;
    }

    function balanceOf(address _voter) external view returns (uint) {
        uint bor1 = bor.balanceOf(_voter) / 2;
        uint bor2 = tunnelBor(_voter);
        uint bor3 = uni(_voter);
        uint bor4 = sushi(_voter);

        return bor1+bor2+bor3+bor4;
    }

    constructor() {}
}