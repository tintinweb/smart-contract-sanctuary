// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library Math {
    function getRateFromBanks(
        uint256 fund1Bank_,
        uint256 fund2Bank_,
        uint256 amount_,
        uint256 team_,
        uint256 marginality_,
        uint256 decimals_
    ) public pure returns (uint256) {
        if (team_ == 1) {
            uint256 pe1 =
                ((fund1Bank_ + amount_) * decimals_) /
                    (fund1Bank_ + fund2Bank_ + amount_);
            uint256 ps1 = (fund1Bank_ * decimals_) / (fund1Bank_ + fund2Bank_);
            uint256 cAmount =
                ceil(
                    ((amount_ * decimals_) / (fund1Bank_ / 100)),
                    decimals_,
                    decimals_
                ) / decimals_; // step?
            uint256 rate =
                (decimals_**3) /
                    (((pe1 * cAmount + ps1 * 2 - pe1 * 2) * decimals_) /
                        cAmount);
            return addMarginality(rate, marginality_, decimals_);
        }

        if (team_ == 2) {
            uint256 pe2 =
                ((fund2Bank_ + amount_) * decimals_) /
                    (fund1Bank_ + fund2Bank_ + amount_);
            uint256 ps2 = (fund2Bank_ * decimals_) / (fund1Bank_ + fund2Bank_);
            uint256 cAmount =
                ceil(
                    ((amount_ * decimals_) / (fund2Bank_ / 100)),
                    decimals_,
                    decimals_
                ) / decimals_;
            uint256 rate =
                (decimals_**3) /
                    (((pe2 * cAmount + ps2 * 2 - pe2 * 2) * decimals_) /
                        cAmount);
            return addMarginality(rate, marginality_, decimals_);
        }
        return 0;
    }

    function ceil(
        uint256 a,
        uint256 m,
        uint256 decimals
    ) public pure returns (uint256) {
        if (a < decimals) return decimals;
        return ((a + m - 1) / m) * m;
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function addMarginality(
        uint256 rate,
        uint256 marginality,
        uint256 decimals
    ) public pure returns (uint256 newRate) {
        //console.log("Rate %s, margin %s", rate, marginality);
        //console.log("1 - 1/kef   ", decimals - decimals**2 / rate);
        uint256 revertRate = decimals**2 / (decimals - decimals**2 / rate);
        //console.log("revert rate", revertRate);
        uint256 marginEUR = decimals + marginality; // decimals
        //console.log("marginEUR rate", marginEUR);
        uint256 a = (marginEUR * (revertRate - decimals)) / (rate - decimals);
        //console.log("a ", a);
        uint256 b =
            ((((revertRate - decimals) * decimals) / (rate - decimals)) *
                marginality +
                decimals *
                marginality) / decimals;
        //console.log("b ", b);
        uint256 c = (2 * decimals - marginEUR);
        //console.log("c ", c);
        newRate =
            ((sqrt(b**2 + 4 * a * c) - b) * decimals) /
            (2 * a) +
            decimals;
        return newRate;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}