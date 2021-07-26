/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract PresaleTest {
    struct PresalePancakeSwapInfo {
        uint256 listingPriceInWei;
        uint256 lpTokensLockDurationInDays;
        uint8 liquidityPercentageAllocation;
        uint256 liquidityAllocationTime;
    }
    struct CertifiedAddition {
        bool liquidity;
        bool automatically;
        uint8 vesting;
        address[] whitelist;
        address nativeToken;
    }
    
    function test(PresalePancakeSwapInfo memory _cakeInfo, CertifiedAddition memory _addition) external returns(bool) {
        if(_addition.liquidity){
            require(_cakeInfo.liquidityPercentageAllocation > 0 && _cakeInfo.listingPriceInWei > 0, "Wrong liq param");
        }
        return true;
    }
}