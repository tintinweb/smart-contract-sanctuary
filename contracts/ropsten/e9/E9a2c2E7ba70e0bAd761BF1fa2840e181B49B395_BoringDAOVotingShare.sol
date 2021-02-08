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

// Part: ITunnel

interface ITunnel {
    function borPledgeInfo(address user) external view returns (uint);
    function lockInfo(address user) external view returns (LockAmount[] memory);
}

// File: BoringDAOVotingShare.sol

contract BoringDAOVotingShare {
    // IERC20 constant bor = IERC20(0x3c9d6c1C73b31c837832c72E04D3152f051fc1A9);    
    IERC20 constant bor = IERC20(0xd6866BCFaA2BD463D88a806cFA909E19F44c7D6d);    
    // ITunnel constant tunnel = ITunnel(0x258a1eb6537Ae84Cf612f06B557B6d53f49cC9A1);
    ITunnel constant tunnel = ITunnel(0x2c6D8ae3940A64349D22feD04946d80037A371C3);
    
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

    function userLockAmount(address _voter) public view returns (uint) {

    }

    function balanceOf(address _voter) external view returns (uint) {
        uint bor1 = bor.balanceOf(_voter);
        uint bor2 = tunnel.borPledgeInfo(_voter);

        uint lock;
        uint unlock;
        for (uint i=0; i<tunnel.lockInfo(_voter).length; i++) {
            if(block.timestamp >= tunnel.lockInfo(_voter)[i].unlockTime) {
                unlock = unlock + tunnel.lockInfo(_voter)[i].amount;
            } else {
                lock = lock + tunnel.lockInfo(_voter)[i].amount;
            }
        }
        return bor1+bor2+lock+unlock;

    }

    constructor() {}
}