// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Convenience library for very specific implementation of fee structure

library FeeLibrary {
    struct Fees {
        uint256 reflection;
        uint256 project;
        uint256 liquidity;
        uint256 burn;
        uint256 marketing;
        uint256 ethReflection;
    }

    function setToZero(Fees storage fees) internal {
        fees.reflection = 0;
        fees.project = 0;
        fees.liquidity = 0;
        fees.burn = 0;
        fees.marketing = 0;
        fees.ethReflection = 0;
    }

    function setTo(Fees storage fees, uint256 reflectionFee, uint256 projectFee, uint256 liquidityFee, uint256 burnFee,
            uint256 marketingFee, uint256 ethReflectionFee) public {
        fees.reflection = reflectionFee;
        fees.project = projectFee;
        fees.liquidity = liquidityFee;
        fees.burn = burnFee;
        fees.marketing = marketingFee;
        fees.ethReflection = ethReflectionFee;
    }

    function setFrom(Fees storage fees, Fees storage newFees) public {
        fees.reflection = newFees.reflection;
        fees.project = newFees.project;
        fees.liquidity = newFees.liquidity;
        fees.burn = newFees.burn;
        fees.marketing = newFees.marketing;
        fees.ethReflection = newFees.ethReflection;
    }

    enum FeeLevels {
        LEVEL1,
        LEVEL2,
        LEVEL3,
        LEVEL4,
        LEVEL5
    }

    function getAllFeeLevels() public pure returns(FeeLevels, FeeLevels, FeeLevels, FeeLevels, FeeLevels){
        return (FeeLevels.LEVEL1, FeeLevels.LEVEL2, FeeLevels.LEVEL3, FeeLevels.LEVEL4, FeeLevels.LEVEL5);
    }

    struct SellFees {
        uint256 saleCoolDownTime;
        uint256 saleCoolDownFee;
        uint256 saleSizeLimitPercent;
        uint256 saleSizeLimitPrice;
    }

    struct SellFeeLevels {
        mapping(FeeLevels => SellFees) level;
    }

    function setToZero(SellFees storage fees) internal {
        fees.saleCoolDownTime = 0;
        fees.saleCoolDownFee = 0;
        fees.saleSizeLimitPercent = 0;
        fees.saleSizeLimitPrice = 0;
    }

    function setTo(SellFees storage fees, uint256 upperTimeLimitInHours, uint256 timeLimitFeePercent, uint256 saleSizePercent, uint256 saleSizeFee) internal {
        fees.saleCoolDownTime = upperTimeLimitInHours;
        fees.saleCoolDownFee = timeLimitFeePercent;
        fees.saleSizeLimitPercent = saleSizePercent;
        fees.saleSizeLimitPrice = saleSizeFee;
    }

    function setTo(SellFees storage fees, SellFees storage newFees) internal {
        fees.saleCoolDownTime = newFees.saleCoolDownTime;
        fees.saleCoolDownFee = newFees.saleCoolDownFee;
        fees.saleSizeLimitPercent = newFees.saleSizeLimitPercent;
        fees.saleSizeLimitPrice = newFees.saleSizeLimitPrice;
    }

    function setToZero(SellFeeLevels storage leveledFees) internal {
        leveledFees.level[FeeLevels.LEVEL1] = SellFees(0, 0, 0, 0);
        leveledFees.level[FeeLevels.LEVEL2] = SellFees(0, 0, 0, 0);
        leveledFees.level[FeeLevels.LEVEL3] = SellFees(0, 0, 0, 0);
        leveledFees.level[FeeLevels.LEVEL4] = SellFees(0, 0, 0, 0);
        leveledFees.level[FeeLevels.LEVEL5] = SellFees(0, 0, 0, 0);
    }

    function setFrom(SellFeeLevels storage leveledFees, SellFeeLevels storage newLeveledFees) internal {
        leveledFees.level[FeeLevels.LEVEL1] = newLeveledFees.level[FeeLevels.LEVEL1];
        leveledFees.level[FeeLevels.LEVEL2] = newLeveledFees.level[FeeLevels.LEVEL2];
        leveledFees.level[FeeLevels.LEVEL3] = newLeveledFees.level[FeeLevels.LEVEL3];
        leveledFees.level[FeeLevels.LEVEL4] = newLeveledFees.level[FeeLevels.LEVEL4];
        leveledFees.level[FeeLevels.LEVEL5] = newLeveledFees.level[FeeLevels.LEVEL5];
    }

    function getAll(SellFeeLevels storage leveledFees) public view returns (SellFees memory, SellFees memory, SellFees memory, SellFees memory, SellFees memory) {
        return(leveledFees.level[FeeLevels.LEVEL1], leveledFees.level[FeeLevels.LEVEL2], leveledFees.level[FeeLevels.LEVEL3], leveledFees.level[FeeLevels.LEVEL4], leveledFees.level[FeeLevels.LEVEL5]);
    }


    function initSellFees(SellFeeLevels storage sellFees) internal {
        sellFees.level[FeeLevels.LEVEL1] = SellFees({
        saleCoolDownTime: 6 hours,
        saleCoolDownFee: 35,
        saleSizeLimitPercent: 4,
        saleSizeLimitPrice: 35
        });
        sellFees.level[FeeLevels.LEVEL2] = SellFees({
        saleCoolDownTime: 12 hours,
        saleCoolDownFee: 30,
        saleSizeLimitPercent: 4,
        saleSizeLimitPrice: 35
        });
        sellFees.level[FeeLevels.LEVEL3] = SellFees({
        saleCoolDownTime: 24 hours,
        saleCoolDownFee: 20,
        saleSizeLimitPercent: 3,
        saleSizeLimitPrice: 30
        });
        sellFees.level[FeeLevels.LEVEL4] = SellFees({
        saleCoolDownTime: 48 hours,
        saleCoolDownFee: 15,
        saleSizeLimitPercent: 2,
        saleSizeLimitPrice: 25
        });
        sellFees.level[FeeLevels.LEVEL5] = SellFees({
        saleCoolDownTime: 72 hours,
        saleCoolDownFee: 10,
        saleSizeLimitPercent: 1,
        saleSizeLimitPrice: 20
        });
    }

    struct EthBuybacks {
        uint256 liquidity;
        uint256 redistribution;
        uint256 buyback;
    }
}

