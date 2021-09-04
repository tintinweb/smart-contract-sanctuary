/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IFeeRecipient {
  function setFeeConverter(address _value) external;
}

contract TimelockProposal {

  function execute() external {

    IFeeRecipient feeRecipient = IFeeRecipient(0x487502F921BA3DADAcF63dBF7a57a978C241B72C);

    feeRecipient.setFeeConverter(0x530C7287a61Fd88201eD9F8691A633bbca896DeF);
  }
}