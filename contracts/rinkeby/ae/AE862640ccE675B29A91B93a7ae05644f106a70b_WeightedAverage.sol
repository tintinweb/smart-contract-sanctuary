// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library WeightedAverage {
    uint256 private constant _PRECISION = 10**18;

    // CALCULATE TIME-WEIGHTED AVERAGE
    /****************************************************************************
    //                                     __                      __          //
    // wA = weightedAmount                /                          \         //
    // a = amout                          |   (a - tA) * (bT - sT)   |         //
    // tA = targetAmount         wA = a + |   --------------------   |         //
    // sT = startTime                     |        (eT - sT)         |         //
    // eT = endTime                       \__                      __/         //
    // bT = block.timestame                                                    //
    //                                                                         //
    ****************************************************************************/

    function calculate(
        uint256 amount,
        uint256 targetAmount,
        uint256 startTime,
        uint256 endTime
    ) external view returns (uint256) {
        if (block.timestamp < startTime) {
            // Update hasn't started, apply no weighting
            return amount;
        } else if (block.timestamp > endTime) {
            // Update is over, return target amount
            return targetAmount;
        } else {
            // Currently in an update, return weighted average
            if (targetAmount > amount) {
                // re-orders above visualized formula to handle negative numbers
                return
                    (_PRECISION *
                        amount +
                        (_PRECISION *
                            (targetAmount - amount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            } else {
                // follows order of visualized formula above
                return
                    (_PRECISION *
                        amount -
                        (_PRECISION *
                            (amount - targetAmount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            }
        }
    }
}