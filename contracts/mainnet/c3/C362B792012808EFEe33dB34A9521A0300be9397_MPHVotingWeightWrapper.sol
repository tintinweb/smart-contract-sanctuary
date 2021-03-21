/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: GPL-v3-or-later
pragma solidity 0.8.1;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// for sushi masterchef
struct UserInfo {
    uint256 amount;     // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
}

interface MasterChef {
    function userInfo(uint256 onsenID, address user) external view returns (UserInfo memory);
}

interface StakingPool {
    function balanceOf(address account) external view returns (uint256);
}

interface Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function totalSupply() external view returns (uint);
}

contract MPHVotingWeightWrapper {
    address public constant mph = 0x8888801aF4d980682e47f1A9036e589479e835C5;
    StakingPool public constant mphStaking = StakingPool(0x98df8D9E56b51e4Ea8AA9b57F8A5Df7A044234e1);
    StakingPool public constant uniLPStaking = StakingPool(0xd48Df82a6371A9e0083FbfC0DF3AF641b8E21E44);
    StakingPool public constant yflLPStaking = StakingPool(0x0E6FA9f95a428F185752b60D38c62184854bB9e1);
    MasterChef public constant masterChef = MasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    uint256 public constant onsenID = 92;
    Pair public constant uniPair = Pair(0x4D96369002fc5b9687ee924d458A7E5bAa5df34E);
    Pair public constant sushiPair = Pair(0xB2C29e311916a346304f83AA44527092D5bd4f0F);
    Pair public constant yflPair = Pair(0x40F1068495Ba9921d6C18cF1aC25f718dF8cE69D);
    
    string public constant symbol = "vMPH";
    uint8 public constant decimals = 9; // sqrt(10**18) = 10**9

    function balanceOf(address account) external view returns (uint256 votes) {
        // MPH in staking pool
        votes += mphStaking.balanceOf(account);
        
        // MPH in LP staking pools
        votes += _getMPHInPair(uniPair, uniLPStaking.balanceOf(account));
        votes += _getMPHInPair(sushiPair, masterChef.userInfo(onsenID, account).amount);
        votes += _getMPHInPair(yflPair, yflLPStaking.balanceOf(account));
        
        // take square root as voting weight
        votes = Babylonian.sqrt(votes);
    }
    
    function _getMPHInPair(Pair pair, uint256 balance) internal view returns (uint256) {
        uint256 totalSupply = pair.totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        address token1 = pair.token1();
        if (token0 == mph) {
            // MPH is token0
            return balance * reserve0 / totalSupply;
        } else if (token1 == mph) {
            // MPH is token1
            return balance * reserve1 / totalSupply;
        } else {
            // wrong LP token?
            return 0;
        }
    }
}