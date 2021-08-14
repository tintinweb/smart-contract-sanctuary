/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IFeeConverter { }

interface IFeeRecipient {
  function setFeeConverter(IFeeConverter _value) external;
}

contract TimelockProposal {

  function execute() external {

    IFeeConverter feeConverter = IFeeConverter(0x2D2a0E94619393b4B9ff4255ddf77ae68306E840);

    IFeeRecipient feeRecipient = IFeeRecipient(0x487502F921BA3DADAcF63dBF7a57a978C241B72C);
    feeRecipient.setFeeConverter(feeConverter);
  }
}