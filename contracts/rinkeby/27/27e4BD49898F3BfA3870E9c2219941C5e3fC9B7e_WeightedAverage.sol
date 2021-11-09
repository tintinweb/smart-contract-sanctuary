// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library WeightedAverage {
    uint256 private constant _PRECISION = 10**18;

    /*
    EXAMPLE:
    _PRECISION = 500
    block.timestamp - startTime = 70
    endTime - startTime = 100

    // scenario 1 :  targetAmount > amount
    amount = 87
    targetAmount = 137

    ### pt 1
    ( _PRECISION*amount + _PRECISION * (targetAmount - amount) * 0.7 ) / _PRECISION;
    ( 500*87 + 500 * (137 - 87) * 0.7 ) / 500  =  122
    ### pt 2
    ( _PRECISION*amount - _PRECISION * (amount - targetAmount) * 0.7 ) / _PRECISION;
    ( 500*87 - 500 * (87 - 137) * 0.7 ) / 500  =  122

    // scenario 2 :  targetAmount < amount
    amount = 201
    targetAmount = 172

    ### pt 1
    ( _PRECISION*amount + _PRECISION * (targetAmount - amount) * 0.7 ) / _PRECISION;
    ( 500*201 + 500 * (172 - 201) * 0.7 ) / 500  =  180.7
    ### pt 2
    ( _PRECISION*amount - _PRECISION * (amount - targetAmount) * 0.7 ) / _PRECISION;
    ( 500*201 - 500 * (201 - 172) * 0.7 ) / 500  =  180.7
    */

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
                return
                    (_PRECISION *
                        amount +
                        (_PRECISION *
                            (targetAmount - amount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            } else {
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