/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;



// Part: IFeeConverter

interface IFeeConverter { }

// Part: IOwnable

interface IOwnable {
  function acceptOwnership() external;
}

// Part: IFeeRecipient

interface IFeeRecipient {
  function setFeeConverter(IFeeConverter _value) external;
}

// File: TimelockProposal.sol

contract TimelockProposal {

  function execute() external {

    IOwnable(0x21E717a282F88e9a2b129408848FE6d506748735).acceptOwnership();

    IFeeConverter feeConverter = IFeeConverter(0x21E717a282F88e9a2b129408848FE6d506748735);

    IFeeRecipient feeRecipient = IFeeRecipient(0x487502F921BA3DADAcF63dBF7a57a978C241B72C);
    feeRecipient.setFeeConverter(feeConverter);
  }
}