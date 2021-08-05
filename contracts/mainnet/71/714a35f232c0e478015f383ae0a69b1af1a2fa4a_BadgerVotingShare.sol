/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
}


interface IUniswapV2Pair {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface ISett {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getPricePerFullShare() external view returns(uint);
}

interface IGeyser {
    function totalStakedFor(address owner) external view returns (uint);
}

contract BadgerVotingShare {
    IERC20 constant badger = IERC20(0x3472A5A71965499acd81997a54BBA8D852C6E53d);    
    ISett constant sett_badger = ISett(0x19D97D8fA813EE2f51aD4B4e04EA08bAf4DFfC28);
    IGeyser constant geyser_badger = IGeyser(0xa9429271a28F8543eFFfa136994c0839E7d7bF77);
    
    //Badger is token1
    IUniswapV2Pair constant badger_wBTC_UniV2 = IUniswapV2Pair(0xcD7989894bc033581532D2cd88Da5db0A4b12859);
    ISett constant sett_badger_wBTC_UniV2 = ISett(0x235c9e24D3FB2FAFd58a2E49D454Fdcd2DBf7FF1);
    IGeyser constant geyser_badger_wBTC_UniV2 = IGeyser(0xA207D69Ea6Fb967E54baA8639c408c31767Ba62D);  

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "Badger Voting Share";
    }

    function symbol() external pure returns (string memory) {
        return "Badger VS";
    }

    function totalSupply() external view returns (uint) {
        return badger.totalSupply();
    }
    
    /*
        The voter can have Badger in Uniswap in 3 configurations:
         * Staked bUni-V2 in Geyser
         * Unstaked bUni-V2 (same as staked Uni-V2 in Sett)
         * Unstaked Uni-V2
        The top two correspond to more than 1 Uni-V2, so they are multiplied by pricePerFullShare.
        After adding all 3 balances we calculate how much BADGER it corresponds to using the pool's reserves.
    */
    function _uniswapBalanceOf(address _voter) internal view returns(uint) {
        uint bUniV2PricePerShare = sett_badger_wBTC_UniV2.getPricePerFullShare();
        (, uint112 reserve1, ) = badger_wBTC_UniV2.getReserves();
        uint totalUniBalance = badger_wBTC_UniV2.balanceOf(_voter)
            + sett_badger_wBTC_UniV2.balanceOf(_voter) * bUniV2PricePerShare / 1e18 
            + geyser_badger_wBTC_UniV2.totalStakedFor(_voter) * bUniV2PricePerShare / 1e18;
        return totalUniBalance * reserve1 / badger_wBTC_UniV2.totalSupply();
    }
    
    /*
        The voter can have regular Badger in 3 configurations as well:
         * Staked bBadger in Geyser
         * Unstaked bBadger (same as staked Badger in Sett)
         * Unstaked Badger
    */
    function _badgerBalanceOf(address _voter) internal view returns(uint) {
        uint bBadgerPricePerShare = sett_badger.getPricePerFullShare();
        return badger.balanceOf(_voter)
            + sett_badger.balanceOf(_voter) * bBadgerPricePerShare / 1e18 
            + geyser_badger.totalStakedFor(_voter) * bBadgerPricePerShare / 1e18;
    }

    function balanceOf(address _voter) external view returns (uint) {
        return _badgerBalanceOf(_voter) + _uniswapBalanceOf(_voter);
    }

    constructor() {}
}