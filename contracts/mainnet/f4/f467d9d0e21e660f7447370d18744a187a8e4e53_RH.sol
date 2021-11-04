/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RH {
  int256 private _one = 1000000000000000000;

  function calc(uint256[] memory separators, int256[] memory params) public view returns (int256[4] memory) {
    int256 totalInvoicedMaterial = params[separators[0]];
    int256 producedSteel = params[separators[2]];
    int256 stopLimit = params[separators[4]];
    int256 contractedValueRatio = params[separators[6]];
    int256 coefficient = params[separators[8]];

    uint256 historyStart = 0;
    uint256 historyEnd = 0;

    int256 status = 0;
    int256 averageProducedSteel = 0;

    int256 lastStopLimit = 0;

    int256 creditDebit = 0;

    if (separators.length > 10) {
      historyStart = separators[10];
      historyEnd = separators[separators.length - 1];

      lastStopLimit = params[historyEnd - 2];

      if (stopLimit != lastStopLimit && params.length == 28) {
        contractedValueRatio = _calculeBaseAdjustment(
          params,
          historyStart,
          historyEnd,
          contractedValueRatio,
          stopLimit
        );

      }
    }

    int256 specificValueRatio = _calculeSpecificValueRatio(
      totalInvoicedMaterial,
      producedSteel
    );

    averageProducedSteel = _calculeAverage(
      params,
      historyStart,
      historyEnd,
      0
    );

    status = _defineStatus(
      coefficient,
      averageProducedSteel,
      producedSteel
    );

    int256 specificPaymentRatio = _calculeSpecificPaymentRatio(
      contractedValueRatio,
      specificValueRatio,
      status
    );

    int256 specificPayment = _calculeSpecificPayment(
      specificPaymentRatio,
      producedSteel
    );

    creditDebit = _calculeteCreditDebit(
      int256(specificPaymentRatio),
      int256(specificValueRatio),
      int256(producedSteel)
    );

    return [
      int256((specificPayment/_one)),
      (status != 0 ? status *  _one : int(0)),
      int256(specificPaymentRatio),
      creditDebit/int(_one)
    ];
  }

  function _calculeSpecificValueRatio(
    int256 totalInvoicedMaterial,
    int256 producedSteel
  ) private view returns (int256) {
    return ((totalInvoicedMaterial * _one) / (producedSteel));
  }

  function _calculeAverage(
    int256[] memory params,
    uint256 start,
    uint256 end,
    uint256 index
  ) private view returns (int256) {

    int256 total = 0;
    int256 counter = 0;
    int256 status = 0;

    for (uint256 i = start; i <= end; i += 4) {
      status = params[i + 2];

      if (status == _one) {
        total += params[i + index];
        counter +=1;
      }
    }

    if (counter > 0) {
      return total / counter;
    }

    return 0;
  }

  function _calculeBaseAdjustment (
    int256[] memory params,
    uint256 historyStart,
    uint256 historyEnd,
    int256 contractedValueRatio,
    int256 stopLimit
  ) private view returns (int256) {
    int256 averageSpecificValueRatio = _calculeAverage(
      params,
      historyStart,
      historyEnd,
      3
    );

    int256 average = (averageSpecificValueRatio + contractedValueRatio) / 2;

    if (average < stopLimit) {
      return average;
    }

    return average;
  }

  function _defineStatus(
    int256 coefficient,
    int256 averageProducedSteel,
    int256 producedSteel
  ) private view returns (int256) {
    if ((producedSteel * _one) < (averageProducedSteel * (coefficient / 100))) {
      return 0;
    }

    return 1;
  }

  function _calculeSpecificPaymentRatio(
    int256 contractedValueRatio,
    int256 specificValueRatio,
    int256 status
  ) private pure returns (int256) {
    if (status == 1) {
      return ((contractedValueRatio) + (specificValueRatio)) / 2;
    }

    return specificValueRatio;
  }

  function _calculeSpecificPayment(int256 specificPaymentRatio, int256 producedSteel) private pure returns (int256) {
    return specificPaymentRatio * producedSteel;
  }

  function _calculeteCreditDebit(
        int256 specificPaymentRatio,
        int256 specificValueRatio,
        int256 producedSteel
    ) private pure returns (int256) {
        int256 creditDebit = (specificPaymentRatio - specificValueRatio) * producedSteel ;
        return creditDebit;
    }
  
}