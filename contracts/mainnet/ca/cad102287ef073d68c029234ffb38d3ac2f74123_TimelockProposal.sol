/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IFeeRecipient {
  function setFeeConverter(address _value) external;
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimelockProposal {

  function execute() external {

    address wildDeployer = 0xd7b3b50977a5947774bFC46B760c0871e4018e97;

    IFeeRecipient feeRecipient = IFeeRecipient(0x487502F921BA3DADAcF63dBF7a57a978C241B72C);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    feeRecipient.setFeeConverter(0x31FD80bf06453ACE58bea89727e88003f0e691Bb);

    // Refund gas expenses from block 12924751 to 13177424 for the deployer address
    // https://etherscan.io/address/0xd7b3b50977a5947774bfc46b760c0871e4018e97

    // 6.64 ETH
    weth.transfer(wildDeployer, 6640000000000000000);
  }
}